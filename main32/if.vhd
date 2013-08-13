--
-- IF.VHD
--
-- Etapa de bsqueda de instruccion de DLX32s
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity etapa_IF is
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
end etapa_IF;

architecture comportamental of etapa_IF is

signal S,pc: std_logic_vector(31 downto 0);
-- CAMBIO2
-- signal PCW: std_logic; -- senal de habilitacin del PC
-- FINCAMBIO2

begin

-- actualizacin del contador de programa PC

-- CAMBIO2
-- PCW <= '1'; -- habilitamos siempre al registro PC
-- FINCAMBIO2

process (CLK,RESET)
begin
  if (RESET='0') then
	pc <= (others=>'0');
  elsif (CLK='1' and CLK'event) then

	-- SI EXISTIESE UNA BURBUJA NO MOVERIAMOS EL PC
        if (burbuja='0') then
--        if (PCW='1') then

	    -- LOS DOS MUX_PC INDICADORES DE SALTO
	    if (EIF1 ='0' and EIF2 = '0') then
		pc <= pc + 4;
	    else  
		pc <= EIF6;
	    end if;
	    --pc <= S;
	    
	end if;
  end if;
-- pcmas4 toma el valor de la siguiente direccion

-- MUX-PC, selecciona PC+4 o direccion de salto
-- senales del PC exteriores para simulacion

end process;

-- SIF_1 <= Next_pc de la tercera instruccion
SIF_1 <= pc + 12;

--  SIF0 <= Next_pc de la segunda instruccion
--          + Direccion de la tercera instruccion
SIF0 <= pc + 8;

--  SIF1 <= Next_pc de la primera instruccion
--          + Direccion de la segunda instruccion
SIF1 <= pc + 4;

--  SIF2 <= Direccion de la primera instruccion
SIF2 <= pc;

end;
