# arqui OBEJTIVO LOGRAR LOS TEST 
## Module diagrams
Los diagramas de cada modulo se encuentran en [docs/module_diagrams](docs/module_diagrams/):

- [adder](docs/module_diagrams/adder.md)
- [flopr](docs/module_diagrams/flopr.md)
- [flopenr](docs/module_diagrams/flopenr.md)
- [mux2](docs/module_diagrams/mux2.md)
- [mux3](docs/module_diagrams/mux3.md)
- [mem](docs/module_diagrams/mem.md)
- [regfile](docs/module_diagrams/regfile.md)
- [alu](docs/module_diagrams/alu.md)
- [fpu](docs/module_diagrams/fpu.md)
- [extend_rotational](docs/module_diagrams/extend_rotational.md)
- [condcheck](docs/module_diagrams/condcheck.md)
- [condlogic](docs/module_diagrams/condlogic.md)
- [mainfsm](docs/module_diagrams/mainfsm.md)
- [decode](docs/module_diagrams/decode.md)
- [controller](docs/module_diagrams/controller.md)
- [datapath](docs/module_diagrams/datapath.md)
- [arm](docs/module_diagrams/arm.md)
- [top](docs/module_diagrams/top.md)

Los archivos de SystemVerilog se encuentran en la carpeta `src/`, con un archivo por módulo y comentarios explicativos.

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
## Suite de pruebas – Instrucciones de multiplicación

Esta sección recoge los **tres tests funcionales** que deben superarse para validar la unidad de multiplicación (entero con signo y sin signo) de tu procesador ARM. Cada test deja el registro `R10` en `1` si todo es correcto y en `0` si algo falla, de modo que el *testbench* sólo necesita comprobar ese único bit al final.
OBJETIVO LOGRAR LOS TEST 
---

### Test 1 – MUL / SMUL básico

```asm
// PREPARACIÓN
MOV   R1, #0xFFFFFFFF   // -1 en complemento a dos (32 bits)
MOV   R2, #0x00000002   // +2

// PRUEBAS DE MULTIPLICACIÓN
MUL   {R3,R4},  R1, R2  // MUL sin signo: 0xFFFFFFFF × 2 = 0x1FFFFFFFE
SMUL  {R5,R6},  R1, R2  // SMUL con signo: -1 × 2 = -2 = 0xFFFFFFFFE

// COMPARACIÓN DE RESULTADOS
SUB   R7, R4, R6        // R7 = parte baja MUL − parte baja SMUL  (¬debe ser 0)
ADD   R8, R5, R3        // R8 = parte alta SMUL + parte alta MUL (¬debe ser 0)
CMP   R7, R8            // ¿Coinciden?
BEQ   CHECKPOINT1       // ↪️ si iguales, continuar
B     ERROR             // ❌ si distintos → R10 = 0
```

---

### Test 2 – SMULS con *flags*

```asm
CHECKPOINT1:
SMULS {R5,R6}, R1, R2   // Igual que antes pero actualiza NZCV
BLT   CHECKPOINT2        // Esperamos N=1 (resultado < 0) → salta si N≠V
B     ERROR
```

---

### Test 3 – UMULS / UMULEQ (sin signo + flags)

```asm
CHECKPOINT2:
MOV   R1, #0x80000000   // 2³¹
UMULS {R10,R3}, R1, R2  // 0x80000000 × 2 = 0x1_00000000 (overflow sin signo)
UMULEQ {R10,R3}, R3, R10 // Si Z=1 (producto cero) ⇒ sustituir (no ocurre)
B     END

ERROR:
MOV   R10, #0           // Marca fallo
END:                    // Si todo OK, R10 quedó en 1
```

---

## Criterios de éxito

| Test                                        | Condición observada                                       | Seńales/flags clave |
| ------------------------------------------- | --------------------------------------------------------- | ------------------- |
| 1                                           | `CMP` provoca `BEQ` a `CHECKPOINT1` (Z=1)                 | Valores de `R3–R8`  |
| 2                                           | `SMULS` genera `N=1`, `V=0` → `BLT` tomado                | NZCV tras SMULS     |
| 3                                           | Producto de `UMULS` = **0x00000001 00000000** <br>(R10=1, |                     |
| R3=0) y `UMULEQ` no se ejecuta porque `Z=0` | N,C,V,Z tras `UMULS`                                      |                     |

