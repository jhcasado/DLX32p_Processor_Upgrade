--
-- MEM_PROG.VHD
--
-- Memoria de programa que utiliza una estructura ROM
--
use work.DLX_pack.all;   -- Entity that uses ROM
use work.DLX_prog2.all;   -- Programa a ejecutar

entity ROM_32x8 is
port(
	-- AHORA DE SE RECOGEN 3 DIRECCIONES DE MEMORIA
	ADDR1: in ROM_RANGE;
	ADDR2: in ROM_RANGE;
	ADDR3: in ROM_RANGE;
	
	-- DEVUELVE 3 INSTRUCCIONES
        DATA1: out ROM_WORD;
        DATA2: out ROM_WORD;
        DATA3: out ROM_WORD);
end ROM_32x8;

architecture comportamental of ROM_32x8 is
begin

  DATA1 <= ROM(ADDR1);      -- Read from the ROM
  DATA2 <= ROM(ADDR2);      -- Read from the ROM
  DATA3 <= ROM(ADDR3);      -- Read from the ROM

end comportamental;
