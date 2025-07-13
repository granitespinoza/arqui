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
