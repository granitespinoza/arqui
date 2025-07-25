//----------------------------------------------------------------------
// adder.sv : Simple adder used for PC and address calculations
//----------------------------------------------------------------------
module adder #(parameter WIDTH = 32)(
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);
    assign y = a + b;
endmodule
