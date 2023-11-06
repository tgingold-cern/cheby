
module bugDPSSRAMbwSel
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [19:2] awaddr,
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
    input   wire [19:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // RAM port for mem
    input   wire [9:0] mem_adr_i,
    input   wire mem_r1_rd_i,
    output  wire [7:0] mem_r1_dat_o
  );
  reg wr_req;
  reg wr_ack;
  reg [19:2] wr_addr;
  reg [31:0] wr_data;
  reg [31:0] wr_sel;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [19:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  wire [7:0] mem_r1_int_dato;
  wire [7:0] mem_r1_ext_dat;
  reg mem_r1_rreq;
  reg mem_r1_rack;
  reg mem_r1_int_wr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [19:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;
  wire mem_wr;
  wire mem_wreq;
  reg [9:0] mem_adr_int;
  reg [3:0] mem_sel_int;

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

  // Memory mem
  always @(rd_addr, wr_adr_d0, mem_wr)
      if (mem_wr == 1'b1)
        mem_adr_int <= wr_adr_d0[11:2];
      else
        mem_adr_int <= rd_addr[11:2];
  assign mem_wreq = mem_r1_int_wr;
  assign mem_wr = mem_wreq;
  cheby_dpssram #(
      .g_data_width(8),
      .g_size(1024),
      .g_addr_width(10),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b1)
    )
  mem_r1_raminst (
      .clk_a_i(aclk),
      .clk_b_i(aclk),
      .addr_a_i(mem_adr_int),
      .bwsel_a_i(mem_sel_int[0:0]),
      .data_a_i(wr_dat_d0[7:0]),
      .data_a_o(mem_r1_int_dato),
      .rd_a_i(mem_r1_rreq),
      .wr_a_i(mem_r1_int_wr),
      .addr_b_i(mem_adr_i),
      .bwsel_b_i({1{1'b1}}),
      .data_b_i(mem_r1_ext_dat),
      .data_b_o(mem_r1_dat_o),
      .rd_b_i(mem_r1_rd_i),
      .wr_b_i(1'b0)
    );
  
  always @(wr_sel_d0)
      begin
        mem_sel_int <= 4'b0;
        if (~(wr_sel_d0[7:0] == 8'b0))
          mem_sel_int[0] <= 1'b1;
        if (~(wr_sel_d0[15:8] == 8'b0))
          mem_sel_int[1] <= 1'b1;
        if (~(wr_sel_d0[23:16] == 8'b0))
          mem_sel_int[2] <= 1'b1;
        if (~(wr_sel_d0[31:24] == 8'b0))
          mem_sel_int[3] <= 1'b1;
      end
  always @(posedge(aclk) or negedge(areset_n))
  begin
    if (!areset_n)
      mem_r1_rack <= 1'b0;
    else
      mem_r1_rack <= (mem_r1_rreq & ~mem_wreq) & ~mem_r1_rack;
  end

  // Process for write requests.
  always @(wr_req_d0)
      begin
        mem_r1_int_wr <= 1'b0;
        // Memory mem
        mem_r1_int_wr <= wr_req_d0;
        wr_ack <= wr_req_d0;
      end

  // Process for read requests.
  always @(mem_r1_int_dato, rd_req, mem_wreq, mem_r1_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        mem_r1_rreq <= 1'b0;
        // Memory mem
        rd_dat_d0 <= {24'b000000000000000000000000, mem_r1_int_dato};
        mem_r1_rreq <= rd_req & ~mem_wreq;
        rd_ack_d0 <= mem_r1_rack;
      end
endmodule
