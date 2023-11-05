
module sps200CavityControl_regs
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [20:2] awaddr,
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
    input   wire [20:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // AXI-4 lite bus hwInfo
    output  wire hwInfo_awvalid_o,
    input   wire hwInfo_awready_i,
    output  wire [4:0] hwInfo_awaddr_o,
    output  wire [2:0] hwInfo_awprot_o,
    output  wire hwInfo_wvalid_o,
    input   wire hwInfo_wready_i,
    output  wire [31:0] hwInfo_wdata_o,
    output  reg [3:0] hwInfo_wstrb_o,
    input   wire hwInfo_bvalid_i,
    output  wire hwInfo_bready_o,
    input   wire [1:0] hwInfo_bresp_i,
    output  wire hwInfo_arvalid_o,
    input   wire hwInfo_arready_i,
    output  wire [4:0] hwInfo_araddr_o,
    output  wire [2:0] hwInfo_arprot_o,
    input   wire hwInfo_rvalid_i,
    output  wire hwInfo_rready_o,
    input   wire [31:0] hwInfo_rdata_i,
    input   wire [1:0] hwInfo_rresp_i,

    // AXI-4 lite bus app
    output  wire app_awvalid_o,
    input   wire app_awready_i,
    output  wire [18:0] app_awaddr_o,
    output  wire [2:0] app_awprot_o,
    output  wire app_wvalid_o,
    input   wire app_wready_i,
    output  wire [31:0] app_wdata_o,
    output  reg [3:0] app_wstrb_o,
    input   wire app_bvalid_i,
    output  wire app_bready_o,
    input   wire [1:0] app_bresp_i,
    output  wire app_arvalid_o,
    input   wire app_arready_i,
    output  wire [18:0] app_araddr_o,
    output  wire [2:0] app_arprot_o,
    input   wire app_rvalid_i,
    output  wire app_rready_o,
    input   wire [31:0] app_rdata_i,
    input   wire [1:0] app_rresp_i
  );
  reg wr_req;
  reg wr_ack;
  reg [20:2] wr_addr;
  reg [31:0] wr_data;
  reg [31:0] wr_sel;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [20:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg hwInfo_aw_val;
  reg hwInfo_w_val;
  reg hwInfo_ar_val;
  reg hwInfo_rd;
  reg hwInfo_wr;
  reg app_aw_val;
  reg app_w_val;
  reg app_ar_val;
  reg app_rd;
  reg app_wr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [20:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;

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
  assign arready = !axi_arset;
  assign rvalid = axi_rdone;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        axi_rdone <= 1'b0;
        rdata <= 19'b0;
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
        wr_sel_d0 <= wr_sel;
      end
  end

  // Interface hwInfo
  assign hwInfo_awvalid_o = hwInfo_aw_val;
  assign hwInfo_awaddr_o = {wr_adr_d0[4:2], 2'b00};
  assign hwInfo_awprot_o = 3'b000;
  assign hwInfo_wvalid_o = hwInfo_w_val;
  assign hwInfo_wdata_o = wr_dat_d0;
  always @(wr_sel_d0)
      begin
        hwInfo_wstrb_o <= 4'b0;
        if (!(wr_sel_d0[7:0] == 8'b0))
          hwInfo_wstrb_o[0] <= 1'b1;
        if (!(wr_sel_d0[15:8] == 8'b0))
          hwInfo_wstrb_o[1] <= 1'b1;
        if (!(wr_sel_d0[23:16] == 8'b0))
          hwInfo_wstrb_o[2] <= 1'b1;
        if (!(wr_sel_d0[31:24] == 8'b0))
          hwInfo_wstrb_o[3] <= 1'b1;
      end
  assign hwInfo_bready_o = 1'b1;
  assign hwInfo_arvalid_o = hwInfo_ar_val;
  assign hwInfo_araddr_o = {rd_addr[4:2], 2'b00};
  assign hwInfo_arprot_o = 3'b000;
  assign hwInfo_rready_o = 1'b1;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        hwInfo_aw_val <= 1'b0;
        hwInfo_w_val <= 1'b0;
        hwInfo_ar_val <= 1'b0;
      end
    else
      begin
        hwInfo_aw_val <= hwInfo_wr | (hwInfo_aw_val & !hwInfo_awready_i);
        hwInfo_w_val <= hwInfo_wr | (hwInfo_w_val & !hwInfo_wready_i);
        hwInfo_ar_val <= hwInfo_rd | (hwInfo_ar_val & !hwInfo_arready_i);
      end
  end

  // Interface app
  assign app_awvalid_o = app_aw_val;
  assign app_awaddr_o = {wr_adr_d0[18:2], 2'b00};
  assign app_awprot_o = 3'b000;
  assign app_wvalid_o = app_w_val;
  assign app_wdata_o = wr_dat_d0;
  always @(wr_sel_d0)
      begin
        app_wstrb_o <= 4'b0;
        if (!(wr_sel_d0[7:0] == 8'b0))
          app_wstrb_o[0] <= 1'b1;
        if (!(wr_sel_d0[15:8] == 8'b0))
          app_wstrb_o[1] <= 1'b1;
        if (!(wr_sel_d0[23:16] == 8'b0))
          app_wstrb_o[2] <= 1'b1;
        if (!(wr_sel_d0[31:24] == 8'b0))
          app_wstrb_o[3] <= 1'b1;
      end
  assign app_bready_o = 1'b1;
  assign app_arvalid_o = app_ar_val;
  assign app_araddr_o = {rd_addr[18:2], 2'b00};
  assign app_arprot_o = 3'b000;
  assign app_rready_o = 1'b1;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        app_aw_val <= 1'b0;
        app_w_val <= 1'b0;
        app_ar_val <= 1'b0;
      end
    else
      begin
        app_aw_val <= app_wr | (app_aw_val & !app_awready_i);
        app_w_val <= app_wr | (app_w_val & !app_wready_i);
        app_ar_val <= app_rd | (app_ar_val & !app_arready_i);
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, hwInfo_bvalid_i, app_bvalid_i)
      begin
        hwInfo_wr <= 1'b0;
        app_wr <= 1'b0;
        case (wr_adr_d0[20:19])
        2'b00:
          begin
            // Submap hwInfo
            hwInfo_wr <= wr_req_d0;
            wr_ack <= hwInfo_bvalid_i;
          end
        2'b10:
          begin
            // Submap app
            app_wr <= wr_req_d0;
            wr_ack <= app_bvalid_i;
          end
        default:
          wr_ack <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(rd_addr, rd_req, hwInfo_rdata_i, hwInfo_rvalid_i, app_rdata_i, app_rvalid_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        hwInfo_rd <= 1'b0;
        app_rd <= 1'b0;
        case (rd_addr[20:19])
        2'b00:
          begin
            // Submap hwInfo
            hwInfo_rd <= rd_req;
            rd_dat_d0 <= hwInfo_rdata_i;
            rd_ack_d0 <= hwInfo_rvalid_i;
          end
        2'b10:
          begin
            // Submap app
            app_rd <= rd_req;
            rd_dat_d0 <= app_rdata_i;
            rd_ack_d0 <= app_rvalid_i;
          end
        default:
          rd_ack_d0 <= rd_req;
        endcase
      end
endmodule
