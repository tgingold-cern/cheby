
module test
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [4:2] awaddr,
    input   wire [2:0] awprot,
    input   wire wvalid,
    output  wire wready,
    input   wire [31:0] wdata,
    input   wire [3:0] wstrb,
    output  wire bvalid,
    input   wire bready,
    output  wire [1:0] bresp,
    input   wire arvalid,
    output  wire arready,
    input   wire [4:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // Test register 1
    output  wire [31:0] register1_o,

    // Test register 2
    // Test field 1
    input   wire block1_register2_field1_i,
    // Test field 2
    input   wire [2:0] block1_register2_field2_i,

    // Test register 3
    output  wire [31:0] block1_register3_o,

    // Test register 4
    // Test field 3
    input   wire block1_block2_register4_field3_i,
    // Test field 4
    input   wire [2:0] block1_block2_register4_field4_i
  );
  reg wr_req;
  reg wr_ack;
  reg [4:2] wr_addr;
  reg [31:0] wr_data;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [4:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg [31:0] register1_reg;
  reg register1_wreq;
  reg register1_wack;
  reg [31:0] block1_register3_reg;
  reg block1_register3_wreq;
  reg block1_register3_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [4:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // AW, W and B channels
  assign awready = !axi_awset;
  assign wready = !axi_wset;
  assign bvalid = axi_wdone;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        wr_req <= 1'b0;
        axi_awset <= 1'b0;
        axi_wset <= 1'b0;
        axi_wdone <= 1'b0;
      end
    else
      begin
        wr_req <= 1'b0;
        if (awvalid == 1'b1 & axi_awset == 1'b0)
          begin
            wr_addr <= awaddr;
            axi_awset <= 1'b1;
            wr_req <= axi_wset;
          end
        if (wvalid == 1'b1 & axi_wset == 1'b0)
          begin
            wr_data <= wdata;
            axi_wset <= 1'b1;
            wr_req <= axi_awset | awvalid;
          end
        if ((axi_wdone & bready) == 1'b1)
          begin
            axi_wset <= 1'b0;
            axi_awset <= 1'b0;
            axi_wdone <= 1'b0;
          end
        if (wr_ack == 1'b1)
          axi_wdone <= 1'b1;
      end
  end
  assign bresp = 2'b00;

  // AR and R channels
  assign arready = !axi_arset;
  assign rvalid = axi_rdone;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        axi_rdone <= 1'b0;
        rdata <= 3'b0;
      end
    else
      begin
        rd_req <= 1'b0;
        if (arvalid == 1'b1 & axi_arset == 1'b0)
          begin
            rd_addr <= araddr;
            axi_arset <= 1'b1;
            rd_req <= 1'b1;
          end
        if ((axi_rdone & rready) == 1'b1)
          begin
            axi_arset <= 1'b0;
            axi_rdone <= 1'b0;
          end
        if (rd_ack == 1'b1)
          begin
            axi_rdone <= 1'b1;
            rdata <= rd_data;
          end
      end
  end
  assign rresp = 2'b00;

  // pipelining for wr-in+rd-out
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        rd_ack <= 1'b0;
        wr_req_d0 <= 1'b0;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end
  end

  // Register register1
  assign register1_o = register1_reg;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        register1_reg <= 32'b00000000000000000000000000000000;
        register1_wack <= 1'b0;
      end
    else
      begin
        if (register1_wreq == 1'b1)
          register1_reg <= wr_dat_d0;
        register1_wack <= register1_wreq;
      end
  end

  // Register block1_register2

  // Register block1_register3
  assign block1_register3_o = block1_register3_reg;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        block1_register3_reg <= 32'b00000000000000000000000000000000;
        block1_register3_wack <= 1'b0;
      end
    else
      begin
        if (block1_register3_wreq == 1'b1)
          block1_register3_reg <= wr_dat_d0;
        block1_register3_wack <= block1_register3_wreq;
      end
  end

  // Register block1_block2_register4

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, register1_wack, block1_register3_wack)
      begin
        register1_wreq <= 1'b0;
        block1_register3_wreq <= 1'b0;
        case (wr_adr_d0[4:2])
        3'b000:
          begin
            // Reg register1
            register1_wreq <= wr_req_d0;
            wr_ack <= register1_wack;
          end
        3'b100:
          // Reg block1_register2
          wr_ack <= wr_req_d0;
        3'b101:
          begin
            // Reg block1_register3
            block1_register3_wreq <= wr_req_d0;
            wr_ack <= block1_register3_wack;
          end
        3'b110:
          // Reg block1_block2_register4
          wr_ack <= wr_req_d0;
        default:
          wr_ack <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(rd_addr, rd_req, block1_register2_field1_i, block1_register2_field2_i, block1_register3_reg, block1_block2_register4_field3_i, block1_block2_register4_field4_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        case (rd_addr[4:2])
        3'b000:
          // Reg register1
          rd_ack_d0 <= rd_req;
        3'b100:
          begin
            // Reg block1_register2
            rd_ack_d0 <= rd_req;
            rd_dat_d0[0] <= block1_register2_field1_i;
            rd_dat_d0[3:1] <= block1_register2_field2_i;
            rd_dat_d0[31:4] <= 28'b0;
          end
        3'b101:
          begin
            // Reg block1_register3
            rd_ack_d0 <= rd_req;
            rd_dat_d0 <= block1_register3_reg;
          end
        3'b110:
          begin
            // Reg block1_block2_register4
            rd_ack_d0 <= rd_req;
            rd_dat_d0[0] <= block1_block2_register4_field3_i;
            rd_dat_d0[3:1] <= block1_block2_register4_field4_i;
            rd_dat_d0[31:4] <= 28'b0;
          end
        default:
          rd_ack_d0 <= rd_req;
        endcase
      end
endmodule
