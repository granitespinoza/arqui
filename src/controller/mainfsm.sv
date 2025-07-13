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
