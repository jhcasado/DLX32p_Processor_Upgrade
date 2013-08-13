--
-- DLX32p.vhd
--
library IEEE;
use IEEE.std_logic_1164.all;

entity DLX32p is
    port (
        clk: in STD_LOGIC;
        clr: in STD_LOGIC;

	-- AHORA SE MANDARAN 3 DIRECCIONES DE MEMORIA DE PROGRAMA
	-- PARA RECIBIR 3 INSTRUCCIONES SIMULTANEAMENTE
        addr_Pmem,addr_Pmem_IF,addr_Pmem_PRE: out STD_LOGIC_VECTOR (31 downto 0); -- direccion mem programa
        instruction,instruction_IF,instruction_PRE: in STD_LOGIC_VECTOR (31 downto 0); -- dato de la mem programa

        addr_Dmem: out STD_LOGIC_VECTOR (31 downto 0); -- direc mem datos
        data_out_Dmem: out STD_LOGIC_VECTOR (31 downto 0); -- dato escrito en mem datos
        data_in_Dmem: in STD_LOGIC_VECTOR (31 downto 0); -- dato leido de mem datos
        we_Dmem: out STD_LOGIC; -- habilitacion escritura en mem datos
        BR_A,BR_B,BR_W: out STD_LOGIC_VECTOR (31 downto 0);
        BR_WE: out STD_LOGIC
    );
end DLX32p;

architecture DLX32s_arch of DLX32p is

component etapa_IF 
port(
	CLK,RESET: in std_logic;

	-- SENALES DE CONTROL
	-- EIF1=Mux que alimenta el PC y crea una burbuja
	EIF1: in std_logic; 
	-- EIF2=Mux que alimenta el PC sin crear burbuja
	EIF2: in std_logic;

	-- DIRECCION DE SALTO
	-- EIF6= dir salto de la etapa ID
	EIF6: in std_logic_vector(31 downto 0);

	-- DIRECCIONES DE MEMORIA DE PROGRAMA CONSECUTIVAS
	SIF_1,SIF0,SIF1,SIF2: out std_logic_vector(31 downto 0);  -- Salida MUX-PC y PC

	-- INTRODUCE UNA BURBUJA DESDE LA ETAPA ID
	burbuja:in std_logic
    );
end component ;

component idp 
port(
	clr,clock: in std_logic;
	
	-- RECOGEMOS LOS 3 NPC DE LAS 3 INSTRUCCIONES RECOGIDAS
	-- PARA NO RECALCULARLOS SI SE ANTICIPA ALGUN SALTO
	NextPC,NextPC_IF,NextPC_PRE: in std_logic_vector(31 downto 0); -- PC + 4
	
	-- LAS 3 INSTRUCCIONES SEGUIDAS EN MEMORIA
	instruccion,instruccion_IF,instruccion_PRE,Data_W: in std_logic_vector(31 downto 0); -- codigo instruccion en PC y dato a escribir
	
	ALU_control: out std_logic_vector(5 downto 0); -- palabra control ALU
	b_dir_W: in std_logic_vector(4 downto 0); -- direccion de registro de escritura
	WE_b32x32_ext: in std_logic; -- habilitacion escritura en banco registros, desde WB
	control_word, Data_A, Data_B, inmediato, NextPC_out: out std_logic_vector(31 downto 0);  -- Salida: control,PA,PB,inmediato, PC+4
	Reg_W: out std_logic_vector(4 downto 0);
	
	-- DATO DE SALIDA DE LA ALU PARA ANTICIPACIONES EN SALTOS
	alu_out_EX_MEM: in std_logic_vector(31 downto 0);
	
	-- DATOS DE CONTROL DE LAS ETAPAS EX Y MEM
	control_ID_EX: in std_logic_vector(6 downto 0);
	control_EX_MEM: in std_logic_vector(6 downto 0);
	
	-- INDICADORES DE SALTO EN ETAPAS
	saltado_en_if,saltado_en_pre: in std_logic;
	
	-- INDICADOR DE BURBUJA
	burbuja: out std_logic;
	
	-- MUX's DE ANTICIPACIONES EN EL CAMINO
	-- PARA LA INSTRUCCION ACTUAL
        anticipa_EX_A: out std_logic_vector (1 downto 0);
        anticipa_EX_B: out std_logic_vector (1 downto 0);
        anticipa_MEM_B: out std_logic;
        
        -- CONTROL PARA QUE LOS SALTOS ANTICIPADOS
        -- NO SE REPITAN AL PROVENIR DE INSTRUCCIONES
        -- POSTERIORES AL SALTO
        salto_IF,salto_PRE: out std_logic
    );
