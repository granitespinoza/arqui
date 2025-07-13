module datapath(
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] Adr,
    output wire [31:0] WriteData,
    input  wire [31:0] ReadData,
    output wire [31:0] Instr,
    output wire [3:0]  ALUFlags,

    input  wire        PCWrite,
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
