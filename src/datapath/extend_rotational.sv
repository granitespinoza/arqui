module extend_rotational(
    input wire [31:0] Instr,
    input wire [1:0] ImmSrc,
    output reg [31:0] ExtImm
);
    wire [7:0]  imm8        = Instr[7:0];
    wire [4:0]  rot_amount  = {1'b0, Instr[11:8]} << 1;  // 0-30 in steps of 2
    wire [31:0] imm32       = {24'b0, imm8};
    wire [31:0] rotated_imm_val;

    assign rotated_imm_val = (imm32 >> rot_amount) |
                             (imm32 << (32 - rot_amount));

    always @(*)
    case (ImmSrc)
        2'b00: ExtImm = rotated_imm_val;
        2'b01: ExtImm = {{20{1'b0}}, Instr[11:0]};
        2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00};
        default: ExtImm = 32'hxxxxxxxx;
    endcase
endmodule
