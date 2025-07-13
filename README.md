# arqui posible contexto  

### 1. Estructura de alto nivel

* **`arm` (HDL Example 7.1)** encapsula al **`controller`** y al **`datapath`** y expone las señales clave: `PC`, `MemWrite`, `ALUResult`, `WriteData` y `ReadData` .
* En el **`top`** de prueba (HDL Example 7.13) ese módulo se conecta con **`imem`** y **`dmem`**; el *testbench* verifica que se escriba el 7 en la dirección `0x64` al final del programa .

### 2. Controlador

* El **`controller`** (HDL Example 7.2) se divide en un **`decoder`** y la lógica condicional **`condlogic`**.

  * **`decoder`** implementa el «main decoder» y el «ALU decoder», generando señales como `RegSrc`, `ImmSrc`, `ALUSrc`, `MemtoReg`, `Branch`, `ALUOp`, etc.
  * **`condlogic`** filtra esas señales según el campo de condición (`Cond`) y los *flags* (`N,Z,C,V`) usando **`condcheck`**, y sólo permite que `RegWrite`, `MemWrite` y `PCSrc` pasen cuando la condición se cumple .

### 3. Camino de datos

* El **`datapath`** (HDL Example 7.5) combina:

  1. **PC logic** (`pcmux`, `pcreg`, `adder`) para actualizar `PC`, `PC+4`, `PC+8`.
  2. **Registro de propósito general** de tres puertos `regfile` que lee `R15` como `PC+8`.
  3. **Extend** para los inmediatos (`ImmSrc`).
  4. **ALU** de 32 bits con `ALUFlags`.
  5. Multiplexores (`resmux`, `srcbmux`) que seleccionan entre datos de memoria, ALU y extensiones .

### 4. Banco de pruebas y programa de ejemplo

* El *testbench* hace *assert* en cada flanco negativo del reloj: si `MemWrite` se activa y la dirección es `100` (decimal 0x64) con dato `7`, imprime **“Simulation succeeded”** y detiene la simulación; cualquier otra escritura distinta de la intermedia a `96` lanza **“Simulation failed”** .
* La tabla de la pág. 452 muestra la secuencia de instrucciones (`SUB`, `ADD`, `ORR`, etc.) y su *machine code*; esto sirve para comprobar que `memfile.dat` esté bien cargado .


**Próximos pasos sugeridos**

1. Verifica que tu sumador de exponentes reste el sesgo (127) y detecte *overflow*.
2. Observa si el producto de significandos requiere la normalización de 1 bit y que el exponente se ajuste en consecuencia.
3. Corre el test mínimo (0.5 × −0.4375) y confirma que obtienes `0xBE600000`.

He añadido al panel un **“Test Mul Suite”** con los tres escenarios que necesitas ejecutar y los criterios exactos de éxito. Ahora puedes:

1. Copiar este bloque de ensamblador a tu `memfile.dat` (o al ensamblador que uses).
2. Correr la simulación y observar qué checkpoint falla primero.
3. Reportar aquí los registros o flags que difieren para enfocarnos en la causa.



* El formato de las instrucciones *Data-Processing* con el bit `I`.
* Cómo se forma el inmediato **Imm8 + Rotate×2 → ROR**.
* La tabla de rotaciones completa y ejemplos que sí / no se pueden codificar.
* Un esbozo de lógica Verilog para tu módulo `extend` y un checklist de pruebas.
