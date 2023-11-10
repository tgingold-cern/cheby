
module reg128
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [3:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG areg
    output  wire [127:0] areg_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [127:0] areg_reg;
  reg [3:0] areg_wreq;
  reg [3:0] areg_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [3:2] wr_adr_d0;
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
        wr_adr_d0 <= 2'b00;
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
        areg_reg <= 128'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        areg_wack <= 4'b0;
      end
    else
      begin
        if (areg_wreq[0] == 1'b1)
          areg_reg[31:0] <= wr_dat_d0;
        if (areg_wreq[1] == 1'b1)
          areg_reg[63:32] <= wr_dat_d0;
        if (areg_wreq[2] == 1'b1)
          areg_reg[95:64] <= wr_dat_d0;
        if (areg_wreq[3] == 1'b1)
          areg_reg[127:96] <= wr_dat_d0;
        areg_wack <= areg_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, areg_wack)
  begin
    areg_wreq <= 4'b0;
    case (wr_adr_d0[3:2])
    2'b00:
      begin
        // Reg areg
        areg_wreq[3] <= wr_req_d0;
        wr_ack_int <= areg_wack[3];
      end
    2'b01:
      begin
        // Reg areg
        areg_wreq[2] <= wr_req_d0;
        wr_ack_int <= areg_wack[2];
      end
    2'b10:
      begin
        // Reg areg
        areg_wreq[1] <= wr_req_d0;
        wr_ack_int <= areg_wack[1];
      end
    2'b11:
      begin
        // Reg areg
        areg_wreq[0] <= wr_req_d0;
        wr_ack_int <= areg_wack[0];
      end
    default:
      wr_ack_int <= wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, areg_reg)
  begin
    // By default ack read requests
    rd_dat_d0 <= {32{1'bx}};
    case (wb_adr_i[3:2])
    2'b00:
      begin
        // Reg areg
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= areg_reg[127:96];
      end
    2'b01:
      begin
        // Reg areg
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= areg_reg[95:64];
      end
    2'b10:
      begin
        // Reg areg
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= areg_reg[63:32];
      end
    2'b11:
      begin
        // Reg areg
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= areg_reg[31:0];
      end
    default:
      rd_ack_d0 <= rd_req_int;
    endcase
  end
endmodule
