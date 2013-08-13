--
-- main32p.vhd
--
-- procesador DLX32p, mem de programa y mem de datos
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use work.dlx_pack.all;
use work.dlx_prog2.all;

entity main32p is
    port (
        clk: in STD_LOGIC;
        clr: in STD_LOGIC;
        PC: out STD_LOGIC_VECTOR (31 downto 0);
        instruccion: out STD_LOGIC_VECTOR (31 downto 0);
        data_out_Rt: out STD_LOGIC_VECTOR (31 downto 0);
        ALU_out: out STD_LOGIC_VECTOR (31 downto 0);
        BR_A,BR_B,BR_W: out STD_LOGIC_VECTOR (31 downto 0);
        BR_WE: out STD_LOGIC

    );
end main32p;

architecture main32s_arch of main32p is

component DLX32p is -- procesador DLX
    port (
        clk: in STD_LOGIC;
        clr: in STD_LOGIC;

	-- AHORA SE MANDARAN 3 DIRECCIONES DE MEMORIA DE PROGRAMA
	-- PARA RECIBIR 3 INSTRUCCIONES SIMULTANEAMENTE
        addr_Pmem,addr_Pmem_IF,addr_Pmem_PRE: out STD_LOGIC_VECTOR (31 downto 0); -- direccion mem programa
        instruction,instruction_IF,instruction_PRE: in STD_LOGIC_VECTOR (31 downto 0); -- dato de la mem programa

        addr_Dmem: out STD_LOGIC_VECTOR (31 downto 0); -- direc mem datos
        data_out_Dmem: out STD_LOGIC_VECTOR (31 downto 0); -- dato escrito en mem datos
        data_in_Dmem: in STD_LOGIC_VECTOR (31 downto 0); -- dato leido de mem datos
        we_Dmem: out STD_LOGIC; -- habilitacion escritura en mem datos
        BR_A,BR_B,BR_W: out STD_LOGIC_VECTOR (31 downto 0);
        BR_WE: out STD_LOGIC
	); 
end component ;

component ROM_32x8 -- memoria de programa
port(
	-- AHORA DE SE RECOGEN 3 DIRECCIONES DE MEMORIA
	ADDR1: in ROM_RANGE;
	ADDR2: in ROM_RANGE;
	ADDR3: in ROM_RANGE;
	
	-- DEVUELVE 3 INSTRUCCIONES
        DATA1: out ROM_WORD;
        DATA2: out ROM_WORD;
        DATA3: out ROM_WORD);
end component ;

component MEM -- memoria de datos
port (
	ADDRESS: in STD_LOGIC_VECTOR (4 downto 0); 
	DATA_IN: in STD_LOGIC_VECTOR (31 downto 0); 
	DATA_OUT: out STD_LOGIC_VECTOR (31 downto 0); 
	WE,CLK : in STD_LOGIC ); 
end component ; 

signal addr_Pmem,addr_Pmem_IF,addr_Pmem_PRE,ins,ins_IF,ins_PRE: std_logic_vector(31 downto 0);
signal addr_Dmem,data_in,data_out,ALU_out_int: std_logic_vector(31 downto 0);
signal addr,addr_IF,addr_PRE: signed(31 downto 0);
signal addr1,addr1_IF,addr1_PRE: ROM_RANGE;
signal we, n_clk: std_logic;

begin

n_clk <= not(clk);

u1: DLX32p port map (
        clk => clk,
        clr => clr,

	-- AHORA SE MANDARAN 3 DIRECCIONES DE MEMORIA DE PROGRAMA
	-- PARA RECIBIR 3 INSTRUCCIONES SIMULTANEAMENTE
        addr_Pmem => addr_Pmem, 
        addr_Pmem_IF => addr_Pmem_IF,
        addr_Pmem_PRE => addr_Pmem_PRE, -- direccion mem programa
        instruction => ins, -- dato de la mem programa
	instruction_IF => ins_IF,
	instruction_PRE => ins_PRE,

        addr_Dmem => addr_Dmem, -- direc mem datos
        data_out_Dmem => data_out, -- dato escrito en mem datos
        data_in_Dmem => data_in, -- dato leido de mem datos
        we_Dmem => we, -- habilitacion escritura en mem datos
        BR_A=>BR_A,BR_B=>BR_B,BR_W=>BR_W, -- salidas A y B y entrada W del banco de registros
        BR_WE=>BR_WE -- habilitacion del banco de registros

);

instruccion <= ins;
PC <= addr_Pmem;

addr <= MVL_TO_SIGNED('0'&'0'& addr_Pmem(31 downto 2)); -- transformamos direccion para dlx_pack
addr1 <= conv_integer(addr);
addr_IF <= MVL_TO_SIGNED('0'&'0'& addr_Pmem_IF(31 downto 2)); -- transformamos direccion para dlx_pack
addr1_IF <= conv_integer(addr_IF);
addr_PRE <= MVL_TO_SIGNED('0'&'0'& addr_Pmem_PRE(31 downto 2)); -- transformamos direccion para dlx_pack
addr1_PRE <= conv_integer(addr_PRE);

ALU_out <= addr_Dmem;
data_out_Rt <= data_out;

u2: ROM_32x8 port map (
	-- AHORA DE SE RECOGEN 3 DIRECCIONES DE MEMORIA
	ADDR1 => addr1,
	ADDR2 => addr1_IF,
	ADDR3 => addr1_PRE,

	-- DEVUELVE 3 INSTRUCCIONES
       	DATA1 => ins,
       	DATA2 => ins_IF,
       	DATA3 => ins_PRE
);

u3: MEM port map (
	ADDRESS => addr_Dmem(4 downto 0),
	DATA_IN => data_out,
	DATA_OUT => data_in,
	WE => we ,CLK => n_clk --clk 
);

end main32s_arch;
