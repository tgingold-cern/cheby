interface t_chan;
  logic [31:0] ctrl;
  modport master(
    output ctrl
  );
  modport slave(
    input ctrl
  );
endinterface


module repeat_name_prefix_false
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

    // REPEAT chan
    t_chan.master chan[2]
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] top_blk_chan0_ctrl_reg;
  reg chan0_ctrl_wreq;
  wire chan0_ctrl_wack;
  reg [31:0] top_blk_chan1_ctrl_reg;
  reg chan1_ctrl_wreq;
  wire chan1_ctrl_wack;
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

  // Register chan0_ctrl
  assign chan[0].ctrl = top_blk_chan0_ctrl_reg;
  assign chan0_ctrl_wack = chan0_ctrl_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      top_blk_chan0_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan0_ctrl_wreq == 1'b1)
        top_blk_chan0_ctrl_reg <= wr_dat_d0;
  end

  // Register chan1_ctrl
  assign chan[1].ctrl = top_blk_chan1_ctrl_reg;
  assign chan1_ctrl_wack = chan1_ctrl_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      top_blk_chan1_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan1_ctrl_wreq == 1'b1)
        top_blk_chan1_ctrl_reg <= wr_dat_d0;
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, chan0_ctrl_wack, chan1_ctrl_wack)
  begin
    chan0_ctrl_wreq = 1'b0;
    chan1_ctrl_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg chan0_ctrl
        chan0_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan0_ctrl_wack;
      end
    1'b1:
      begin
        // Reg chan1_ctrl
        chan1_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan1_ctrl_wack;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, top_blk_chan0_ctrl_reg, top_blk_chan1_ctrl_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[2:2])
    1'b0:
      begin
        // Reg chan0_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = top_blk_chan0_ctrl_reg;
      end
    1'b1:
      begin
        // Reg chan1_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = top_blk_chan1_ctrl_reg;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
