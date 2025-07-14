module arm_tb;
  reg clk = 0;
  reg reset;
  wire [31:0] WriteData;
  wire [31:0] Adr;
  wire MemWrite;

  // Instantiate top-level design
  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .Adr(Adr),
    .MemWrite(MemWrite)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reset pulse
  initial begin
    reset = 1;
    #22;
    reset = 0;
  end

  // Track number of cycles and stop after a timeout
  integer cycle_count = 0;
  always @(posedge clk) begin
    cycle_count <= cycle_count + 1;
    $display("cycle %0d PC=%h", cycle_count, dut.arm_inst.dp.PC);
    if (cycle_count > 400) begin
      $display("Simulation result: R10 = 0x%08h", dut.arm_inst.dp.rf.rf[10]);
      if (dut.arm_inst.dp.rf.rf[10] == 32'd1) begin
        $display("Simulation succeeded");
      end else begin
        $display("Simulation failed");
      end
      dut.arm_inst.dp.rf.dump();
      $finish;
    end
  end
endmodule
