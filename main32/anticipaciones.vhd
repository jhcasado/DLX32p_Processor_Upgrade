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

entity anticipaciones is
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
end anticipaciones;

architecture anticipaciones_arch of anticipaciones is

begin

-- adelanta A en la etapa ID para los saltos
-- with anticipa_ID_A select
--	Data_Salto <= DataA when '0',
--		      alu_out_EX_MEM when others;
process(WE_b32_32_EX_MEM, MUX_wb_EX_MEM, dir_rs, dir_rt_rd_EX_MEM)
begin
  if ( 
      -- EL DATO VENDRA DE SER CALCULADO EN LA ALU
      -- escribe en registro + se calcula el dato de la alu
      (WE_b32_32_EX_MEM = '1') and (MUX_wb_EX_MEM = '1') 

      -- COMPARACION DE RS CON ESCRITURA
      and (dir_rs = dir_rt_rd_EX_MEM) 
     ) then
	anticipa_ID_A <= '1';
  else
	anticipa_ID_A <= '0';
  end if;
end process;


-- adelanta A en la etapa EX
-- with reg_ID_EX(150 downto 149) select
--	data_A_adelantado <= reg_EX_MEM(31 downto 0) when "10",
--			     dataW_int when "01",
--			     reg_ID_EX(116 downto 85) when others;
process(WE_b32_32_ID_EX, MUX_wb_ID_EX, dir_rs, dir_rt_rd_ID_EX, MUX_wb_EX_MEM, dir_rt_rd_EX_MEM)
begin
  if (
      -- EL DATO VENDRA DE SER CALCULADO EN LA ALU
      -- escribe en registro + se calcula el dato de la alu
      (WE_b32_32_ID_EX = '1') and (MUX_wb_ID_EX = '1')
      
      -- COMPARACION DE RS CON ESCRITURA
      and (dir_rs = dir_rt_rd_ID_EX) -- dir. lectura EX = dir. escritura MEM
  ) then
  	anticipa_EX_A <= "10";
  elsif (
      -- EL DATO ESTA EN LA ETAPA MEM
      (MUX_wb_EX_MEM = '1') 

      -- COMPARACION DE RS CON ESCRITURA
      and (dir_rs = dir_rt_rd_EX_MEM)
  ) then
	anticipa_EX_A <= "01";
  else
	anticipa_EX_A <= "00";
  end if;
end process;


-- adelanta B en la etapa EX
-- with reg_ID_EX(152 downto 151) select
--	data_B_adelantado <= reg_EX_MEM(31 downto 0) when "10",
--			     dataW_int when "01",
--			     reg_ID_EX(116 downto 85) when others;
process(WE_b32_32_ID_EX, MUX_wb_ID_EX, dir_rt, dir_rt_rd_ID_EX, MUX_wb_EX_MEM, dir_rt_rd_EX_MEM)
begin
  if (
      -- EL DATO VENDRA DE SER CALCULADO EN LA ALU
      -- escribe en registro + se calcula el dato de la alu
      (WE_b32_32_ID_EX = '1') and (MUX_wb_ID_EX = '1')

      -- COMPARACION DE RT CON ESCRITURA
      and (dir_rt = dir_rt_rd_ID_EX) 
  ) then
  	anticipa_EX_B <= "10";
  elsif (
      -- EL DATO ESTA EN LA ETAPA MEM
      (MUX_wb_EX_MEM = '1') 

      -- COMPARACION DE RT CON ESCRITURA
      and (dir_rt = dir_rt_rd_EX_MEM)
  ) then
	anticipa_EX_B <= "01";
  else
	anticipa_EX_B <= "00";
  end if;
end process;



-- adelanta B en la etapa MEM para las SW
-- que tuviesen delante una LW que lee de memoria
-- lo que la SW quiere escribir en memoria
-- with reg_EX_MEM(73) select
--	data_out_Dmem <= reg_MEM_WB(31 downto 0) when '1',   -- anticipa de WB la B de una LW
--			 reg_EX_MEM(63 downto 32) when others;
process(WE_b32_32_ID_EX, MUX_wb_ID_EX, dir_rt, dir_rt_rd_ID_EX)
begin
  if ( 
      -- INDICACION DE LW EN MEM: escribe lo que viene de memoria
      (WE_b32_32_ID_EX = '1') and (MUX_wb_ID_EX = '0') 
      
      -- COMPARACION DE RT CON ESCRITURA
      and (dir_rt = dir_rt_rd_ID_EX)
     ) then
	anticipa_MEM_B <= '1';
  else
	anticipa_MEM_B <= '0';
  end if;
end process;


end anticipaciones_arch;
