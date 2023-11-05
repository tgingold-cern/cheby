
module qsm_regs
  (
    t_wishbone.slave wb,

    // Control register
    // Send the Reset state to DIM
    output  wire regs_0_control_reset_o,
    // Trigger DIM readout
    output  wire regs_0_control_trig_o,
    // Address of last DIM register (number of registers - 1)
    output  wire [3:0] regs_0_control_last_reg_adr_o,
    // Maximum number of devices present on line
    output  wire [3:0] regs_0_control_max_dim_no_o,
    // Delay between consecutive register reads in microseconds (usually 512 us)
    output  wire [9:0] regs_0_control_read_delay_o,

    // Status register
    // QSPI master is busy (either in RESET or READOUT)
    input   wire regs_0_status_busy_i,
    // QSPI master has finished DIM readout
    input   wire regs_0_status_done_i,
    // Too many devices on DIM line (more than set by 'max_dim_no' register)
    input   wire regs_0_status_err_many_i,
    // Detected error on QSPI fb line
    input   wire regs_0_status_err_fb_i,
    // Detected number of DIM devices (can be lower than 'max_dim_no')
    input   wire [3:0] regs_0_status_dim_count_i,

    // Control register
    // Send the Reset state to DIM
    output  wire regs_1_control_reset_o,
    // Trigger DIM readout
    output  wire regs_1_control_trig_o,
    // Address of last DIM register (number of registers - 1)
    output  wire [3:0] regs_1_control_last_reg_adr_o,
    // Maximum number of devices present on line
    output  wire [3:0] regs_1_control_max_dim_no_o,
    // Delay between consecutive register reads in microseconds (usually 512 us)
    output  wire [9:0] regs_1_control_read_delay_o,

    // Status register
    // QSPI master is busy (either in RESET or READOUT)
    input   wire regs_1_status_busy_i,
    // QSPI master has finished DIM readout
    input   wire regs_1_status_done_i,
    // Too many devices on DIM line (more than set by 'max_dim_no' register)
    input   wire regs_1_status_err_many_i,
    // Detected error on QSPI fb line
    input   wire regs_1_status_err_fb_i,
    // Detected number of DIM devices (can be lower than 'max_dim_no')
    input   wire [3:0] regs_1_status_dim_count_i,

    // SRAM bus memory_0_mem_readout
    output  wire [8:2] memory_0_mem_readout_addr_o,
    input   wire [15:0] memory_0_mem_readout_data_i,

    // SRAM bus memory_1_mem_readout
    output  wire [8:2] memory_1_mem_readout_addr_o,
    input   wire [15:0] memory_1_mem_readout_data_i
  );
  wire [10:2] adr_int;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg regs_0_control_reset_reg;
  reg regs_0_control_trig_reg;
  reg [3:0] regs_0_control_last_reg_adr_reg;
  reg [3:0] regs_0_control_max_dim_no_reg;
  reg [9:0] regs_0_control_read_delay_reg;
  reg regs_0_control_wreq;
  reg regs_0_control_wack;
  reg regs_1_control_reset_reg;
  reg regs_1_control_trig_reg;
  reg [3:0] regs_1_control_last_reg_adr_reg;
  reg [3:0] regs_1_control_max_dim_no_reg;
  reg [9:0] regs_1_control_read_delay_reg;
  reg regs_1_control_wreq;
  reg regs_1_control_wack;
  reg memory_0_mem_readout_rack;
  reg memory_0_mem_readout_re;
  reg memory_1_mem_readout_rack;
  reg memory_1_mem_readout_re;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [10:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always @(wb.sel)
      ;
  assign adr_int = wb.adr[10:2];
  assign wb_en = wb.cyc & wb.stb;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & !wb.we)) & !rd_ack_int;
  end
  assign rd_req_int = (wb_en & !wb.we) & !wb_rip;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb.we)) & !wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb.we) & !wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb.ack = ack_int;
  assign wb.stall = !ack_int & wb_en;
  assign wb.rty = 1'b0;
  assign wb.err = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
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

  // Register regs_0_control
  assign regs_0_control_reset_o = regs_0_control_reset_reg;
  assign regs_0_control_trig_o = regs_0_control_trig_reg;
  assign regs_0_control_last_reg_adr_o = regs_0_control_last_reg_adr_reg;
  assign regs_0_control_max_dim_no_o = regs_0_control_max_dim_no_reg;
  assign regs_0_control_read_delay_o = regs_0_control_read_delay_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        regs_0_control_reset_reg <= 1'b0;
        regs_0_control_trig_reg <= 1'b0;
        regs_0_control_last_reg_adr_reg <= 4'b0000;
        regs_0_control_max_dim_no_reg <= 4'b0000;
        regs_0_control_read_delay_reg <= 10'b0000000000;
        regs_0_control_wack <= 1'b0;
      end
    else
      begin
        if (regs_0_control_wreq == 1'b1)
          begin
            regs_0_control_reset_reg <= wr_dat_d0[0];
            regs_0_control_trig_reg <= wr_dat_d0[1];
            regs_0_control_last_reg_adr_reg <= wr_dat_d0[5:2];
            regs_0_control_max_dim_no_reg <= wr_dat_d0[9:6];
            regs_0_control_read_delay_reg <= wr_dat_d0[19:10];
          end
        else
          begin
            regs_0_control_reset_reg <= 1'b0;
            regs_0_control_trig_reg <= 1'b0;
          end
        regs_0_control_wack <= regs_0_control_wreq;
      end
  end

  // Register regs_0_status

  // Register regs_1_control
  assign regs_1_control_reset_o = regs_1_control_reset_reg;
  assign regs_1_control_trig_o = regs_1_control_trig_reg;
  assign regs_1_control_last_reg_adr_o = regs_1_control_last_reg_adr_reg;
  assign regs_1_control_max_dim_no_o = regs_1_control_max_dim_no_reg;
  assign regs_1_control_read_delay_o = regs_1_control_read_delay_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        regs_1_control_reset_reg <= 1'b0;
        regs_1_control_trig_reg <= 1'b0;
        regs_1_control_last_reg_adr_reg <= 4'b0000;
        regs_1_control_max_dim_no_reg <= 4'b0000;
        regs_1_control_read_delay_reg <= 10'b0000000000;
        regs_1_control_wack <= 1'b0;
      end
    else
      begin
        if (regs_1_control_wreq == 1'b1)
          begin
            regs_1_control_reset_reg <= wr_dat_d0[0];
            regs_1_control_trig_reg <= wr_dat_d0[1];
            regs_1_control_last_reg_adr_reg <= wr_dat_d0[5:2];
            regs_1_control_max_dim_no_reg <= wr_dat_d0[9:6];
            regs_1_control_read_delay_reg <= wr_dat_d0[19:10];
          end
        else
          begin
            regs_1_control_reset_reg <= 1'b0;
            regs_1_control_trig_reg <= 1'b0;
          end
        regs_1_control_wack <= regs_1_control_wreq;
      end
  end

  // Register regs_1_status

  // Interface memory_0_mem_readout
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      memory_0_mem_readout_rack <= 1'b0;
    else
      memory_0_mem_readout_rack <= memory_0_mem_readout_re & !memory_0_mem_readout_rack;
  end
  assign memory_0_mem_readout_addr_o = adr_int[8:2];

  // Interface memory_1_mem_readout
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      memory_1_mem_readout_rack <= 1'b0;
    else
      memory_1_mem_readout_rack <= memory_1_mem_readout_re & !memory_1_mem_readout_rack;
  end
  assign memory_1_mem_readout_addr_o = adr_int[8:2];

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, regs_0_control_wack, regs_1_control_wack)
      begin
        regs_0_control_wreq <= 1'b0;
        regs_1_control_wreq <= 1'b0;
        case (wr_adr_d0[10:9])
        2'b00:
          case (wr_adr_d0[8:2])
          7'b0000000:
            begin
              // Reg regs_0_control
              regs_0_control_wreq <= wr_req_d0;
              wr_ack_int <= regs_0_control_wack;
            end
          7'b0000001:
            // Reg regs_0_status
            wr_ack_int <= wr_req_d0;
          7'b0000010:
            begin
              // Reg regs_1_control
              regs_1_control_wreq <= wr_req_d0;
              wr_ack_int <= regs_1_control_wack;
            end
          7'b0000011:
            // Reg regs_1_status
            wr_ack_int <= wr_req_d0;
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        2'b10:
          // Memory memory_0_mem_readout
          wr_ack_int <= wr_req_d0;
        2'b11:
          // Memory memory_1_mem_readout
          wr_ack_int <= wr_req_d0;
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(adr_int, rd_req_int, regs_0_control_last_reg_adr_reg, regs_0_control_max_dim_no_reg, regs_0_control_read_delay_reg, regs_0_status_busy_i, regs_0_status_done_i, regs_0_status_err_many_i, regs_0_status_err_fb_i, regs_0_status_dim_count_i, regs_1_control_last_reg_adr_reg, regs_1_control_max_dim_no_reg, regs_1_control_read_delay_reg, regs_1_status_busy_i, regs_1_status_done_i, regs_1_status_err_many_i, regs_1_status_err_fb_i, regs_1_status_dim_count_i, memory_0_mem_readout_data_i, memory_0_mem_readout_rack, memory_1_mem_readout_data_i, memory_1_mem_readout_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        memory_0_mem_readout_re <= 1'b0;
        memory_1_mem_readout_re <= 1'b0;
        case (adr_int[10:9])
        2'b00:
          case (adr_int[8:2])
          7'b0000000:
            begin
              // Reg regs_0_control
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= 1'b0;
              rd_dat_d0[1] <= 1'b0;
              rd_dat_d0[5:2] <= regs_0_control_last_reg_adr_reg;
              rd_dat_d0[9:6] <= regs_0_control_max_dim_no_reg;
              rd_dat_d0[19:10] <= regs_0_control_read_delay_reg;
              rd_dat_d0[31:20] <= 12'b0;
            end
          7'b0000001:
            begin
              // Reg regs_0_status
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= regs_0_status_busy_i;
              rd_dat_d0[1] <= regs_0_status_done_i;
              rd_dat_d0[2] <= regs_0_status_err_many_i;
              rd_dat_d0[3] <= regs_0_status_err_fb_i;
              rd_dat_d0[7:4] <= regs_0_status_dim_count_i;
              rd_dat_d0[31:8] <= 24'b0;
            end
          7'b0000010:
            begin
              // Reg regs_1_control
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= 1'b0;
              rd_dat_d0[1] <= 1'b0;
              rd_dat_d0[5:2] <= regs_1_control_last_reg_adr_reg;
              rd_dat_d0[9:6] <= regs_1_control_max_dim_no_reg;
              rd_dat_d0[19:10] <= regs_1_control_read_delay_reg;
              rd_dat_d0[31:20] <= 12'b0;
            end
          7'b0000011:
            begin
              // Reg regs_1_status
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= regs_1_status_busy_i;
              rd_dat_d0[1] <= regs_1_status_done_i;
              rd_dat_d0[2] <= regs_1_status_err_many_i;
              rd_dat_d0[3] <= regs_1_status_err_fb_i;
              rd_dat_d0[7:4] <= regs_1_status_dim_count_i;
              rd_dat_d0[31:8] <= 24'b0;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        2'b10:
          begin
            // Memory memory_0_mem_readout
            rd_dat_d0[15:0] <= memory_0_mem_readout_data_i;
            rd_ack_d0 <= memory_0_mem_readout_rack;
            memory_0_mem_readout_re <= rd_req_int;
          end
        2'b11:
          begin
            // Memory memory_1_mem_readout
            rd_dat_d0[15:0] <= memory_1_mem_readout_data_i;
            rd_ack_d0 <= memory_1_mem_readout_rack;
            memory_1_mem_readout_re <= rd_req_int;
          end
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
