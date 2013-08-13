--
-- IDp.VHD
--
-- Etapa de decodificacion en DLX32p, especialmente para el procesador segmentado
-- La diferencia del no segmentado es que la direccion de escritura en banco de
-- registros se ha anadido a la entity.
-- La condicion dir_W<= instruccion(15 downto 11) when (mux_rt_rd='1') else instruccion(20 downto 16);
-- se ha pasado a dlx32p.vhd -- HA VUELTO A ESTA UNIDAD
-- Se han anadido nuevas unidades:
-- unidad de salto: unidad de calculo del salto
-- unidad de anticipaciones: senales de anticipacion para la instruccion
-- unidad de riesgos: senal de burbuja en caso de riesgo
-- unidad de anticipacion de salto: anticipa el salto de instrucciones posteriores
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.dlx_pack.all;

entity idp is
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
end idp;

architecture comportamental of idp is

component control 
port(
	clr: in std_logic;
	COP: in TypeDlxOpcode; -- codigo operacion 6 bits
	func: in TypeDlxFunc; -- campo func 6 bits
	cond_Z: in std_logic; -- contenido registro cero (Z=1)
	MUX_rt_rd,MUX_PC,WE_b32x32,MUX_ALU_A,MUX_ALU_B,WE_mem,MUX_wb,tam_inm,signo_inm,
--CAMBIO
	jal: out std_logic;  -- control de registro de escritura R31 para las inst. jal
	MUX_salto: out std_logic_vector(1 downto 0);  -- tipo de calculo del salto
--FINCAMBIO
	ALU_op: out std_logic_vector(5 downto 0);
-- CAMBIO2
	-- Indica si es un salto que necesita la lectura de un registro
	-- (beqz o jr)
	salto_con_registro: out std_logic
-- FINCAMBIO2
	);
end component;

component b32x32  
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
-- ANADIDO UN NUEVO PUERTO DE LECTURA PARA LA ANTICIPACION DE SALTOS
-- P4: tercer puerto de lectura
port ( DAT_P1W_up : in STD_LOGIC_VECTOR (31 downto 0); 
	DIR_P1W_up,DIR_P2R_up,DIR_P3R_up,

	-- DIRECCION DEL TERCER PUERTO DE LECTURA
	DIR_P4R_up: in STD_LOGIC_VECTOR (4 downto 0); 

	WE_up,CLK_up : in STD_LOGIC; 
	DAT_P2R_up,DAT_P3R_up,

	-- TERCER PUERTO DE LECTURA
	DAT_P4R_up : out STD_LOGIC_VECTOR (31 downto 0) ); 
end component; 

component inm
port(
	-- TAMANO: 16 O 26 BITS
	tam,
	-- SIGNO: ENTERO O NATURAL
	signo: in std_logic;  -- tamano del inmediato 16/26, signo no/si
	parte_instruccion: in std_logic_vector(25 downto 0);  -- inmediato 26 bits
	inmediato: out std_logic_vector(31 downto 0)  -- Salida ExtSig(inmediato) 32 bits
    );
end component;

component salto
port(
	-- PARA INDICAR SI SE SE ESCRIBE EN IAR
	MUX_PC: in std_logic;
	-- TIPO DE CALCULO PARA EL SALTO
        Salto_control: in STD_LOGIC_VECTOR (1 downto 0);  -- viene de la unidad de control
        -- DATOS PARA REALIZAR EL CALCULO
        NextPC,Dato_RS,Inme: in STD_LOGIC_VECTOR (31 downto 0);  -- PC+4,RS,ExtSig(Inm)
        Salto_out: out STD_LOGIC_VECTOR (31 downto 0)  -- Direccion del salto
    );
end component;

