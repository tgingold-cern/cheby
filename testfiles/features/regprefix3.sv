
module regprefix3
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
    output  wire [31:0] blk1_r1_o,

    // REG r2
    output  wire [31:0] blk1_r2_o,

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
  reg [31:0] blk1_r1_reg;
  reg blk1_r1_wreq;
  reg blk1_r1_wack;
  reg [31:0] blk1_r2_reg;
  reg blk1_r2_wreq;
  reg blk1_r2_wack;
  reg [31:0] r3_reg;
  reg r3_wreq;
  reg r3_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [5:2] wr_adr_d0;
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
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end
  end

  // Register blk1_r1
  assign blk1_r1_o = blk1_r1_reg;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        blk1_r1_reg <= 32'b00000000000000000000000000000000;
        blk1_r1_wack <= 1'b0;
      end
    else
      begin
        if (blk1_r1_wreq == 1'b1)
          blk1_r1_reg <= wr_dat_d0;
        blk1_r1_wack <= blk1_r1_wreq;
      end
  end

  // Register blk1_r2
  assign blk1_r2_o = blk1_r2_reg;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        blk1_r2_reg <= 32'b00000000000000000000000000000000;
        blk1_r2_wack <= 1'b0;
      end
    else
      begin
        if (blk1_r2_wreq == 1'b1)
          blk1_r2_reg <= wr_dat_d0;
        blk1_r2_wack <= blk1_r2_wreq;
      end
  end

  // Register r3
  assign r3_o = r3_reg;
  always @(posedge(clk_i) or negedge(rst_n_i))
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
  always @(wr_adr_d0, wr_req_d0, blk1_r1_wack, blk1_r2_wack, r3_wack)
      begin
        blk1_r1_wreq <= 1'b0;
        blk1_r2_wreq <= 1'b0;
        r3_wreq <= 1'b0;
        case (wr_adr_d0[5:2])
        4'b0000:
          begin
            // Reg blk1_r1
            blk1_r1_wreq <= wr_req_d0;
            wr_ack_int <= blk1_r1_wack;
          end
        4'b0001:
          begin
            // Reg blk1_r2
            blk1_r2_wreq <= wr_req_d0;
            wr_ack_int <= blk1_r2_wack;
          end
        4'b1000:
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
  always @(wb_adr_i, rd_req_int, blk1_r1_reg, blk1_r2_reg, r3_reg)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        case (wb_adr_i[5:2])
        4'b0000:
          begin
            // Reg blk1_r1
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= blk1_r1_reg;
          end
        4'b0001:
          begin
            // Reg blk1_r2
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= blk1_r2_reg;
          end
        4'b1000:
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
