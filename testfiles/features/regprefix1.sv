
module regprefix1
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

    // REG r1
    output  wire [2:0] f1_o,
    output  wire f2_o,

    // REG r2
    output  wire [2:0] f3_o,
    output  wire f4_o,

    // REG r3
    output  wire [31:0] r3_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [2:0] f1_reg;
  reg f2_reg;
  reg r1_wreq;
  reg r1_wack;
  reg [2:0] f3_reg;
  reg f4_reg;
  reg r2_wreq;
  reg r2_wack;
  reg [31:0] r3_reg;
  reg r3_wreq;
  reg r3_wack;
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

  // Register r1
  assign f1_o = f1_reg;
  assign f2_o = f2_reg;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        f1_reg <= 3'b000;
        f2_reg <= 1'b0;
        r1_wack <= 1'b0;
      end
    else
      begin
        if (r1_wreq == 1'b1)
          begin
            f1_reg <= wr_dat_d0[2:0];
            f2_reg <= wr_dat_d0[4];
          end
        r1_wack <= r1_wreq;
      end
  end

  // Register r2
  assign f3_o = f3_reg;
  assign f4_o = f4_reg;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        f3_reg <= 3'b000;
        f4_reg <= 1'b0;
        r2_wack <= 1'b0;
      end
    else
      begin
        if (r2_wreq == 1'b1)
          begin
            f3_reg <= wr_dat_d0[2:0];
            f4_reg <= wr_dat_d0[4];
          end
        r2_wack <= r2_wreq;
      end
  end

  // Register r3
  assign r3_o = r3_reg;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        r3_reg <= 32'b00000000000000000000000000000000;
        r3_wack <= 1'b0;
      end
    else
      begin
        if (r3_wreq == 1'b1)
          r3_reg <= wr_dat_d0;
        r3_wack <= r3_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, r1_wack, r2_wack, r3_wack)
  begin
    r1_wreq <= 1'b0;
    r2_wreq <= 1'b0;
    r3_wreq <= 1'b0;
    case (wr_adr_d0[3:2])
    2'b00:
      begin
        // Reg r1
        r1_wreq <= wr_req_d0;
        wr_ack_int <= r1_wack;
      end
    2'b01:
      begin
        // Reg r2
        r2_wreq <= wr_req_d0;
        wr_ack_int <= r2_wack;
      end
    2'b10:
      begin
        // Reg r3
        r3_wreq <= wr_req_d0;
        wr_ack_int <= r3_wack;
      end
    default:
      wr_ack_int <= wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, f1_reg, f2_reg, f3_reg, f4_reg, r3_reg)
  begin
    // By default ack read requests
    rd_dat_d0 <= {32{1'bx}};
    case (wb_adr_i[3:2])
    2'b00:
      begin
        // Reg r1
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0[2:0] <= f1_reg;
        rd_dat_d0[3] <= 1'b0;
        rd_dat_d0[4] <= f2_reg;
        rd_dat_d0[31:5] <= 27'b0;
      end
    2'b01:
      begin
        // Reg r2
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0[2:0] <= f3_reg;
        rd_dat_d0[3] <= 1'b0;
        rd_dat_d0[4] <= f4_reg;
        rd_dat_d0[31:5] <= 27'b0;
      end
    2'b10:
      begin
        // Reg r3
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= r3_reg;
      end
    default:
      rd_ack_d0 <= rd_req_int;
    endcase
  end
endmodule
