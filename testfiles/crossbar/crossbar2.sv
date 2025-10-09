interface t_clkpat;
  logic [31:0] ClkPatternLength;
  logic [7:2] ClkPattern_addr_o;
  logic [31:0] ClkPattern_data_i;
  logic [31:0] ClkPattern_data_o;
  logic ClkPattern_wr_o;
  modport master(
    input ClkPattern_data_i,
    output ClkPatternLength,
    output ClkPattern_addr_o,
    output ClkPattern_data_o,
    output ClkPattern_wr_o
  );
  modport slave(
    output ClkPattern_data_i,
    input ClkPatternLength,
    input ClkPattern_addr_o,
    input ClkPattern_data_o,
    input ClkPattern_wr_o
  );
endinterface


module crossbar_wb
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [8:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,
    t_clkpat.master clkpat
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg [31:0] ClkPatternBlock_ClkPatternLength_reg;
  reg ClkPatternBlock_ClkPatternLength_wreq;
  wire ClkPatternBlock_ClkPatternLength_wack;
  reg ClkPatternBlock_ClkPattern_rack;
  reg ClkPatternBlock_ClkPattern_re;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [8:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg ClkPatternBlock_ClkPattern_wp;
  wire ClkPatternBlock_ClkPattern_we;

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
        wr_adr_d0 <= 7'b0000000;
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

  // Register ClkPatternBlock_ClkPatternLength
  assign clkpat.ClkPatternLength = ClkPatternBlock_ClkPatternLength_reg;
  assign ClkPatternBlock_ClkPatternLength_wack = ClkPatternBlock_ClkPatternLength_wreq;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      ClkPatternBlock_ClkPatternLength_reg <= 32'b00000000000000000000000000000000;
    else
      if (ClkPatternBlock_ClkPatternLength_wreq == 1'b1)
        ClkPatternBlock_ClkPatternLength_reg <= wr_dat_d0;
  end

  // Interface ClkPatternBlock_ClkPattern
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      ClkPatternBlock_ClkPattern_rack <= 1'b0;
    else
      ClkPatternBlock_ClkPattern_rack <= ClkPatternBlock_ClkPattern_re & ~ClkPatternBlock_ClkPattern_rack;
  end
  assign clkpat.ClkPattern_data_o = wr_dat_d0;
  always_ff @(posedge(clk_i))
  begin
    if (!rst_n_i)
      ClkPatternBlock_ClkPattern_wp <= 1'b0;
    else
      ClkPatternBlock_ClkPattern_wp <= (wr_req_d0 | ClkPatternBlock_ClkPattern_wp) & rd_req_int;
  end
  assign ClkPatternBlock_ClkPattern_we = (wr_req_d0 | ClkPatternBlock_ClkPattern_wp) & ~rd_req_int;
  always_comb
  if (ClkPatternBlock_ClkPattern_re == 1'b1)
    clkpat.ClkPattern_addr_o = wb_adr_i[7:2];
  else
    clkpat.ClkPattern_addr_o = wr_adr_d0[7:2];

  // Process for write requests.
  always_comb
  begin
    ClkPatternBlock_ClkPatternLength_wreq = 1'b0;
    clkpat.ClkPattern_wr_o = 1'b0;
    case (wr_adr_d0[8:8])
    1'b0:
      case (wr_adr_d0[7:2])
      6'b000000:
        begin
          // Reg ClkPatternBlock_ClkPatternLength
          ClkPatternBlock_ClkPatternLength_wreq = wr_req_d0;
          wr_ack_int = ClkPatternBlock_ClkPatternLength_wack;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    1'b1:
      begin
        // Memory ClkPatternBlock_ClkPattern
        clkpat.ClkPattern_wr_o = ClkPatternBlock_ClkPattern_we;
        wr_ack_int = ClkPatternBlock_ClkPattern_we;
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
    ClkPatternBlock_ClkPattern_re = 1'b0;
    case (wb_adr_i[8:8])
    1'b0:
      case (wb_adr_i[7:2])
      6'b000000:
        begin
          // Reg ClkPatternBlock_ClkPatternLength
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = ClkPatternBlock_ClkPatternLength_reg;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    1'b1:
      begin
        // Memory ClkPatternBlock_ClkPattern
        rd_dat_d0 = clkpat.ClkPattern_data_i;
        rd_ack_d0 = ClkPatternBlock_ClkPattern_rack;
        ClkPatternBlock_ClkPattern_re = rd_req_int;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
