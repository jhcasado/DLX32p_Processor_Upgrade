--
-- DLX_PROG2.vhd
--
-- Programa para el DLX32p
-- Se ha insertado nop para evitar las dependencias. Esta es la diferencia con DLX_PROG.vhd
-- que es el que se ha utilizado para DLX32s monociclo.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use work.DLX_pack.all;

package DLX_prog2 is
  type ROM_TABLE is array (0 to 43) of ROM_WORD;

  constant ROM: ROM_TABLE := ROM_TABLE'(

-- PROGRAMA PRINCIPAL
								--	; vector 1
	ROM_WORD'("00110100000000010000000000010100"),  	--0	ORI R1, R0, 20
	ROM_WORD'("00110100000000100000000000000010"),  	--4	ORI R2, R0, 2
	ROM_WORD'("00000000001000100001100000000111"),  	--8	SRA R3, R1, R2
	ROM_WORD'("10101100000000110000000000000000"),  	--12	SW 0(R0), R3

	ROM_WORD'("00110100000000010000000000000100"),  	--16	ORI R1, R0, 4
	ROM_WORD'("00110100000000100000000000000011"),  	--20	ORI R2, R0, 3
	ROM_WORD'("00000000001000100001100000000100"),  	--24	SLL R3, R1, R2
	ROM_WORD'("10101100000000110000000000000001"),  	--28	SW 1(R0), R3

	ROM_WORD'("00110100000000010000000000011000"),  	--32	ORI R1, R0, 24
	ROM_WORD'("00110100000000100000000000000010"),  	--36	ORI R2, R0, 2
	ROM_WORD'("00000000001000100001100000000110"),  	--40	SRL R3, R1, R2
	ROM_WORD'("10101100000000110000000000000010"),  	--44	SW 2(R0), R3

								--	; vector 2
	ROM_WORD'("00110100000000010000000000000100"),  	--48	ORI R1, R0, 4
	ROM_WORD'("00110100000000100000000000001000"),  	--52	ORI R2, R0, 8
	ROM_WORD'("00000000001000100001100000100101"),  	--56	OR R3, R1, R2
	ROM_WORD'("10101100000000110000000000000011"),  	--60	SW 3(R0), R3

	ROM_WORD'("00110100000000010000000000011100"),  	--64	ORI R1, R0, 28
	ROM_WORD'("00110100000000100000000000000011"),  	--68	ORI R2, R0, 3
	ROM_WORD'("00000000001000100001100000100010"),  	--72	SUB R3, R1, R2
	ROM_WORD'("10101100000000110000000000000100"),  	--76	SW 4(R0), R3

	ROM_WORD'("00110100000000010000000000011000"),  	--80	ORI R1, R0, 24
	ROM_WORD'("00110100000000100000000000001000"),  	--84	ORI R2, R0, 8
	ROM_WORD'("00000000001000100001100000100100"),  	--88	AND R3, R1, R2
	ROM_WORD'("10101100000000110000000000000101"),  	--92	SW 5(R0), R3

								--	; llamadas al procedimiento
	ROM_WORD'("00110100000111100000000000000000"),  	--96	ORI R30, R0, 0
	ROM_WORD'("00001100000000000000000000011100"),  	--100	JAL SUMA_VECTOR ;(100 + 4 + 28 = 132)
	ROM_WORD'("00000000000111010000100000100000"),  	--104	ADD R1, R0, R29

	ROM_WORD'("00110100000111100000000000000011"),  	--108	ORI R30, R0, 3
	ROM_WORD'("00001100000000000000000000010000"),  	--112	JAL SUMA_VECTOR ;(112 + 4 + 16 = 132)
	ROM_WORD'("00000000000111010001000000100000"),  	--116	ADD R2, R0, R29

								--	; comparaci�n final
	ROM_WORD'("00000000001000100001100000101010"),  	--120	SLT R3, R1, R2

								--	; llamada al sistema, por ejemplo, escribir en pantalla el resultado
	ROM_WORD'("01000100000000000000000010101100"),  	--124	TRAP PANTALLA ;(172)

								--	; finaliza la ejecuci�n del programa
	ROM_WORD'("01000100000000000000000000000000"),  	--128	TRAP 0

-- FIN PROGRAMA PRINCIPAL

-- FUNCION SUMA_VECTOR

								--SUMA_VECTOR: ;(132) implemantaci�n del procedimiento 
								--	; inicializamos las variables locales
	ROM_WORD'("00110100000101010000000000000011"),  	--132	ORI R21, R0, 3 ; contador de iteraciones
	ROM_WORD'("00110100000101100000000000000001"),  	--136	ORI R22, R0, 1 ; decremento/incremento unidad
	ROM_WORD'("00110100000111010000000000000000"),  	--140	ORI R29, R0, 0 ; inicializaci�n del acumulado
	
								--LOOP: ;(144)
	ROM_WORD'("00010010101000000000000000010100"),  	--144	BEQZ R21, END_LOOP ;(144 + 4 + 20 = 168)
	ROM_WORD'("10001111110101110000000000000000"),  	--148	LW R23, 0(R30)
	ROM_WORD'("00000010101101101010100000100010"),  	--152	SUB R21, R21, R22
	ROM_WORD'("00000011110101101111000000100000"),  	--156	ADD R30, R30, R22
	ROM_WORD'("00000011101101111110100000100000"),  	--160	ADD R29, R29, R23
	ROM_WORD'("00001011111111111111111111101000"),  	--164	J LOOP ;(164 + 4 + (-24) = 144)
	
								--END_LOOP: ;(168) retornamos del procedimiento
	ROM_WORD'("01001011111000000000000000000000"),  	--168	JR R31	
	
-- FIN FUNCION SUMA_VECTOR

-- LLAMADA AL SISTEMA
								--PANTALLA: ;(172) suponemos que ejecuta un syscall que escribe algo en pantalla
	ROM_WORD'("01000000000000000000000000000000")	  	--172	RFE			

-- FIN LLAMADA AL SISTEMA
      );

end DLX_prog2;

