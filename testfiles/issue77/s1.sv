
module s1
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
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
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // WB bus sub
    output  wire sub_cyc_o,
    output  wire sub_stb_o,
    output  reg [3:0] sub_sel_o,
    output  wire sub_we_o,
    output  wire [31:0] sub_dat_o,
    input   wire sub_ack_i,
    input   wire sub_err_i,
    input   wire sub_rty_i,
    input   wire sub_stall_i,
    input   wire [31:0] sub_dat_i
  );
  reg wr_req;
  reg wr_ack;
  reg [31:0] wr_data;
  reg [31:0] wr_sel;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg sub_re;
  reg sub_we;
  reg sub_wt;
  reg sub_rt;
  wire sub_tr;
  wire sub_wack;
  wire sub_rack;
  reg sub_wr;
  reg sub_rr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
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
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Interface sub
  assign sub_tr = sub_wt | sub_rt;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        sub_rt <= 1'b0;
        sub_wt <= 1'b0;
        sub_wr <= 1'b0;
        sub_rr <= 1'b0;
      end
    else
      begin
        sub_wr <= (sub_wr | sub_we) & ~sub_wack;
        sub_wt <= (sub_wt | (sub_wr & ~sub_tr)) & ~sub_wack;
        sub_rr <= (sub_rr | sub_re) & ~sub_rack;
        sub_rt <= (sub_rt | (sub_rr & ~(sub_wr | sub_tr))) & ~sub_rack;
      end
  end
  assign sub_cyc_o = sub_tr;
  assign sub_stb_o = sub_tr;
  assign sub_wack = sub_ack_i & sub_wt;
  assign sub_rack = sub_ack_i & sub_rt;
  always @(wr_sel_d0)
      begin
        sub_sel_o <= 4'b0;
        if (~(wr_sel_d0[7:0] == 8'b0))
          sub_sel_o[0] <= 1'b1;
        if (~(wr_sel_d0[15:8] == 8'b0))
          sub_sel_o[1] <= 1'b1;
        if (~(wr_sel_d0[23:16] == 8'b0))
          sub_sel_o[2] <= 1'b1;
        if (~(wr_sel_d0[31:24] == 8'b0))
          sub_sel_o[3] <= 1'b1;
      end
  assign sub_we_o = sub_wt;
  assign sub_dat_o = wr_dat_d0;

  // Process for write requests.
  always @(wr_req_d0, sub_wack)
      begin
        sub_we <= 1'b0;
        // Submap sub
        sub_we <= wr_req_d0;
        wr_ack <= sub_wack;
      end

  // Process for read requests.
  always @(rd_req, sub_dat_i, sub_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        sub_re <= 1'b0;
        // Submap sub
        sub_re <= rd_req;
        rd_dat_d0 <= sub_dat_i;
        rd_ack_d0 <= sub_rack;
      end
endmodule