component burbujas
    port (
	-- SENALES DE CONTROL DE LA ETAPA EX
        WE_b32_32_ID_EX: in std_logic;
        MUX_wb_ID_EX: in std_logic;
        dir_rt_rd_ID_EX: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LA ETAPA MEM
        WE_b32_32_EX_MEM: in std_logic;
        MUX_wb_EX_MEM: in std_logic;
        dir_rt_rd_EX_MEM: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LA INSTRUCCION ACTUAL
        MUX_alu_a: in std_logic;
        MUX_alu_b: in std_logic;
        salto_con_registro: in std_logic;
        dir_rs: in std_logic_vector (4 downto 0);
        dir_rt: in std_logic_vector (4 downto 0);

	-- INDICADOR DE BURBUJA
        burbuja: out std_logic
    );
end component;

component anticipaciones
    port (
	-- SENALES DE CONTROL DE LA ETAPA EX
        WE_b32_32_ID_EX: in std_logic;
        MUX_wb_ID_EX: in std_logic;
        dir_rt_rd_ID_EX: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LA ETAPA MEM
        WE_b32_32_EX_MEM: in std_logic;
        MUX_wb_EX_MEM: in std_logic;
        dir_rt_rd_EX_MEM: in std_logic_vector (4 downto 0);

	-- RS Y RT PARA LAS COMPARACIONES
        dir_rs: in std_logic_vector (4 downto 0);
        dir_rt: in std_logic_vector (4 downto 0);

	-- SENALES DE ANTICIPACIONES PARA LA INSTRUCCION ACTUAL
	anticipa_ID_A: out std_logic;
        anticipa_EX_A: out std_logic_vector (1 downto 0);
        anticipa_EX_B: out std_logic_vector (1 downto 0);
        anticipa_MEM_B: out std_logic
    );
end component;


component anticipa_saltos 
    port (
	-- SENALES DE CONTROL DE LA ETAPA PRE (ANTES DE LA IF)
        WE_b32_32_IF: in std_logic;
        MUX_wb_IF: in std_logic;
        dir_rt_rd_IF: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LA ETAPA IF
        WE_b32_32_IF_ID: in std_logic;
        MUX_wb_IF_ID: in std_logic;
        dir_rt_rd_IF_ID: in std_logic_vector (4 downto 0);
    
	-- SENALES DE CONTROL DE LA ETAPA EX
        WE_b32_32_ID_EX: in std_logic;
        MUX_wb_ID_EX: in std_logic;
        dir_rt_rd_ID_EX: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LA ETAPA MEM
        WE_b32_32_EX_MEM: in std_logic;
        MUX_wb_EX_MEM: in std_logic;
        dir_rt_rd_EX_MEM: in std_logic_vector (4 downto 0);

	-- SENALES DE CONTROL DE LAS INSTRUCCIONES PRE E IF
	-- si hay un salto jal en PRE no debe saltar
	-- puesto que debe escribir en R31
	control_jal_PRE: in std_logic;
	-- indicadores de uso de un registro para los saltos
        salto_con_registro_PRE,salto_con_registro_IF,salto_con_registro: in std_logic;
        -- salto relativo o no, diferencia entre beqz y jr para
        -- determinar si usar Z_PRE_IF
        salto_relativo_PRE,salto_relativo_IF,salto_relativo: in std_logic;
        -- direccion del registro de lectura para la deteccion de
        -- anticipaciones o riesgos
        dir_rs_PRE_IF: in std_logic_vector (4 downto 0);
        -- indicacion de salto para las instrucciones beqz
        Z,Z_PRE_IF: in std_logic;
        -- indicaciones para no repetir un salto ya tomado
	saltado_en_if,saltado_en_pre: in std_logic;

	-- INDICA LA REALIZACION DE LOS SALTOS
        MUX_PC, MUX_PC_IF, MUX_PC_PRE: in std_logic;

	-- ANTICIPA EL REGISTRO DE LECTURA PARA PRE E IF
	anticipa_ID_A_PRE_IF: out std_logic;
	
	-- REALIZA UN SALTO DESCARTANDO LA INSTRUCCION SIGUIENTE
	-- SOLO SE USARA EN SALTOS DE LA INSTRUCCION ACTUAL
	MUX_PC_CON_BURBUJA: out std_logic;
	
	-- SALTA SIN PARAR LA ENTRADA DE INSTRUCCIONES
	MUX_PC_SIN_BURBUJA: out std_logic;
	
	-- DIRA QUE INSTRUCCION ES LA QUE SALTA PARA SELECCIONAR
	-- LOS DATOS CORRESPONDIENTES A ESA INSTRUCCION
	-- 00: ID ; 01: IF ; 10: PRE
	MUX_NPC: out std_logic_vector(1 downto 0);

	-- SELECCIONA EL RS A UTILIZAR PARA EL SALTO	
	MUX_DATA_RS: out std_logic;
	
	-- INDICADORES PARA LA INSTRUCCION QUE VIENE DE QUE SE
	-- HA SALTADO EN ESA ETAPA
	-- salto_IF alimentara saltado_en_if en el ciclo sig.
	-- salto_PRE alimentara saltado_en_pre en el ciclo sig.
	salto_IF,salto_PRE: out std_logic
    );
