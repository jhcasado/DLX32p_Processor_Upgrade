DLX32p Processor Upgrade
------------------------
(Xillinx, VHDL)

![ScreenShot](https://raw.github.com/jhcasado/screenshots/master/DLX32p_Processor_Upgrade/dlx32p_01.png)

- Modificación del Repertorio de Instrucciones

En esta memoria describimos los cambios que hemos realizado en el código de la arquitectura del microprocesador DLX32 para incorporar soporte a nuevas instrucciones. 

Estas nuevas instrucciones, separadas en dos grupos, son:

	Aritmético/Lógicas
	- SRL, desplazamiento lógico a la derecha
	- SLL, desplazamiento lógico a la izquierda
	- SLT, condición
	
	Saltos
	- JAL, llamada a un procedimiento
	- JR, retorno de la llamada al procedimiento
	- TRAP, llamada al sistema
	- RFE, retorno de la llamada al sistema

En la implementación de las instrucciones aritmético/lógicas simplemente hemos añadido nuevas operaciones a la ALU de la etapa de ejecución que se correspondan con su campo de los 6 bits menos significativos de la instrucción.

Para realizar la implementación de los saltos hemos añadido una nueva unidad, salto.vhd, encargada de calcular las nuevas direcciones de salto. Esta unidad de salto se encuentra situada dentro de la etapa ID, adelantando así una etapa el cálculo de todos los saltos. También se ha añadido código al fichero control.vhd para distinguir entre los distintos saltos y poder generar las señales de control correspondientes. La unidad inm.vhd, encargada del cálculo del inmediato, ha sido rescrita para poder contemplar los diferentes casos.


- Anticipación de Saltos

En esta memoria describiremos los cambios que hemos realizado sobre el código de la práctica anterior para intentar controlar y reducir los riesgos producidos por las dependencias de datos. Para nuestro procesador sólo se van a dar un tipo de dependencias de datos, las RAW (Read After Write).

Las dependencias de datos RAW se producen en los procesadores segmentados cuando una instrucción que llega, necesita leer de un registro que va a ser escrito a posteriori por una instrucción que está en una etapa posterior pero que todavía no ha acabado su ejecución y, por lo tanto, todavía no ha actualizado el dato en el banco de registros para que la nueva instrucción pueda leer el dato actualizado.

Nos hemos decidido primero por comentar las anticipaciones de datos que es un método para reducir los riesgos producidos por las dependencias de datos. Para esta práctica hemos añadido una unidad de anticipación de datos que será la encargada de llevar a cabo el descubrimiento de dichas dependencias y resolverlas gracias a la anticipación. Cuando llega una nueva instrucción se comparan los registros que va a utilizar con los registros de escritura de las instrucciones que se encuentran en etapas posteriores para detectar la dependencia y, en caso de que ya esté disponible el resultado, se copiará, se “anticipará”, el nuevo dato hacia la nueva instrucción para que utilice el dato actualizado.

Después de haber reducido los riesgos por las dependencias de datos tendremos que determinar que hacer cuando se produce alguno de estos riesgos. Tuvimos que determinar y aislar cada uno de los casos de riesgo para implementar un proceso que lo detectara y que “parara” el flujo de instrucciones desde la etapa ID hasta que el riesgo desapareciese ya sea porque se consiguió anticipar el dato o porque la instrucción que creaba la dependencia ha terminado su ejecución y ha escrito el dato en el banco de registros. Este “parón” en realidad es la inclusión de burbujas desde la etapa ID hasta que la dependencia de la instrucción actual con las siguientes cese por anticipación o por terminación de estas últimas.

Tras terminar dichas modificaciones entramos con los riesgos de los saltos. Recordar que nosotros en la segunda práctica pasamos el cálculo de los saltos a la etapa ID y tratábamos a los saltos como saltos retardados ejecutando siempre la instrucción siguiente al salto. ¿Qué pasaba cuando un salto condicional es tomado ya que por defecto nosotros ejecutamos las instrucción siguiente al salto? pues teníamos que poner una instrucción de NOP después de los saltos condicionales BEQZ.

Para eliminar totalmente las instrucciones NOP del código teníamos que arreglar los saltos y como solución se nos ocurrió meter una burbuja en la etapa IF cada vez que tomábamos cualquier tipo de salto. Tras esto nos dimos cuenta de que podríamos mejorar el microprocesador haciendo saltos retardados a todos los saltos incondicionales y tratar como saltos tomados los incondicionales y añadir burbujas cada vez que estos saltaran. Pero descartamos dicha solución porque así no evitábamos las instrucciones NOP ya que si al saltar llegamos a una instrucción de salto incondicional que sólo debe volver a saltar sin ejecutar nada tendremos que añadir una NOP tras ella. Y también, estaríamos obligando a los compiladores a poner detrás de los saltos JR una instrucción que no modificase su registro de lectura ya que se produciría una dependencia de datos WAR más difíciles de resolver.

Pues bien, tras mucha meditación y comprobar que teníamos una unidad de salto en la etapa ID que está siempre ociosa hasta que le llega ya una instrucción salto y se ve obligada a meter siempre una burbuja, nos decidimos por realizar cambios profundos en la arquitectura del procesador para que dicha unidad de saltos tuviera más trabajo. Así surgió nuestra nueva unidad de anticipación de saltos la cual no hace otra cosa que intentar anticipar saltos en instrucciones anteriores a la actual. De esta forma nuestra unidad de anticipación de saltos detectará instrucciones de salto y cambiará el contador de programa a tiempo utilizando la unidad de salto ociosa para que no se interrumpa la ejecución de intrucciones mediante la utilización de burbujas.

