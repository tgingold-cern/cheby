
module blkprefix3
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [5:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG r1
    output  wire [2:0] b1_r1_f1_o,
    output  wire b1_r1_f2_o,

    // REG r2
    output  wire [63:0] b1_r2_o,

    // REG r3
    output  wire [2:0] b1_r3_f1_o,
    output  wire b1_r3_f2_o,

    // REG r4
    output  wire [63:0] b1_r4_o,

    // REG r1
    output  wire [2:0] b2_r1_f1_o,

    // REG r2
    output  wire [63:0] b2_r2_o
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [2:0] b1_r1_f1_reg;
  reg b1_r1_f2_reg;
  reg b1_r1_wreq;
  wire b1_r1_wack;
  reg [63:0] b1_r2_reg;
  reg [1:0] b1_r2_wreq;
  wire [1:0] b1_r2_wack;
  reg [2:0] b1_b11_r3_f1_reg;
  reg b1_b11_r3_f2_reg;
  reg b1_r3_wreq;
  wire b1_r3_wack;
  reg [63:0] b1_b11_r4_reg;
  reg [1:0] b1_r4_wreq;
  wire [1:0] b1_r4_wack;
  reg [2:0] b2_r1_f1_reg;
  reg b2_r1_wreq;
  wire b2_r1_wack;
  reg [63:0] b2_r2_reg;
  reg [1:0] b2_r2_wreq;
  wire [1:0] b2_r2_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [5:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always_comb
  ;
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
        wr_adr_d0 <= 4'b0000;
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

  // Register b1_r1
  assign b1_r1_f1_o = b1_r1_f1_reg;
  assign b1_r1_f2_o = b1_r1_f2_reg;
  assign b1_r1_wack = b1_r1_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        b1_r1_f1_reg <= 3'b000;
        b1_r1_f2_reg <= 1'b0;
      end
    else
      if (b1_r1_wreq == 1'b1)
        begin
          b1_r1_f1_reg <= wr_dat_d0[2:0];
          b1_r1_f2_reg <= wr_dat_d0[4];
        end
  end

  // Register b1_r2
  assign b1_r2_o = b1_r2_reg;
  assign b1_r2_wack = b1_r2_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      b1_r2_reg <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    else
      begin
        if (b1_r2_wreq[0] == 1'b1)
          b1_r2_reg[31:0] <= wr_dat_d0;
        if (b1_r2_wreq[1] == 1'b1)
          b1_r2_reg[63:32] <= wr_dat_d0;
      end
  end

  // Register b1_r3
  assign b1_r3_f1_o = b1_b11_r3_f1_reg;
  assign b1_r3_f2_o = b1_b11_r3_f2_reg;
  assign b1_r3_wack = b1_r3_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        b1_b11_r3_f1_reg <= 3'b000;
        b1_b11_r3_f2_reg <= 1'b0;
      end
    else
      if (b1_r3_wreq == 1'b1)
        begin
          b1_b11_r3_f1_reg <= wr_dat_d0[2:0];
          b1_b11_r3_f2_reg <= wr_dat_d0[4];
        end
  end

  // Register b1_r4
  assign b1_r4_o = b1_b11_r4_reg;
  assign b1_r4_wack = b1_r4_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      b1_b11_r4_reg <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    else
      begin
        if (b1_r4_wreq[0] == 1'b1)
          b1_b11_r4_reg[31:0] <= wr_dat_d0;
        if (b1_r4_wreq[1] == 1'b1)
          b1_b11_r4_reg[63:32] <= wr_dat_d0;
      end
  end

  // Register b2_r1
  assign b2_r1_f1_o = b2_r1_f1_reg;
  assign b2_r1_wack = b2_r1_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      b2_r1_f1_reg <= 3'b000;
    else
      if (b2_r1_wreq == 1'b1)
        b2_r1_f1_reg <= wr_dat_d0[2:0];
  end

  // Register b2_r2
  assign b2_r2_o = b2_r2_reg;
  assign b2_r2_wack = b2_r2_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      b2_r2_reg <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
    else
      begin
        if (b2_r2_wreq[0] == 1'b1)
          b2_r2_reg[31:0] <= wr_dat_d0;
        if (b2_r2_wreq[1] == 1'b1)
          b2_r2_reg[63:32] <= wr_dat_d0;
      end
  end

  // Process for write requests.
  always_comb
  begin
    b1_r1_wreq = 1'b0;
    b1_r2_wreq = 2'b0;
    b1_r3_wreq = 1'b0;
    b1_r4_wreq = 2'b0;
    b2_r1_wreq = 1'b0;
    b2_r2_wreq = 2'b0;
    case (wr_adr_d0[5:3])
    3'b000:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b1_r1
          b1_r1_wreq = wr_req_d0;
          wr_ack_int = b1_r1_wack;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    3'b001:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b1_r2
          b1_r2_wreq[1] = wr_req_d0;
          wr_ack_int = b1_r2_wack[1];
        end
      1'b1:
        begin
          // Reg b1_r2
          b1_r2_wreq[0] = wr_req_d0;
          wr_ack_int = b1_r2_wack[0];
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    3'b010:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b1_r3
          b1_r3_wreq = wr_req_d0;
          wr_ack_int = b1_r3_wack;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    3'b011:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b1_r4
          b1_r4_wreq[1] = wr_req_d0;
          wr_ack_int = b1_r4_wack[1];
        end
      1'b1:
        begin
          // Reg b1_r4
          b1_r4_wreq[0] = wr_req_d0;
          wr_ack_int = b1_r4_wack[0];
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    3'b100:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b2_r1
          b2_r1_wreq = wr_req_d0;
          wr_ack_int = b2_r1_wack;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    3'b101:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg b2_r2
          b2_r2_wreq[1] = wr_req_d0;
          wr_ack_int = b2_r2_wack[1];
        end
      1'b1:
        begin
          // Reg b2_r2
          b2_r2_wreq[0] = wr_req_d0;
          wr_ack_int = b2_r2_wack[0];
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[5:3])
    3'b000:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b1_r1
          rd_ack_d0 = rd_req_int;
          rd_dat_d0[2:0] = b1_r1_f1_reg;
          rd_dat_d0[3] = 1'b0;
          rd_dat_d0[4] = b1_r1_f2_reg;
          rd_dat_d0[31:5] = 27'b0;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    3'b001:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b1_r2
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b1_r2_reg[63:32];
        end
      1'b1:
        begin
          // Reg b1_r2
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b1_r2_reg[31:0];
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    3'b010:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b1_r3
          rd_ack_d0 = rd_req_int;
          rd_dat_d0[2:0] = b1_b11_r3_f1_reg;
          rd_dat_d0[3] = 1'b0;
          rd_dat_d0[4] = b1_b11_r3_f2_reg;
          rd_dat_d0[31:5] = 27'b0;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    3'b011:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b1_r4
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b1_b11_r4_reg[63:32];
        end
      1'b1:
        begin
          // Reg b1_r4
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b1_b11_r4_reg[31:0];
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    3'b100:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b2_r1
          rd_ack_d0 = rd_req_int;
          rd_dat_d0[2:0] = b2_r1_f1_reg;
          rd_dat_d0[31:3] = 29'b0;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    3'b101:
      case (wb_adr_i[2:2])
      1'b0:
        begin
          // Reg b2_r2
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b2_r2_reg[63:32];
        end
      1'b1:
        begin
          // Reg b2_r2
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = b2_r2_reg[31:0];
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
