--
-- BURBUJAS.VHD
--
-- Unidad para controlar las burbujas
-- Se compara a la instruccion actual con las
-- que estan en las etapas EX y MEM
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.dlx_pack.all;

entity burbujas is
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
end burbujas;

architecture burbujas_arch of burbujas is

signal control_burbuja: std_logic_vector(3 downto 0);
signal caso1, caso2, caso3, caso4: std_logic;

begin

-- LW en la etapa EX coincide con RS
process(WE_b32_32_ID_EX, MUX_wb_ID_EX, MUX_alu_a, dir_rs, dir_rt_rd_ID_EX)
begin
  if (
  	-- INDICACION DE LW EN EX: escribe lo que viene de memoria
	(WE_b32_32_ID_EX = '1')	and (MUX_wb_ID_EX = '0')

	-- VA A USAR RS	EN EX
  	and (MUX_alu_a = '1')
  	
  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs = dir_rt_rd_ID_EX)
     ) then
     caso1 <= '1';
  else
     caso1 <= '0';
  end if;
end process;


-- LW en la etapa EX coincide con RT
process(WE_b32_32_ID_EX, MUX_wb_ID_EX, MUX_alu_b, dir_rt, dir_rt_rd_ID_EX)
begin
  if (
  	-- INDICACION DE LW EN EX: escribe lo que viene de memoria
	(WE_b32_32_ID_EX = '1') and (MUX_wb_ID_EX = '0')

	-- VA A USAR RT EN EX
  	and (MUX_alu_b = '0')

  	-- COMPARACION DE RT CON ESCRITURA
  	and (dir_rt = dir_rt_rd_ID_EX)
     ) then
     caso2 <= '1';
  else
     caso2 <= '0';
  end if;
end process;


-- Etapa EX coincide con RS de un salto con registro
process(WE_b32_32_ID_EX, salto_con_registro, dir_rs, dir_rt_rd_ID_EX)
begin
  if (
  	-- ESCRIBE EN REGISTRO EN EX
	(WE_b32_32_ID_EX = '1')
	
	-- SALTARA USANDO RS YA EN ID
  	and (salto_con_registro = '1')
  	
  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs = dir_rt_rd_ID_EX)
     ) then
     caso3 <= '1';
  else
     caso3 <= '0';
  end if;

end process;


-- LW en la etapa MEM coincide con RS de un salto con registro
process(WE_b32_32_EX_MEM, MUX_wb_EX_MEM, salto_con_registro, dir_rs, dir_rt_rd_EX_MEM)
begin
  if (
  	-- INDICACION DE LW EN MEM: escribe lo que viene de memoria
	(WE_b32_32_EX_MEM = '1') and (MUX_wb_EX_MEM = '0')

	-- SALTARA USANDO RS YA EN ID
  	and (salto_con_registro = '1')
  	
  	-- COMPARACION DE RS CON ESCRITURA
  	and (dir_rs = dir_rt_rd_EX_MEM)
     ) then
     caso4 <= '1';
  else
     caso4 <= '0';
  end if;

end process;

control_burbuja <= caso1 & caso2 & caso3 & caso4;

with control_burbuja select
	burbuja <= '0' when "0000",
		   '1' when others;


end burbujas_arch;

