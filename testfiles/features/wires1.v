
module wires1
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

    // REG strobe
    output  wire [31:0] strobe_o,
    output  wire strobe_wr_o,
    output  reg strobe_rd_o,

    // REG wires
    input   wire [31:0] wires_i,
    output  wire [31:0] wires_o,
    output  reg wires_rd_o,

    // REG acks
    input   wire [31:0] acks_i,
    output  wire [31:0] acks_o,
    output  wire acks_wr_o,
    output  reg acks_rd_o,
    input   wire acks_wack_i,
    input   wire acks_rack_i
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] strobe_reg;
  reg strobe_wreq;
  wire strobe_wack;
  reg strobe_wstrb;
  reg acks_wreq;
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

  // Register strobe
  assign strobe_o = strobe_reg;
  assign strobe_wack = strobe_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        strobe_reg <= 32'b00000000000000000000000000000000;
        strobe_wstrb <= 1'b0;
      end
    else
      begin
        if (strobe_wreq == 1'b1)
          strobe_reg <= wr_dat_d0;
        strobe_wstrb <= strobe_wreq;
      end
  end
  assign strobe_wr_o = strobe_wstrb;

  // Register wires
  assign wires_o = wr_dat_d0;

  // Register acks
  assign acks_o = wr_dat_d0;
  assign acks_wr_o = acks_wreq;

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, strobe_wack, acks_wack_i)
  begin
    strobe_wreq = 1'b0;
    acks_wreq = 1'b0;
    case (wr_adr_d0[3:2])
    2'b00:
      begin
        // Reg strobe
        strobe_wreq = wr_req_d0;
        wr_ack_int = strobe_wack;
      end
    2'b01:
      // Reg wires
      wr_ack_int = wr_req_d0;
    2'b10:
      begin
        // Reg acks
        acks_wreq = wr_req_d0;
        wr_ack_int = acks_wack_i;
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, strobe_reg, wires_i, acks_rack_i, acks_i)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    strobe_rd_o = 1'b0;
    wires_rd_o = 1'b0;
    acks_rd_o = 1'b0;
    case (wb_adr_i[3:2])
    2'b00:
      begin
        // Reg strobe
        strobe_rd_o = rd_req_int;
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = strobe_reg;
      end
    2'b01:
      begin
        // Reg wires
        wires_rd_o = rd_req_int;
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = wires_i;
      end
    2'b10:
      begin
        // Reg acks
        acks_rd_o = rd_req_int;
        rd_ack_d0 = acks_rack_i;
        rd_dat_d0 = acks_i;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