end component;



signal cond_control_Z_PRE_IF_ID,Z_PRE_IF,mux_rt_rd,mux_pc,b32x32_we,mux_wb,mux_alu_a,mux_alu_b,control_isigno,control_itam,Z,control_jal: std_logic;
signal inme,inme_IF,inme_PRE: std_logic_vector(31 downto 0);
signal control_IF,control_PRE: std_logic_vector(18 downto 0);
signal dir_salto: std_logic_vector(31 downto 0);
signal DataA,Data_PRE_IF: std_logic_vector(31 downto 0); 
signal dir_rt_rd_IF_ID,dir_W,Reg_W_IF,Reg_RS_PRE_IF: std_logic_vector(4 downto 0); 
signal Mux_Reg_W,Mux_Reg_W_IF: std_logic_vector(1 downto 0);
signal MUX_NPC,Mux_tipo_salto: std_logic_vector(1 downto 0);
-- CAMBIO2
signal Data_Salto,Data_Salto_PRE_IF: std_logic_vector(31 downto 0); 
signal salto_con_registro,MUX_DATA_RS,MUX_PC_CON_BURBUJA,MUX_PC_SIN_BURBUJA: std_logic;
signal anticipa_ID_A,anticipa_ID_A_PRE_IF,mux_pc_j: std_logic;
signal SALTO_mux_pc: std_logic;
signal SALTO_salto_control: std_logic_vector(1 downto 0);
signal SALTO_Next_PC, SALTO_Dato_RS, SALTO_Inme: std_logic_vector(31 downto 0); 
-- FINCAMBIO


begin


-- CAMBIO2
-- Gneracion del flag Zero
--Z <= '1' when (DataA = X"00000000") else '0';
-- AHORA ES CALCULADO CON EL DATO ADELANTADO
Z <= '1' when (Data_Salto = X"00000000") else '0';

-- CONDICION DE SALTO ADELANTADO PARA LOS SALTOS ANTICIPADOS
Z_PRE_IF <= '1' when (Data_Salto_PRE_IF = X"00000000") else '0';
-- FINCAMBIO2

u1: control port map (
  clr => clr,
  COP => instruccion(31 downto 26),
  func => instruccion(5 downto 0),
--  cond_Z => Z, 
  cond_Z => cond_control_Z_PRE_IF_ID, 
  MUX_rt_rd => mux_rt_rd,
  MUX_PC => mux_pc, WE_b32x32 => b32x32_we, MUX_ALU_A => mux_alu_a, MUX_ALU_B => mux_alu_b, 
  WE_mem => control_word(3), MUX_wb => mux_wb, tam_inm => control_itam ,signo_inm => control_isigno,
--CAMBIO
  jal => control_jal, MUX_salto => Mux_tipo_salto,
--FINCAMBIO
  ALU_op => ALU_control,
-- CAMBIO2
  -- Indica si es un salto que necesita la lectura de un registro
  -- (beqz o jr)
  salto_con_registro => salto_con_registro
-- FINCAMBIO2
);

