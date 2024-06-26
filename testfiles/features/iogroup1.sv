interface t_ios;
  logic [31:0] areg1;
  logic [31:0] areg2;
  logic [31:0] areg3;
  logic areg3_wr;
  logic [31:0] areg4i;
  logic [31:0] areg4o;
  logic areg4_wr;
  logic areg4_rd;
  logic areg4_wack;
  logic areg4_rack;
  modport master(
    input areg2,
    input areg4i,
    input areg4_wack,
    input areg4_rack,
    output areg1,
    output areg3,
    output areg3_wr,
    output areg4o,
    output areg4_wr,
    output areg4_rd
  );
  modport slave(
    output areg2,
    output areg4i,
    output areg4_wack,
    output areg4_rack,
    input areg1,
    input areg3,
    input areg3_wr,
    input areg4o,
    input areg4_wr,
    input areg4_rd
  );
endinterface


module iogroup1
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
    t_ios.master ios
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] areg1_reg;
  reg areg1_wreq;
  wire areg1_wack;
  reg [31:0] areg3_reg;
  reg areg3_wreq;
  wire areg3_wack;
  reg areg3_wstrb;
  reg areg4_wreq;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [3:2] wr_adr_d0;
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

  // Register areg1
  assign ios.areg1 = areg1_reg;
  assign areg1_wack = areg1_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      areg1_reg <= 32'b00000000000000000000000000000000;
    else
      if (areg1_wreq == 1'b1)
        areg1_reg <= wr_dat_d0;
  end

  // Register areg2

  // Register areg3
  assign ios.areg3 = areg3_reg;
  assign areg3_wack = areg3_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        areg3_reg <= 32'b00000000000000000000000000000000;
        areg3_wstrb <= 1'b0;
      end
    else
      begin
        if (areg3_wreq == 1'b1)
          areg3_reg <= wr_dat_d0;
        areg3_wstrb <= areg3_wreq;
      end
  end
  assign ios.areg3_wr = areg3_wstrb;

  // Register areg4
  assign ios.areg4o = wr_dat_d0;
  assign ios.areg4_wr = areg4_wreq;

  // Process for write requests.
  always_comb
  begin
    areg1_wreq = 1'b0;
    areg3_wreq = 1'b0;
    areg4_wreq = 1'b0;
    case (wr_adr_d0[3:2])
    2'b00:
      begin
        // Reg areg1
        areg1_wreq = wr_req_d0;
        wr_ack_int = areg1_wack;
      end
    2'b01:
      // Reg areg2
      wr_ack_int = wr_req_d0;
    2'b10:
      begin
        // Reg areg3
        areg3_wreq = wr_req_d0;
        wr_ack_int = areg3_wack;
      end
    2'b11:
      begin
        // Reg areg4
        areg4_wreq = wr_req_d0;
        wr_ack_int = ios.areg4_wack;
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
    ios.areg4_rd = 1'b0;
    case (wb_adr_i[3:2])
    2'b00:
      begin
        // Reg areg1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = areg1_reg;
      end
    2'b01:
      begin
        // Reg areg2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = ios.areg2;
      end
    2'b10:
      // Reg areg3
      rd_ack_d0 = rd_req_int;
    2'b11:
      begin
        // Reg areg4
        ios.areg4_rd = rd_req_int;
        rd_ack_d0 = ios.areg4_rack;
        rd_dat_d0 = ios.areg4i;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
