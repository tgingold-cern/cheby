interface t_io;
  logic ctrl_enable;
  logic [2:0] ctrl_mode;
  logic [7:0] ctrl_divisor;
  logic status_ready;
  logic [15:0] status_count;
  modport master(
    input status_ready,
    input status_count,
    output ctrl_enable,
    output ctrl_mode,
    output ctrl_divisor
  );
  modport slave(
    output status_ready,
    output status_count,
    input ctrl_enable,
    input ctrl_mode,
    input ctrl_divisor
  );
endinterface


module reuse_submap_leaf
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
    // Wires and registers
    t_io.master io
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg ctrl_enable_reg;
  reg [2:0] ctrl_mode_reg;
  reg [7:0] ctrl_divisor_reg;
  reg ctrl_wreq;
  wire ctrl_wack;
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

  // Register ctrl
  assign io.ctrl_enable = ctrl_enable_reg;
  assign io.ctrl_mode = ctrl_mode_reg;
  assign io.ctrl_divisor = ctrl_divisor_reg;
  assign ctrl_wack = ctrl_wreq;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        ctrl_enable_reg <= 1'b0;
        ctrl_mode_reg <= 3'b000;
        ctrl_divisor_reg <= 8'b00000000;
      end
    else
      if (ctrl_wreq == 1'b1)
        begin
          ctrl_enable_reg <= wr_dat_d0[0];
          ctrl_mode_reg <= wr_dat_d0[3:1];
          ctrl_divisor_reg <= wr_dat_d0[15:8];
        end
  end

  // Register status

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, ctrl_wack)
  begin
    ctrl_wreq = 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      begin
        // Reg ctrl
        ctrl_wreq = wr_req_d0;
        wr_ack_int = ctrl_wack;
      end
    1'b1:
      // Reg status
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, ctrl_enable_reg, ctrl_mode_reg, ctrl_divisor_reg, io.status_ready, io.status_count)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (wb_adr_i[2:2])
    1'b0:
      begin
        // Reg ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0[0] = ctrl_enable_reg;
        rd_dat_d0[3:1] = ctrl_mode_reg;
        rd_dat_d0[7:4] = 4'b0;
        rd_dat_d0[15:8] = ctrl_divisor_reg;
        rd_dat_d0[31:16] = 16'b0;
      end
    1'b1:
      begin
        // Reg status
        rd_ack_d0 = rd_req_int;
        rd_dat_d0[0] = io.status_ready;
        rd_dat_d0[15:1] = 15'b0;
        rd_dat_d0[31:16] = io.status_count;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
