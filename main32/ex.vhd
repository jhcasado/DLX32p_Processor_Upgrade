--
-- EX.VHD
-- Etapa de ejecucion de la instruccion para DLX32s
--
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all; 
use work.dlx_pack.all;

entity ex is
    port (
    	MUX_A_control,MUX_B_control: in STD_LOGIC; -- bit de control MUX_ALU_A y MUX_ALU_B
    	-- palabra de control de la ALU
        ALU_control: in STD_LOGIC_VECTOR (5 downto 0);
        -- NextPC=PC+4, Data_A,Data_B= Banco, Inm= inmediato
        NextPC,Data_A,Data_B,Inm: in STD_LOGIC_VECTOR (31 downto 0);
        -- ALUout= salida de la ALU
        ALU_out: out STD_LOGIC_VECTOR (31 downto 0)
    );
end ex;

architecture ex_arch of ex is

begin

process(ALU_control,Data_A,Data_B,NextPC,Inm,MUX_A_control,MUX_B_control)

variable index, v2: integer;
variable MUX_A_out, MUX_B_out, v5, iALU_out: SIGNED(31 DOWNTO 0); -- v1, v3, v4
variable COUNT,dummy1,dummy2: unsigned(31 downto 0);

begin

case MUX_A_control is
	when '1' => 
		MUX_A_out := MVL_TO_SIGNED(Data_A); -- Transforma 32 bits a entero con signo
	when others =>
		MUX_A_out := MVL_TO_SIGNED(NextPC);
end case;

case MUX_B_control is
	when '0' => 
		MUX_B_out := MVL_TO_SIGNED(Data_B); -- Transforma 32 bits a entero con signo
	when others =>
		MUX_B_out := MVL_TO_SIGNED(Inm);
end case;

        case ALU_control is
	    when cAluFunc_add =>
		 iALU_out := MUX_A_out + MUX_B_out;		   
		   
--CAMBIO		 
--	    when cAluFunc_undef_01 =>
--	         iALU_out := MUX_B_out; -- desde bloque inmediato sale la direccion de salto INCONDICIONAL

--	    Calculo de la direccion de retorno para las ins. jal: R31 = OUT = (PC+4) + 4
	    when cAluFunc_undef_02 =>
	         iALU_out := MUX_A_out;-- + 4; 
--FINCAMBIO
	    when cAluFunc_sub =>
	         iALU_out := MUX_A_out - MUX_B_out;
		   
	    when cAluFunc_and =>
                 for index in 31 downto 0 loop
                     v5(index) := MUX_A_out(index) and MUX_B_out(index);
                 end loop;
	         iALU_out := v5;   	
		   
	    when cAluFunc_or =>
                 for index in 31 downto 0 loop
                     v5(index) := MUX_A_out(index) or MUX_B_out(index);
                 end loop;
	         iALU_out := v5;   	
		   
	    when cAluFunc_sra =>
		COUNT := CONV_UNSIGNED(MUX_B_out,32);
		iALU_out := SHR(MUX_A_out,COUNT); -- SHR funcion XILINX, desplazamiento aritmetico, replica signo

--CAMBIO		 
--	    Instruccion Aritmetica SLL (OUT = A << B)
	    when cAluFunc_sll =>
		COUNT := CONV_UNSIGNED(MUX_B_out,32);
		dummy1 := CONV_UNSIGNED(MUX_A_out,32);
		dummy2 := SHL(dummy1,COUNT); -- SHL funcion XILINX, desplazamiento aritmetico, replica signo
		iALU_out := CONV_SIGNED(dummy2,32);
		
--	    Instruccion Aritmetica SRL (OUT = A >> B)
	    when cAluFunc_srl =>
		COUNT := CONV_UNSIGNED(MUX_B_out,32);
		dummy1 := CONV_UNSIGNED(MUX_A_out,32);
		dummy2 := SHR(dummy1,COUNT); -- SHR funcion XILINX, desplazamiento aritmetico, replica signo
		iALU_out := CONV_SIGNED(dummy2,32);

--	    Instruccion Aritmetica SLT (IF (A < B) OUT = 1 ELSE OUT = 0)
	    when cAluFunc_slt =>
	    	if (MUX_A_out < MUX_B_out) then
	    		iALU_out(31 downto 1) := (others=>'0');
			iALU_out(0) := '1';	    		
	    	else
	    		iALU_out := (others=>'0');
	    	end if;
--FINCAMBIO		 
	    when others =>  
		 iALU_out := CONV_SIGNED(0,32);    	          		   	   
        end case;

ALU_out <= CONV_STD_LOGIC_VECTOR(iALU_out,32);

end process;

end ex_arch;
