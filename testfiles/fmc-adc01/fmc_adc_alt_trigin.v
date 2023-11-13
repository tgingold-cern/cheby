
module alt_trigin
  (
    t_wishbone.slave wb,

    // Control register
    // Enable trigger, cleared when triggered
    input   wire ctrl_enable_i,
    output  wire ctrl_enable_o,
    output  wire ctrl_wr_o,

    // Time (seconds) to trigger
    input   wire [63:0] seconds_i,

    // Time (cycles) to trigger
    input   wire [31:0] cycles_i
  );
  wire [4:2] adr_int;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg ctrl_wreq;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [4:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always @(wb.sel)
  ;
  assign adr_int = wb.adr[4:2];
  assign wb_en = wb.cyc & wb.stb;

  always @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb.we)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb.we) & ~wb_rip;

  always @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb.we)) & ~wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb.we) & ~wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb.ack = ack_int;
  assign wb.stall = ~ack_int & wb_en;
  assign wb.rty = 1'b0;
  assign wb.err = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      begin
        rd_ack_int <= 1'b0;
        wb.dati <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 3'b000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb.dati <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb.dato;
      end
  end

  // Register ctrl
  assign ctrl_enable_o = wr_dat_d0[1];
  assign ctrl_wr_o = ctrl_wreq;

  // Register seconds

  // Register cycles

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0)
  begin
    ctrl_wreq = 1'b0;
    case (wr_adr_d0[4:3])
    2'b00:
      case (wr_adr_d0[2:2])
      1'b0:
        begin
          // Reg ctrl
          ctrl_wreq = wr_req_d0;
          wr_ack_int = wr_req_d0;
        end
      default:
        wr_ack_int = wr_req_d0;
      endcase
    2'b01:
      case (wr_adr_d0[2:2])
      1'b0:
        // Reg seconds
        wr_ack_int = wr_req_d0;
      1'b1:
        // Reg seconds
        wr_ack_int = wr_req_d0;
      default:
        wr_ack_int = wr_req_d0;
      endcase
    2'b10:
      case (wr_adr_d0[2:2])
      1'b0:
        // Reg cycles
        wr_ack_int = wr_req_d0;
      default:
        wr_ack_int = wr_req_d0;
      endcase
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(adr_int, rd_req_int, ctrl_enable_i, seconds_i, cycles_i)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (adr_int[4:3])
    2'b00:
      case (adr_int[2:2])
      1'b0:
        begin
          // Reg ctrl
          rd_ack_d0 = rd_req_int;
          rd_dat_d0[0] = 1'b0;
          rd_dat_d0[1] = ctrl_enable_i;
          rd_dat_d0[31:2] = 30'b0;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    2'b01:
      case (adr_int[2:2])
      1'b0:
        begin
          // Reg seconds
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = seconds_i[63:32];
        end
      1'b1:
        begin
          // Reg seconds
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = seconds_i[31:0];
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    2'b10:
      case (adr_int[2:2])
      1'b0:
        begin
          // Reg cycles
          rd_ack_d0 = rd_req_int;
          rd_dat_d0 = cycles_i;
        end
      default:
        rd_ack_d0 = rd_req_int;
      endcase
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
