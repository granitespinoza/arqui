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
    output wire WAsel,
    output wire ResultWEn,
    output wire AandBWrite,
    output wire RA2Sel,
    output wire [1:0] FPUOp
);
    wire [1:0] Op    = Instr[27:26];
    wire [5:0] Funct = Instr[25:20];
    wire [3:0] Rd    = Instr[15:12];

    wire Branch;
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
