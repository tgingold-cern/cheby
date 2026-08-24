
module buserr_mem_int
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [7:2] awaddr,
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
    input   wire [7:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // REG scratch
    output  wire [31:0] scratch_o,

    // RAM port for lut
    input   wire [4:0] lut_adr_i,
    input   wire lut_value_rd_i,
    output  wire [31:0] lut_value_dat_o
  );
  reg wr_req;
  reg wr_ack;
  reg wr_err;
  reg [7:2] wr_addr;
  reg [31:0] wr_data;
  reg [31:0] wr_sel;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg [1:0] axi_werr;
  reg rd_req;
  reg rd_ack;
  reg rd_err;
  reg [7:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg [1:0] axi_rerr;
  reg [31:0] scratch_reg;
  reg scratch_wreq;
  wire scratch_wack;
  wire [31:0] lut_value_int_dato;
  wire [31:0] lut_value_ext_dat;
  reg lut_value_rreq;
  reg lut_value_rack;
  reg lut_value_int_wr;
  reg rd_ack_d0;
  reg rd_err_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [7:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;
  wire lut_wr;
  wire lut_wreq;
  reg [4:0] lut_adr_int;
  reg [3:0] lut_sel_int;

  // AW, W and B channels
  assign awready = ~axi_awset;
  assign wready = ~axi_wset;
  assign bvalid = axi_wdone | ~areset_n;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        wr_req <= 1'b0;
        axi_awset <= 1'b0;
        axi_wset <= 1'b0;
        // During reset, return error (BVALID is forced by the reset signal)
        axi_wdone <= 1'b0;
        axi_werr <= 2'b10;
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
          begin
            axi_wdone <= 1'b1;
            if (wr_err == 1'b0)
              axi_werr <= 2'b00;
            else
              axi_werr <= 2'b10;
          end
      end
  end
  assign bresp = axi_werr;

  // AR and R channels
  assign arready = ~axi_arset;
  assign rvalid = axi_rdone | ~areset_n;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        // During reset, return error (RVALID is forced by the reset signal)
        axi_rdone <= 1'b0;
        axi_rerr <= 2'b10;
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
            if (rd_err == 1'b0)
              axi_rerr <= 2'b00;
            else
              axi_rerr <= 2'b10;
          end
      end
  end
  assign rresp = axi_rerr;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_ack <= 1'b0;
        rd_err <= 1'b0;
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 6'b000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Register scratch
  assign scratch_o = scratch_reg;
  assign scratch_wack = scratch_wreq;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      scratch_reg <= 32'b00000000000000000000000000000000;
    else
      if (scratch_wreq == 1'b1)
        scratch_reg <= wr_dat_d0;
  end

  // Memory lut
  always_comb
  if (lut_wr == 1'b1)
    lut_adr_int = wr_adr_d0[6:2];
  else
    lut_adr_int = rd_addr[6:2];
  assign lut_wreq = lut_value_int_wr;
  assign lut_wr = lut_wreq;
  cheby_dpssram #(
      .g_data_width(32),
      .g_size(32),
      .g_addr_width(5),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b1)
    )
  lut_value_raminst (
      .clk_a_i(aclk),
      .clk_b_i(aclk),
      .addr_a_i(lut_adr_int),
      .bwsel_a_i(lut_sel_int),
      .data_a_i(wr_dat_d0),
      .data_a_o(lut_value_int_dato),
      .rd_a_i(lut_value_rreq),
      .wr_a_i(lut_value_int_wr),
      .addr_b_i(lut_adr_i),
      .bwsel_b_i({4{1'b1}}),
      .data_b_i(lut_value_ext_dat),
      .data_b_o(lut_value_dat_o),
      .rd_b_i(lut_value_rd_i),
      .wr_b_i(1'b0)
    );
  
  always_comb
  begin
    lut_sel_int = 4'b0;
    if (~(wr_sel_d0[7:0] == 8'b0))
      lut_sel_int[0] = 1'b1;
    if (~(wr_sel_d0[15:8] == 8'b0))
      lut_sel_int[1] = 1'b1;
    if (~(wr_sel_d0[23:16] == 8'b0))
      lut_sel_int[2] = 1'b1;
    if (~(wr_sel_d0[31:24] == 8'b0))
      lut_sel_int[3] = 1'b1;
  end
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      lut_value_rack <= 1'b0;
    else
      lut_value_rack <= (lut_value_rreq & ~lut_wreq) & ~lut_value_rack;
  end

  // Process for write requests.
  always_comb
  begin
    scratch_wreq = 1'b0;
    lut_value_int_wr = 1'b0;
    case (wr_adr_d0[7:7])
    1'b0:
      case (wr_adr_d0[6:2])
      5'b00000:
        begin
          // Reg scratch
          scratch_wreq = wr_req_d0;
          wr_ack = scratch_wack;
          wr_err = 1'b0;
        end
      default:
        begin
          wr_ack = wr_req_d0;
          wr_err = wr_req_d0;
        end
      endcase
    1'b1:
      begin
        // Memory lut
        lut_value_int_wr = wr_req_d0;
        wr_ack = wr_req_d0;
        wr_err = 1'b0;
      end
    default:
      begin
        wr_ack = wr_req_d0;
        wr_err = wr_req_d0;
      end
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    lut_value_rreq = 1'b0;
    case (rd_addr[7:7])
    1'b0:
      case (rd_addr[6:2])
      5'b00000:
        begin
          // Reg scratch
          rd_ack_d0 = rd_req;
          rd_err_d0 = 1'b0;
          rd_dat_d0 = scratch_reg;
        end
      default:
        begin
          rd_ack_d0 = rd_req;
          rd_err_d0 = rd_req;
        end
      endcase
    1'b1:
      begin
        // Memory lut
        rd_dat_d0 = lut_value_int_dato;
        lut_value_rreq = rd_req & ~lut_wreq;
        rd_ack_d0 = lut_value_rack;
        rd_err_d0 = 1'b0;
      end
    default:
      begin
        rd_ack_d0 = rd_req;
        rd_err_d0 = rd_req;
      end
    endcase
  end
endmodule
