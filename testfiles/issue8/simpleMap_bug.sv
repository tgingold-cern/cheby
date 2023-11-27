
module exemple
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [19:1] VMEAddr,
    output  reg [15:0] VMERdData,
    input   wire [15:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // REG smallReg
    input   wire [15:0] smallReg_i,

    // REG largeReg
    input   wire [63:0] largeReg_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg rd_ack_d0;
  reg [15:0] rd_dat_d0;
  reg wr_req_d0;
  reg [19:1] wr_adr_d0;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 16'b0000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 19'b0000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
      end
  end

  // Register smallReg

  // Register largeReg

  // Process for write requests.
  always_comb
  case (wr_adr_d0[19:1])
  19'b0000000000000000000:
    // Reg smallReg
    wr_ack_int = wr_req_d0;
  19'b0000000000000000001:
    // Reg largeReg
    wr_ack_int = wr_req_d0;
  19'b0000000000000000010:
    // Reg largeReg
    wr_ack_int = wr_req_d0;
  19'b0000000000000000011:
    // Reg largeReg
    wr_ack_int = wr_req_d0;
  19'b0000000000000000100:
    // Reg largeReg
    wr_ack_int = wr_req_d0;
  default:
    wr_ack_int = wr_req_d0;
  endcase

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {16{1'bx}};
    case (VMEAddr[19:1])
    19'b0000000000000000000:
      begin
        // Reg smallReg
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = smallReg_i;
      end
    19'b0000000000000000001:
      begin
        // Reg largeReg
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = largeReg_i[63:48];
      end
    19'b0000000000000000010:
      begin
        // Reg largeReg
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = largeReg_i[47:32];
      end
    19'b0000000000000000011:
      begin
        // Reg largeReg
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = largeReg_i[31:16];
      end
    19'b0000000000000000100:
      begin
        // Reg largeReg
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = largeReg_i[15:0];
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
