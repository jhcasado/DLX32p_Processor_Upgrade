--
-- ANTICIPACIONES.VHD
--
-- Unidad para controlar las anticipaciones
--
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.dlx_pack.all;

entity anticipa_saltos is
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
end anticipa_saltos;

architecture anticipa_saltos_arch of anticipa_saltos is

signal control_salto: std_logic_vector(6 downto 0);
signal control_riesgo: std_logic_vector(3 downto 0);
signal riesgo_PRE,riesgo_IF,riesgo_ID: std_logic;
signal caso1, caso2, caso3, caso4: std_logic;

begin


---------------------------------------------------------------------------------
---------------------------------- ADELANTA EL REGISTRO DE LECTURA PARA PRE E IF

-- adelanta el registro de lectura en la etapa ID para los saltos PRE e IF
-- with anticipa_ID_A_PRE_IF select
--	Data_Salto_PRE_IF <= Data_PRE_IF when '0',
--			     alu_out_EX_MEM when others;
process(WE_b32_32_EX_MEM, MUX_wb_EX_MEM, dir_rs_PRE_IF, dir_rt_rd_EX_MEM)
begin
  if ( 
      -- EL DATO VENDRA DE SER CALCULADO EN LA ALU
      -- escribe en registro + se calcula el dato de la alu
      (WE_b32_32_EX_MEM = '1') and (MUX_wb_EX_MEM = '1') 
      
      -- COMPARACION DEL REGISTRO DE LECTURA CON EL DE ESCRITURA
      and (dir_rs_PRE_IF = dir_rt_rd_EX_MEM) 
     ) then
	anticipa_ID_A_PRE_IF <= '1';
  else
	anticipa_ID_A_PRE_IF <= '0';
  end if;
end process;


---------------------------------------------------------------------------------
--------------------------- RIESGOS CON EL REG. DE LECTURA DE SALTOS EN PRE E IF

-- LW en la etapa MEM coincide con RS de un salto con registro anticipado
process(WE_b32_32_EX_MEM, MUX_wb_EX_MEM, dir_rs_PRE_IF, dir_rt_rd_EX_MEM)
begin
  if (
  	-- INDICACION DE LW EN MEM: escribe lo que viene de memoria
	(WE_b32_32_EX_MEM = '1') and (MUX_wb_EX_MEM = '0')
	
  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs_PRE_IF = dir_rt_rd_EX_MEM)
     ) then
     caso1 <= '1';
  else
     caso1 <= '0';
  end if;

end process;

-- Etapa EX coincide con RS de un salto con registro anticipado
process(WE_b32_32_ID_EX, dir_rs_PRE_IF, dir_rt_rd_ID_EX)
begin
  if (
  	-- ESCRIBE EN REGISTRO EN EX
	(WE_b32_32_ID_EX = '1')

  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs_PRE_IF = dir_rt_rd_ID_EX)
     ) then
     caso2 <= '1';
  else
     caso2 <= '0';
  end if;

end process;

-- Etapa ID coincide con RS de un salto con registro anticipado
process(WE_b32_32_IF_ID, dir_rs_PRE_IF, dir_rt_rd_IF_ID)
begin
  if (
  	-- ESCRIBE EN REGISTRO EN ID
	(WE_b32_32_IF_ID = '1')

  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs_PRE_IF = dir_rt_rd_IF_ID)
     ) then
     caso3 <= '1';
  else
     caso3 <= '0';
  end if;

end process;

-- Etapa IF coincide con RS de un salto con registro de la etapa PRE
process(WE_b32_32_IF, dir_rs_PRE_IF, dir_rt_rd_IF)
begin
  if (
  	-- ESCRIBE EN REGISTRO EN IF
	(WE_b32_32_IF = '1')

  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs_PRE_IF = dir_rt_rd_IF)
     ) then
     caso4 <= '1';
  else
     caso4 <= '0';
  end if;

end process;

-- SENAL QUE CONTROLA LOS POSIBLES RIESGOS
-- 0000: SIN RIESGO
-- OTROS: COMPROBAR POSIBLE RIESGO
control_riesgo <= caso1 & caso2 & caso3 & caso4;


process(salto_con_registro,Z,salto_relativo)
begin
  -- LA INS. EN ID VA A USAR EL REGISTRO
  if (salto_con_registro = '1') then

	-- SE COMPRUEBA Z SOLO SI ES UNA BEQZ
  	if (Z = '1') or (salto_relativo = '0') then
  		riesgo_ID <= '0';
  	else
  		riesgo_ID <= '1';
  	end if;
  else
  -- SERA UN SALTO SIN REGISTRO, NO EXISTE RIESGO
  	riesgo_ID <= '0';
  end if;
