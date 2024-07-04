
module orclrout
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG breg
    input   wire [31:0] breg_i,
    output  wire [31:0] breg_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] breg_reg;
  reg breg_wreq;
  wire breg_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
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
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_dat_i;
      end
  end

  // Register breg
  assign breg_o = breg_reg;
  assign breg_wack = breg_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      breg_reg <= 32'b00000000000000000000000000000000;
    else
      if (breg_wreq == 1'b1)
        breg_reg <= breg_i | (breg_reg & ~wr_dat_d0);
      else
        breg_reg <= breg_i | breg_reg;
  end

  // Process for write requests.
  always @(wr_req_d0, breg_wack)
  begin
    breg_wreq = 1'b0;
    // Reg breg
    breg_wreq = wr_req_d0;
    wr_ack_int = breg_wack;
  end

  // Process for read requests.
  always @(rd_req_int, breg_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    // Reg breg
    rd_ack_d0 = rd_req_int;
    rd_dat_d0 = breg_reg;
  end
endmodule
