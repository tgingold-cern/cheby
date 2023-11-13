
module xilinx_attrs
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [2:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // CERN-BE bus subm
    output  reg [2:2] subm_VMEAddr_o,
    input   wire [31:0] subm_VMERdData_i,
    output  wire [31:0] subm_VMEWrData_o,
    output  reg subm_VMERdMem_o,
    output  wire subm_VMEWrMem_o,
    input   wire subm_VMERdDone_i,
    input   wire subm_VMEWrDone_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg subm_ws;
  reg subm_wt;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
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

  // Interface subm
  assign subm_VMEWrData_o = wr_dat_d0;
  always @(posedge(Clk))
  begin
    if (!rst_n)
      subm_wt <= 1'b0;
    else
      subm_wt <= (subm_wt | subm_ws) & ~subm_VMEWrDone_i;
  end
  assign subm_VMEWrMem_o = subm_ws;
  always @(VMEAddr, wr_adr_d0, subm_wt, subm_ws)
  if ((subm_ws | subm_wt) == 1'b1)
    subm_VMEAddr_o = wr_adr_d0[2:2];
  else
    subm_VMEAddr_o = VMEAddr[2:2];

  // Process for write requests.
  always @(wr_req_d0, subm_VMEWrDone_i)
  begin
    subm_ws = 1'b0;
    // Submap subm
    subm_ws = wr_req_d0;
    wr_ack_int = subm_VMEWrDone_i;
  end

  // Process for read requests.
  always @(VMERdMem, subm_VMERdData_i, subm_VMERdDone_i)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    subm_VMERdMem_o = 1'b0;
    // Submap subm
    subm_VMERdMem_o = VMERdMem;
    rd_dat_d0 = subm_VMERdData_i;
    rd_ack_d0 = subm_VMERdDone_i;
  end
endmodule