--CAMBIO2
-- NO ESPERAMOS POR Z_PRE_IF
-- DAMOS POR SUPUESTO QUE LOS BEQZ SALTAN SIEMPRE
-- EN LA UNIDAD DE ANTICIPACION DE SALTOS HAREMOS LA COMPROBACION
-- ESTO ES PORQUE SOLO TENEMOS UN BANCO DE LECTURA
-- Y NO SABEMOS A QUE ETAPA LE PERTENECE
-- Y PARA NO DEPENDER LA UNIDAD DE CONTROL DE UN DATO
-- QUE SE LEERA EN MITAD DEL CICLO
cond_control_Z_PRE_IF_ID <= '1';

-- CONTROL PARA IF
u9: control port map (
  clr => clr,
  COP => instruccion_IF(31 downto 26),
  func => instruccion_IF(5 downto 0),
  cond_Z => cond_control_Z_PRE_IF_ID , MUX_rt_rd => control_IF(0),
  MUX_PC => control_IF(1), WE_b32x32 => control_IF(2), MUX_ALU_A => control_IF(3), MUX_ALU_B => control_IF(4), 
  WE_mem => control_IF(5), MUX_wb => control_IF(6), tam_inm => control_IF(7) ,signo_inm => control_IF(8),
--CAMBIO
  jal => control_IF(9), MUX_salto => control_IF(11 downto 10),
--FINCAMBIO
  ALU_op => control_IF(17 downto 12),
-- CAMBIO2
  -- Indica si es un salto que necesita la lectura de un registro
  -- (beqz o jr)
  salto_con_registro => control_IF(18)
-- FINCAMBIO2
);


-- CONTROL PARA PRE
u10: control port map (
  clr => clr,
  COP => instruccion_PRE(31 downto 26),
  func => instruccion_PRE(5 downto 0),
  cond_Z => cond_control_Z_PRE_IF_ID , MUX_rt_rd => control_PRE(0),
  MUX_PC => control_PRE(1), WE_b32x32 => control_PRE(2), MUX_ALU_A => control_PRE(3), MUX_ALU_B => control_PRE(4), 
  WE_mem => control_PRE(5), MUX_wb => control_PRE(6), tam_inm => control_PRE(7),signo_inm => control_PRE(8),
--CAMBIO
  jal => control_PRE(9), MUX_salto => control_PRE(11 downto 10),
--FINCAMBIO
  ALU_op => control_PRE(17 downto 12),
-- CAMBIO2
  -- Indica si es un salto que necesita la lectura de un registro
  -- (beqz o jr)
  salto_con_registro => control_PRE(18)
-- FINCAMBIO2
);
--FINCAMBIO2

-- Generacion de la palabra de control, por ahora solo se usan 8 bits de un total de 32
control_word(31 downto 10) <= (others=>'0');
control_word(9) <= MUX_PC_SIN_BURBUJA;
control_word(8) <= mux_rt_rd;
control_word(7) <= MUX_PC_CON_BURBUJA;
control_word(6) <= b32x32_we;
control_word(5) <= mux_alu_a;
control_word(4) <= mux_alu_b;
control_word(2) <= mux_wb;
control_word(1) <= control_itam;
control_word(0) <= control_isigno;

-- seleccion de la direccion del registro donde se escribe resultado
--CAMBIO
Mux_Reg_W <= control_jal & mux_rt_rd; -- senal que selecciona a rt, rd o r31 como puerto de escritura en banco
with Mux_Reg_W select
	dir_rt_rd_IF_ID <= instruccion(15 downto 11) when "01", -- RD (Instruccion 11..15)
		  	   (others=>'1')           when "10", -- R31 (11111)
		 	   instruccion(20 downto 16) when others; -- RT (Instruccion 16..20)
Reg_W <= dir_rt_rd_IF_ID;
--FINCAMBIO

--CAMBIO2
-- SELECCIONA EL REGISTRO DE ESCRITURA PARA LA INS DE LA ETAPA IF
-- PARA COMPROBAR RIESGOS CON LA ETAPA PRE EN LOS SALTOS ANTICIPADOS
Mux_Reg_W_IF <= control_IF(9) & control_IF(0); -- senal que selecciona a rt, rd o r31 como puerto de escritura en banco
with Mux_Reg_W_IF select
	Reg_W_IF <= instruccion_IF(15 downto 11) when "01", -- RD (Instruccion 11..15)
		  (others=>'1')           when "10", -- R31 (11111)
		  instruccion_IF(20 downto 16) when others; -- RT (Instruccion 16..20)
