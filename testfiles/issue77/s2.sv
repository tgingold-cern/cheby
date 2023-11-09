
module s2
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

    // CERN-BE bus sub
    input   wire [31:0] sub_VMERdData_i,
    output  wire [31:0] sub_VMEWrData_o,
    output  reg sub_VMERdMem_o,
    output  reg sub_VMEWrMem_o,
    input   wire sub_VMERdDone_i,
    input   wire sub_VMEWrDone_i
  );
  reg wr_req;
  reg wr_ack;
  reg [31:0] wr_data;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg sub_wr;
  reg sub_rr;
  wire sub_ws;
  wire sub_rs;
  reg sub_re;
  reg sub_we;
  reg sub_wt;
  reg sub_rt;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [31:0] wr_dat_d0;

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
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_dat_d0 <= wr_data;
      end
  end

  // Interface sub
  assign sub_VMEWrData_o = wr_dat_d0;
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      begin
        sub_wr <= 1'b0;
        sub_wt <= 1'b0;
        sub_rr <= 1'b0;
        sub_rt <= 1'b0;
      end
    else
      begin
        sub_wr <= (sub_wr | sub_we) & ~sub_VMEWrDone_i;
        sub_wt <= (sub_wt | sub_ws) & ~sub_VMEWrDone_i;
        sub_rr <= (sub_rr | sub_re) & ~sub_VMERdDone_i;
        sub_rt <= (sub_rt | sub_rs) & ~sub_VMERdDone_i;
      end
  end
  assign sub_rs = sub_rr & ~(sub_wr | (sub_rt | sub_wt));
  assign sub_ws = sub_wr & ~(sub_rt | sub_wt);

  // Process for write requests.
  always @(wr_req_d0, sub_ws, sub_VMEWrDone_i)
      begin
        sub_we <= 1'b0;
        sub_VMEWrMem_o <= 1'b0;
        // Submap sub
        sub_we <= wr_req_d0;
        sub_VMEWrMem_o <= sub_ws;
        wr_ack <= sub_VMEWrDone_i;
      end

  // Process for read requests.
  always @(rd_req, sub_rs, sub_VMERdData_i, sub_VMERdDone_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        sub_VMERdMem_o <= 1'b0;
        sub_re <= 1'b0;
        // Submap sub
        sub_re <= rd_req;
        sub_VMERdMem_o <= sub_rs;
        rd_dat_d0 <= sub_VMERdData_i;
        rd_ack_d0 <= sub_VMERdDone_i;
      end
endmodule
