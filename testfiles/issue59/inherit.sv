
module inherit
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

    // a normal reg with some fields
    // 1-bit field
    input   wire reg0_field00_i,
    output  wire reg0_field00_o,
    // multi bit field
    output  wire [3:0] reg0_field01_o,
    // a field with a preset value
    input   wire [2:0] reg0_field02_i,
    output  wire [2:0] reg0_field02_o,
    output  wire reg0_wr_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [3:0] reg0_field01_reg;
  reg reg0_wreq;
  reg reg0_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always @(wb_sel_i)
      ;
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
        wr_req_d0 <= 1'b0;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_dat_i;
      end
  end

  // Register reg0
  assign reg0_field00_o = wr_dat_d0[1];
  assign reg0_field01_o = reg0_field01_reg;
  assign reg0_field02_o = wr_dat_d0[10:8];
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        reg0_field01_reg <= 4'b0000;
        reg0_wack <= 1'b0;
      end
    else
      begin
        if (reg0_wreq == 1'b1)
          reg0_field01_reg <= wr_dat_d0[7:4];
        reg0_wack <= reg0_wreq;
      end
  end
  assign reg0_wr_o = reg0_wack;

  // Process for write requests.
  always @(wr_req_d0, reg0_wack)
      begin
        reg0_wreq <= 1'b0;
        // Reg reg0
        reg0_wreq <= wr_req_d0;
        wr_ack_int <= reg0_wack;
      end

  // Process for read requests.
  always @(rd_req_int, reg0_field00_i, reg0_field01_reg, reg0_field02_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        // Reg reg0
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0[0] <= 1'b0;
        rd_dat_d0[1] <= reg0_field00_i;
        rd_dat_d0[3:2] <= 2'b0;
        rd_dat_d0[7:4] <= reg0_field01_reg;
        rd_dat_d0[10:8] <= reg0_field02_i;
        rd_dat_d0[31:11] <= 21'b0;
      end
endmodule
