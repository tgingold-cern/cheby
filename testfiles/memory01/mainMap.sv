
module mainMap
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [19:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // RAM port for acqVP
    input   wire [8:0] acqVP_adr_i,
    input   wire acqVP_value_we_i,
    input   wire [15:0] acqVP_value_dat_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  wire [15:0] acqVP_value_int_dato;
  wire [15:0] acqVP_value_ext_dat;
  reg acqVP_value_rreq;
  reg acqVP_value_rack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
      end
  end

  // Memory acqVP
  cheby_dpssram #(
      .g_data_width(16),
      .g_size(512),
      .g_addr_width(9),
      .g_dual_clock(1'b0),
      .g_use_bwsel(1'b0)
    )
  acqVP_value_raminst (
      .clk_a_i(Clk),
      .clk_b_i(Clk),
      .addr_a_i(VMEAddr[10:2]),
      .bwsel_a_i({2{1'b1}}),
      .data_a_i({16{1'bx}}),
      .data_a_o(acqVP_value_int_dato),
      .rd_a_i(acqVP_value_rreq),
      .wr_a_i(1'b0),
      .addr_b_i(acqVP_adr_i),
      .bwsel_b_i({2{1'b1}}),
      .data_b_i(acqVP_value_dat_i),
      .data_b_o(acqVP_value_ext_dat),
      .rd_b_i(1'b0),
      .wr_b_i(acqVP_value_we_i)
    );
  
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      acqVP_value_rack <= 1'b0;
    else
      acqVP_value_rack <= acqVP_value_rreq;
  end

  // Process for write requests.
  always @(wr_req_d0)
      // Memory acqVP
      wr_ack_int <= wr_req_d0;

  // Process for read requests.
  always @(acqVP_value_int_dato, VMERdMem, acqVP_value_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        acqVP_value_rreq <= 1'b0;
        // Memory acqVP
        rd_dat_d0 <= {16'b0000000000000000, acqVP_value_int_dato};
        acqVP_value_rreq <= VMERdMem;
        rd_ack_d0 <= acqVP_value_rack;
      end
endmodule
