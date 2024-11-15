
module sub_repro
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [1:1] VMEAddr,
    output  reg [15:0] VMERdData,
    input   wire [15:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // REG subrA
    output  wire [15:0] subrA_o,

    // REG subrB
    input   wire [15:0] subrB_i
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [15:0] subrA_reg;
  reg subrA_wreq;
  wire subrA_wack;
  reg rd_ack_d0;
  reg [15:0] rd_dat_d0;
  reg wr_req_d0;
  reg [1:1] wr_adr_d0;
  reg [15:0] wr_dat_d0;
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
        wr_adr_d0 <= 1'b0;
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

  // Register subrA
  assign subrA_o = subrA_reg;
  assign subrA_wack = subrA_wreq;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      subrA_reg <= 16'b0000000000000000;
    else
      if (subrA_wreq == 1'b1)
        subrA_reg <= wr_dat_d0;
  end

  // Register subrB

  // Process for write requests.
  always_comb
  begin
    subrA_wreq = 1'b0;
    case (wr_adr_d0[1:1])
    1'b0:
      begin
        // Reg subrA
        subrA_wreq = wr_req_d0;
        wr_ack_int = subrA_wack;
      end
    1'b1:
      // Reg subrB
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {16{1'bx}};
    case (VMEAddr[1:1])
    1'b0:
      begin
        // Reg subrA
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = subrA_reg;
      end
    1'b1:
      begin
        // Reg subrB
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = subrB_i;
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
