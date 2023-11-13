interface t_blk;
  logic [31:0] breg;
  modport master(
    output breg
  );
  modport slave(
    input breg
  );
endinterface


module igroup2
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

    // REG areg
    output  wire [31:0] areg_o,
    t_blk.master blk
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] areg_reg;
  reg areg_wreq;
  reg areg_wack;
  reg [31:0] blk_breg_reg;
  reg blk_breg_wreq;
  reg blk_breg_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always @(wb_sel_i)
  ;
  assign wb_en = wb_cyc_i & wb_stb_i;

  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb_we_i)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb_we_i) & ~wb_rip;

  always @(posedge(clk_i))
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
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wb_dat_o <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end
  end

  // Register areg
  assign areg_o = areg_reg;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        areg_reg <= 32'b00000000000000000000000000000000;
        areg_wack <= 1'b0;
      end
    else
      begin
        if (areg_wreq == 1'b1)
          areg_reg <= wr_dat_d0;
        areg_wack <= areg_wreq;
      end
  end

  // Register blk_breg
  assign blk.breg = blk_breg_reg;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        blk_breg_reg <= 32'b00000000000000000000000000000000;
        blk_breg_wack <= 1'b0;
      end
    else
      begin
        if (blk_breg_wreq == 1'b1)
          blk_breg_reg <= wr_dat_d0;
        blk_breg_wack <= blk_breg_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, areg_wack, blk_breg_wack)
  begin
    areg_wreq = 1'b0;
    blk_breg_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg areg
        areg_wreq = wr_req_d0;
        wr_ack_int = areg_wack;
      end
    1'b1:
      begin
        // Reg blk_breg
        blk_breg_wreq = wr_req_d0;
        wr_ack_int = blk_breg_wack;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, areg_reg, blk_breg_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[2:2])
    1'b0:
      begin
        // Reg areg
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = areg_reg;
      end
    1'b1:
      begin
        // Reg blk_breg
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = blk_breg_reg;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
