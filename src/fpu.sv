//----------------------------------------------------------------------
// fpu.sv : Minimal floating point unit for add and mul
//----------------------------------------------------------------------
module fpu (
    input wire [31:0] fp_a,
    input wire [31:0] fp_b,
    input wire [1:0]  fp_control,
    output reg [31:0] fp_result
);

    real real_a;
    real real_b;
    real real_result;

    always @(*) begin
        real_a = $bitstoreal({32'b0, fp_a});
        real_b = $bitstoreal({32'b0, fp_b});

        case (fp_control)
            2'b00: begin
                real_result = real_a + real_b;
            end
            2'b01: begin
                real_result = real_a * real_b;
            end
            default: begin
                real_result = 0.0;
                fp_result = 32'hFFFF_FFFF;
            end
        endcase
        
        if (fp_control == 2'b00 || fp_control == 2'b01) begin
            fp_result = $realtobits(real_result);
        end
    end

endmodule
