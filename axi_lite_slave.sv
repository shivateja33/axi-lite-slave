

module axi_lite_slave #(
    
    parameter ADDR_WIDTH = 32,    
    parameter DATA_WIDTH = 32    
)(

    input  logic 	clk,
    input  logic    resetn,


    input  logic [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  logic    s_axi_awvalid,
    output logic    s_axi_awready,


    input  logic [DATA_WIDTH-1:0]    s_axi_wdata,
    input logic [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic    s_axi_wvalid,
    output logic    s_axi_wready,

  
  	output logic [1:0] s_axi_bresp,   
    output logic 	s_axi_bvalid,
    input  logic 	s_axi_bready,


    input  logic [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  logic    s_axi_arvalid,
    output logic    s_axi_arready,


    output logic [DATA_WIDTH-1:0]  s_axi_rdata,
    output logic [1:0]  s_axi_rresp,  
    output logic    s_axi_rvalid,
    input  logic    s_axi_rready
);

    logic [DATA_WIDTH-1:0] reg0, reg1, reg2; 

    logic [ADDR_WIDTH-1:0] awaddr_latched;
    logic aw_valid_seen, w_valid_seen;
    logic aw_handshake,  w_handshake;


  
  assign aw_handshake = (s_axi_awvalid && s_axi_awready);
  assign w_handshake  = s_axi_wvalid  && s_axi_wready;
  
  // Write Address Ready Logic
  
  always_ff @(posedge clk or negedge resetn) begin   
    if(!resetn)
      s_axi_awready <=0;
    else if(!aw_handshake && !aw_valid_seen)
      s_axi_awready <=1;
    else if(aw_handshake)
      s_axi_awready <=0;
  end
  
  // Track AW/W arrival & latch address
  always_ff @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      awaddr_latched<=0;
      aw_valid_seen <= 0;
      w_valid_seen <= 0;
            
      

    end 
    else begin 
      if(aw_handshake) begin
        aw_valid_seen <=1;
        awaddr_latched <= s_axi_awaddr;
      end
      if(w_handshake) begin
        w_valid_seen <=1;
      end
    end 
    
    // Clear flags when both arrived and write done
   // Here aw_valid_seen and W_valid seen are just telling we have got both address and data but the write is not finished yet. b_valid is only 1 when the write gets finsished. so until the write gets finsihed we cant wait for bvalid to 1 so we set the awvalid and wvalid seen flags to zero so that we can capture other aw and w values for the next cycle. and b_valid however becomes active when the write is done 
    
    if (s_axi_bvalid && s_axi_bready) begin
        aw_valid_seen <= 0;
        w_valid_seen  <= 0;
    end
    
  end
  
   // -----------------------------------------
    // Register Write Logic
  // ------------------------------------------
  
    
  always_ff @(posedge clk or negedge resetn) begin
    if(!resetn) begin
       s_axi_wready <= 0;
       reg0 <= 0;
       reg1 <= 0;
       reg2 <= 0;
    end 
    else if (!w_handshake && !w_valid_seen)
    s_axi_wready <= 1;
	else if (w_handshake)
    s_axi_wready <= 0;
    
  	if(aw_valid_seen && w_valid_seen && !s_axi_bvalid) begin
      unique case (awaddr_latched [4:2])
        3'b000: begin
          if (s_axi_wstrb[0]) reg0[7:0] <= s_axi_wdata[7:0];
          if (s_axi_wstrb[1]) reg0[15:8]  <= s_axi_wdata[15:8];
          if (s_axi_wstrb[2]) reg0[23:16] <= s_axi_wdata[23:16];
          if (s_axi_wstrb[3]) reg0[31:24] <= s_axi_wdata[31:24];
        end
        3'b001: begin
          if (s_axi_wstrb[0]) reg1[7:0] <= s_axi_wdata[7:0];
          if (s_axi_wstrb[1]) reg1[15:8]  <= s_axi_wdata[15:8];
          if (s_axi_wstrb[2]) reg1[23:16] <= s_axi_wdata[23:16];
          if (s_axi_wstrb[3]) reg1[31:24] <= s_axi_wdata[31:24];
        end
        3'b010: begin
          if (s_axi_wstrb[0]) reg2[7:0] <= s_axi_wdata[7:0];
          if (s_axi_wstrb[1]) reg2[15:8]  <= s_axi_wdata[15:8];
          if (s_axi_wstrb[2]) reg2[23:16] <= s_axi_wdata[23:16];
          if (s_axi_wstrb[3]) reg2[31:24] <= s_axi_wdata[31:24];
        end          
  
        default : ;
      endcase
    end
  end
  
  
    // ----------------------------------------
  // Write Response Channel
  // ----------------------------------------
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      s_axi_bvalid <= 0;
      s_axi_bresp  <= 2'b00;
    end else begin
      if (aw_valid_seen && w_valid_seen && !s_axi_bvalid) begin
        s_axi_bvalid <= 1;
        s_axi_bresp  <= 2'b00; // OKAY
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 0;
      end
    end
  end
  
    // ----------------------------------------
  // Read-address handshake + latch
  // ----------------------------------------
  logic [ADDR_WIDTH-1:0]  araddr_latched;
  logic                   ar_valid_seen;
  logic                   ar_handshake, r_handshake;

  assign ar_handshake = s_axi_arvalid & s_axi_arready;   // master-to-slave
  assign r_handshake  = s_axi_rvalid  & s_axi_rready;    // slave-to-master

  // ARREADY – hold high until handshake happens
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn)
      s_axi_arready <= 0;
    else if (!ar_handshake && !ar_valid_seen)
      s_axi_arready <= 1;
    else if (ar_handshake)
      s_axi_arready <= 0;
  end

  // Track AR arrival and latch address
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      araddr_latched <= '0;
      ar_valid_seen  <= 0;
    end else if (ar_handshake) begin
      ar_valid_seen  <= 1;
      araddr_latched <= s_axi_araddr;
    end else if (r_handshake) begin
      ar_valid_seen  <= 0;      // clear after data accepted
    end
  end

  // ----------------------------------------
  // Read-data/response channel
  // ----------------------------------------
  always_ff @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      s_axi_rvalid <= 0;
      s_axi_rdata  <= '0;
      s_axi_rresp  <= 2'b00;
    end else begin
      // Launch data as soon as we have a latched AR
      if (ar_valid_seen && !s_axi_rvalid) begin
        unique case (araddr_latched[4:2])
          3'b000: s_axi_rdata <= reg0;
          3'b001: s_axi_rdata <= reg1;
          3'b010: s_axi_rdata <= reg2;
          default: s_axi_rdata <= 32'hDEAD_BEEF;
        endcase
        s_axi_rresp <= 2'b00;   // OKAY
        s_axi_rvalid <= 1;
      end
      // Drop RVALID after master accepts
      else if (r_handshake) begin
        s_axi_rvalid <= 0;
      end
    end
  end
 
endmodule
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