--FINCAMBIO2


-- Registro de escritura de vuelta de la etapa WB para escribir en el banco de registros
dir_W <= b_dir_W; 


--CAMBIO2
-- REGISTRO DE LECTURA DE LOS SALTOS ANTICIPADOS
-- SE USARA EL REGISTRO DE PRE SOLO SI IF NO LO NECESITA
with control_IF(18) select  -- = SALTO CON REGISTRO EN LA ETAPA IF
	Reg_RS_PRE_IF <= instruccion_PRE(25 downto 21) when '0', -- RS DE LA ETAPA PRE
		  	 instruccion_IF(25 downto 21) when others; -- RS DE LA ETAPA IF
--FINCAMBIO2

u2: b32x32 port map (
  DAT_P1W_up => Data_W,  -- dato puerto de escritura
  DIR_P1W_up => dir_W, -- direccion puerto escritura
  DIR_P2R_up => instruccion(25 downto 21), -- direccion puerto rs
  DIR_P3R_up => instruccion(20 downto 16), -- direccion puerto rt
  DIR_P4R_up => Reg_RS_PRE_IF, -- direccion puerto rs de los saltos anticipados
  WE_up => WE_b32x32_ext, -- habilitacion escritura en banco registros, desde etapa WB
  CLK_up => clock, 
  DAT_P2R_up => DataA, -- PA del banco registros
  DAT_P3R_up => Data_B, -- PB del banco registros
  DAT_P4R_up => Data_PRE_IF -- PC del banco registros
);

Data_A <= DataA;

--CAMBIO2
-- SE ANTICIPA EL DATO DE LECTURA PARA LOS SALTOS
with anticipa_ID_A select
	Data_Salto <= DataA when '0',
		      alu_out_EX_MEM when others;

-- SE ANTICIPA EL DATO DE LECTURA PARA LOS SALTOS ANTICIPADOS
with anticipa_ID_A_PRE_IF select
	Data_Salto_PRE_IF <= Data_PRE_IF when '0',
			     alu_out_EX_MEM when others;
--FINCAMBIO2

--CAMBIO
u3: inm port map (
  tam => control_itam,signo => control_isigno, 
  parte_instruccion => instruccion(25 downto 0),
  inmediato => inme -- Salida inmediato de 32 bits
);
--FINCAMBIO

--CAMBIO2
u7: inm port map (
  tam => control_IF(7),signo => control_IF(8), 
  parte_instruccion => instruccion_IF(25 downto 0),
  inmediato => inme_IF -- Salida inmediato de 32 bits de IF
);

u8: inm port map (
  tam => control_PRE(7),signo => control_PRE(8), 
  parte_instruccion => instruccion_PRE(25 downto 0),
  inmediato => inme_PRE -- Salida inmediato de 32 bits de PRE
);
--FINCAMBIO2

inmediato <= inme;

--CAMBIO2
u5: burbujas port map (
        WE_b32_32_ID_EX => control_ID_EX(6),
        MUX_wb_ID_EX => control_ID_EX(5),
        dir_rt_rd_ID_EX => control_ID_EX(4 downto 0),

        WE_b32_32_EX_MEM => control_EX_MEM(6),
        MUX_wb_EX_MEM => control_EX_MEM(5),
        dir_rt_rd_EX_MEM => control_EX_MEM(4 downto 0),

        MUX_alu_a => mux_alu_a,
        MUX_alu_b => mux_alu_b,
        salto_con_registro => salto_con_registro,
        dir_rs => instruccion(25 downto 21),
        dir_rt => instruccion(20 downto 16),

        burbuja => burbuja
);


