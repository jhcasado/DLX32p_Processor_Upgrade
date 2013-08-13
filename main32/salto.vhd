--
-- SALTO.VHD
--
-- Unidad para calcular la direccion de salto
--
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all; 
use work.dlx_pack.all;

entity salto is
    port (
	-- PARA INDICAR SI SE SE ESCRIBE EN IAR
	MUX_PC: in std_logic;
	-- TIPO DE CALCULO PARA EL SALTO
        Salto_control: in STD_LOGIC_VECTOR (1 downto 0);  -- viene de la unidad de control
        -- DATOS PARA REALIZAR EL CALCULO
        NextPC,Dato_RS,Inme: in STD_LOGIC_VECTOR (31 downto 0);  -- PC+4,RS,ExtSig(Inm)
        Salto_out: out STD_LOGIC_VECTOR (31 downto 0)  -- Direccion del salto
    );
end salto;

architecture salto_arch of salto is

signal IAR: std_logic_vector(31 downto 0);
signal iSalto_out: STD_LOGIC_VECTOR(31 downto 0);

begin

process(Salto_control,Dato_RS,NextPC,Inme,IAR,iSalto_out)
variable temp, iIAR: SIGNED(31 DOWNTO 0);
begin
	if (MUX_PC = '1') then
		case Salto_control is
		    when "01" =>   -- JR: 		DirSalto = Registro RS
			iSalto_out <= Dato_RS; 
		
		    when "10" =>   -- TRAP: 		DirSalto = Inmediato; IAR = PC + 4
			iIAR := MVL_TO_SIGNED(NextPC);
	        	IAR <= CONV_STD_LOGIC_VECTOR(iIAR,32);
		        iSalto_out <= Inme;
	        
		    when "11" =>   -- RFE: 		DirSalto = IAR
			iSalto_out <= IAR; 
		
		    when others => -- BEQZ, J, JAL: 	DirSalto = (PC+4) + Inmediato
			temp := MVL_TO_SIGNED(NextPC) + MVL_TO_SIGNED(Inme);
			iSalto_out <= CONV_STD_LOGIC_VECTOR(temp,32);
		end case;
	end if;

  Salto_out <= iSalto_out;

end process;

end salto_arch;