end component;

component ex 
    port (
    	MUX_A_control,MUX_B_control: in STD_LOGIC; -- bit de control MUX_ALU_A y MUX_ALU_B
    	-- palabra de control de la ALU
        ALU_control: in STD_LOGIC_VECTOR (5 downto 0);
        -- NextPC=PC+4, Data_A,Data_B= Banco, Inm= inmediato
        NextPC,Data_A,Data_B,Inm: in STD_LOGIC_VECTOR (31 downto 0);
        -- ALUout= salida de la ALU
        ALU_out: out STD_LOGIC_VECTOR (31 downto 0)
    );
end component;

component wb 
    port (
        data_mem: in STD_LOGIC_VECTOR (31 downto 0);
        data_ALU: in STD_LOGIC_VECTOR (31 downto 0);
        mux_wb: in STD_LOGIC;
        data_WB: out STD_LOGIC_VECTOR (31 downto 0)
    );
end component;

signal ALU_out_int,dataW_int,NPC,NPC_PRE,NPC_IF,NPCout,dataRS,dataRT,INM,control : STD_LOGIC_VECTOR (31 downto 0);
signal controlALU : STD_LOGIC_VECTOR (5 downto 0); -- palabra de control de la ALU
signal MUX_PC,MUX_ALU_A,MUX_ALU_B,MUX_wb: std_logic; -- sanales de control de muxs desde CONTROL.VHD
signal n_clk: std_logic; -- not(clk)
signal reg_IF_ID : STD_LOGIC_VECTOR (194 downto 0); -- segmento IF/ID
--CAMBIO2
--signal reg_ID_EX : STD_LOGIC_VECTOR (148 downto 0); -- segmento ID/EX
signal reg_ID_EX : STD_LOGIC_VECTOR (153 downto 0); -- segmento ID/EX
--FINCAMBIO2
signal reg_EX_MEM : STD_LOGIC_VECTOR (73 downto 0); -- segmento EX/MEM
signal reg_MEM_WB : STD_LOGIC_VECTOR (71 downto 0); -- segmento MEM/WB
signal ena_IF_ID,ena_ID_EX,ena_EX_MEM,ena_MEM_WB: std_logic;
--CAMBIO
signal WE_b32x32,mux_rt_rd,clr_idp: std_logic;
--FINCAMBIO
--CAMBIO2
signal salto_IF,salto_PRE: std_logic;
signal anticipa_EX_A: std_logic_vector (1 downto 0);
signal anticipa_EX_B: std_logic_vector (1 downto 0);
signal anticipa_MEM_B: std_logic;
signal burbuja,MUX_PC_SIN_BURBUJA: std_logic;
signal idp_control_ID_EX: STD_LOGIC_VECTOR (6 downto 0);
signal idp_control_EX_MEM: STD_LOGIC_VECTOR (6 downto 0);
signal data_A_adelantado, data_B_adelantado : STD_LOGIC_VECTOR (31 downto 0);
--FINCAMBIO2
signal control_ID_EX: STD_LOGIC_VECTOR (8 downto 0);
--signal MUX_rt_rd,MUX_PC,WE_b32x32,MUX_ALU_A,MUX_ALU_B,WE_mem,MUX_wb,beq,j: std_logic;
signal control_EX_MEM: STD_LOGIC_VECTOR (2 downto 0);
signal control_MEM_WB: STD_LOGIC_VECTOR (1 downto 0);
signal dir_rt_rd,dir_W,dir_rt_rd_EX_MEM,dir_rt_rd_MEM_WB: STD_LOGIC_VECTOR (4 downto 0);

