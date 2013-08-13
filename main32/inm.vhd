--
-- INM.VHD
--
-- Etapa de generacion del inmediato para la ALU en DLX32s
--
library ieee;
use ieee.std_logic_1164.all;

entity inm is
port(
	tam,signo: in std_logic;  -- tamano(16/26), signo(no/si)
	parte_instruccion: in std_logic_vector(25 downto 0);  -- inmediato 26 bits
	inmediato: out std_logic_vector(31 downto 0)  -- Salida ExtSig(inmediato) 32 bits
    );
end inm;

architecture comportamental of inm is

signal extension1,extension2,extension3,extension4: std_logic_vector(31 downto 0);
signal PCW: std_logic_vector(1 downto 0); 

begin

PCW <= tam & signo;  -- 2 bits de control para diferenciar los 4 tipos

-- inmediato sin signo de 16 bits (ORI)
extension1(31 downto 16) <= (others=>'0');
extension1(15 downto 0) <= parte_instruccion(15 downto 0);

-- inmediato con signo de 16 bits (LW, SW, BEQZ)
extension2(31 downto 16) <= (others=>parte_instruccion(15));
extension2(15 downto 0) <= parte_instruccion(15 downto 0);

-- inmediato sin signo de 26 bits (TRAP)
extension3(31 downto 26) <= (others=>'0');
extension3(25 downto 0) <= parte_instruccion;

-- inmediato con signo de 26 bits (J, JAL)
extension4(31 downto 26) <= (others=>parte_instruccion(25));
extension4(25 downto 0) <= parte_instruccion;

with PCW select

inmediato <= 	extension1 when "00", -- inmediato sin signo de 16 bits (ORI)
		extension2 when "01", -- inmediato con signo de 16 bits (LW, SW, BEQZ)
		extension3 when "10", -- inmediato sin signo de 26 bits (TRAP)
		extension4 when others; -- inmediato con signo de 26 bits (J, JAL)

end;
