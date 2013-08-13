--
-- mem16x8d.vhd
--
-- Banco de 16 registros de 8 bits
--
library IEEE; 
use IEEE.STD_LOGIC_1164.all; 

entity mem16x8d is 
-- P1: puerto de escritura; P2: primer puerto de lectura; P3: segundo puerto de lectura
port ( DAT_P1W : in STD_LOGIC_VECTOR (7 downto 0); 
	DIR_P1W,DIR_P2R: in STD_LOGIC_VECTOR (3 downto 0); 
	WE,CLK : in STD_LOGIC; 
	DAT_P2R,DAT_P1R : out STD_LOGIC_VECTOR (7 downto 0) ); 
end mem16x8d; 

architecture behav of mem16x8d is

component RAM16X8D 
port ( 
D7,D6,D5,D4,D3,D2,D1,D0, 
A3, A2, A1, A0, DPRA3,DPRA2,DPRA1,DPRA0,WE, WCLK : in STD_LOGIC; 
SPO7,SPO6,SPO5,SPO4,SPO3,SPO2,SPO1,SPO0,
DPO7,DPO6,DPO5,DPO4,DPO3,DPO2,DPO1,DPO0 : out STD_LOGIC ); 
end component; 

begin

-- The SPO output reflects the data in the memory cell addressed by A3 - A0. (write port)
-- The DPO output reflects the data in the memory cell addressed by DPRA3 - DPRA0. (read port)

u1:RAM16X8D
port map( 
D7=>DAT_P1W(7),D6=>DAT_P1W(6),D5=>DAT_P1W(5),D4=>DAT_P1W(4),D3=>DAT_P1W(3),D2=>DAT_P1W(2),D1=>DAT_P1W(1),D0=>DAT_P1W(0), 
A3=>DIR_P1W(3), A2=>DIR_P1W(2), A1=>DIR_P1W(1), A0=>DIR_P1W(0), 
DPRA3=>DIR_P2R(3),DPRA2=>DIR_P2R(2),DPRA1=>DIR_P2R(1),DPRA0=>DIR_P2R(0),
WE=>WE, WCLK=>CLK,
SPO7=>DAT_P1R(7),SPO6=>DAT_P1R(6),SPO5=>DAT_P1R(5),SPO4=>DAT_P1R(4),SPO3=>DAT_P1R(3),SPO2=>DAT_P1R(2),SPO1=>DAT_P1R(1),SPO0=>DAT_P1R(0),
DPO7=>DAT_P2R(7),DPO6=>DAT_P2R(6),DPO5=>DAT_P2R(5),DPO4=>DAT_P2R(4),DPO3=>DAT_P2R(3),DPO2=>DAT_P2R(2),DPO1=>DAT_P2R(1),DPO0=>DAT_P2R(0)
);	  
	
end behav;
	 
