
module mapinfo2
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
    output  wire VMERdError,
    output  wire VMEWrError,

    // REG test1
    output  wire [31:0] test1_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [31:0] test1_reg;
  reg test1_wreq;
  reg test1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [19:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
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
        wr_adr_d0 <= 18'b000000000000000000;
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

  // Register test1
  assign test1_o = test1_reg;
  always @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        test1_reg <= 32'b00000000000000000000000000000000;
        test1_wack <= 1'b0;
      end
    else
      begin
        if (test1_wreq == 1'b1)
          test1_reg <= wr_dat_d0;
        test1_wack <= test1_wreq;
      end
  end

  // Register mapver

  // Register icode

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, test1_wack)
  begin
    test1_wreq = 1'b0;
    case (wr_adr_d0[19:2])
    18'b000000000000000000:
      begin
        // Reg test1
        test1_wreq = wr_req_d0;
        wr_ack_int = test1_wack;
      end
    18'b000000000000000001:
      // Reg mapver
      wr_ack_int = wr_req_d0;
    18'b000000000000000010:
      // Reg icode
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always @(VMEAddr, VMERdMem, test1_reg)
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (VMEAddr[19:2])
    18'b000000000000000000:
      begin
        // Reg test1
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = test1_reg;
      end
    18'b000000000000000001:
      begin
        // Reg mapver
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = 32'b00000000000000010000001000000011;
      end
    18'b000000000000000010:
      begin
        // Reg icode
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = 32'b00000000000000000000000000010001;
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