begin

n_clk <= not(clk);

u1: etapa_IF port map(
	CLK => clk, RESET => clr, -- entradas generales del procesador

	-- SENALES DE CONTROL
	-- EIF1=Mux que alimenta el PC y crea una burbuja
	EIF1 => MUX_PC,
	-- EIF2=Mux que alimenta el PC sin crear burbuja
	-- EIF2=Mux que alimenta el PC, viene de la etapa ID
	EIF2 => MUX_PC_SIN_BURBUJA, 

	-- DIRECCION DE SALTO
	-- EIF6= dir salto de la etapa ID
	EIF6 => NPCout, 

	-- DIRECCIONES DE MEMORIA DE PROGRAMA CONSECUTIVAS
	SIF_1 => NPC_PRE,SIF0 => NPC_IF, SIF1 => NPC, SIF2 => addr_Pmem,  -- Salida MUX-PC y PC

	-- INTRODUCE UNA BURBUJA DESDE LA ETAPA ID
	burbuja => burbuja -- Indica al PC que no se mueva
    );

-- TAMBIEN BUSCAMOS LAS 2 SIGUIENTES INTRUCCIONES A LA ACTUAL
-- PARA REALIZAR LAS ANTICIPACIONES DE LOS SALTOS
addr_Pmem_PRE <= NPC_IF;
addr_Pmem_IF <= NPC;

