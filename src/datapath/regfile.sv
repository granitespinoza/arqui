module regfile(
    input  wire        clk,
    input  wire        we3,
    input  wire [3:0]  ra1,
    input  wire [3:0]  ra2,
    input  wire [3:0]  wa3,
    input  wire [31:0] wd3,
    input  wire [31:0] r15,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    // Banco de registros R0–R15
    reg [31:0] rf [0:15];
    always @(posedge clk)
        if (we3) rf[wa3] <= wd3;
    assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
    assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];

    // ------------------------------------------------------------
    // Tarea dump: imprime valores de R0–R14 (para depuración)
    // ------------------------------------------------------------
    task dump;
        integer idx;
        begin
            $display("-------------------------------------------");
            $display("       ESTADO FINAL DE REGISTROS            ");
            for (idx = 0; idx < 15; idx = idx + 1)
                $display("R%0d = 0x%08h", idx, rf[idx]);
            $display("-------------------------------------------");
        end
    endtask
endmodule
