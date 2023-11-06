
module map1
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [7:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // RAM port for m1
    input   wire [5:0] m1_adr_i,
    input   wire m1_r1_rd_i,
    output  wire [15:0] m1_r1_dat_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  wire [15:0] m1_r1_int_dato;
  wire [15:0] m1_r1_ext_dat;
  reg m1_r1_rreq;
  reg m1_r1_rack;
  reg m1_r1_int_wr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [7:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  wire m1_wr;
  wire m1_wreq;
  reg [5:0] m1_adr_int;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 6'b000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end
  end

  // Memory m1
  always @(VMEAddr, wr_adr_d0, m1_wr)
      if (m1_wr == 1'b1)
        m1_adr_int <= wr_adr_d0[7:2];
      else
        m1_adr_int <= VMEAddr[7:2];
  assign m1_wreq = m1_r1_int_wr;
  assign m1_wr = m1_wreq;
  cheby_dpssram #(
      .g_data_width(16),
      .g_size(64),
      .g_addr_width(6),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b0)
    )
  m1_r1_raminst (
      .clk_a_i(Clk),
      .clk_b_i(Clk),
      .addr_a_i(m1_adr_int),
      .bwsel_a_i({2{1'b1}}),
      .data_a_i(wr_dat_d0[15:0]),
      .data_a_o(m1_r1_int_dato),
      .rd_a_i(m1_r1_rreq),
      .wr_a_i(m1_r1_int_wr),
      .addr_b_i(m1_adr_i),
      .bwsel_b_i({2{1'b1}}),
      .data_b_i(m1_r1_ext_dat),
      .data_b_o(m1_r1_dat_o),
      .rd_b_i(m1_r1_rd_i),
      .wr_b_i(1'b0)
    );
  
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      m1_r1_rack <= 1'b0;
    else
      m1_r1_rack <= m1_r1_rreq;
  end

  // Process for write requests.
  always @(wr_req_d0)
      begin
        m1_r1_int_wr <= 1'b0;
        // Memory m1
        m1_r1_int_wr <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      end

  // Process for read requests.
  always @(m1_r1_int_dato, VMERdMem, m1_r1_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        m1_r1_rreq <= 1'b0;
        // Memory m1
        rd_dat_d0 <= {16'b0000000000000000, m1_r1_int_dato};
        m1_r1_rreq <= VMERdMem;
        rd_ack_d0 <= m1_r1_rack;
      end
endmodule
