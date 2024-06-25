interface t_itf;
  logic [31:0] areg1;
  modport master(
    output areg1
  );
  modport slave(
    input areg1
  );
endinterface


module repeat_iogroup1
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

    // REPEAT arr1
    t_itf.master itf[2]
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] arr1_0_areg1_reg;
  reg arr1_0_areg1_wreq;
  wire arr1_0_areg1_wack;
  reg [31:0] arr1_1_areg1_reg;
  reg arr1_1_areg1_wreq;
  wire arr1_1_areg1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
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

  // Register arr1_0_areg1
  assign itf[0].areg1 = arr1_0_areg1_reg;
  assign arr1_0_areg1_wack = arr1_0_areg1_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      arr1_0_areg1_reg <= 32'b00000000000000000000000000000000;
    else
      if (arr1_0_areg1_wreq == 1'b1)
        arr1_0_areg1_reg <= wr_dat_d0;
  end

  // Register arr1_1_areg1
  assign itf[1].areg1 = arr1_1_areg1_reg;
  assign arr1_1_areg1_wack = arr1_1_areg1_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      arr1_1_areg1_reg <= 32'b00000000000000000000000000000000;
    else
      if (arr1_1_areg1_wreq == 1'b1)
        arr1_1_areg1_reg <= wr_dat_d0;
  end

  // Process for write requests.
  always_comb
  begin
    arr1_0_areg1_wreq = 1'b0;
    arr1_1_areg1_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg arr1_0_areg1
        arr1_0_areg1_wreq = wr_req_d0;
        wr_ack_int = arr1_0_areg1_wack;
      end
    1'b1:
      begin
        // Reg arr1_1_areg1
        arr1_1_areg1_wreq = wr_req_d0;
        wr_ack_int = arr1_1_areg1_wack;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[2:2])
    1'b0:
      begin
        // Reg arr1_0_areg1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = arr1_0_areg1_reg;
      end
    1'b1:
      begin
        // Reg arr1_1_areg1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = arr1_1_areg1_reg;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