u6: anticipaciones port map (
        WE_b32_32_ID_EX => control_ID_EX(6),
        MUX_wb_ID_EX => control_ID_EX(5),
        dir_rt_rd_ID_EX => control_ID_EX(4 downto 0),

        WE_b32_32_EX_MEM => control_EX_MEM(6),
        MUX_wb_EX_MEM => control_EX_MEM(5),
        dir_rt_rd_EX_MEM => control_EX_MEM(4 downto 0),

        dir_rs => instruccion(25 downto 21),
        dir_rt => instruccion(20 downto 16),

	anticipa_ID_A => anticipa_ID_A,
        anticipa_EX_A => anticipa_EX_A,
        anticipa_EX_B => anticipa_EX_B,
        anticipa_MEM_B => anticipa_MEM_B

);

u11: anticipa_saltos port map (
        WE_b32_32_IF => control_IF(2),
        MUX_wb_IF => control_IF(6),
        dir_rt_rd_IF => Reg_W_IF,

        WE_b32_32_IF_ID => b32x32_we,
        MUX_wb_IF_ID => mux_wb,
        dir_rt_rd_IF_ID => dir_rt_rd_IF_ID,
    
        WE_b32_32_ID_EX => control_ID_EX(6),
        MUX_wb_ID_EX => control_ID_EX(5),
        dir_rt_rd_ID_EX => control_ID_EX(4 downto 0),

        WE_b32_32_EX_MEM => control_EX_MEM(6),
        MUX_wb_EX_MEM => control_EX_MEM(5),
        dir_rt_rd_EX_MEM => control_EX_MEM(4 downto 0),

	control_jal_PRE => control_PRE(9),
        salto_con_registro_PRE => control_PRE(18),
        salto_con_registro_IF => control_IF(18),
        salto_con_registro => salto_con_registro,
        salto_relativo_PRE => control_PRE(8),
        salto_relativo_IF => control_IF(8),
        salto_relativo => control_isigno,
        dir_rs_PRE_IF => Reg_RS_PRE_IF,
        Z => Z,
        Z_PRE_IF => Z_PRE_IF,
	saltado_en_if => saltado_en_if, saltado_en_pre => saltado_en_pre,

        MUX_PC => mux_pc, MUX_PC_IF => control_IF(1), MUX_PC_PRE => control_PRE(1),

	anticipa_ID_A_PRE_IF => anticipa_ID_A_PRE_IF,
	MUX_PC_CON_BURBUJA => MUX_PC_CON_BURBUJA,
	MUX_PC_SIN_BURBUJA => MUX_PC_SIN_BURBUJA,
	MUX_NPC => MUX_NPC,
	MUX_DATA_RS => MUX_DATA_RS,
	salto_IF => salto_IF, salto_PRE => salto_PRE
    );

-- MUX QUE INDICA SI SE SALTA O NO
SALTO_mux_pc <= MUX_PC_CON_BURBUJA or MUX_PC_SIN_BURBUJA;

-- MUX QUE ELIGE EL DATO RS DEL SALTO A REALIZAR
with MUX_DATA_RS select
	SALTO_Dato_RS <= Data_Salto when '0',
			 Data_Salto_PRE_IF when others;

-- MUX PARA EL TIPO DE SALTO
with MUX_NPC select
	SALTO_salto_control <= control_PRE(11 downto 10) when "10",
			       control_IF(11 downto 10) when "01",
			       Mux_tipo_salto when others;
-- MUX PARA LA ELECCION DE NPC SEGUN LA ETAPA ESCOGIDA
with MUX_NPC select
	SALTO_Next_PC <= NextPC_PRE when "10",
			 NextPC_IF when "01",
			 NextPC when others;
-- MUX PARA LA ELECCION DEL INMEDIATO SEGUN LA ETAPA ESCOGIDA
with MUX_NPC select
	SALTO_Inme <= Inme_PRE when "10",
		      Inme_IF when "01",
		      Inme when others;

u4: salto port map (
        MUX_PC => SALTO_mux_pc,
        Salto_control => SALTO_salto_control,
        NextPC => SALTO_Next_PC, Dato_RS => SALTO_Dato_RS,Inme =>SALTO_Inme, 
        Salto_out => dir_salto
);

-- Direccion del salto para la etapa IF
NextPC_out <= dir_salto;

--FINCAMBIO2
end;
