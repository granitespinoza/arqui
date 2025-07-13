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
