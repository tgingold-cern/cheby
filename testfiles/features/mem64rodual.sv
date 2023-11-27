
module mem64rodual
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [8:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // RAM port for DdrCapturesIndex
    input   wire [5:0] DdrCapturesIndex_adr_i,
    input   wire DdrCapturesIndex_clk_i,
    input   wire DdrCapturesIndex_DdrCaptures_we_i,
    input   wire [63:0] DdrCapturesIndex_DdrCaptures_dat_i
  );
  reg [31:0] wr_sel;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  wire [31:0] DdrCapturesIndex_DdrCaptures_int_dato0;
  wire [31:0] DdrCapturesIndex_DdrCaptures_int_dato1;
  wire [31:0] DdrCapturesIndex_DdrCaptures_ext_dat0;
  wire [31:0] DdrCapturesIndex_DdrCaptures_ext_dat1;
  reg DdrCapturesIndex_DdrCaptures_rreq0;
  reg DdrCapturesIndex_DdrCaptures_rreq1;
  reg DdrCapturesIndex_DdrCaptures_rack0;
  reg DdrCapturesIndex_DdrCaptures_rack1;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [31:0] wr_sel_d0;
  reg [3:0] DdrCapturesIndex_0_sel_int;
  reg [3:0] DdrCapturesIndex_1_sel_int;

  // WB decode signals
  always_comb
  begin
    wr_sel[7:0] = {8{wb_sel_i[0]}};
    wr_sel[15:8] = {8{wb_sel_i[1]}};
    wr_sel[23:16] = {8{wb_sel_i[2]}};
    wr_sel[31:24] = {8{wb_sel_i[3]}};
  end
  assign wb_en = wb_cyc_i & wb_stb_i;

  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb_we_i)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb_we_i) & ~wb_rip;

  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb_we_i)) & ~wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb_we_i) & ~wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb_ack_o = ack_int;
  assign wb_stall_o = ~ack_int & wb_en;
  assign wb_rty_o = 1'b0;
  assign wb_err_o = 1'b0;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wb_dat_o <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Memory DdrCapturesIndex
  cheby_dpssram #(
      .g_data_width(32),
      .g_size(64),
      .g_addr_width(6),
      .g_dual_clock(1'b1),
      .g_use_bwsel(1'b1)
    )
  DdrCapturesIndex_DdrCaptures_raminst0 (
      .clk_a_i(clk_i),
      .clk_b_i(DdrCapturesIndex_clk_i),
      .addr_a_i(wb_adr_i[8:3]),
      .bwsel_a_i(DdrCapturesIndex_0_sel_int),
      .data_a_i({32{1'bx}}),
      .data_a_o(DdrCapturesIndex_DdrCaptures_int_dato0),
      .rd_a_i(DdrCapturesIndex_DdrCaptures_rreq0),
      .wr_a_i(1'b0),
      .addr_b_i(DdrCapturesIndex_adr_i),
      .bwsel_b_i({4{1'b1}}),
      .data_b_i(DdrCapturesIndex_DdrCaptures_dat_i[63:32]),
      .data_b_o(DdrCapturesIndex_DdrCaptures_ext_dat0),
      .rd_b_i(1'b0),
      .wr_b_i(DdrCapturesIndex_DdrCaptures_we_i)
    );
  
  always_comb
  begin
    DdrCapturesIndex_0_sel_int = 4'b0;
    if (~(wr_sel_d0[7:0] == 8'b0))
      DdrCapturesIndex_0_sel_int[0] = 1'b1;
    if (~(wr_sel_d0[15:8] == 8'b0))
      DdrCapturesIndex_0_sel_int[1] = 1'b1;
    if (~(wr_sel_d0[23:16] == 8'b0))
      DdrCapturesIndex_0_sel_int[2] = 1'b1;
    if (~(wr_sel_d0[31:24] == 8'b0))
      DdrCapturesIndex_0_sel_int[3] = 1'b1;
  end
  cheby_dpssram #(
      .g_data_width(32),
      .g_size(64),
      .g_addr_width(6),
      .g_dual_clock(1'b1),
      .g_use_bwsel(1'b1)
    )
  DdrCapturesIndex_DdrCaptures_raminst1 (
      .clk_a_i(clk_i),
      .clk_b_i(DdrCapturesIndex_clk_i),
      .addr_a_i(wb_adr_i[8:3]),
      .bwsel_a_i(DdrCapturesIndex_1_sel_int),
      .data_a_i({32{1'bx}}),
      .data_a_o(DdrCapturesIndex_DdrCaptures_int_dato1),
      .rd_a_i(DdrCapturesIndex_DdrCaptures_rreq1),
      .wr_a_i(1'b0),
      .addr_b_i(DdrCapturesIndex_adr_i),
      .bwsel_b_i({4{1'b1}}),
      .data_b_i(DdrCapturesIndex_DdrCaptures_dat_i[31:0]),
      .data_b_o(DdrCapturesIndex_DdrCaptures_ext_dat1),
      .rd_b_i(1'b0),
      .wr_b_i(DdrCapturesIndex_DdrCaptures_we_i)
    );
  
  always_comb
  begin
    DdrCapturesIndex_1_sel_int = 4'b0;
    if (~(wr_sel_d0[7:0] == 8'b0))
      DdrCapturesIndex_1_sel_int[0] = 1'b1;
    if (~(wr_sel_d0[15:8] == 8'b0))
      DdrCapturesIndex_1_sel_int[1] = 1'b1;
    if (~(wr_sel_d0[23:16] == 8'b0))
      DdrCapturesIndex_1_sel_int[2] = 1'b1;
    if (~(wr_sel_d0[31:24] == 8'b0))
      DdrCapturesIndex_1_sel_int[3] = 1'b1;
  end
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        DdrCapturesIndex_DdrCaptures_rack0 <= 1'b0;
        DdrCapturesIndex_DdrCaptures_rack1 <= 1'b0;
      end
    else
      begin
        DdrCapturesIndex_DdrCaptures_rack0 <= DdrCapturesIndex_DdrCaptures_rreq0;
        DdrCapturesIndex_DdrCaptures_rack1 <= DdrCapturesIndex_DdrCaptures_rreq1;
      end
  end

  // Process for write requests.
  always_comb
  // Memory DdrCapturesIndex
  wr_ack_int = wr_req_d0;

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    DdrCapturesIndex_DdrCaptures_rreq0 = 1'b0;
    DdrCapturesIndex_DdrCaptures_rreq1 = 1'b0;
    // Memory DdrCapturesIndex
    case (wb_adr_i[2:2])
    1'b0:
      begin
        rd_dat_d0 = DdrCapturesIndex_DdrCaptures_int_dato0;
        DdrCapturesIndex_DdrCaptures_rreq0 = rd_req_int;
        rd_ack_d0 = DdrCapturesIndex_DdrCaptures_rack0;
      end
    1'b1:
      begin
        rd_dat_d0 = DdrCapturesIndex_DdrCaptures_int_dato1;
        DdrCapturesIndex_DdrCaptures_rreq1 = rd_req_int;
        rd_ack_d0 = DdrCapturesIndex_DdrCaptures_rack1;
      end
    default:
      ;
    endcase
  end
endmodule