---

## Consejos de depuración

1. **Verifica el multiplicador de 64 bits**: asegúrate de que produce parte alta y baja correctas en modo con/sin signo.
2. **Chequea la extensión de signo** antes de multiplicar (en SMUL / SMULS): `R1` debe convertirse a 0xFFFFFFFF.
3. **Confirma la lógica de flags**:

   * `SMULS` actualiza NZCV según el resultado de 64 bits (consulta pág. 226 del PDF *FPmult\_guide.pdf*).
   * `UMULS` define `N` y `Z` basándose en la parte alta (`R10`) **y** la baja (`R3`).
4. **Rama condicional**: `BLT` depende de `N XOR V`; prueba aislada de flags con un *testbench* simple para descartar errores en `condcheck`.

integraremos  este bloque en tu archivo `memfile.dat`, recarga la simulación y verifica que `R10` termina en `1`. Si no, captura la traza de `R3,R4,R5,R6,R10` y los flags para identificar la divergencia.
## Test 2 – Punto flotante (Integrador de Euler)

Este test comprueba **FMUL, FADD, FMUL con flags y el loop de control** usando un integrador de 2º orden. Al finalizar **`R1` debe valer ≈ 11.4 (32‑bit float)**; si vas a mostrarlo en la placa de 7 segmentos, conviértelo a binario de 16 bits.

---

### 1. Código de prueba

```asm
// 128 iteraciones
MOV     R0, #128        // contador N

// --- VARIABLES (32‑bit IEEE‑754) ---
// Para cargar constantes de 32 bits, usa una de estas tácticas:
//  a) LDR literal desde pool:  LDR Rn, =0x3F800000  ; 1.0f
//  b) MOVW/MOVT:             MOVW Rn, #0x3F80 ; MOVT Rn, #0x0000
//  c) Copiar desde memoria de datos (dmem)
// A continuación se muestran los valores en notación hex.

LDR     R1, =0x00000000  // X  = 0.0f
LDR     R2, =0x40400000  // DX = 3.0f
LDR     R3, =0x3DCCCCCD  // DT = 0.1f
LDR     R4, =0xBECCCCCD  // A  = –0.4f
LDR     R5, =0x3DCCCCCD  // B  = 0.1f

FOR:
    // dX = DT * DX
    MOV     R6, R2
    FMUL    R6, R3

    // dDX = DT * (A * X + B * DX)
    MOV     R7, R1      // R7 = X
    FMUL    R7, R4      // A * X
    MOV     R8, R2      // R8 = DX
    FMUL    R8, R5      // B * DX
    FADD    R7, R8      // A*X + B*DX
    FMUL    R7, R3      // DT * (...)

    // Actualiza X y DX
    FADD    R1, R6      // X  += dX
    FADD    R2, R7      // DX += dDX

    SUB     R0, #1
    BEQ     END_FOR
    B       FOR

END_FOR:
    // En R1 ~ 11.4264f (≈ 0x41366666). Para la placa, conviértelo a 16 bits.
```

> **Nota:** el valor medio teórico tras 128 pasos con `dt = 0.1` es **11.4264…**; redondeado a 11.4 para mostrar con 3 cifras.

---

### 2. Criterios de éxito

| Registro | Valor esperado       | Comentario                       |
| -------- | -------------------- | -------------------------------- |
| `R1`     | `0x41366666` ± 1 LSB | 32‑bit float ≈ 11.426            |
| `R2`     | \~−11.684            | Oscila al final; no se comprueba |
| `NZCV`   | Indiferente          | No usado en el loop              |

Si el resultado se muestra en 16 bits (half‑precision) debería quedar `0x49B7`.

---

### 3. Puntos de depuración

