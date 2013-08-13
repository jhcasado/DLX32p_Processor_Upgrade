--
-- MEM.vhd
--
-- Etapa de acceso a la memoria de datos (32x32) del procesador DLX32s
-- Para la memoria se utiliza el Banco de 32 registros de 32 bits 
-- con 1 puerto de escritura y 1 puerto de lectura que se utilizo en b32x32.vhd
--
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 

entity  MEM is 
port (
	ADDRESS: in STD_LOGIC_VECTOR (4 downto 0); 
	DATA_IN: in STD_LOGIC_VECTOR (31 downto 0); 
	DATA_OUT: out STD_LOGIC_VECTOR (31 downto 0); 
	WE,CLK : in STD_LOGIC ); 
end MEM; 

architecture behav of MEM is

component BANCOREG
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
port (  DAT_P1W_int : in STD_LOGIC_VECTOR (31 downto 0); 
	DIR_P1W_int,DIR_P2R_int: in STD_LOGIC_VECTOR (4 downto 0); 
	WE_int,CLK_int : in STD_LOGIC; 
	DAT_P2R_int,DAT_P1R_int : out STD_LOGIC_VECTOR (31 downto 0) ); 
end component; 

signal NULO1: STD_LOGIC_VECTOR(31 downto 0);

begin

u1:BANCOREG port map( 
	DAT_P1W_int => DATA_IN, 
	DIR_P1W_int => ADDRESS, DIR_P2R_int => ADDRESS,
	WE_int => WE, CLK_int => CLK, 
	DAT_P2R_int => DATA_OUT, DAT_P1R_int => NULO1);	

end behav;
	 