end process;


-- COMPRUEBA LA EXISTENCIA DE RIESGO PARA LA INS. EN IF
process(control_riesgo,salto_con_registro_IF,Z_PRE_IF,salto_relativo_IF)
begin
  -- LA INS. EN IF VA A USAR EL REGISTRO
  if (salto_con_registro_IF = '1') then

  	-- SE COMPRUEBA SOLO EN SUS INS. POSTERIORES SI HAY RIESGO
  	-- ID + EX + MEM
  	if (control_riesgo(3 downto 1) = "000") 
	    -- SE COMPRUEBA Z SOLO SI ES UNA BEQZ
  	    and ((Z_PRE_IF = '1') or (salto_relativo_IF = '0')) then
  		riesgo_IF <= '0';
  	else
  		riesgo_IF <= '1';
  	end if;
  else
  -- SERA UN SALTO SIN REGISTRO, NO EXISTE RIESGO
  	riesgo_IF <= '0';
  end if;
end process;

-- COMPRUEBA LA EXISTENCIA DE RIESGO PARA LA INS. EN PRE
process(control_riesgo,salto_con_registro_PRE,salto_con_registro_IF,Z_PRE_IF,salto_relativo_PRE)
begin
  -- LA INS. EN PRE VA A USAR EL REGISTRO
  if (salto_con_registro_PRE = '1') then

	-- ASEGURA QUE Z_PRE_IF PERTENECE A PRE
  	if (salto_con_registro_IF = '0') then

	  	-- SE COMPRUEBA SOLO EN SUS INS. POSTERIORES SI HAY RIESGO
  		-- IF + ID + EX + MEM
	  	if (control_riesgo(3 downto 0) = "0000") 
	           -- SE COMPRUEBA Z SOLO SI ES UNA BEQZ
	  	   and ((Z_PRE_IF = '1') or (salto_relativo_PRE = '0')) then
  			riesgo_PRE <= '0';
	  	else
  			riesgo_PRE <= '1';
	  	end if;
	else
		riesgo_PRE <= '1';
	end if;
  -- NO SALTAR SI EN PRE HAY UNA INS. JAL
  -- YA QUE ESTA NECESITA ESCRIBIR EN R31
  elsif (control_jal_PRE = '1') then
	riesgo_PRE <= '1';
  else  
  -- SERA UN SALTO SIN REGISTRO, NO EXISTE RIESGO
  	riesgo_PRE <= '0';
  end if;
end process;



---------------------------------------------------------------------------------
------------------------------------------ CONTROL DE QUE ETAPA EFECTUA EL SALTO
-- 
process(MUX_PC,MUX_PC_IF,MUX_PC_PRE,saltado_en_IF,saltado_en_PRE,riesgo_PRE,riesgo_IF,riesgo_ID)
begin
  -- SALTA LA INS ID SI NO EXISTEN RIESGOS Y SI NO
  -- SE HA SALTADO EN EL CICLO ANTERIOR EN IF
  -- TENDREMOS QUE DESCARTAR LA INSTRUCCION DE IF
  if (MUX_PC = '1') and (riesgo_ID = '0') then
	if (saltado_en_IF = '1') then
		control_salto <= "0000000";
	else
		control_salto <= "0000001";
	end if;
  -- SALTA LA INS IF SI NO EXISTEN RIESGOS Y SI NO SE HA
  -- SALTADO EN EL CICLO ANTERIOR EN PRE
  -- LA SIGUIENTE INSTRUCCION LEIDA SERA LA DEL SALTO
  -- PARA EVITAR UNA BURBUJA
  elsif (MUX_PC_IF = '1') and (riesgo_IF = '0') then
	if (saltado_en_PRE = '1') then
		control_salto <= "0000000";
	else
		control_salto <= "0110110";
	end if;
  -- SALTA LA INS PRE SI NO EXISTEN RIESGOS
  -- SE CAMBIARA LA INSTRUCCION DE SALTO POR LA DEL SALTO
  -- CON ESTO GANAMOS UNA INSTRUCCION
  elsif (MUX_PC_PRE = '1') and (riesgo_PRE = '0') then
	control_salto <= "1011010";
  else
	control_salto <= "0000000";
  end if;
end process;

MUX_PC_CON_BURBUJA <= control_salto(0);
MUX_PC_SIN_BURBUJA <= control_salto(1);
MUX_NPC <= control_salto(3 downto 2);
MUX_DATA_RS <= control_salto(4);
salto_IF <= control_salto(5);
salto_PRE <= control_salto(6);

end anticipa_saltos_arch;

