//----------------------------------------------------------------------
// controller.sv : Connects decode, condlogic and FSM
//----------------------------------------------------------------------
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
