// Code your design here
`timescale 1ns/1ps
 
//--------------------------------------------------------------------
// design.sv: Diseño Completo del Procesador ARM Multiciclo
//--------------------------------------------------------------------
// Este archivo integra todos los módulos del procesador ARM multiciclo,
// siguiendo una estructura jerárquica de 11 grupos. Cada módulo se define
// antes de ser instanciado, asegurando la correcta interconexión y
// funcionalidad del sistema.
//
// Se han incorporado todos los ajustes y correcciones discutidos en las
// revisiones de calidad anteriores para asegurar la robustez y la fidelidad
// a la arquitectura ARMv4, incluyendo el soporte para operaciones de
// multiplicación, comparaciones y punto flotante (simulado).
//--------------------------------------------------------------------

module adder #(parameter WIDTH = 32)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);
    assign y = a + b;
endmodule

module flopr #(parameter WIDTH = 8)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire [WIDTH-1:0]       d,
    output reg  [WIDTH-1:0]       q
);
    always @(posedge clk or posedge reset)
        if (reset) q <= 0;
        else       q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)(
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   en,
    input  wire [WIDTH-1:0]       d,
    output reg  [WIDTH-1:0]       q
);
    always @(posedge clk or posedge reset)
        if (reset)   q <= 0;
        else if (en) q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)(
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire             s,
    output wire [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule

module mux3 #(parameter WIDTH = 8)(
    input  wire [WIDTH-1:0] d0,
    input  wire [WIDTH-1:0] d1,
    input  wire [WIDTH-1:0] d2,
    input  wire [1:0]       s,
    output reg  [WIDTH-1:0] y
);
    always @(*) begin
        case (s)
            2'b00: y = d0;
            2'b01: y = d1;
            2'b10: y = d2;
            default: y = {WIDTH{1'bx}};
        endcase
    end
endmodule

//--------------------------------------------------------------------
// Grupo 2: Elementos de Almacenamiento Principal
//--------------------------------------------------------------------
module mem #(parameter MEM_DEPTH = 1024) (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] a,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] RAM [0:MEM_DEPTH-1];
    initial $readmemh("memfile.dat", RAM);
    assign rd = RAM[a[($clog2(MEM_DEPTH)+1):2]];
    always @(posedge clk)
        if (we) RAM[a[($clog2(MEM_DEPTH)+1):2]] <= wd;
endmodule

module regfile(
    input  wire        clk,
    input  wire        we3,
    input  wire [3:0]  ra1,
    input  wire [3:0]  ra2,
    input  wire [3:0]  wa3,
    input  wire [31:0] wd3,
    input  wire [31:0] r15,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    // Banco de registros R0–R15
    reg [31:0] rf [0:15];
    always @(posedge clk)
        if (we3) rf[wa3] <= wd3;
    assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
    assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];

    // ------------------------------------------------------------
    // Tarea dump: imprime valores de R0–R14 (para depuración)
    // ------------------------------------------------------------
    task dump;
        integer idx;
        begin
            $display("-------------------------------------------");
            $display("       ESTADO FINAL DE REGISTROS            ");
            for (idx = 0; idx < 15; idx = idx + 1)
                $display("R%0d = 0x%08h", idx, rf[idx]);
            $display("-------------------------------------------");
        end
    endtask
endmodule


//--------------------------------------------------------------------
// Grupo 3: Unidades Aritméticas y de Extensión Especializadas (The Calculators)
//--------------------------------------------------------------------
// Propósito: Módulos que implementan funcionalidades de cálculo específicas
// y extensiones de datos. Incluye la ALU principal, la FPU (simulada) y el
// extensor rotacional.
// Impacto y Conexiones: Este grupo es fundamental para las operaciones de
// procesamiento de datos y la correcta interpretación de los inmediatos.
// Sus módulos son instanciados por el 'datapath' (Grupo 9).
// Las correcciones y adiciones (ALU para 64-bit MULs, FPU, extend_rotational)
// son CRÍTICAS para ejecutar los tests de multiplicación y punto flotante.
//--------------------------------------------------------------------

module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] ALUControl,
    output reg [31:0] Result,
    output reg [63:0] ALUResult64,
    output reg [3:0] ALUFlags
);
    wire [32:0] sum = {1'b0, a} + {1'b0, b}; 
    wire [32:0] sub = {1'b0, a} - {1'b0, b};

    wire [63:0] mul_unsigned = {32'b0, a} * {32'b0, b};
    wire [63:0] mul_signed   = $signed(a) * $signed(b);

    always @(*) begin
        case (ALUControl)
            4'b0000: begin
                Result = sum[31:0];
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0001: begin
                Result = sub[31:0];
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0010: begin
                Result = a & b;
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0011: begin
                Result = a | b;
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0100: begin
                Result = mul_unsigned[31:0];
                ALUResult64 = mul_unsigned;
            end
            4'b0101: begin
                Result = mul_signed[31:0];
                ALUResult64 = mul_signed;
            end
            default: begin
                Result = 32'hxxxxxxxx;
                ALUResult64 = 64'hxxxxxxxxxxxxxxxx;
            end
        endcase
    end
    
    always @(*) begin
        case (ALUControl)
            4'b0000, 4'b0001: begin
                ALUFlags[3] = Result[31];
                ALUFlags[2] = (Result == 32'h0);
                ALUFlags[1] = (ALUControl == 4'b0000) ? sum[32] : ~sub[32];
                ALUFlags[0] = (ALUControl == 4'b0000) ? (a[31] == b[31] && Result[31] != a[31]) :
                                                        (a[31] != b[31] && Result[31] != a[31]);
            end
            4'b0010, 4'b0011: begin
                ALUFlags[3] = Result[31];
                ALUFlags[2] = (Result == 32'h0);
                ALUFlags[1] = 1'b0;
                ALUFlags[0] = 1'b0;
            end
            4'b0100, 4'b0101: begin
                ALUFlags[3] = ALUResult64[63];
                ALUFlags[2] = (ALUResult64 == 64'h0);
                ALUFlags[1] = 1'b0;
                ALUFlags[0] = 1'b0;
            end
            default: begin
                ALUFlags = 4'bxxxx;
            end
        endcase
    end
endmodule

module fpu (
    input wire [31:0] fp_a,
    input wire [31:0] fp_b,
    input wire [1:0]  fp_control,
    output reg [31:0] fp_result
);

    real real_a;
    real real_b;
    real real_result;

    always @(*) begin
        real_a = $bitstoreal({32'b0, fp_a});
        real_b = $bitstoreal({32'b0, fp_b});

        case (fp_control)
            2'b00: begin
                real_result = real_a + real_b;
            end
            2'b01: begin
                real_result = real_a * real_b;
            end
            default: begin
                real_result = 0.0;
                fp_result = 32'hFFFF_FFFF;
            end
        endcase
        
        if (fp_control == 2'b00 || fp_control == 2'b01) begin
            fp_result = $realtobits(real_result);
        end
    end

endmodule

module extend_rotational(
    input wire [31:0] Instr,
    input wire [1:0] ImmSrc,
    output reg [31:0] ExtImm
);
    wire [7:0] imm8 = Instr[7:0];
    wire [3:0] rot  = Instr[11:8];
    wire [31:0] rotated_imm_val;

    assign rotated_imm_val = (imm8 >> (2 * rot)) | (imm8 << (32 - (2 * rot)));

    always @(*)
    case (ImmSrc)
        2'b00: ExtImm = rotated_imm_val;
        2'b01: ExtImm = {{20{1'b0}}, Instr[11:0]};
        2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00};
        default: ExtImm = 32'hxxxxxxxx;
    endcase
endmodule


//--------------------------------------------------------------------
// Grupo 4: Lógica de Control - Verificador de Condición (The Condition Evaluator)
//--------------------------------------------------------------------
// Propósito: Módulo combinacional que evalúa las banderas de estado del
// procesador (ALUFlags) contra la condición de ejecución de la instrucción
// (Cond) para producir la señal CondEx.
// Impacto y Conexiones: Este módulo es CRÍTICO para la ejecución condicional
// de las instrucciones ARM. Recibe las banderas de estado actualizadas de la ALU
// (via condlogic) y el campo de condición de la instrucción (Cond). Su salida
// CondEx es utilizada por 'condlogic' (Grupo 5) para habilitar o deshabilitar
// las escrituras en el PC, RegFile y Memoria.
// Se mantiene sin cambios en su lógica principal, ya que fue validado como
// completo y robusto en su función de evaluar las condiciones de ARMv4.
//--------------------------------------------------------------------
module condcheck(
    input wire [3:0] Cond,
    input wire [3:0] Flags,
    output reg CondEx
);
    wire N, Z, C, V;
    assign {N, Z, C, V} = Flags;
    
    wire ge = (N == V);

    always @(*) begin
        case (Cond)
            4'b0000: CondEx = Z;
            4'b0001: CondEx = ~Z;
            4'b0010: CondEx = C;
            4'b0011: CondEx = ~C;
            4'b0100: CondEx = N;
            4'b0101: CondEx = ~N;
            4'b0110: CondEx = V;
            4'b0111: CondEx = ~V;
            4'b1000: CondEx = C & ~Z;
            4'b1001: CondEx = ~C | Z;
            4'b1010: CondEx = ge;
            4'b1011: CondEx = ~ge;
            4'b1100: CondEx = ~Z & ge;
            4'b1101: CondEx = Z | ~ge;
            4'b1110: CondEx = 1'b1;
            default: CondEx = 1'b1;
        endcase
    end
endmodule


//--------------------------------------------------------------------
// Grupo 5: Lógica de Control - Lógica Condicional de Escritura (The Conditional Writer)
//--------------------------------------------------------------------
// Propósito: Módulo combinacional que aplica el filtro condicional (CondEx)
// a las señales de habilitación de escritura finales para el PC, el banco
// de registros y la memoria. También gestiona la actualización de las banderas
// de estado.
// Impacto y Conexiones: Este módulo es CRÍTICO para la correcta ejecución
// condicional de las instrucciones ARM.
// - Recibe 'CondEx' del módulo 'condcheck' (Grupo 4).
// - Recibe 'FlagW' (indicando si se deben actualizar flags) y las señales
//   de habilitación de escritura 'PCS', 'NextPC', 'RegW', 'MemW' del 'decode'
//   (Grupo 7) y 'mainfsm' (Grupo 6).
// - Sus salidas 'PCWrite', 'RegWrite', 'MemWrite' son las habilitaciones
//   finales que controlan las escrituras en el 'datapath' (Grupo 9).
// - Gestiona el registro de banderas de estado ('Flags'), actualizándolo
//   con 'ALUFlags' del 'datapath' (Grupo 9) solo cuando la instrucción
//   se ejecuta y el bit 'S' lo indica.
// Ajustes Recientes:
// - Se ha simplificado y corregido la lógica de actualización de las banderas
//   de estado ('Flags') para mayor robustez, utilizando un 'flopenr' con
//   habilitación clara.
//--------------------------------------------------------------------
module condlogic(
    input wire clk,
    input wire reset,
    input wire [3:0] Cond,
    input wire [3:0] ALUFlags,
    input wire [1:0] FlagW,
    input wire PCS,
    input wire NextPC,
    input wire RegW,
    input wire MemW,
    output wire PCWrite,
    output wire RegWrite,
    output wire MemWrite
);
    wire [3:0] Flags;
    wire CondEx;

    condcheck cc(
        .Cond(Cond),
        .Flags(Flags),
        .CondEx(CondEx)
    );

    wire update_flags_nz = FlagW[1] & CondEx;
    wire update_flags_cv = FlagW[0] & CondEx;

    flopenr #(2) flags_nz_reg(
        .clk(clk),
        .reset(reset),
        .en(update_flags_nz),
        .d(ALUFlags[3:2]),
        .q(Flags[3:2])
    );

    flopenr #(2) flags_cv_reg(
        .clk(clk),
        .reset(reset),
        .en(update_flags_cv),
        .d(ALUFlags[1:0]),
        .q(Flags[1:0])
    );

    assign PCWrite = NextPC | (CondEx & PCS);
    assign RegWrite = CondEx & RegW;
    assign MemWrite = CondEx & MemW;

endmodule


//--------------------------------------------------------------------
// Grupo 6: Lógica de Control - Máquina de Estados Finitos (The Brain's Orchestrator)
//--------------------------------------------------------------------
// Propósito: Módulo secuencial que orquesta el flujo de ejecución del procesador
// a través de diferentes estados (FETCH, DECODE, EXECUTE, etc.).
// Impacto y Conexiones: Este es el corazón del control multiciclo.
// - Recibe señales de detección de instrucción (is_mul64, is_mul32, is_compare_op, is_fp_op)
//   del 'decode' (Grupo 7).
// - Genera todas las señales de control temporizadas para el 'datapath' (Grupo 9)
//   y para la 'condlogic' (Grupo 5).
// - Sus salidas controlan el flujo de datos, las operaciones de la ALU/FPU,
//   y las escrituras en el banco de registros y la memoria.
// Ajustes Recientes:
// - Se han añadido nuevos estados (EXEC_MUL, WB_MUL_LO, WB_MUL_HI, ALU_NO_WB,
//   EXEC_FP, WB_FP) para manejar las complejidades de las multiplicaciones
//   de 64 bits, las comparaciones y las operaciones de punto flotante.
// - La lógica de transición de estados y las asignaciones de señales de control
//   se han actualizado para reflejar estos nuevos estados y sus operaciones.
//--------------------------------------------------------------------
module mainfsm(
    input wire clk,
    input wire reset,
    input wire [1:0] Op,
    input wire [5:0] Funct,
    input wire is_mul64,
    input wire is_mul32,
    input wire is_compare_op,
    input wire is_fp_op,
    
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ResultSrc,
    output wire NextPC,
    output wire RegW,
    output wire MemW,
    output wire Branch,
    output wire ALUOp,
    output wire WAsel,
    output wire ResultWEn,
    output wire AandBWrite,
    output wire RA2Sel,
    output wire [1:0] FPUOp
);
    reg [3:0] state, nextstate;
    reg [18:0] controls;

    localparam [3:0] 
        FETCH       = 0,
        DECODE      = 1,
        MEMADR      = 2,
        MEMRD       = 3,
        MEMWB       = 4,
        MEMWRITE    = 5,
        EXECUTER    = 6,
        EXECUTEI    = 7,
        ALUWB       = 8,
        BRANCH      = 9,
        UNKNOWN     = 10,
        EXEC_MUL    = 11,
        WB_MUL_LO   = 12,
        WB_MUL_HI   = 13,
        ALU_NO_WB   = 14,
        EXEC_FP     = 15,
        WB_FP       = 16;

    always @(posedge clk or posedge reset) begin
        if (reset) 
            state <= FETCH;
        else       
            state <= nextstate;
    end

    always @(*) begin
        nextstate = FETCH;
        case (state)
            FETCH:      nextstate = DECODE;
            DECODE:     
                case (Op)
                    2'b00: begin
                        if (is_mul64)      nextstate = EXEC_MUL;
                        else if (is_mul32) nextstate = EXECUTER;
                        else if (is_compare_op) nextstate = EXECUTER;
                        else if (Funct[5]) nextstate = EXECUTEI;
                        else               nextstate = EXECUTER;
                    end
                    2'b01: nextstate = MEMADR;
                    2'b10: nextstate = BRANCH;
                    2'b11: nextstate = EXEC_FP;
                    default: nextstate = UNKNOWN;
                endcase
            EXECUTER:   
                if(is_compare_op) nextstate = ALU_NO_WB;
                else              nextstate = ALUWB;
            EXECUTEI:   nextstate = ALUWB;
            ALUWB:      nextstate = FETCH;
            ALU_NO_WB:  nextstate = FETCH;
            MEMADR:     nextstate = Funct[0] ? MEMRD : MEMWRITE;
            MEMRD:      nextstate = MEMWB;
            MEMWRITE:   nextstate = FETCH;
            MEMWB:      nextstate = FETCH;
            BRANCH:     nextstate = FETCH;
            EXEC_MUL:   nextstate = WB_MUL_LO;
            WB_MUL_LO:  nextstate = WB_MUL_HI;
            WB_MUL_HI:  nextstate = FETCH;
            EXEC_FP:    nextstate = WB_FP;
            WB_FP:      nextstate = FETCH;
            default:    nextstate = UNKNOWN;
        endcase
    end

    always @(*) begin
        case (state)
            FETCH:      controls = 19'b00_0_0_0_0_1_0_0_0_1_0_10_01_10_0;
            DECODE:     controls = 19'b00_1_1_0_0_0_0_0_0_0_0_10_01_10_0;
            EXECUTER:   controls = 19'b00_0_0_0_0_0_0_0_0_0_00_00_00_1;
            EXECUTEI:   controls = 19'b00_0_0_0_0_0_0_0_0_0_00_00_01_1;
            ALUWB:      controls = 19'b00_0_0_0_0_0_0_1_1_0_0_00_00_00_0;
            ALU_NO_WB:  controls = 19'b00_0_0_0_0_0_0_0_0_0_0_00_00_00_0;
            MEMADR:     controls = 19'b00_0_0_0_0_0_0_0_0_0_1_00_00_01_0;
            MEMWRITE:   controls = 19'b00_1_0_0_0_0_0_1_0_0_1_00_00_00_0;
            MEMRD:      controls = 19'b00_0_0_0_0_0_0_0_1_0_0_00_00_00_0;
            MEMWB:      controls = 19'b00_0_0_0_0_0_0_1_1_0_0_01_00_00_0;
            BRANCH:     controls = 19'b00_0_0_0_0_1_1_0_0_0_0_00_00_01_0;
            EXEC_MUL:   controls = 19'b00_0_0_1_0_0_0_0_0_0_0_00_00_00_1;
            WB_MUL_LO:  controls = 19'b00_0_0_0_0_0_0_1_1_0_0_10_00_00_0;
            WB_MUL_HI:  controls = 19'b00_0_0_0_1_0_0_1_1_0_0_11_00_00_0;
            EXEC_FP:    controls = 19'b01_0_0_1_0_0_0_0_0_0_0_00_00_00_0;
            WB_FP:      controls = 19'b00_0_0_0_0_0_0_1_1_0_0_01_00_00_0;
            default:    controls = 19'hXXXXX;
        endcase
    end

    assign {FPUOp, RA2Sel, AandBWrite, ResultWEn, WAsel, NextPC, Branch, MemW, RegW, IRWrite, AdrSrc, ResultSrc, ALUSrcA, ALUSrcB, ALUOp} = controls;

endmodule


//--------------------------------------------------------------------
// Grupo 7: Lógica de Control - Decodificador de Instrucciones (The Instruction Interpreter)
//--------------------------------------------------------------------
// Propósito: Módulo combinacional que interpreta los campos de la instrucción
// y genera las señales de control estáticas para la FSM y el datapath.
// Impacto y Conexiones: Este módulo es el primer nivel de decodificación.
// - Recibe la instrucción COMPLETA (Instr) del 'datapath' (Grupo 9).
// - Genera señales de detección de tipo de instrucción (is_mul64, is_fp_op, etc.)
//   para la 'mainfsm' (Grupo 6).
// - Genera señales de control para la ALU, FPU, selección de registros,
//   y extensión de inmediatos, que son consumidas por 'mainfsm' y 'datapath'.
// Ajustes Recientes:
// - Entrada 'Instr' completa para una decodificación precisa.
// - Lógica de detección de MULs (is_mul_family, is_mul64, is_mul32) corregida
//   para ser fiel a ARMv4 (usando Instr[7:4] y Funct[4:1]).
// - Lógica de ALUControl para MULs refinada.
// - Detección y generación de señales para instrucciones de Punto Flotante (FP).
//--------------------------------------------------------------------
module decode(
    input wire clk,
    input wire reset,
    input wire [31:0] Instr,
    
    output wire [1:0] FlagW,
    output wire PCS,
    output wire NextPC,
    output wire RegW,
    output wire MemW,
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] ResultSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ImmSrc,
    output wire [1:0] RegSrc,
    output wire [3:0] ALUControl,
    output wire Branch,
    output wire WAsel,
    output wire ResultWEn,
    output wire AandBWrite,
    output wire RA2Sel,
    output wire [1:0] FPUOp
);
    wire [1:0] Op    = Instr[27:26];
    wire [5:0] Funct = Instr[25:20];
    wire [3:0] Rd    = Instr[15:12];

    wire ALUOp;

    wire is_mul_family = (Op == 2'b00) && (Instr[7:4] == 4'b1001);

    wire is_mul32 = is_mul_family && (Funct[4:1] == 4'b0000);
    wire is_mul64 = is_mul_family && (Funct[4:1] >= 4'b0100 && Funct[4:1] <= 4'b0111);
    
    wire is_compare_op = (Op == 2'b00) && Funct[0] && (Funct[4:1] == 4'b1010 || Funct[4:1] == 4'b1000);

    wire is_fp_op = (Op == 2'b11);

    mainfsm fsm(
        .clk(clk), .reset(reset), .Op(Op), .Funct(Funct), 
        .is_mul64(is_mul64), .is_mul32(is_mul32), .is_compare_op(is_compare_op),
        .is_fp_op(is_fp_op),
        .IRWrite(IRWrite), .AdrSrc(AdrSrc), .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc), .NextPC(NextPC), .RegW(RegW), .MemW(MemW),
        .Branch(Branch), .ALUOp(ALUOp), .WAsel(WAsel), .ResultWEn(ResultWEn),
        .AandBWrite(AandBWrite), .RA2Sel(RA2Sel), .FPUOp(FPUOp)
    );

    assign ALUControl = ALUOp ? (
                                    is_mul_family ? (
                                        Funct[4:1] == 4'b0000 ? (Funct[0] ? 4'b0001 : 4'b0000) :
                                        Funct[4:1] == 4'b0100 ? (Funct[0] ? 4'b0101 : 4'b0100) :
                                        Funct[4:1] == 4'b0110 ? (Funct[0] ? 4'b0111 : 4'b0110) :
                                        4'bXXXX
                                    ) : (
                                        is_fp_op ? 4'bXXXX : // ALUControl para FP no relevante aquí, FPUOp lo maneja
                                        Funct[4:1] == 4'b0100 ? 4'b0000 :
                                        Funct[4:1] == 4'b0010 ? 4'b0001 :
                                        Funct[4:1] == 4'b1010 ? 4'b0001 :
                                        Funct[4:1] == 4'b0000 ? 4'b0010 :
                                        Funct[4:1] == 4'b1000 ? 4'b0010 :
                                        Funct[4:1] == 4'b1100 ? 4'b0011 :
                                        4'b0000
                                    )
                                ) : 4'b0000;

    assign FlagW[1] = ALUOp & Funct[0];
    assign FlagW[0] = ALUOp & Funct[0] & (ALUControl < 4'b0010);
    
    assign PCS = Branch | (RegW & (Rd == 4'b1111));
    
    assign ImmSrc = Op; 

    assign RegSrc[0] = (Op == 2'b10);
    assign RegSrc[1] = (Op == 2'b01) & ~Funct[0];

endmodule


//--------------------------------------------------------------------
// Grupo 8: Ensamblaje del Control Principal (The Control Unit Top)
//--------------------------------------------------------------------
// Propósito: Este módulo de nivel superior dentro del control, instancia
// y conecta los módulos de lógica de control (condcheck, condlogic, mainfsm, decode).
// Impacto y Conexiones: Es el punto de entrada para todas las señales
// de control que vienen del procesador principal ('arm'). Orquesta la
// decodificación y el flujo de control, pasando las señales al 'datapath'.
// Los ajustes recientes aseguran que la instrucción completa se pase al
// decodificador y que todas las nuevas señales de control (para MULs y FP)
// sean gestionadas y transmitidas correctamente.
//--------------------------------------------------------------------
module controller(
    input wire clk,
    input wire reset,
    input wire [31:0] Instr,
    input wire [3:0] ALUFlags,
    
    output wire PCWrite,
    output wire MemWrite,
    output wire RegWrite,
    output wire IRWrite,
    output wire AdrSrc,
    output wire [1:0] RegSrc,
    output wire [1:0] ALUSrcA,
    output wire [1:0] ALUSrcB,
    output wire [1:0] ResultSrc,
    output wire [1:0] ImmSrc,
    output wire [3:0] ALUControl,
    output wire PCS,
    output wire NextPC,
    output wire Branch,
    output wire WAsel,
    output wire ResultWEn,
    output wire AandBWrite,
    output wire RA2Sel,
    output wire [1:0] FPUOp
);
    wire [1:0] FlagW;
    wire NextPC_int;
    wire RegW_fsm;
    wire MemW_fsm;
    wire Branch_int;
    wire ALUOp_fsm;

    decode dec(
        .clk(clk), .reset(reset), .Instr(Instr),
        .FlagW(FlagW), .PCS(PCS), .NextPC(NextPC_int), .RegW(RegW_fsm), .MemW(MemW_fsm),
        .IRWrite(IRWrite), .AdrSrc(AdrSrc), .ResultSrc(ResultSrc), .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB), .ImmSrc(ImmSrc), .RegSrc(RegSrc), .ALUControl(ALUControl),
        .WAsel(WAsel), .ResultWEn(ResultWEn), .AandBWrite(AandBWrite), .RA2Sel(RA2Sel),
        .FPUOp(FPUOp),
        .Branch(Branch_int)
    );

    condlogic cl(
        .clk(clk), .reset(reset), .Cond(Instr[31:28]), .ALUFlags(ALUFlags), .FlagW(FlagW),
        .PCS(PCS), .NextPC(NextPC_int), .RegW(RegW_fsm), .MemW(MemW_fsm),
        .PCWrite(PCWrite), .RegWrite(RegWrite), .MemWrite(MemWrite)
    );

    assign NextPC = NextPC_int;
    assign Branch = Branch_int;
endmodule


//--------------------------------------------------------------------
// Grupo 9: datapath (con fixes en pcreg y Result_to_RegFile)
//--------------------------------------------------------------------
module datapath(
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input  wire [31:0] ReadData,
    output wire [31:0] Instr,
    output wire [3:0]  ALUFlags,

    input  wire        PCWrite,
    input  wire        NextPC,
    input  wire        Branch,
    input  wire        RegWrite,
    input  wire        IRWrite,
    input  wire        AdrSrc,
    input  wire [1:0]  RegSrc,
    input  wire [1:0]  ALUSrcA,
    input  wire [1:0]  ALUSrcB,
    input  wire [1:0]  ResultSrc,
    input  wire [1:0]  ImmSrc,
    input  wire [3:0]  ALUControl,
    input  wire        PCS,
    input  wire        WAsel,
    input  wire        ResultWEn,
    input  wire        AandBWrite,
    input  wire        RA2Sel,
    input  wire [1:0]  FPUOp
);
    wire [31:0] PCNext, PC, ExtImm, SrcA, SrcB, PCPlus4;
    wire [31:0] Data, RD1, RD2, A_reg, B_reg;
    wire [31:0] ALUResult;
    wire [63:0] ALUResult64;
    wire [31:0] Result_Hi_Out, Result_Lo_Out;
    wire [31:0] FP_Result;
    reg  [31:0] Result_to_RegFile;   // ← ahora reg

    wire [3:0] RA1;
    wire [3:0] RA2;
    wire [3:0] WA3;

    wire [31:0] ALUOut;

    // pcreg usa flopenr (con enable PCWrite)
    flopenr #(32) pcreg(
        .clk   (clk),
        .reset (reset),
        .en    (PCWrite),
        .d     (PCNext),
        .q     (PC)
    );

    mux2 #(32) adrmux(PC, ALUResult, AdrSrc, Adr);
    flopenr #(32) ir(clk, reset, IRWrite, ReadData, Instr);
    flopenr #(32) datareg(clk, reset, 1'b1, ReadData, Data);

    adder #(32) pcplus4_adder(PC, 32'd4, PCPlus4);

    wire [31:0] PCBranch;
    adder #(32) pcbranch_adder(PCPlus4, ExtImm, PCBranch);

    wire [1:0] PCSel;
    assign PCSel = Branch ? 2'b01 :
                    PCS   ? 2'b10 :
                             2'b00;

    mux3 #(32) pcmux(PCPlus4, PCBranch, ALUResult, PCSel, PCNext);

    mux2 #(4) wa3_mux(Instr[15:12], Instr[19:16], WAsel, WA3);
    
    mux2 #(4) ra2mux(Instr[3:0], Instr[15:12], RA2Sel, RA2); 

    wire [3:0] Rs_reg = Instr[11:8];
    assign RA1 = (RegSrc[0]) ? 4'b1111 :
                 (ALUControl == 4'b0100 || ALUControl == 4'b0101) ? Rs_reg :
                 (ALUControl == 4'b0000 || ALUControl == 4'b0001) ? Instr[3:0] :
                 Instr[19:16];

    regfile rf(
        .clk(clk), .we3(RegWrite), .ra1(RA1), .ra2(RA2), .wa3(WA3), .wd3(Result_to_RegFile), 
        .r15(PCPlus4),
        .rd1(RD1), .rd2(RD2)
    );
    
    flopenr #(32) areg(clk, reset, AandBWrite, RD1, A_reg);
    flopenr #(32) breg(clk, reset, AandBWrite, RD2, B_reg);

    extend_rotational extend_unit(
        .Instr(Instr),
        .ImmSrc(ImmSrc), 
        .ExtImm(ExtImm)
    );
    
    assign SrcA = ALUSrcA[0] ? PC : A_reg;

    mux3 #(32) srcBmux(B_reg, ExtImm, 32'd4, ALUSrcB, SrcB);

    alu alu_unit(
        .a(SrcA), 
        .b(SrcB), 
        .ALUControl(ALUControl), 
        .Result(ALUResult), 
        .ALUResult64(ALUResult64), 
        .ALUFlags(ALUFlags)
    );

    fpu fpu_unit(
        .fp_a(A_reg),
        .fp_b(B_reg),
        .fp_control(FPUOp),
        .fp_result(FP_Result)
    );

    wire [31:0] alu_fp_mux_input;
    assign alu_fp_mux_input = (FPUOp == 2'b00 || FPUOp == 2'b01) ? FP_Result : ALUResult;

    flopenr #(32) aluoutreg_inst(clk, reset, ResultWEn, alu_fp_mux_input, ALUOut);

    flopenr #(32) Result_Lo_Reg(clk, reset, ResultWEn, ALUResult64[31:0], Result_Lo_Out);
    flopenr #(32) Result_Hi_Reg(clk, reset, ResultWEn, ALUResult64[63:32], Result_Hi_Out);

    always @(*) begin
        case (ResultSrc)
            2'b00: Result_to_RegFile = ALUOut;
            2'b01: Result_to_RegFile = Data;
            2'b10: Result_to_RegFile = Result_Lo_Out;
            2'b11: Result_to_RegFile = Result_Hi_Out;
            default: Result_to_RegFile = 32'hxxxxxxxx;
        endcase
    end

    assign WriteData = B_reg;

endmodule


//--------------------------------------------------------------------
// Grupo 10: Ensamblaje del Procesador (The CPU Unit)
//--------------------------------------------------------------------
// Propósito: Este módulo de nivel intermedio conecta la unidad de control
// ('controller') con la ruta de datos ('datapath') y la memoria ('mem'),
// formando el procesador completo.
// Impacto y Conexiones: Es el módulo principal del procesador.
// - Instancia el 'controller' (Grupo 8) y el 'datapath' (Grupo 9).
// - Conecta todas las señales de control y datos entre ellos.
// - Proporciona las interfaces externas de memoria.
//--------------------------------------------------------------------
module arm(
    input wire clk,
    input wire reset,
    output wire MemWrite,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input wire [31:0] ReadData
);
    wire [31:0] Instr;
    wire [3:0] ALUFlags;
    
    wire PCWrite, RegWrite, IRWrite, AdrSrc, PCS;
    wire NextPC, Branch;
    wire [1:0] RegSrc, ALUSrcA, ALUSrcB, ImmSrc, ResultSrc;
    wire [3:0] ALUControl;
    wire WAsel, ResultWEn, AandBWrite, RA2Sel;
    wire [1:0] FPUOp;

    controller c(
        .clk(clk), .reset(reset), .Instr(Instr),
        .ALUFlags(ALUFlags),
        .PCWrite(PCWrite), .MemWrite(MemWrite), .RegWrite(RegWrite), .IRWrite(IRWrite),
        .AdrSrc(AdrSrc), .RegSrc(RegSrc), .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB),
        .ResultSrc(ResultSrc), .ImmSrc(ImmSrc), .ALUControl(ALUControl), .PCS(PCS),
        .NextPC(NextPC), .Branch(Branch),
        .WAsel(WAsel), .ResultWEn(ResultWEn), .AandBWrite(AandBWrite), .RA2Sel(RA2Sel),
        .FPUOp(FPUOp)
    );

    datapath dp(
        .clk(clk), .reset(reset), .Adr(Adr), .WriteData(WriteData), .ReadData(ReadData),
        .Instr(Instr), .ALUFlags(ALUFlags), .PCWrite(PCWrite), .NextPC(NextPC), .Branch(Branch), .RegWrite(RegWrite),
        .IRWrite(IRWrite), .AdrSrc(AdrSrc), .RegSrc(RegSrc), .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB), .ResultSrc(ResultSrc), .ImmSrc(ImmSrc), .ALUControl(ALUControl),
        .PCS(PCS), .WAsel(WAsel), .ResultWEn(ResultWEn), .AandBWrite(AandBWrite), .RA2Sel(RA2Sel),
        .FPUOp(FPUOp)
    );
endmodule


//--------------------------------------------------------------------
// Grupo 11: Nivel Superior del Sistema (The Complete System)
//--------------------------------------------------------------------
// Propósito: Este es el módulo más alto en la jerarquía, instanciando
// el procesador completo ('arm') y conectándolo a componentes externos,
// como la memoria ('mem'). Es el punto de entrada para la simulación.
// Impacto y Conexiones: Este módulo es el ensamblador final del sistema.
// Instancia el procesador ARM ('arm', Grupo 10) y la memoria ('mem', Grupo 2).
// Sus conexiones son directas y reflejan la interfaz externa del procesador.
//--------------------------------------------------------------------
module top(
    input wire clk,
    input wire reset,
    output wire [31:0] WriteData,
    output wire [31:0] Adr,
    output wire MemWrite
);
    wire [31:0] ReadData;

    arm arm_inst(
        .clk(clk),
        .reset(reset),
        .MemWrite(MemWrite),
        .Adr(Adr),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

    mem mem_inst(
        .clk(clk),
        .we(MemWrite),
        .a(Adr),
        .wd(WriteData),
        .rd(ReadData)
    );
endmodule
