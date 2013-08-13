--
-- BANCOREG.vhd
--
-- Banco de 32 registros de 32 bits con 1 puerto de escritura y 1 puerto de lectura
--
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 

entity BANCOREG is 
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
port (  DAT_P1W_int : in STD_LOGIC_VECTOR (31 downto 0); 
	DIR_P1W_int,DIR_P2R_int: in STD_LOGIC_VECTOR (4 downto 0); 
	WE_int,CLK_int : in STD_LOGIC; 
	DAT_P2R_int,DAT_P1R_int : out STD_LOGIC_VECTOR (31 downto 0) ); 
end BANCOREG; 

architecture behav of BANCOREG is

component mem16x8d
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
port ( DAT_P1W : in STD_LOGIC_VECTOR (7 downto 0); 
	DIR_P1W,DIR_P2R: in STD_LOGIC_VECTOR (3 downto 0); 
	WE,CLK : in STD_LOGIC; 
	DAT_P2R,DAT_P1R : out STD_LOGIC_VECTOR (7 downto 0) ); 
end component; 

signal 	DAT_P2Ri,DAT_P2R1o,DAT_P1Ri,DAT_P1R1o : STD_LOGIC_VECTOR (31 downto 0);
signal WE_0, WE_1: std_logic;

begin

-- Se utilizan 8 bancos de de memoria dual port de 16x8 (RAM16x8D)
-- La palabra de 32 bits de salida se selecciona con DIR_P2R(4), bien de los 4 
-- primeros bloques (u1..u4) o de los segundos (u5..u8).
-- La escritura viene seleccionada por DIR_P1W(4)

WE_0 <= not(DIR_P1W_int(4)) and WE_int;
WE_1 <= DIR_P1W_int(4) and WE_int;

DAT_P2R_int <= DAT_P2R1o when (DIR_P2R_int(4)='1') else DAT_P2Ri ;

DAT_P1R_int <= DAT_P1R1o when (DIR_P1W_int(4)='1') else DAT_P1Ri ;
			
u1:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(7 downto 0), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_0, CLK=>CLK_int,
DAT_P2R=>DAT_P2Ri(7 downto 0),
DAT_P1R=>DAT_P1Ri(7 downto 0)
);	

u2:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(15 downto 8), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_0, CLK=>CLK_int,
DAT_P2R=>DAT_P2Ri(15 downto 8),
DAT_P1R=>DAT_P1Ri(15 downto 8)
);	  

u3:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(23 downto 16), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_0, CLK=>CLK_int,
DAT_P2R=>DAT_P2Ri(23 downto 16),
DAT_P1R=>DAT_P1Ri(23 downto 16)
);	
	
u4:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(31 downto 24), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_0, CLK=>CLK_int,
DAT_P2R=>DAT_P2Ri(31 downto 24),
DAT_P1R=>DAT_P1Ri(31 downto 24)
);	

u5:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(7 downto 0), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_1, CLK=>CLK_int,
DAT_P2R=>DAT_P2R1o(7 downto 0),
DAT_P1R=>DAT_P1R1o(7 downto 0)
);	

u6:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(15 downto 8), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_1, CLK=>CLK_int,
DAT_P2R=>DAT_P2R1o(15 downto 8),
DAT_P1R=>DAT_P1R1o(15 downto 8)
);	  

u7:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(23 downto 16), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_1, CLK=>CLK_int,
DAT_P2R=>DAT_P2R1o(23 downto 16),
DAT_P1R=>DAT_P1R1o(23 downto 16)
);	
	
u8:mem16x8d
port map( 
DAT_P1W=>DAT_P1W_int(31 downto 24), 
DIR_P1W=>DIR_P1W_int(3 downto 0), 
DIR_P2R=>DIR_P2R_int(3 downto 0),
WE=>WE_1, CLK=>CLK_int,
DAT_P2R=>DAT_P2R1o(31 downto 24),
DAT_P1R=>DAT_P1R1o(31 downto 24)
);	

end behav;
	 
