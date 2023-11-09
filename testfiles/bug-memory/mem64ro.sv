
module mem64ro
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [9:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // The first register (with some fields)
    // 1-bit field
    output  wire regA_field0_o,

    // RAM port for DdrCapturesIndex
    input   wire [5:0] DdrCapturesIndex_adr_i,
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
  reg regA_field0_reg;
  reg regA_wreq;
  reg regA_wack;
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
  reg [9:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;
  reg [3:0] DdrCapturesIndex_0_sel_int;
  reg [3:0] DdrCapturesIndex_1_sel_int;

  // WB decode signals
  always @(wb_sel_i)
      begin
        wr_sel[7:0] <= {8{wb_sel_i[0]}};
        wr_sel[15:8] <= {8{wb_sel_i[1]}};
        wr_sel[23:16] <= {8{wb_sel_i[2]}};
        wr_sel[31:24] <= {8{wb_sel_i[3]}};
      end
  assign wb_en = wb_cyc_i & wb_stb_i;

  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb_we_i)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb_we_i) & ~wb_rip;

  always @(posedge(clk_i) or negedge(rst_n_i))
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
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wb_dat_o <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 8'b00000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Register regA
  assign regA_field0_o = regA_field0_reg;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        regA_field0_reg <= 1'b0;
        regA_wack <= 1'b0;
      end
    else
      begin
        if (regA_wreq == 1'b1)
          regA_field0_reg <= wr_dat_d0[1];
        regA_wack <= regA_wreq;
      end
  end

  // Memory DdrCapturesIndex
  cheby_dpssram #(
      .g_data_width(32),
      .g_size(64),
      .g_addr_width(6),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b1)
    )
  DdrCapturesIndex_DdrCaptures_raminst0 (
      .clk_a_i(clk_i),
      .clk_b_i(clk_i),
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
  
  always @(wr_sel_d0)
      begin
        DdrCapturesIndex_0_sel_int <= 4'b0;
        if (~(wr_sel_d0[7:0] == 8'b0))
          DdrCapturesIndex_0_sel_int[0] <= 1'b1;
        if (~(wr_sel_d0[15:8] == 8'b0))
          DdrCapturesIndex_0_sel_int[1] <= 1'b1;
        if (~(wr_sel_d0[23:16] == 8'b0))
          DdrCapturesIndex_0_sel_int[2] <= 1'b1;
        if (~(wr_sel_d0[31:24] == 8'b0))
          DdrCapturesIndex_0_sel_int[3] <= 1'b1;
      end
  cheby_dpssram #(
      .g_data_width(32),
      .g_size(64),
      .g_addr_width(6),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b1)
    )
  DdrCapturesIndex_DdrCaptures_raminst1 (
      .clk_a_i(clk_i),
      .clk_b_i(clk_i),
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
  
  always @(wr_sel_d0)
      begin
        DdrCapturesIndex_1_sel_int <= 4'b0;
        if (~(wr_sel_d0[7:0] == 8'b0))
          DdrCapturesIndex_1_sel_int[0] <= 1'b1;
        if (~(wr_sel_d0[15:8] == 8'b0))
          DdrCapturesIndex_1_sel_int[1] <= 1'b1;
        if (~(wr_sel_d0[23:16] == 8'b0))
          DdrCapturesIndex_1_sel_int[2] <= 1'b1;
        if (~(wr_sel_d0[31:24] == 8'b0))
          DdrCapturesIndex_1_sel_int[3] <= 1'b1;
      end
  always @(posedge(clk_i) or negedge(rst_n_i))
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
  always @(wr_adr_d0, wr_req_d0, regA_wack)
      begin
        regA_wreq <= 1'b0;
        case (wr_adr_d0[9:9])
        1'b0:
          case (wr_adr_d0[8:2])
          7'b0000000:
            begin
              // Reg regA
              regA_wreq <= wr_req_d0;
              wr_ack_int <= regA_wack;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        1'b1:
          // Memory DdrCapturesIndex
          wr_ack_int <= wr_req_d0;
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, regA_field0_reg, DdrCapturesIndex_DdrCaptures_int_dato0, DdrCapturesIndex_DdrCaptures_rack0, DdrCapturesIndex_DdrCaptures_int_dato1, DdrCapturesIndex_DdrCaptures_rack1)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        DdrCapturesIndex_DdrCaptures_rreq0 <= 1'b0;
        DdrCapturesIndex_DdrCaptures_rreq1 <= 1'b0;
        case (wb_adr_i[9:9])
        1'b0:
          case (wb_adr_i[8:2])
          7'b0000000:
            begin
              // Reg regA
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= 1'b0;
              rd_dat_d0[1] <= regA_field0_reg;
              rd_dat_d0[31:2] <= 30'b0;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        1'b1:
          // Memory DdrCapturesIndex
          case (wb_adr_i[2:2])
          1'b0:
            begin
              rd_dat_d0 <= DdrCapturesIndex_DdrCaptures_int_dato0;
              DdrCapturesIndex_DdrCaptures_rreq0 <= rd_req_int;
              rd_ack_d0 <= DdrCapturesIndex_DdrCaptures_rack0;
            end
          1'b1:
            begin
              rd_dat_d0 <= DdrCapturesIndex_DdrCaptures_int_dato1;
              DdrCapturesIndex_DdrCaptures_rreq1 <= rd_req_int;
              rd_ack_d0 <= DdrCapturesIndex_DdrCaptures_rack1;
            end
          default:
            ;
          endcase
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
