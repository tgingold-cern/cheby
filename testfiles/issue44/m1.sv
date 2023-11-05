
module m1
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [13:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // CERN-BE bus m0
    output  reg [12:2] m0_VMEAddr_o,
    input   wire [31:0] m0_VMERdData_i,
    output  wire [31:0] m0_VMEWrData_o,
    output  reg m0_VMERdMem_o,
    output  wire m0_VMEWrMem_o,
    input   wire m0_VMERdDone_i,
    input   wire m0_VMEWrDone_i,

    // CERN-BE bus m1
    output  reg [11:2] m1_VMEAddr_o,
    input   wire [31:0] m1_VMERdData_i,
    output  wire [31:0] m1_VMEWrData_o,
    output  reg m1_VMERdMem_o,
    output  wire m1_VMEWrMem_o,
    input   wire m1_VMERdDone_i,
    input   wire m1_VMEWrDone_i,

    // CERN-BE bus m2
    output  reg [11:2] m2_VMEAddr_o,
    input   wire [31:0] m2_VMERdData_i,
    output  wire [31:0] m2_VMEWrData_o,
    output  reg m2_VMERdMem_o,
    output  wire m2_VMEWrMem_o,
    input   wire m2_VMERdDone_i,
    input   wire m2_VMEWrDone_i
  );
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [13:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg m0_ws;
  reg m0_wt;
  reg m1_ws;
  reg m1_wt;
  reg m2_ws;
  reg m2_wt;

  // WB decode signals
  always @(wb_sel_i)
      ;
  assign wb_en = wb_cyc_i & wb_stb_i;

  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & !wb_we_i)) & !rd_ack_int;
  end
  assign rd_req_int = (wb_en & !wb_we_i) & !wb_rip;

  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb_we_i)) & !wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb_we_i) & !wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb_ack_o = ack_int;
  assign wb_stall_o = !ack_int & wb_en;
  assign wb_rty_o = 1'b0;
  assign wb_err_o = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
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

  // Interface m0
  assign m0_VMEWrData_o = wr_dat_d0;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      m0_wt <= 1'b0;
    else
      m0_wt <= (m0_wt | m0_ws) & !m0_VMEWrDone_i;
  end
  assign m0_VMEWrMem_o = m0_ws;
  always @(wb_adr_i, wr_adr_d0, m0_wt, m0_ws)
      if ((m0_ws | m0_wt) == 1'b1)
        m0_VMEAddr_o <= wr_adr_d0[12:2];
      else
        m0_VMEAddr_o <= wb_adr_i[12:2];

  // Interface m1
  assign m1_VMEWrData_o = wr_dat_d0;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      m1_wt <= 1'b0;
    else
      m1_wt <= (m1_wt | m1_ws) & !m1_VMEWrDone_i;
  end
  assign m1_VMEWrMem_o = m1_ws;
  always @(wb_adr_i, wr_adr_d0, m1_wt, m1_ws)
      if ((m1_ws | m1_wt) == 1'b1)
        m1_VMEAddr_o <= wr_adr_d0[11:2];
      else
        m1_VMEAddr_o <= wb_adr_i[11:2];

  // Interface m2
  assign m2_VMEWrData_o = wr_dat_d0;
  always @(posedge(clk_i) or negedge(rst_n_i))
  begin
    if (!rst_n_i)
      m2_wt <= 1'b0;
    else
      m2_wt <= (m2_wt | m2_ws) & !m2_VMEWrDone_i;
  end
  assign m2_VMEWrMem_o = m2_ws;
  always @(wb_adr_i, wr_adr_d0, m2_wt, m2_ws)
      if ((m2_ws | m2_wt) == 1'b1)
        m2_VMEAddr_o <= wr_adr_d0[11:2];
      else
        m2_VMEAddr_o <= wb_adr_i[11:2];

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, m0_VMEWrDone_i, m1_VMEWrDone_i, m2_VMEWrDone_i)
      begin
        m0_ws <= 1'b0;
        m1_ws <= 1'b0;
        m2_ws <= 1'b0;
        case (wr_adr_d0[13:13])
        1'b0:
          begin
            // Memory m0
            m0_ws <= wr_req_d0;
            wr_ack_int <= m0_VMEWrDone_i;
          end
        1'b1:
          case (wr_adr_d0[12:12])
          1'b0:
            begin
              // Memory m1
              m1_ws <= wr_req_d0;
              wr_ack_int <= m1_VMEWrDone_i;
            end
          1'b1:
            begin
              // Memory m2
              m2_ws <= wr_req_d0;
              wr_ack_int <= m2_VMEWrDone_i;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(wb_adr_i, rd_req_int, m0_VMERdData_i, m0_VMERdDone_i, m1_VMERdData_i, m1_VMERdDone_i, m2_VMERdData_i, m2_VMERdDone_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        m0_VMERdMem_o <= 1'b0;
        m1_VMERdMem_o <= 1'b0;
        m2_VMERdMem_o <= 1'b0;
        case (wb_adr_i[13:13])
        1'b0:
          begin
            // Memory m0
            m0_VMERdMem_o <= rd_req_int;
            rd_dat_d0 <= m0_VMERdData_i;
            rd_ack_d0 <= m0_VMERdDone_i;
          end
        1'b1:
          case (wb_adr_i[12:12])
          1'b0:
            begin
              // Memory m1
              m1_VMERdMem_o <= rd_req_int;
              rd_dat_d0 <= m1_VMERdData_i;
              rd_ack_d0 <= m1_VMERdDone_i;
            end
          1'b1:
            begin
              // Memory m2
              m2_VMERdMem_o <= rd_req_int;
              rd_dat_d0 <= m2_VMERdData_i;
              rd_ack_d0 <= m2_VMERdDone_i;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
