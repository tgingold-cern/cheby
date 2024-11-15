
module mem64ro
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [7:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // REG regA
    output  wire regA_field0_o,

    // SRAM bus ts
    output  wire [6:2] ts_addr_o,
    input   wire [31:0] ts_data_i
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg regA_field0_reg;
  reg regA_wreq;
  wire regA_wack;
  reg ts_rack;
  reg ts_re;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [7:2] wr_adr_d0;
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
        wr_adr_d0 <= 6'b000000;
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

  // Register regA
  assign regA_field0_o = regA_field0_reg;
  assign regA_wack = regA_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      regA_field0_reg <= 1'b0;
    else
      if (regA_wreq == 1'b1)
        regA_field0_reg <= wr_dat_d0[1];
  end

  // Interface ts
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      ts_rack <= 1'b0;
    else
      ts_rack <= ts_re & ~ts_rack;
  end
  assign ts_addr_o = wb_adr_i[6:2];

  // Process for write requests.
  always_comb
  begin
    regA_wreq = 1'b0;
    case (wr_adr_d0[7:7])
    1'b0:
      case (wr_adr_d0[6:2])
      5'b00000:
        begin
          // Reg regA
          regA_wreq = wr_req_d0;
          wr_ack_int = regA_wack;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    1'b1:
      // Memory ts
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
    ts_re = 1'b0;
    case (wb_adr_i[7:7])
    1'b0:
      case (wb_adr_i[6:2])
      5'b00000:
        begin
          // Reg regA
          rd_ack_d0 = rd_req_int;
          rd_dat_d0[0] = 1'b0;
          rd_dat_d0[1] = regA_field0_reg;
          rd_dat_d0[31:2] = 30'b0;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    1'b1:
      begin
        // Memory ts
        rd_dat_d0 = ts_data_i;
        rd_ack_d0 = ts_rack;
        ts_re = rd_req_int;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
