--
-- DLX_PACK para el DLX32s
--
-- Declaraciones para el procesador DLX32s "sencillo"
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

package DLX_pack is
  constant CERO: std_logic := '0';
  constant UNO: std_logic := '1';
  -- declare a 32x8 ROM called ROM
  constant ROM_WIDTH: INTEGER := 32;
  subtype ROM_WORD is STD_LOGIC_VECTOR (ROM_WIDTH-1 downto 0);
  subtype ROM_RANGE is INTEGER range 0 to 256;
  constant VECTOR_CERO: ROM_WORD:= X"00000000";

-- decode instructions
	subtype TypeDlxOpcode is std_logic_vector(5 downto 0);
	subtype TypeDlxFunc is std_logic_vector(5 downto 0);

	constant cOpcode_alu		: TypeDlxOpcode := "000000";
	constant cOpcode_mdu		: TypeDlxOpcode := "000001";
	constant cOpcode_j		: TypeDlxOpcode := "000010";
	constant cOpcode_jal		: TypeDlxOpcode := "000011";
	constant cOpcode_beqz		: TypeDlxOpcode := "000100";
	constant cOpcode_bnez		: TypeDlxOpcode := "000101";
	constant cOpcode_undef_06	: TypeDlxOpcode := "000110";
	constant cOpcode_undef_07	: TypeDlxOpcode := "000111";
	constant cOpcode_addi		: TypeDlxOpcode := "001000";
	constant cOpcode_addui		: TypeDlxOpcode := "001001";
	constant cOpcode_subi		: TypeDlxOpcode := "001010";
	constant cOpcode_subui		: TypeDlxOpcode := "001011";
	constant cOpcode_andi		: TypeDlxOpcode := "001100";
	constant cOpcode_ori		: TypeDlxOpcode := "001101";
	constant cOpcode_xori		: TypeDlxOpcode := "001110";
	constant cOpcode_lhi		: TypeDlxOpcode := "001111";

	constant cOpcode_rfe		: TypeDlxOpcode := "010000";
	constant cOpcode_trap		: TypeDlxOpcode := "010001";
	constant cOpcode_jr			: TypeDlxOpcode := "010010";
	constant cOpcode_jalr		: TypeDlxOpcode := "010011";
	constant cOpcode_slli		: TypeDlxOpcode := "010100";
	constant cOpcode_undef_15	: TypeDlxOpcode := "010101";
	constant cOpcode_srli		: TypeDlxOpcode := "010110";
	constant cOpcode_srai		: TypeDlxOpcode := "010111";
	constant cOpcode_seqi		: TypeDlxOpcode := "011000";
	constant cOpcode_snei		: TypeDlxOpcode := "011001";
	constant cOpcode_slti		: TypeDlxOpcode := "011010";
	constant cOpcode_sgti		: TypeDlxOpcode := "011011";
	constant cOpcode_slei		: TypeDlxOpcode := "011100";
	constant cOpcode_sgei		: TypeDlxOpcode := "011101";
	constant cOpcode_undef_1E	: TypeDlxOpcode := "011110";
	constant cOpcode_undef_1F	: TypeDlxOpcode := "011111";

	constant cOpcode_lb		: TypeDlxOpcode := "100000";
	constant cOpcode_lh		: TypeDlxOpcode := "100001";
	constant cOpcode_undef_22	: TypeDlxOpcode := "100010";
	constant cOpcode_lw		: TypeDlxOpcode := "100011";
	constant cOpcode_lbu		: TypeDlxOpcode := "100100";
	constant cOpcode_lhu		: TypeDlxOpcode := "100101";
	constant cOpcode_undef_26	: TypeDlxOpcode := "100110";
	constant cOpcode_undef_27	: TypeDlxOpcode := "100111";
	constant cOpcode_sb		: TypeDlxOpcode := "101000";
	constant cOpcode_sh		: TypeDlxOpcode := "101001";
	constant cOpcode_undef_2A	: TypeDlxOpcode := "101010";
	constant cOpcode_sw		: TypeDlxOpcode := "101011";
	constant cOpcode_undef_2C	: TypeDlxOpcode := "101100";
	constant cOpcode_undef_2D	: TypeDlxOpcode := "101101";
	constant cOpcode_undef_2E	: TypeDlxOpcode := "101110";
	constant cOpcode_undef_2F	: TypeDlxOpcode := "101111";

	constant cOpcode_sequi		: TypeDlxOpcode := "110000";
	constant cOpcode_sneui		: TypeDlxOpcode := "110001";
	constant cOpcode_sltui		: TypeDlxOpcode := "110010";
	constant cOpcode_sgtui		: TypeDlxOpcode := "110011";
	constant cOpcode_sleui		: TypeDlxOpcode := "110100";
	constant cOpcode_sgeui		: TypeDlxOpcode := "110101";
	constant cOpcode_undef_36	: TypeDlxOpcode := "110110";
	constant cOpcode_undef_37	: TypeDlxOpcode := "110111";
	constant cOpcode_undef_38	: TypeDlxOpcode := "111000";
	constant cOpcode_undef_39	: TypeDlxOpcode := "111001";
	constant cOpcode_undef_3A	: TypeDlxOpcode := "111010";
	constant cOpcode_undef_3B	: TypeDlxOpcode := "111011";
	constant cOpcode_undef_3C	: TypeDlxOpcode := "111100";
	constant cOpcode_undef_3D	: TypeDlxOpcode := "111101";
	constant cOpcode_undef_3E	: TypeDlxOpcode := "111110";
	constant cOpcode_undef_3F	: TypeDlxOpcode := "111111";
			     

	constant cAluFunc_nop		: TypeDlxFunc := "000000";
	constant cAluFunc_undef_01	: TypeDlxFunc := "000001";
	constant cAluFunc_undef_02	: TypeDlxFunc := "000010";
	constant cAluFunc_undef_03	: TypeDlxFunc := "000011";
	constant cAluFunc_sll		: TypeDlxFunc := "000100";
	constant cAluFunc_undef_05	: TypeDlxFunc := "000101";
	constant cAluFunc_srl		: TypeDlxFunc := "000110";
	constant cAluFunc_sra		: TypeDlxFunc := "000111";
	constant cAluFunc_undef_08	: TypeDlxFunc := "001000";
	constant cAluFunc_undef_09	: TypeDlxFunc := "001001";
	constant cAluFunc_undef_0A	: TypeDlxFunc := "001010";
	constant cAluFunc_undef_0B	: TypeDlxFunc := "001011";
	constant cAluFunc_undef_0C	: TypeDlxFunc := "001100";
	constant cAluFunc_undef_0D	: TypeDlxFunc := "001101";
	constant cAluFunc_undef_0E	: TypeDlxFunc := "001110";
	constant cAluFunc_undef_0F	: TypeDlxFunc := "001111";
					 
	constant cAluFunc_sequ		: TypeDlxFunc := "010000";
	constant cAluFunc_sneu		: TypeDlxFunc := "010001";
	constant cAluFunc_sltu		: TypeDlxFunc := "010010";
	constant cAluFunc_sgtu		: TypeDlxFunc := "010011";
	constant cAluFunc_sleu		: TypeDlxFunc := "010100";
	constant cAluFunc_sgeu		: TypeDlxFunc := "010101";
	constant cAluFunc_undef_16	: TypeDlxFunc := "010110";
	constant cAluFunc_undef_17	: TypeDlxFunc := "010111";
	constant cAluFunc_undef_18	: TypeDlxFunc := "011000";
	constant cAluFunc_undef_19	: TypeDlxFunc := "011001";
	constant cAluFunc_undef_1A	: TypeDlxFunc := "011010";
	constant cAluFunc_undef_1B	: TypeDlxFunc := "011011";
	constant cAluFunc_undef_1C	: TypeDlxFunc := "011100";
	constant cAluFunc_undef_1D	: TypeDlxFunc := "011101";
	constant cAluFunc_undef_1E	: TypeDlxFunc := "011110";
	constant cAluFunc_undef_1F	: TypeDlxFunc := "011111";
					 
	constant cAluFunc_add		: TypeDlxFunc := "100000";
	constant cAluFunc_addu		: TypeDlxFunc := "100001";
	constant cAluFunc_sub		: TypeDlxFunc := "100010";
	constant cAluFunc_subu		: TypeDlxFunc := "100011";
	constant cAluFunc_and		: TypeDlxFunc := "100100";
	constant cAluFunc_or		: TypeDlxFunc := "100101";
	constant cAluFunc_xor		: TypeDlxFunc := "100110";
	constant cAluFunc_undef_27	: TypeDlxFunc := "100111";
	constant cAluFunc_seq		: TypeDlxFunc := "101000";
	constant cAluFunc_sne		: TypeDlxFunc := "101001";
	constant cAluFunc_slt		: TypeDlxFunc := "101010";
	constant cAluFunc_sgt		: TypeDlxFunc := "101011";
	constant cAluFunc_sle		: TypeDlxFunc := "101100";
	constant cAluFunc_sge		: TypeDlxFunc := "101101";
	constant cAluFunc_undef_2E	: TypeDlxFunc := "101110";
	constant cAluFunc_undef_2F	: TypeDlxFunc := "101111";

-- MVL= Multi Value Logic
subtype MVL_VECTOR is STD_LOGIC_VECTOR (ROM_WIDTH-1 downto 0);

-- Funcion que cambia std_logic_vector a integer
function MVL_TO_SIGNED(ARG : MVL_VECTOR) return SIGNED;
  
end DLX_pack;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

package body DLX_pack is

function MVL_TO_SIGNED(ARG : MVL_VECTOR) 
  return SIGNED is
  -- pragma built_in SYN_FEED_THRU
  variable uns: UNSIGNED (ARG'range);
begin
    for i in ARG'range loop
        case ARG(i) is
            when '0' | 'L' => uns(i) := '0';
            when '1' | 'H' => uns(i) := '1';
            when others    => return CONV_SIGNED(-1,ROM_WIDTH);
        end case;
    end loop;
    return CONV_SIGNED(uns,ROM_WIDTH);
end MVL_TO_SIGNED;

end DLX_pack;
