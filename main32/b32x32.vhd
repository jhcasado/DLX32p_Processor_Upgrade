--
-- b32x32.vhd
--
-- Banco de 4 puertos de 32 registros de 32 bits
-- 3 de lectura y 1 de escritura
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 

entity b32x32 is 
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
end b32x32; 


architecture behav of b32x32 is

component BANCOREG
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
port ( DAT_P1W_int : in STD_LOGIC_VECTOR (31 downto 0); 
	DIR_P1W_int,DIR_P2R_int: in STD_LOGIC_VECTOR (4 downto 0); 
	WE_int,CLK_int : in STD_LOGIC; 
	DAT_P2R_int,DAT_P1R_int : out STD_LOGIC_VECTOR (31 downto 0) ); 
end component; 

signal NULO1,NULO2,NULO3: STD_LOGIC_VECTOR(31 DOWNTO 0);

begin

u1:BANCOREG port map( 
	DAT_P1W_int => DAT_P1W_up,  
	DIR_P1W_int => DIR_P1W_up, DIR_P2R_int => DIR_P2R_up,
	WE_int => WE_up, CLK_int => CLK_up, 
	DAT_P2R_int => DAT_P2R_up, DAT_P1R_int => NULO1
);	  

u2:BANCOREG port map( 
	DAT_P1W_int => DAT_P1W_up,  
	DIR_P1W_int => DIR_P1W_up, DIR_P2R_int => DIR_P3R_up,
	WE_int => WE_up, CLK_int => CLK_up, 
	DAT_P2R_int => DAT_P3R_up, DAT_P1R_int => NULO2
);	  

-- BANCO DE REGISTROS ANADIDO PARA SOPORTAR 3 LECTURAS SIMULTANEAS
u3:BANCOREG port map( 
	DAT_P1W_int => DAT_P1W_up,  
	DIR_P1W_int => DIR_P1W_up, DIR_P2R_int => DIR_P4R_up,
	WE_int => WE_up, CLK_int => CLK_up, 
	DAT_P2R_int => DAT_P4R_up, DAT_P1R_int => NULO3
);	  
	
end behav;
	 
