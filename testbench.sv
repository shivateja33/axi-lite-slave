
`timescale 1ns/1ps

module tb_axi_lite_slave;

  // ------------------------------------------------------------
  // DUT parameters & local addr map
  // ------------------------------------------------------------
  localparam int ADDR_WIDTH = 32;
  localparam int DATA_WIDTH = 32;

  // 32-bit word offsets (aligned)  ───►  addr[4:2]
  localparam int REG0_ADDR = 32'h0000_0000;   // 3'b000
  localparam int REG1_ADDR = 32'h0000_0004;   // 3'b001
  localparam int REG2_ADDR = 32'h0000_0008;   // 3'b010

  // ------------------------------------------------------------
  // Clock / reset
  // ------------------------------------------------------------
  logic clk = 0;
  always #5 clk = ~clk;          // 100 MHz

  logic resetn;
  initial begin
    resetn = 0;
    repeat (3) @(posedge clk);
    resetn = 1;
  end

  // ------------------------------------------------------------
  // AXI-Lite signals
  // ------------------------------------------------------------
  logic [ADDR_WIDTH-1:0]  awaddr;
  logic                   awvalid;
  logic                   awready;

  logic [DATA_WIDTH-1:0]  wdata;
  logic [(DATA_WIDTH/8)-1:0] wstrb;
  logic                   wvalid;
  logic                   wready;

  logic [1:0]             bresp;
  logic                   bvalid;
  logic                   bready;

  logic [ADDR_WIDTH-1:0]  araddr;
  logic                   arvalid;
  logic                   arready;

  logic [DATA_WIDTH-1:0]  rdata;
  logic [1:0]             rresp;
  logic                   rvalid;
  logic                   rready;
	logic [31:0] rd_val;
  // ------------------------------------------------------------
  // DUT
  // ------------------------------------------------------------
  axi_lite_slave #(.ADDR_WIDTH(ADDR_WIDTH),
                   .DATA_WIDTH(DATA_WIDTH)) dut (
      .clk          (clk),
      .resetn       (resetn),

      .s_axi_awaddr (awaddr),
      .s_axi_awvalid(awvalid),
      .s_axi_awready(awready),

      .s_axi_wdata  (wdata),
      .s_axi_wstrb  (wstrb),
      .s_axi_wvalid (wvalid),
      .s_axi_wready (wready),

      .s_axi_bresp  (bresp),
      .s_axi_bvalid (bvalid),
      .s_axi_bready (bready),

      .s_axi_araddr (araddr),
      .s_axi_arvalid(arvalid),
      .s_axi_arready(arready),

      .s_axi_rdata  (rdata),
      .s_axi_rresp  (rresp),
      .s_axi_rvalid (rvalid),
      .s_axi_rready (rready)
  );

  // ------------------------------------------------------------
  // Simple AXI-Lite tasks
  // ------------------------------------------------------------
  task automatic axil_write (input logic [31:0] addr,
                             input logic [31:0] data);
    begin
      // default strobes = full-word
      awaddr  <= addr;
      awvalid <= 1;
      wdata   <= data;
      wstrb   <= '1;
      wvalid  <= 1;
      @(posedge clk);
      // wait until both handshakes happen
      while (!(awready && wready)) @(posedge clk);
      awvalid <= 0;
      wvalid  <= 0;

      // accept B-response
      bready  <= 1;
      while (!bvalid) @(posedge clk);
      @(posedge clk);
      bready  <= 0;
    end
  endtask


  task automatic axil_read (input  logic [31:0] addr,
                            output logic [31:0] data_out);
    begin
      araddr  <= addr;
      arvalid <= 1;
      @(posedge clk);
      while (!arready) @(posedge clk);
      arvalid <= 0;

      rready  <= 1;
      while (!rvalid) @(posedge clk);
      data_out = rdata;
      @(posedge clk);
      rready  <= 0;
    end
  endtask

  // ------------------------------------------------------------
  // Test sequence
  // ------------------------------------------------------------
  initial begin
    // initialise master side
    awaddr = 0;  awvalid = 0;
    wdata  = 0;  wstrb  = 0;  wvalid = 0;
    bready = 0;
    araddr = 0;  arvalid = 0;
    rready = 0;

    // wait for reset
    @(posedge resetn);

    // 1) WRITE 0xA5A55A5A to REG0
    $display("[%0t] WRITE 0xA5A55A5A -> REG0", $time);
    axil_write(REG0_ADDR, 32'hA5A55A5A);

    // 2) READ  REG0 back
    
    axil_read(REG0_ADDR, rd_val);
    $display("[%0t] READ  REG0 = 0x%08h", $time, rd_val);

    // 3) Simple pass/fail print
    if (rd_val === 32'hA5A55A5A)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    // finish
    #20 $finish;
  end

endmodule
