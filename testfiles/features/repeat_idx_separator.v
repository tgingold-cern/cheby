
module repeat_idx_separator
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [4:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG r
    output  wire [31:0] rep0_0_r_o,

    // REG r
    output  wire [31:0] rep0_1_r_o,

    // REG r
    output  wire [31:0] rep10_r_o,

    // REG r
    output  wire [31:0] rep11_r_o,

    // REG r
    output  wire [31:0] rep2_0_r_o,

    // REG r
    output  wire [31:0] rep2_1_r_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] rep0_0_r_reg;
  reg rep0_0_r_wreq;
  wire rep0_0_r_wack;
  reg [31:0] rep0_1_r_reg;
  reg rep0_1_r_wreq;
  wire rep0_1_r_wack;
  reg [31:0] rep10_r_reg;
  reg rep10_r_wreq;
  wire rep10_r_wack;
  reg [31:0] rep11_r_reg;
  reg rep11_r_wreq;
  wire rep11_r_wack;
  reg [31:0] rep2_0_r_reg;
  reg rep2_0_r_wreq;
  wire rep2_0_r_wack;
  reg [31:0] rep2_1_r_reg;
  reg rep2_1_r_wreq;
  wire rep2_1_r_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [4:2] wr_adr_d0;
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
        wr_adr_d0 <= 3'b000;
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

  // Register rep0_0_r
  assign rep0_0_r_o = rep0_0_r_reg;
  assign rep0_0_r_wack = rep0_0_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep0_0_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep0_0_r_wreq == 1'b1)
        rep0_0_r_reg <= wr_dat_d0;
  end

  // Register rep0_1_r
  assign rep0_1_r_o = rep0_1_r_reg;
  assign rep0_1_r_wack = rep0_1_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep0_1_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep0_1_r_wreq == 1'b1)
        rep0_1_r_reg <= wr_dat_d0;
  end

  // Register rep10_r
  assign rep10_r_o = rep10_r_reg;
  assign rep10_r_wack = rep10_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep10_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep10_r_wreq == 1'b1)
        rep10_r_reg <= wr_dat_d0;
  end

  // Register rep11_r
  assign rep11_r_o = rep11_r_reg;
  assign rep11_r_wack = rep11_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep11_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep11_r_wreq == 1'b1)
        rep11_r_reg <= wr_dat_d0;
  end

  // Register rep2_0_r
  assign rep2_0_r_o = rep2_0_r_reg;
  assign rep2_0_r_wack = rep2_0_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep2_0_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep2_0_r_wreq == 1'b1)
        rep2_0_r_reg <= wr_dat_d0;
  end

  // Register rep2_1_r
  assign rep2_1_r_o = rep2_1_r_reg;
  assign rep2_1_r_wack = rep2_1_r_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      rep2_1_r_reg <= 32'b00000000000000000000000000000000;
    else
      if (rep2_1_r_wreq == 1'b1)
        rep2_1_r_reg <= wr_dat_d0;
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, rep0_0_r_wack, rep0_1_r_wack, rep10_r_wack, rep11_r_wack, rep2_0_r_wack, rep2_1_r_wack)
  begin
    rep0_0_r_wreq = 1'b0;
    rep0_1_r_wreq = 1'b0;
    rep10_r_wreq = 1'b0;
    rep11_r_wreq = 1'b0;
    rep2_0_r_wreq = 1'b0;
    rep2_1_r_wreq = 1'b0;
    case (wr_adr_d0[4:2])
    3'b000:
      begin
        // Reg rep0_0_r
        rep0_0_r_wreq = wr_req_d0;
        wr_ack_int = rep0_0_r_wack;
      end
    3'b001:
      begin
        // Reg rep0_1_r
        rep0_1_r_wreq = wr_req_d0;
        wr_ack_int = rep0_1_r_wack;
      end
    3'b010:
      begin
        // Reg rep10_r
        rep10_r_wreq = wr_req_d0;
        wr_ack_int = rep10_r_wack;
      end
    3'b011:
      begin
        // Reg rep11_r
        rep11_r_wreq = wr_req_d0;
        wr_ack_int = rep11_r_wack;
      end
    3'b100:
      begin
        // Reg rep2_0_r
        rep2_0_r_wreq = wr_req_d0;
        wr_ack_int = rep2_0_r_wack;
      end
    3'b101:
      begin
        // Reg rep2_1_r
        rep2_1_r_wreq = wr_req_d0;
        wr_ack_int = rep2_1_r_wack;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, rep0_0_r_reg, rep0_1_r_reg, rep10_r_reg, rep11_r_reg, rep2_0_r_reg, rep2_1_r_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[4:2])
    3'b000:
      begin
        // Reg rep0_0_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep0_0_r_reg;
      end
    3'b001:
      begin
        // Reg rep0_1_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep0_1_r_reg;
      end
    3'b010:
      begin
        // Reg rep10_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep10_r_reg;
      end
    3'b011:
      begin
        // Reg rep11_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep11_r_reg;
      end
    3'b100:
      begin
        // Reg rep2_0_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep2_0_r_reg;
      end
    3'b101:
      begin
        // Reg rep2_1_r
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = rep2_1_r_reg;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
