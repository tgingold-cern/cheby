
module s4
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [2:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG r1
    output  wire [31:0] r1_o,

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
  reg [31:0] wr_sel;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] r1_reg;
  reg r1_wreq;
  reg r1_wack;
  reg sub_re;
  reg sub_we;
  reg sub_wt;
  reg sub_rt;
  wire sub_tr;
  wire sub_wack;
  wire sub_rack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;

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
      wb_rip <= (wb_rip | (wb_en & !wb_we_i)) & !rd_ack_int;
  end
  assign rd_req_int = (wb_en & !wb_we_i) & !wb_rip;

  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb_we_i)) & !wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb_we_i) & !wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb_ack_o = ack_int;
  assign wb_stall_o = !ack_int & wb_en;
  assign wb_rty_o = 1'b0;
  assign wb_err_o = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
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

  // Register r1
  assign r1_o = r1_reg;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        r1_reg <= 32'b00000000000000000000000000000000;
        r1_wack <= 1'b0;
      end
    else
      begin
        if (r1_wreq == 1'b1)
          r1_reg <= wr_dat_d0;
        r1_wack <= r1_wreq;
      end
  end

  // Interface sub
  assign sub_tr = sub_wt | sub_rt;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        sub_rt <= 1'b0;
        sub_wt <= 1'b0;
      end
    else
      begin
        sub_rt <= (sub_rt | sub_re) & !sub_rack;
        sub_wt <= (sub_wt | sub_we) & !sub_wack;
      end
  end
  assign sub_cyc_o = sub_tr;
  assign sub_stb_o = sub_tr;
  assign sub_wack = sub_ack_i & sub_wt;
  assign sub_rack = sub_ack_i & sub_rt;
  always @(wr_sel_d0)
      begin
        sub_sel_o <= 4'b0;
        if (!(wr_sel_d0[7:0] == 8'b0))
          sub_sel_o[0] <= 1'b1;
        if (!(wr_sel_d0[15:8] == 8'b0))
          sub_sel_o[1] <= 1'b1;
        if (!(wr_sel_d0[23:16] == 8'b0))
          sub_sel_o[2] <= 1'b1;
        if (!(wr_sel_d0[31:24] == 8'b0))
          sub_sel_o[3] <= 1'b1;
      end
  assign sub_we_o = sub_wt;
  assign sub_dat_o = wr_dat_d0;

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, r1_wack, sub_wack)
      begin
        r1_wreq <= 1'b0;
        sub_we <= 1'b0;
        case (wr_adr_d0[2:2])
        1'b0:
          begin
            // Reg r1
            r1_wreq <= wr_req_d0;
            wr_ack_int <= r1_wack;
          end
        1'b1:
          begin
            // Submap sub
            sub_we <= wr_req_d0;
            wr_ack_int <= sub_wack;
          end
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, r1_reg, sub_dat_i, sub_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        sub_re <= 1'b0;
        case (wb_adr_i[2:2])
        1'b0:
          begin
            // Reg r1
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= r1_reg;
          end
        1'b1:
          begin
            // Submap sub
            sub_re <= rd_req_int;
            rd_dat_d0 <= sub_dat_i;
            rd_ack_d0 <= sub_rack;
          end
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
