
module xilinx_attrs
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [2:2] awaddr,
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
    input   wire [2:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // AXI-4 lite bus subm
    output  wire subm_awvalid_o,
    input   wire subm_awready_i,
    output  wire [2:2] subm_awaddr_o,
    output  wire [2:0] subm_awprot_o,
    output  wire subm_wvalid_o,
    input   wire subm_wready_i,
    output  wire [31:0] subm_wdata_o,
    output  reg [3:0] subm_wstrb_o,
    input   wire subm_bvalid_i,
    output  wire subm_bready_o,
    input   wire [1:0] subm_bresp_i,
    output  wire subm_arvalid_o,
    input   wire subm_arready_i,
    output  wire [2:2] subm_araddr_o,
    output  wire [2:0] subm_arprot_o,
    input   wire subm_rvalid_i,
    output  wire subm_rready_o,
    input   wire [31:0] subm_rdata_i,
    input   wire [1:0] subm_rresp_i
  );
  reg wr_req;
  reg wr_ack;
  reg [2:2] wr_addr;
  reg [31:0] wr_data;
  reg [31:0] wr_sel;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [2:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg subm_aw_val;
  reg subm_w_val;
  reg subm_ar_val;
  reg subm_rd;
  reg subm_wr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;

  // AW, W and B channels
  assign awready = ~axi_awset;
  assign wready = ~axi_wset;
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
            wr_sel[7:0] <= {8{wstrb[0]}};
            wr_sel[15:8] <= {8{wstrb[1]}};
            wr_sel[23:16] <= {8{wstrb[2]}};
            wr_sel[31:24] <= {8{wstrb[3]}};
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
  assign arready = ~axi_arset;
  assign rvalid = axi_rdone;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        axi_rdone <= 1'b0;
        rdata <= 32'b0;
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
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Interface subm
  assign subm_awvalid_o = subm_aw_val;
  assign subm_awaddr_o = wr_adr_d0[2:2];
  assign subm_awprot_o = 3'b000;
  assign subm_wvalid_o = subm_w_val;
  assign subm_wdata_o = wr_dat_d0;
  always @(wr_sel_d0)
      begin
        subm_wstrb_o <= 4'b0;
        if (~(wr_sel_d0[7:0] == 8'b0))
          subm_wstrb_o[0] <= 1'b1;
        if (~(wr_sel_d0[15:8] == 8'b0))
          subm_wstrb_o[1] <= 1'b1;
        if (~(wr_sel_d0[23:16] == 8'b0))
          subm_wstrb_o[2] <= 1'b1;
        if (~(wr_sel_d0[31:24] == 8'b0))
          subm_wstrb_o[3] <= 1'b1;
      end
  assign subm_bready_o = 1'b1;
  assign subm_arvalid_o = subm_ar_val;
  assign subm_araddr_o = rd_addr[2:2];
  assign subm_arprot_o = 3'b000;
  assign subm_rready_o = 1'b1;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        subm_aw_val <= 1'b0;
        subm_w_val <= 1'b0;
        subm_ar_val <= 1'b0;
      end
    else
      begin
        subm_aw_val <= subm_wr | (subm_aw_val & ~subm_awready_i);
        subm_w_val <= subm_wr | (subm_w_val & ~subm_wready_i);
        subm_ar_val <= subm_rd | (subm_ar_val & ~subm_arready_i);
      end
  end

  // Process for write requests.
  always @(wr_req_d0, subm_bvalid_i)
      begin
        subm_wr <= 1'b0;
        // Submap subm
        subm_wr <= wr_req_d0;
        wr_ack <= subm_bvalid_i;
      end

  // Process for read requests.
  always @(rd_req, subm_rdata_i, subm_rvalid_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        subm_rd <= 1'b0;
        // Submap subm
        subm_rd <= rd_req;
        rd_dat_d0 <= subm_rdata_i;
        rd_ack_d0 <= subm_rvalid_i;
      end
endmodule
