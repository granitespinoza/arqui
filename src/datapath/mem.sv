module mem #(parameter MEM_DEPTH = 1024) (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] a,
    input  wire [31:0] wd,
    output wire [31:0] rd
);
    reg [31:0] RAM [0:MEM_DEPTH-1];
    initial $readmemh("memfile.dat", RAM);
    assign rd = RAM[a[($clog2(MEM_DEPTH)+1):2]];
    always @(posedge clk)
        if (we) RAM[a[($clog2(MEM_DEPTH)+1):2]] <= wd;
endmodule
