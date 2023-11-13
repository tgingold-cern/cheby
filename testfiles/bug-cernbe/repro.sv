
module example
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [2:1] VMEAddr,
    output  reg [15:0] VMERdData,
    input   wire [15:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // The first register (with some fields)
    output  wire [31:0] regA_o,

    // CERN-BE bus sm
    output  reg [1:1] sm_VMEAddr_o,
    input   wire [15:0] sm_VMERdData_i,
    output  wire [15:0] sm_VMEWrData_o,
    output  reg sm_VMERdMem_o,
    output  wire sm_VMEWrMem_o,
    input   wire sm_VMERdDone_i,
    input   wire sm_VMEWrDone_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [31:0] regA_reg;
  reg [1:0] regA_wreq;
  reg [1:0] regA_wack;
  reg rd_ack_d0;
  reg [15:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:1] wr_adr_d0;
  reg [15:0] wr_dat_d0;
  reg sm_ws;
  reg sm_wt;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 16'b0000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 2'b00;
        wr_dat_d0 <= 16'b0000000000000000;
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

  // Register regA
  assign regA_o = regA_reg;
  always @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        regA_reg <= 32'b00000000000000000000000000000000;
        regA_wack <= 2'b0;
      end
    else
      begin
        if (regA_wreq[0] == 1'b1)
          regA_reg[15:0] <= wr_dat_d0;
        if (regA_wreq[1] == 1'b1)
          regA_reg[31:16] <= wr_dat_d0;
        regA_wack <= regA_wreq;
      end
  end

  // Interface sm
  assign sm_VMEWrData_o = wr_dat_d0;
  always @(posedge(Clk))
  begin
    if (!rst_n)
      sm_wt <= 1'b0;
    else
      sm_wt <= (sm_wt | sm_ws) & ~sm_VMEWrDone_i;
  end
  assign sm_VMEWrMem_o = sm_ws;
  always @(VMEAddr, wr_adr_d0, sm_wt, sm_ws)
  if ((sm_ws | sm_wt) == 1'b1)
    sm_VMEAddr_o <= wr_adr_d0[1:1];
  else
    sm_VMEAddr_o <= VMEAddr[1:1];

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, regA_wack, sm_VMEWrDone_i)
  begin
    regA_wreq <= 2'b0;
    sm_ws <= 1'b0;
    case (wr_adr_d0[2:2])
    1'b0:
      case (wr_adr_d0[1:1])
      1'b0:
        begin
          // Reg regA
          regA_wreq[1] <= wr_req_d0;
          wr_ack_int <= regA_wack[1];
        end
      1'b1:
        begin
          // Reg regA
          regA_wreq[0] <= wr_req_d0;
          wr_ack_int <= regA_wack[0];
        end
      default:
        wr_ack_int <= wr_req_d0;
      endcase
    1'b1:
      begin
        // Submap sm
        sm_ws <= wr_req_d0;
        wr_ack_int <= sm_VMEWrDone_i;
      end
    default:
      wr_ack_int <= wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(VMEAddr, VMERdMem, regA_reg, sm_VMERdData_i, sm_VMERdDone_i)
  begin
    // By default ack read requests
    rd_dat_d0 <= {16{1'bx}};
    sm_VMERdMem_o <= 1'b0;
    case (VMEAddr[2:2])
    1'b0:
      case (VMEAddr[1:1])
      1'b0:
        begin
          // Reg regA
          rd_ack_d0 <= VMERdMem;
          rd_dat_d0 <= regA_reg[31:16];
        end
      1'b1:
        begin
          // Reg regA
          rd_ack_d0 <= VMERdMem;
          rd_dat_d0 <= regA_reg[15:0];
        end
      default:
        rd_ack_d0 <= VMERdMem;
      endcase
    1'b1:
      begin
        // Submap sm
        sm_VMERdMem_o <= VMERdMem;
        rd_dat_d0 <= sm_VMERdData_i;
        rd_ack_d0 <= sm_VMERdDone_i;
      end
    default:
      rd_ack_d0 <= VMERdMem;
    endcase
  end
endmodule
