//----------------------------------------------------------------------
// arm.sv : Processor core combining controller and datapath
//----------------------------------------------------------------------
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
