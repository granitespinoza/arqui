//----------------------------------------------------------------------
// flopr.sv : Flip-flop with reset
//----------------------------------------------------------------------
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
