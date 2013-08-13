--
-- control.vhd
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.dlx_pack.all;

entity control  is
port(
	clr: in std_logic;
	COP: in TypeDlxOpcode; -- codigo operacion 6 bits
	func: in TypeDlxFunc; -- campo func 6 bits
	cond_Z: in std_logic; -- contenido registro cero (Z=1)
	MUX_rt_rd,MUX_PC,WE_b32x32,MUX_ALU_A,MUX_ALU_B,WE_mem,MUX_wb,tam_inm,signo_inm,
--CAMBIO
	jal: out std_logic;  -- control de registro de escritura R31 para las inst. jal
	MUX_salto: out std_logic_vector(1 downto 0);  -- tipo de calculo del salto
--FINCAMBIO
	ALU_op: out std_logic_vector(5 downto 0);
-- CAMBIO2
	-- Indica si es un salto que necesita la lectura de un registro
	-- (beqz o jr)
	salto_con_registro: out std_logic
-- FINCAMBIO2
	);
end control;

architecture estructural of control is

signal c_out: std_logic_vector(12 downto 0);

begin

-- c_out = MUX_salto(1), MUX_salto(0), jal, MUX_rt_rd, MUX_PC, WE_b32x32, MUX_ALU_A, MUX_ALU_B, WE_mem, MUX_wb, beq, j;

with COP select
	c_out <="0000101100100" when cOpcode_alu, -- operacion ALU
	 	"0000001110001" when cOpcode_lw, -- carga desde mem (lw)
	 	"0000000111001" when cOpcode_sw, -- almacenamiento (sw)
	 	"0000001110100" when cOpcode_ori, -- or inmediato
		"10000" & cond_Z & "0010001" when cOpcode_beqz, -- salto condicional si registro=0 (Z=1,beqz)
	 	"0000010010011" when cOpcode_j, -- salto incondicional (j)
-- CAMBIO
		"0001011010111" when cOpcode_jal, -- salto incondicional (jal)
		"1010010010000" when cOpcode_jr, -- salto incondicional (jr)
		"0100010010010" when cOpcode_trap, -- manejo de interrupciones (trap)
		"0110010010000" when cOpcode_rfe, -- manejo de interrupciones (rfe)
-- FINCAMBIO
		"0000000010000" when others;
	
with COP select
	ALU_op <= func when cOpcode_alu, -- va directamente a la ALU
		  cAluFunc_add when cOpcode_lw, -- sumar direccion e inmediato
		  cAluFunc_add when cOpcode_sw, -- sumar direccion e inmediato
	 	  cAluFunc_or when cOpcode_ori, -- or inmediato
-- CAMBIO
--		  CALCULO DEL SALTO ADELANTADO A LA ETAPA ID
--		  cAluFunc_undef_01 when cOpcode_beqz, -- ALU_out <= PC+4 + Inm
--		  cAluFunc_undef_01 when cOpcode_j, -- ALU_out<= PC+4 + Inm(25..0)

		  cAluFunc_undef_02 when cOpcode_jal, -- R31<= ALU_out<= (PC+4) + 4
-- FINCAMBIO
		  cAluFunc_nop when others;

salto_con_registro <= c_out(12) and clr;	
MUX_salto(1) <= c_out(11) and clr;
MUX_salto(0) <= c_out(10) and clr;
jal <= c_out(9) and clr;
MUX_rt_rd <= c_out(8);
MUX_PC <= c_out(7) and clr; 
WE_b32x32 <= c_out(6) and clr;
MUX_ALU_A <= c_out(5) and clr;
MUX_ALU_B <= c_out(4) and clr;
WE_mem <= c_out(3) and clr;
MUX_wb <= c_out(2) and clr;
tam_inm <= c_out(1) and clr; -- antes beq
signo_inm <= c_out(0) and clr; -- antes j
end;