1. **Carga de constantes:** verifica en el waveform que `R1–R5` contengan los valores IEEE‑754 correctos antes de entrar al bucle.
2. **Pipeline de FPU:** asegúrate de que FMUL/FADD respetan su latencia; si la unidad es de varios ciclos, inserta *NOPs* o usa *stall*.
3. **Desbordamiento gradual:** observa `R1` cada 16 iteraciones; debería crecer de 0 → 1.12 → … → 11.4.
4. **Flags y riesgos de precisión:** el código no depende de ellos, pero comprueba que FMULS/FADDS actualicen NZCV si planeas usarlos.

---

### 4. Estrategia si falla

* Si `R1` termina muy pequeño (<1): probablemente **FMUL** usa 16 bits o falla el corrimiento de implicit‑1.
* Si `R1` se va a `NaN`/`Inf`: revisa **overflow del exponente** en la normalización.
* Divergencias leves ( < 1 %): tu **rounder** podría estar cortando `guard` o `sticky`. Ajusta modo “round‑to‑nearest, ties‑to‑even”.

Ejecútalo y comparte el valor final de `R1` (hex y decimal) para cerrar la depuración de la FPU.

## Test 3 – MOV / LDR de literales (carga de constantes float)

Aunque el código coincide con el integrador de Euler del Test 2, este escenario se centra exclusivamente en **verificar que tu procesador carga correctamente valores de 32 bits** mediante instrucciones **`MOV`**, **`MOVW/MOVT`** o **`LDR literal`** (pool). Si fallan, todo el bucle de punto flotante también fallará, por eso lo separamos.

---

### 1. Objetivo

* Confirmar que tras ejecutar cada instrucción de carga, los registros contienen exactamente el patrón IEEE‑754 esperado.
* Demostrar que el ensamblador/loader emite los pares `MOVW` + `MOVT` correctos o la instrucción `LDR` con la etiqueta apropiada.

---

### 2. Secuencia mínima de prueba

```asm
// 1) Cargar variables flotantes
LDR     R1, =0x00000000  // 0.0f  – X
LDR     R2, =0x40400000  // 3.0f  – DX
LDR     R3, =0x3DCCCCCD  // 0.1f  – DT
LDR     R4, =0xBECCCCCD  // -0.4f – A
LDR     R5, =0x3DCCCCCD  // 0.1f  – B

// 2) Verificación rápida (opcional)
MOV     R6, R1           // Copia para comparaciones
CMP     R6, #0           // ¿X es exactamente 0x00000000?
BNE     ERROR

// …puedes repetir comparaciones similares para R2–R5…

B       END_TEST

ERROR:
MOV     R10, #0          // Señal de fallo
END_TEST:
```

Si tu ensamblador no soporta `LDR =.constant`, reemplázalo por **`MOVW`/`MOVT`**:

```asm
MOVW    R1, #0x0000
MOVT    R1, #0x0000  // R1 = 0x00000000
```

---

### 3. Criterios de éxito

| Registro | Valor hex    | Valor float | Método de carga         |
| -------- | ------------ | ----------- | ----------------------- |
| R1       | `0x00000000` | +0.0        | MOVW/MOVT o LDR literal |
| R2       | `0x40400000` | 3.0         | «                       |
| R3       | `0x3DCCCCCD` | 0.1         | «                       |
| R4       | `0xBECCCCCD` | –0.4        | «                       |
| R5       | `0x3DCCCCCD` | 0.1         | «                       |

Si todos los registros corresponden exactamente, el test coloca `R10 = 1` (o deja sin modificar) y continúa; cualquier discrepancia activa la rama **ERROR** y fija `R10 = 0`.

---

### 4. Depuración

1. **Waveform**: observa `WriteData` en la etapa de memoria inmediatamente después de cada instrucción de carga.
2. **PC & alignment**: al usar literal pool, verifica que el `PC` apunta a la palabra correcta (`PC+8` en ARM monociclo).
3. **Big-endian/little‑endian**: asegúrate de que la memoria de instrucciones y datos comparten el mismo endianness.

