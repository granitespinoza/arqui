module alu(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] ALUControl,
    output reg [31:0] Result,
    output reg [63:0] ALUResult64,
    output reg [3:0] ALUFlags
);
    wire [32:0] sum = {1'b0, a} + {1'b0, b}; 
    wire [32:0] sub = {1'b0, a} - {1'b0, b};

    wire [63:0] mul_unsigned = {32'b0, a} * {32'b0, b};
    wire [63:0] mul_signed   = $signed(a) * $signed(b);

    always @(*) begin
        case (ALUControl)
            4'b0000: begin
                Result = sum[31:0];
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0001: begin
                Result = sub[31:0];
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0010: begin
                Result = a & b;
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0011: begin
                Result = a | b;
                ALUResult64 = { {32{1'b0}}, Result };
            end
            4'b0100: begin
                Result = mul_unsigned[31:0];
                ALUResult64 = mul_unsigned;
            end
            4'b0101: begin
                Result = mul_signed[31:0];
                ALUResult64 = mul_signed;
            end
            default: begin
                Result = 32'hxxxxxxxx;
                ALUResult64 = 64'hxxxxxxxxxxxxxxxx;
            end
        endcase
    end
    
    always @(*) begin
        case (ALUControl)
            4'b0000, 4'b0001: begin
                ALUFlags[3] = Result[31];
                ALUFlags[2] = (Result == 32'h0);
                ALUFlags[1] = (ALUControl == 4'b0000) ? sum[32] : ~sub[32];
                ALUFlags[0] = (ALUControl == 4'b0000) ? (a[31] == b[31] && Result[31] != a[31]) :
                                                        (a[31] != b[31] && Result[31] != a[31]);
            end
            4'b0010, 4'b0011: begin
                ALUFlags[3] = Result[31];
                ALUFlags[2] = (Result == 32'h0);
                ALUFlags[1] = 1'b0;
                ALUFlags[0] = 1'b0;
            end
            4'b0100, 4'b0101: begin
                ALUFlags[3] = ALUResult64[63];
                ALUFlags[2] = (ALUResult64 == 64'h0);
                ALUFlags[1] = 1'b0;
                ALUFlags[0] = 1'b0;
            end
            default: begin
                ALUFlags = 4'bxxxx;
            end
        endcase
    end
endmodule
