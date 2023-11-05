
module m1
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

    // REG r1
    output  wire [31:0] r1_o,

    // CERN-BE bus sm2
    input   wire [31:0] sm2_VMERdData_i,
    output  wire [31:0] sm2_VMEWrData_o,
    output  reg sm2_VMERdMem_o,
    output  wire sm2_VMEWrMem_o,
    input   wire sm2_VMERdDone_i,
    input   wire sm2_VMEWrDone_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [31:0] r1_reg;
  reg r1_wreq;
  reg r1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg sm2_ws;
  assign rst_n = !Rst;
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
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end
  end

  // Register r1
  assign r1_o = r1_reg;
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        r1_reg <= 32'b00000000000000000000000000000000;
        r1_wack <= 1'b0;
      end
    else
      begin
        if (r1_wreq == 1'b1)
          r1_reg <= wr_dat_d0;
        r1_wack <= r1_wreq;
      end
  end

  // Interface sm2
  assign sm2_VMEWrData_o = wr_dat_d0;
  assign sm2_VMEWrMem_o = sm2_ws;

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, r1_wack, sm2_VMEWrDone_i)
      begin
        r1_wreq <= 1'b0;
        sm2_ws <= 1'b0;
        case (wr_adr_d0[2:2])
        1'b0:
          begin
            // Reg r1
            r1_wreq <= wr_req_d0;
            wr_ack_int <= r1_wack;
          end
        1'b1:
          begin
            // Submap sm2
            sm2_ws <= wr_req_d0;
            wr_ack_int <= sm2_VMEWrDone_i;
          end
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(VMEAddr, VMERdMem, r1_reg, sm2_VMERdData_i, sm2_VMERdDone_i)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        sm2_VMERdMem_o <= 1'b0;
        case (VMEAddr[2:2])
        1'b0:
          begin
            // Reg r1
            rd_ack_d0 <= VMERdMem;
            rd_dat_d0 <= r1_reg;
          end
        1'b1:
          begin
            // Submap sm2
            sm2_VMERdMem_o <= VMERdMem;
            rd_dat_d0 <= sm2_VMERdData_i;
            rd_ack_d0 <= sm2_VMERdDone_i;
          end
        default:
          rd_ack_d0 <= VMERdMem;
        endcase
      end
endmodule