Una vez que los valores se cargan bien, el integrador del Test 2 debería producir `R1 ≈ 11.4` sin errores de arrastre por constantes mal inicializadas.
## Referencia – Codificación de valores inmediatos en instrucciones ARM

### 1. Formato de instrucción *Data‑Processing*

```
31       28       27 26 25 24          21 20 19    16 15    12 11   0
┆  Cond   ┆ 0 0 I ┆   Opcode  ┆  S ┆   Rn   ┆   Rd   ┆   Operand2   ┆
```

* **`I` = 1** indica que `Operand2` es un **inmediato de 12 bits**.

### 2. Almacén de 12 bits ⇒ *8‑bit constante + rotación de 4 bits*

```
11   8 7   0
┆Rotate┆  Imm8 ┆
```

* `Imm8` se **zero‑extiende** a 32 bits.
* El resultado se **rota a la derecha** `2·Rotate` bits (`ROR (Rotate×2)`).

> Con solo 12 bits se pueden generar \~4000 millones de valores útiles, incluidas cualquier potencia de 2 (0–31), cualquier byte alineado, máscaras de bits, etc.

### 3. Tabla de rotaciones (nibble `Rotate` → desplazamiento real)

| `Rotate` | Bits de `Imm8` tras la rotación (posición en la palabra de 32 bits)         |
| -------: | :-------------------------------------------------------------------------- |
|      0x0 | 7 6 5 4 3 2 1 0                                                             |
|      0x1 |                                 7 6 5 4 3 2 1 0                             |
|      0x2 |                         7 6 5 4 3 2 1 0                                     |
|       …  | *(continúa hasta 0xF; recorre de 0 a 30 bits, paso 2)*                      |

*(La imagen verde del PDF ilustra gráficamente estas posiciones.)*

### 4. Ejemplos típicos que **sí** se pueden codificar

| Constante    | Codificación `Imm8,Rotate` | Ejemplo de uso                             |
| ------------ | -------------------------- | ------------------------------------------ |
| `0x000000FF` | `Imm8=0xFF`, `Rotate=0x0`  | filtro de byte bajo                        |
| `0x80000000` | `Imm8=0x80`, `Rotate=0x7`  | `EOR r0,r0,#0x80000000` (cambia el bit 31) |
| `0x00FF0000` | `Imm8=0xFF`, `Rotate=0x6`  | máscara de byte alto‑medio                 |
| `0x3FC00`    | `Imm8=0xFF`, `Rotate=0x2`  | constantes de bucle grandes                |

### 5. Ejemplos **que no** se pueden codificar directamente

* `0x12345678`  (no cabe en la familia rotada de ningún `Imm8`).
* `0xC0000034`  (uno de los ejercicios propuestos → requiere secuencia `MOV`/`ORR`).

### 6. Implicaciones para la microarquitectura

**Módulo `extend` / `ImmSrc=00` (inmediatos DP):**

```verilog
// imm12 = Instr[11:0];
imm8   = imm12[7:0];
rot    = imm12[11:8] * 2;    // 0‑30 en pasos de 2
ExtImm = {24{1'b0}} | imm8;  // zero‑extend a 32 bits
ExtImm = (ExtImm >> rot) | (ExtImm << (32‑rot)); // ROR
```

* Usar un **multiplexor + barrel shifter** de 32×32 o un pequeño LUT pre‑calculado.
* `C` puede actualizarse con el **bit 31** rotado si la instrucción lleva el sufijo `S`.

### 7. Estrategia de depuración de inmediatos

1. **Test estático:** comprueba que instrucción `MOV r0,#0x80000000` escribe exactamente ese patrón.
2. **Barrido sistemático:** genera todos los `Rotate` con `Imm8=8'hFF` y verifica la tabla verde.
3. **Comparativa con ensamblador GNU:** desensamblar (`objdump -d`) un binario conocido y confirmar que tu decodificador produce las mismas constantes en el datapath.

### 8. Referencias

* ARM Architecture Reference Manual, § A5.2.4 “Data‑processing operands”
* Artículo «ARM immediate value encoding» – blog de E. Clarke (fuente del ejemplo `0x3FC00`).

