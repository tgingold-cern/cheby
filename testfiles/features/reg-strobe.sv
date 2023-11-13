
module reg_strobe
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

    // The first register (with some fields)
    // 1-bit field
    output  wire regA_field0_o,
    output  wire regA_wr_o
  );
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

  // Register regA
  assign regA_field0_o = regA_field0_reg;
  always @(posedge(clk_i))
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
  assign regA_wr_o = regA_wack;

  // Process for write requests.
  always @(wr_req_d0, regA_wack)
  begin
    regA_wreq <= 1'b0;
    // Reg regA
    regA_wreq <= wr_req_d0;
    wr_ack_int <= regA_wack;
  end

  // Process for read requests.
  always @(rd_req_int, regA_field0_reg)
  begin
    // By default ack read requests
    rd_dat_d0 <= {32{1'bx}};
    // Reg regA
    rd_ack_d0 <= rd_req_int;
    rd_dat_d0[0] <= 1'b0;
    rd_dat_d0[1] <= regA_field0_reg;
    rd_dat_d0[31:2] <= 30'b0;
  end
endmodule
