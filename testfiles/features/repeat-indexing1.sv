interface t_itf;
  logic [31:0] ctrl;
  logic [31:0] status;
  modport master(
    input status,
    output ctrl
  );
  modport slave(
    output status,
    input ctrl
  );
endinterface


module repeat_indexing1
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

    // REPEAT chan
    t_itf.master itf[4]
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] chan_0_ctrl_reg;
  reg chan_0_ctrl_wreq;
  wire chan_0_ctrl_wack;
  reg [31:0] chan_1_ctrl_reg;
  reg chan_1_ctrl_wreq;
  wire chan_1_ctrl_wack;
  reg [31:0] chan_2_ctrl_reg;
  reg chan_2_ctrl_wreq;
  wire chan_2_ctrl_wack;
  reg [31:0] chan_3_ctrl_reg;
  reg chan_3_ctrl_wreq;
  wire chan_3_ctrl_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [4:2] wr_adr_d0;
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

  // Register chan_0_ctrl
  assign itf[0].ctrl = chan_0_ctrl_reg;
  assign chan_0_ctrl_wack = chan_0_ctrl_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      chan_0_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan_0_ctrl_wreq == 1'b1)
        chan_0_ctrl_reg <= wr_dat_d0;
  end

  // Register chan_0_status

  // Register chan_1_ctrl
  assign itf[1].ctrl = chan_1_ctrl_reg;
  assign chan_1_ctrl_wack = chan_1_ctrl_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      chan_1_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan_1_ctrl_wreq == 1'b1)
        chan_1_ctrl_reg <= wr_dat_d0;
  end

  // Register chan_1_status

  // Register chan_2_ctrl
  assign itf[2].ctrl = chan_2_ctrl_reg;
  assign chan_2_ctrl_wack = chan_2_ctrl_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      chan_2_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan_2_ctrl_wreq == 1'b1)
        chan_2_ctrl_reg <= wr_dat_d0;
  end

  // Register chan_2_status

  // Register chan_3_ctrl
  assign itf[3].ctrl = chan_3_ctrl_reg;
  assign chan_3_ctrl_wack = chan_3_ctrl_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      chan_3_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (chan_3_ctrl_wreq == 1'b1)
        chan_3_ctrl_reg <= wr_dat_d0;
  end

  // Register chan_3_status

  // Process for write requests.
  always_comb
  begin
    chan_0_ctrl_wreq = 1'b0;
    chan_1_ctrl_wreq = 1'b0;
    chan_2_ctrl_wreq = 1'b0;
    chan_3_ctrl_wreq = 1'b0;
    case (wr_adr_d0[4:2])
    3'b000:
      begin
        // Reg chan_0_ctrl
        chan_0_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan_0_ctrl_wack;
      end
    3'b001:
      // Reg chan_0_status
      wr_ack_int = wr_req_d0;
    3'b010:
      begin
        // Reg chan_1_ctrl
        chan_1_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan_1_ctrl_wack;
      end
    3'b011:
      // Reg chan_1_status
      wr_ack_int = wr_req_d0;
    3'b100:
      begin
        // Reg chan_2_ctrl
        chan_2_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan_2_ctrl_wack;
      end
    3'b101:
      // Reg chan_2_status
      wr_ack_int = wr_req_d0;
    3'b110:
      begin
        // Reg chan_3_ctrl
        chan_3_ctrl_wreq = wr_req_d0;
        wr_ack_int = chan_3_ctrl_wack;
      end
    3'b111:
      // Reg chan_3_status
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[4:2])
    3'b000:
      begin
        // Reg chan_0_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = chan_0_ctrl_reg;
      end
    3'b001:
      begin
        // Reg chan_0_status
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = itf[0].status;
      end
    3'b010:
      begin
        // Reg chan_1_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = chan_1_ctrl_reg;
      end
    3'b011:
      begin
        // Reg chan_1_status
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = itf[1].status;
      end
    3'b100:
      begin
        // Reg chan_2_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = chan_2_ctrl_reg;
      end
    3'b101:
      begin
        // Reg chan_2_status
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = itf[2].status;
      end
    3'b110:
      begin
        // Reg chan_3_ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = chan_3_ctrl_reg;
      end
    3'b111:
      begin
        // Reg chan_3_status
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = itf[3].status;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
