
module mainMap2
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [14:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,
    output  wire VMERdError,
    output  wire VMEWrError,

    // CERN-BE bus subMap1
    output  reg [12:2] subMap1_VMEAddr_o,
    input   wire [31:0] subMap1_VMERdData_i,
    output  wire [31:0] subMap1_VMEWrData_o,
    output  reg subMap1_VMERdMem_o,
    output  wire subMap1_VMEWrMem_o,
    input   wire subMap1_VMERdDone_i,
    input   wire subMap1_VMEWrDone_i,
    input   wire subMap1_VMERdError_i,
    input   wire subMap1_VMEWrError_i,

    // CERN-BE bus subMap2
    output  reg [12:2] subMap2_VMEAddr_o,
    input   wire [31:0] subMap2_VMERdData_i,
    output  wire [31:0] subMap2_VMEWrData_o,
    output  reg subMap2_VMERdMem_o,
    output  wire subMap2_VMEWrMem_o,
    input   wire subMap2_VMERdDone_i,
    input   wire subMap2_VMEWrDone_i,
    input   wire subMap2_VMERdError_i,
    input   wire subMap2_VMEWrError_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [14:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg subMap1_ws;
  reg subMap1_wt;
  reg subMap2_ws;
  reg subMap2_wt;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 13'b0000000000000;
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

  // Interface subMap1
  assign subMap1_VMEWrData_o = wr_dat_d0;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      subMap1_wt <= 1'b0;
    else
      subMap1_wt <= (subMap1_wt | subMap1_ws) & ~subMap1_VMEWrDone_i;
  end
  assign subMap1_VMEWrMem_o = subMap1_ws;
  always_comb
  if ((subMap1_ws | subMap1_wt) == 1'b1)
    subMap1_VMEAddr_o = wr_adr_d0[12:2];
  else
    subMap1_VMEAddr_o = VMEAddr[12:2];

  // Interface subMap2
  assign subMap2_VMEWrData_o = wr_dat_d0;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      subMap2_wt <= 1'b0;
    else
      subMap2_wt <= (subMap2_wt | subMap2_ws) & ~subMap2_VMEWrDone_i;
  end
  assign subMap2_VMEWrMem_o = subMap2_ws;
  always_comb
  if ((subMap2_ws | subMap2_wt) == 1'b1)
    subMap2_VMEAddr_o = wr_adr_d0[12:2];
  else
    subMap2_VMEAddr_o = VMEAddr[12:2];

  // Process for write requests.
  always_comb
  begin
    subMap1_ws = 1'b0;
    subMap2_ws = 1'b0;
    case (wr_adr_d0[14:13])
    2'b00:
      begin
        // Submap subMap1
        subMap1_ws = wr_req_d0;
        wr_ack_int = subMap1_VMEWrDone_i;
      end
    2'b01:
      begin
        // Submap subMap2
        subMap2_ws = wr_req_d0;
        wr_ack_int = subMap2_VMEWrDone_i;
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
    subMap1_VMERdMem_o = 1'b0;
    subMap2_VMERdMem_o = 1'b0;
    case (VMEAddr[14:13])
    2'b00:
      begin
        // Submap subMap1
        subMap1_VMERdMem_o = VMERdMem;
        rd_dat_d0 = subMap1_VMERdData_i;
        rd_ack_d0 = subMap1_VMERdDone_i;
      end
    2'b01:
      begin
        // Submap subMap2
        subMap2_VMERdMem_o = VMERdMem;
        rd_dat_d0 = subMap2_VMERdData_i;
        rd_ack_d0 = subMap2_VMERdDone_i;
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
