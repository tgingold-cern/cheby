
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
    output  wire [63:0] r1_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [63:0] r1_reg;
  reg [1:0] r1_wreq;
  reg [1:0] r1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
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

  // Register r1
  assign r1_o = r1_reg;
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        r1_reg <= 64'b0000000000000000000000000000000000000000000000000000000000000000;
        r1_wack <= 2'b0;
      end
    else
      begin
        if (r1_wreq[0] == 1'b1)
          r1_reg[31:0] <= wr_dat_d0;
        else
          r1_reg[31:0] <= 32'b00000000000000000000000000000000;
        if (r1_wreq[1] == 1'b1)
          r1_reg[63:32] <= wr_dat_d0;
        else
          r1_reg[63:32] <= 32'b00000000000000000000000000000000;
        r1_wack <= r1_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, r1_wack)
      begin
        r1_wreq <= 2'b0;
        case (wr_adr_d0[2:2])
        1'b0:
          begin
            // Reg r1
            r1_wreq[1] <= wr_req_d0;
            wr_ack_int <= r1_wack[1];
          end
        1'b1:
          begin
            // Reg r1
            r1_wreq[0] <= wr_req_d0;
            wr_ack_int <= r1_wack[0];
          end
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(VMEAddr, VMERdMem)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        case (VMEAddr[2:2])
        1'b0:
          begin
            // Reg r1
            rd_ack_d0 <= VMERdMem;
            rd_dat_d0 <= 32'b00000000000000000000000000000000;
          end
        1'b1:
          begin
            // Reg r1
            rd_ack_d0 <= VMERdMem;
            rd_dat_d0 <= 32'b00000000000000000000000000000000;
          end
        default:
          rd_ack_d0 <= VMERdMem;
        endcase
      end
endmodule
