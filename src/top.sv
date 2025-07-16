//----------------------------------------------------------------------
// top.sv : Simulation entry point with memory
//----------------------------------------------------------------------
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
