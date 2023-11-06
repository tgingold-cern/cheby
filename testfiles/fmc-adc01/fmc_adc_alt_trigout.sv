
module alt_trigout
  (
    t_wishbone.slave wb,

    // Status register
    // Set when WR is enabled
    input   wire wr_enable_i,
    // WR link status
    input   wire wr_link_i,
    // Set when WR time is valid
    input   wire wr_valid_i,
    // Set when the timestamp fifo is not empty
    input   wire ts_present_i,

    // Control register
    // Enable channel 1 trigger
    output  wire ch1_enable_o,
    // Enable channel 2 trigger
    output  wire ch2_enable_o,
    // Enable channel 3 trigger
    output  wire ch3_enable_o,
    // Enable channel 4 trigger
    output  wire ch4_enable_o,
    // Enable external trigger
    output  wire ext_enable_o,

    // Time (seconds) of the last event
    // Seconds part of the timestamp
    input   wire [39:0] ts_sec_i,
    // Set if channel 1 triggered
    input   wire ch1_mask_i,
    // Set if channel 2 triggered
    input   wire ch2_mask_i,
    // Set if channel 3 triggered
    input   wire ch3_mask_i,
    // Set if channel 4 triggered
    input   wire ch4_mask_i,
    // Set if external trigger
    input   wire ext_mask_i,

    // Reading this register discard the entry
    // Cycles
    input   wire [27:0] cycles_i,
    output  reg ts_cycles_rd_o
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
  reg ch1_enable_reg;
  reg ch2_enable_reg;
  reg ch3_enable_reg;
  reg ch4_enable_reg;
  reg ext_enable_reg;
  reg ctrl_wreq;
  reg ctrl_wack;
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

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb.we)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb.we) & ~wb_rip;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
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
  always @(posedge(wb.clk) or negedge(wb.rst_n))
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

  // Register status

  // Register ctrl
  assign ch1_enable_o = ch1_enable_reg;
  assign ch2_enable_o = ch2_enable_reg;
  assign ch3_enable_o = ch3_enable_reg;
  assign ch4_enable_o = ch4_enable_reg;
  assign ext_enable_o = ext_enable_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        ch1_enable_reg <= 1'b0;
        ch2_enable_reg <= 1'b0;
        ch3_enable_reg <= 1'b0;
        ch4_enable_reg <= 1'b0;
        ext_enable_reg <= 1'b0;
        ctrl_wack <= 1'b0;
      end
    else
      begin
        if (ctrl_wreq == 1'b1)
          begin
            ch1_enable_reg <= wr_dat_d0[0];
            ch2_enable_reg <= wr_dat_d0[1];
            ch3_enable_reg <= wr_dat_d0[2];
            ch4_enable_reg <= wr_dat_d0[3];
            ext_enable_reg <= wr_dat_d0[8];
          end
        ctrl_wack <= ctrl_wreq;
      end
  end

  // Register ts_mask_sec

  // Register ts_cycles

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, ctrl_wack)
      begin
        ctrl_wreq <= 1'b0;
        case (wr_adr_d0[4:3])
        2'b00:
          case (wr_adr_d0[2:2])
          1'b0:
            // Reg status
            wr_ack_int <= wr_req_d0;
          1'b1:
            begin
              // Reg ctrl
              ctrl_wreq <= wr_req_d0;
              wr_ack_int <= ctrl_wack;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        2'b01:
          case (wr_adr_d0[2:2])
          1'b0:
            // Reg ts_mask_sec
            wr_ack_int <= wr_req_d0;
          1'b1:
            // Reg ts_mask_sec
            wr_ack_int <= wr_req_d0;
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        2'b10:
          case (wr_adr_d0[2:2])
          1'b0:
            // Reg ts_cycles
            wr_ack_int <= wr_req_d0;
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(adr_int, rd_req_int, wr_enable_i, wr_link_i, wr_valid_i, ts_present_i, ch1_enable_reg, ch2_enable_reg, ch3_enable_reg, ch4_enable_reg, ext_enable_reg, ts_sec_i, ch1_mask_i, ch2_mask_i, ch3_mask_i, ch4_mask_i, ext_mask_i, cycles_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        ts_cycles_rd_o <= 1'b0;
        case (adr_int[4:3])
        2'b00:
          case (adr_int[2:2])
          1'b0:
            begin
              // Reg status
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= wr_enable_i;
              rd_dat_d0[1] <= wr_link_i;
              rd_dat_d0[2] <= wr_valid_i;
              rd_dat_d0[7:3] <= 5'b0;
              rd_dat_d0[8] <= ts_present_i;
              rd_dat_d0[31:9] <= 23'b0;
            end
          1'b1:
            begin
              // Reg ctrl
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= ch1_enable_reg;
              rd_dat_d0[1] <= ch2_enable_reg;
              rd_dat_d0[2] <= ch3_enable_reg;
              rd_dat_d0[3] <= ch4_enable_reg;
              rd_dat_d0[7:4] <= 4'b0;
              rd_dat_d0[8] <= ext_enable_reg;
              rd_dat_d0[31:9] <= 23'b0;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        2'b01:
          case (adr_int[2:2])
          1'b0:
            begin
              // Reg ts_mask_sec
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[7:0] <= ts_sec_i[39:32];
              rd_dat_d0[15:8] <= 8'b0;
              rd_dat_d0[16] <= ch1_mask_i;
              rd_dat_d0[17] <= ch2_mask_i;
              rd_dat_d0[18] <= ch3_mask_i;
              rd_dat_d0[19] <= ch4_mask_i;
              rd_dat_d0[23:20] <= 4'b0;
              rd_dat_d0[24] <= ext_mask_i;
              rd_dat_d0[31:25] <= 7'b0;
            end
          1'b1:
            begin
              // Reg ts_mask_sec
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= ts_sec_i[31:0];
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        2'b10:
          case (adr_int[2:2])
          1'b0:
            begin
              // Reg ts_cycles
              ts_cycles_rd_o <= rd_req_int;
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[27:0] <= cycles_i;
              rd_dat_d0[31:28] <= 4'b0;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
