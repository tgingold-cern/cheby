interface t_regs;
  logic [31:0] areg;
  logic [31:0] breg1;
  logic [31:0] breg2;
  modport master(
    input breg2,
    output areg,
    output breg1
  );
  modport slave(
    output breg2,
    input areg,
    input breg1
  );
endinterface


module nested_iogroup1
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
    // Wires and registers
    t_regs.master regs
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
  wire areg_wack;
  reg [31:0] blk_breg1_reg;
  reg blk_breg1_wreq;
  wire blk_breg1_wack;
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
  assign regs.areg = areg_reg;
  assign areg_wack = areg_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      areg_reg <= 32'b00000000000000000000000000000000;
    else
      if (areg_wreq == 1'b1)
        areg_reg <= wr_dat_d0;
  end

  // Register blk_breg1
  assign regs.breg1 = blk_breg1_reg;
  assign blk_breg1_wack = blk_breg1_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      blk_breg1_reg <= 32'b00000000000000000000000000000000;
    else
      if (blk_breg1_wreq == 1'b1)
        blk_breg1_reg <= wr_dat_d0;
  end

  // Register blk_breg2

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, areg_wack, blk_breg1_wack)
  begin
    areg_wreq = 1'b0;
    blk_breg1_wreq = 1'b0;
    case (wr_adr_d0[3:2])
    2'b00:
      begin
        // Reg areg
        areg_wreq = wr_req_d0;
        wr_ack_int = areg_wack;
      end
    2'b10:
      begin
        // Reg blk_breg1
        blk_breg1_wreq = wr_req_d0;
        wr_ack_int = blk_breg1_wack;
      end
    2'b11:
      // Reg blk_breg2
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, areg_reg, blk_breg1_reg, regs.breg2)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[3:2])
    2'b00:
      begin
        // Reg areg
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = areg_reg;
      end
    2'b10:
      begin
        // Reg blk_breg1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = blk_breg1_reg;
      end
    2'b11:
      begin
        // Reg blk_breg2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = regs.breg2;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