-- Registro del segmento IF/ID 64 bits
-- Guarda la salida del mux-PC y la salida de mem programa
ena_IF_ID <= '1'; -- por ahora se habilita siempre
process(clk,clr,NPC,NPC_PRE,NPC_IF,instruction,instruction_IF,instruction_PRE,burbuja,MUX_PC,salto_IF,salto_PRE)
begin
  if (clr='0') then
	reg_IF_ID <= (others=>'0');
  elsif (CLK='1' and CLK'event) then
        if (ena_IF_ID='1' and burbuja='0') then
	    reg_IF_ID(31 downto 0) <= NPC;

	    -- CUANDO EL SALTO SE REALIZA CON LA INSTRUCCION DE LA ETAPA ID
	    -- TENEMOS QUE DESCARTAR LA INSTRUCCION QUE VIENE DE LA ETAPA IF
	    -- AL NO UTILIZAR SALTOS RETARDADOS	    
	    if (MUX_PC='1') then
			reg_IF_ID(63 downto 32) <= (others=>'0');
		        reg_IF_ID(96 downto 65) <= (others=>'0');
		        reg_IF_ID(128 downto 97) <= (others=>'0');
	    else			
			reg_IF_ID(63 downto 32) <= instruction; 	    
		        reg_IF_ID(96 downto 65) <= instruction_IF; 	    
		        reg_IF_ID(128 downto 97) <= instruction_PRE; 
	    end if;
	    
	    reg_IF_ID(64) <= '1'; -- senal que indica que se transmite instruccion 	    

	    -- NEXT_PC DE LAS SIGUIENTES INSTRUCCIONES PARA NO RECALCULARLOS
	    reg_IF_ID(160 downto 129) <= NPC_IF; 
	    reg_IF_ID(192 downto 161) <= NPC_PRE;
	    
	    -- INDICADORES DE CUAL HA SIDO LA INSTRUCCION QUE
	    -- HA ANTICIPADO EL SALTO 
	    -- USADAS POSTERIORMENTE POR LA UNIDAD DE ANTICIPACION
	    -- DE SALTOS PARA QUE NO REPITA EL SALTO DADO
	    reg_IF_ID(193) <= Salto_IF; 
	    reg_IF_ID(194) <= Salto_PRE; 
	end if;
  end if;
end process;
-- clr_idp habilita a actuar la etapa idp cuando llega una instruccion al segmento
clr_idp <= clr and reg_IF_ID(64);


--CAMBIO2

-- DATOS DE CONTROL DE LAS DISTINTAS ETAPAS PARA LA REALIZACION CORRECTA
-- DE ANTICIPACIONES Y BURBUJAS

-- control(9) : SC -> SALTO QUE USA REGISTROS 1:SI
-- reg_ID_EX(70) : WE_b32_32_ID_EX -> ESCRIBE ALGUN REGISTRO EN LA ETAPA EX 1:SI
-- reg_EX_MEM(66) : WE_b32_32_EX_MEM-> ESCRIBE ALGUN REGISTRO EN LA ETAPA MEM 1:SI
-- reg_ID_EX(66) : MUX_WB_ID_EX -> EL DATO A ESCRIBIR VIENE DE MEMORIA EN LA ETAPA EX 0:SI
-- reg_EX_MEM(64) : MUX_WB_EX_MEM -> EL DATO A ESCRIBIR VIENE DE MEMORIA EN LA ETAPA MEM 0:SI
-- control(5) : MUX_ALU_A -> SE USARA A EN LA ALU 1:SI
-- control(4) : MUX_ALU_B -> SE USARA B EN LA ALU 0:SI
-- reg_IF_ID(57 downto 53) : DIR_A -> DIRECCION DEL REGISTRO A
-- reg_IF_ID(52 downto 48) : DIR_B -> DIRECCION DEL REGISTRO B
-- reg_ID_EX(83 downto 79) : DIR_DEST_ID_EX -> DIRECCION DEL REGISTRO DE DESTINO DE LA ETAPA EX
-- reg_EX_MEM(71 downto 67) : DIR_DEST_EX_MEM -> DIRECCION DEL REGISTRO DE DESTINO DE LA ETAPA MEM

-- reg_ID_EX[WE_b32x32 & MUX_wb & dir_rt_rd]
idp_control_ID_EX<=reg_ID_EX(70) & reg_ID_EX(66) & reg_ID_EX(83 downto 79);

-- reg_EX_MEM[WE_b32x32 & MUX_wb & dir_rt_rd]
idp_control_EX_MEM<=reg_EX_MEM(66) & reg_EX_MEM(64) & reg_EX_MEM(71 downto 67);

--FINCAMBIO2

u2: idp port map(
	clr => clr_idp, clock => n_clk, -- esta senal va directamente al banco registros

	-- RECOGEMOS LOS 3 NPC DE LAS 3 INSTRUCCIONES RECOGIDAS
	-- PARA NO RECALCULARLOS SI SE ANTICIPA ALGUN SALTO
	NextPC => reg_IF_ID(31 downto 0), -- NPC, PC + 4
	NextPC_IF => reg_IF_ID(160 downto 129), -- NNPC, PC + 8
	NextPC_PRE => reg_IF_ID(192 downto 161), -- NNNPC, PC + 12

	-- LAS 3 INSTRUCCIONES SEGUIDAS EN MEMORIA
	instruccion => reg_IF_ID(63 downto 32), -- instruction 
	instruccion_IF => reg_IF_ID(96 downto 65), -- instruction_IF
	instruccion_PRE => reg_IF_ID(128 downto 97), -- instruction_PRE

	Data_W => dataW_int, -- dato a escribir en banco de registros en puerto W
	ALU_control => controlALU, -- palabra control ALU
	b_dir_W => dir_W, -- direccion de registro de escritura que viene de la etapa WB
	WE_b32x32_ext => WE_b32x32, -- senal que viene desde WB
	control_word=>control, Data_A=>dataRS, Data_B=>dataRT, inmediato=>INM, -- Salida: control,PA,PB,inmediato
	NextPC_out => NPCout, -- Salida: Direccion del salto
	Reg_W=>dir_rt_rd, -- Salida: Registro de escritura

	-- DATO DE SALIDA DE LA ALU PARA ANTICIPACIONES EN SALTOS
	alu_out_EX_MEM=>reg_EX_MEM(31 downto 0),

	-- DATOS DE CONTROL DE LAS ETAPAS EX Y MEM
	control_ID_EX=>idp_control_ID_EX,
	control_EX_MEM=>idp_control_EX_MEM,

	-- INDICADORES DE SALTO EN ETAPAS
	saltado_en_if=>reg_IF_ID(193), saltado_en_pre=>reg_IF_ID(194),

	-- INDICADOR DE BURBUJA
	burbuja=>burbuja,

	-- MUX's DE ANTICIPACIONES EN EL CAMINO
	-- PARA LA INSTRUCCION ACTUAL
        anticipa_EX_A=>anticipa_EX_A,
        anticipa_EX_B=>anticipa_EX_B,
        anticipa_MEM_B=>anticipa_MEM_B,

        -- CONTROL PARA QUE LOS SALTOS ANTICIPADOS
        -- NO SE REPITAN AL PROVENIR DE INSTRUCCIONES
        -- POSTERIORES AL SALTO
        salto_IF=>salto_IF, salto_PRE=>salto_PRE
    );

-- ALIMENTAN A LA ETAPA IF PARA INDICAR SI SE SALTA
MUX_PC <= control(7); -- borra la instruccion que hay ahora mismo en IF
MUX_PC_SIN_BURBUJA <= control(9); 		


-- CREA UNA BURBUJA EN LA ETAPA ID Y PARA NO PROPAGAR LA INSTRUCCION
-- ACTUAL MODIFICAMOS SUS CONTROLES PARA QUE NO HAGA NADA
-- EN LAS ETAPAS POSTERIORES
with burbuja select
-- Palabra de control que se transmite a la etapa EX desde la etapa ID
-- control_ID_EX <= MUX_rt_rd & MUX_PC & WE_b32x32 & MUX_ALU_A & MUX_ALU_B & WE_mem & MUX_wb & beq & j;
	control_ID_EX <= control(8 downto 0) when '0',
			 "000010000" when others;

-- senales del Banco de registros que se visualizan en simulacion
BR_A <= dataRS; BR_B <= dataRT; BR_W <= dataW_int;
BR_WE <= WE_b32x32; --control(6);

--
-- Registro del segmento ID/EX  bits
--
-- El banco de regs es un registro por lo que no hace falta guardar los datos A y B 
-- otra vez en regs: dataRS y dataRT
-- El reg ID/EX Guarda la salida del mux-PC y la salida de mem programa
ena_ID_EX <= '1'; -- por ahora se habilita siempre
process(clk,clr,NPCout,INM,control_ID_EX,controlALU,dir_rt_rd,reg_IF_ID,anticipa_EX_A,anticipa_EX_B,anticipa_MEM_B)
begin
  if (clr='0' or reg_IF_ID(64)='0') then
	reg_ID_EX <= (others=>'0');
  elsif (clk='1' and clk'event) then
        if (ena_ID_EX='1') then
-- CAMBIO
-- NPCout AHORA CONTIENE LA DIRECCION DEL SALTO
-- SE SUSTITUYE POR NPC(PC+4) DE LA ETAPA ID
--	    reg_ID_EX(31 downto 0) <= NPCout; -- NPC
	    reg_ID_EX(31 downto 0) <= reg_IF_ID(31 downto 0); -- NPC
-- FINCAMBIO	    
	    reg_ID_EX(63 downto 32) <= INM; -- inmediato	
	    reg_ID_EX(72 downto 64) <= control_ID_EX; -- senales de control generales  
	    reg_ID_EX(78 downto 73) <= controlALU; -- senales de control de la ALU
	    reg_ID_EX(83 downto 79) <= dir_rt_rd; -- direccion de registro de escritura en banco
	    reg_ID_EX(84) <= reg_IF_ID(64); -- senal que indica que se transmite instruccion
	    reg_ID_EX(116 downto 85) <= dataRS; -- data_A
	    reg_ID_EX(148 downto 117) <= dataRT; -- data_B
--CAMBIO2
	    -- MUX's DE LAS ANTICIPACIONES
	    reg_ID_EX(150 downto 149) <= anticipa_EX_A; -- data_A
	    reg_ID_EX(152 downto 151) <= anticipa_EX_B; -- data_B
	    reg_ID_EX(153) <= anticipa_MEM_B; -- data_B
--FINCAMBIO2
	end if;
  end if;
end process;

-- Senales de control que sale del registro ID/EX
-- MUX_wb <= reg_ID_EX(66); --control(2);
-- we_Dmem <= reg_ID_EX(67); --control(3);
MUX_ALU_B <= reg_ID_EX(68); --control(4);
MUX_ALU_A <= reg_ID_EX(69); --control(5);
-- CAMBIO
-- MUX_PC <= EL SALTO SE HA ADELANTADO A LA ETAPA ID
-- FIN CAMBIO

--CAMBIO2
-- Adelanta Data A
with reg_ID_EX(150 downto 149) select -- anticipa_EX_A
	data_A_adelantado <= reg_EX_MEM(31 downto 0) when "10",    -- anticipa de MEM
			     dataW_int when "01",                  -- anticipa de WB
			     reg_ID_EX(116 downto 85) when others; -- no anticipa

-- Adelanta Data B
with reg_ID_EX(152 downto 151) select -- anticipa_EX_B
	data_B_adelantado <= reg_EX_MEM(31 downto 0) when "10",     -- anticipa de MEM
			     dataW_int when "01",                   -- anticipa de WB
			     reg_ID_EX(148 downto 117) when others; -- no anticipa
--FINCAMBIO2

u3: ex port map(
	-- control de muxs de la ALU
    	MUX_A_control=>MUX_ALU_A, MUX_B_control=>MUX_ALU_B, 
    	-- palabra de control de la ALU
        ALU_control => reg_ID_EX(78 downto 73), --controlALU,
        -- NextPC=PC+4, Data_A,Data_B= Banco, Inm= inmediato
        NextPC => reg_ID_EX(31 downto 0), --NPCout, 
--CAMBIO2
	-- ENTRAN LOS DATOS YA ADELANTADOS
        Data_A => data_A_adelantado , --dataRS, 
        Data_B => data_B_adelantado , --dataRT, 
--FINCAMBIO2
        Inm => reg_ID_EX(63 downto 32), --INM,
        -- ALUout= salida de la ALU a salida del procesador y entrada WB y entrada a IF
        ALU_out => ALU_out_int );

--
-- Registro del segmento EX/MEM  bits
--
ena_EX_MEM <= '1'; -- por ahora se habilita siempre

-- Palabra de control que se transmite a la etapa MEM desde la etapa EX
-- control_EX_MEM <= WE_b32x32 & WE_mem & MUX_wb;
control_EX_MEM <= reg_ID_EX(70) & reg_ID_EX(67) & reg_ID_EX(66);

dir_rt_rd_EX_MEM <= reg_ID_EX(83 downto 79);

process(clk,clr,ALU_out_int,dataRT,control_EX_MEM,dir_rt_rd_EX_MEM,reg_ID_EX)
begin
  if (clr='0' or reg_ID_EX(84)='0') then
	reg_EX_MEM <= (others=>'0');
  elsif (clk='1' and clk'event) then
        if (ena_EX_MEM='1') then
	    reg_EX_MEM(31 downto 0) <= ALU_out_int; -- Salida de la ALU
--CAMBIO2
	    -- ENTRA EL DATO B YA ACTUALIZADO PARA LAS SW
	    reg_EX_MEM(63 downto 32) <= data_B_adelantado; --dataRT; dato del banco de registros Puerto B	
--FINCAMBIO2
	    reg_EX_MEM(66 downto 64) <= control_EX_MEM; --WE_b32x32 & WE_mem & MUX_wb 
	    reg_EX_MEM(71 downto 67) <= dir_rt_rd_EX_MEM; --reg_ID_EX(83 downto 79); dir_rt_rd; -- direccion de registro de escritura en banco
	    reg_EX_MEM(72) <= reg_ID_EX(84); -- senal que indica que se transmite instruccion

--CAMBIO2
	    -- MUX DE ANTICIPACION
	    reg_EX_MEM(73) <= reg_ID_EX(153); -- ANTICIPA_MEM_B
--FINCAMBIO2
	end if;
  end if;
end process;

--CAMBIO2
-- ANTICIPA DE WB EL DATO A ESCRIBIR EN MEMORIA POR UNA SW
-- ESTE CASO SOLO SE PRODUCIRA CUANDO A UNA INSTRUCCION LW
-- LEE DE MEMORIA EL DATO QUE UNA SW QUE LE SIGUE ESCRIBE
-- EN MEMORIA
with reg_EX_MEM(73) select  -- ANTICIPA_MEM_B
	data_out_Dmem <= reg_MEM_WB(31 downto 0) when '1',   -- anticipa de WB la B de una LW
			 reg_EX_MEM(63 downto 32) when others;
--FINCAMBIO2

addr_Dmem <= reg_EX_MEM(31 downto 0); --ALU_out_int; 
we_Dmem <= reg_EX_MEM(65); -- WE de memoria de datos

-- Palabra de control que se transmite a la etapa WB desde la etapa MEM
-- control_MEM_WB <= WE_b32x32 & MUX_wb;
control_MEM_WB <= reg_EX_MEM(66) & reg_EX_MEM(64);

--
-- Registro del segmento MEM/WB  bits
--
ena_MEM_WB <= '1'; -- por ahora se habilita siempre

dir_rt_rd_MEM_WB <= reg_EX_MEM(71 downto 67);

process(clk,clr,data_in_Dmem,control_MEM_WB,dir_rt_rd_MEM_WB,reg_EX_MEM)
begin
  if (clr='0' or reg_EX_MEM(72)='0') then
	reg_MEM_WB <= (others=>'0');
  elsif (clk='1' and clk'event) then
        if (ena_MEM_WB='1') then
	    reg_MEM_WB(31 downto 0) <= data_in_Dmem; -- Salida de la memoria de datos que se introduce en el proc
	    reg_MEM_WB(36 downto 32) <= dir_rt_rd_MEM_WB; --reg_EX_MEM(71 downto 67); dir_rt_rd
	    reg_MEM_WB(38 downto 37) <= control_MEM_WB; -- senales de control: WE_b32x32 & MUX_wb
	    reg_MEM_WB(70 downto 39) <= reg_EX_MEM(31 downto 0); -- ALU_out_int; Salida de la ALU
	    reg_MEM_WB(71) <= reg_EX_MEM(72); -- senal que indica que se transmite instruccion
	end if;
  end if;
end process;

MUX_wb <= reg_MEM_WB(37); --control(2); va a etpa WB
WE_b32x32 <= reg_MEM_WB(38); --control(6); va a etapa ID
dir_W <= reg_MEM_WB(36 downto 32); -- direccion del puerto de escritura en banco registros

u4: wb port map(
        data_mem => reg_MEM_WB(31 downto 0), --data_in_Dmem, -- entrada desde la memoria de datos
        data_ALU => reg_MEM_WB(70 downto 39), -- salida de la ALU
        mux_wb => MUX_wb, -- control del mux de esta etapa
        data_WB => dataW_int -- dato que se escribe en el banco de registros en el puerto W
    );

end DLX32s_arch;
