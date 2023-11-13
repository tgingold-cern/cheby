
module bugBlockRegField
  (
    input   wire Clk,
    input   wire Rst,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // REG r1
    output  wire b1_r1_f1_o,
    output  wire [9:0] b1_r1_f2_o,
    output  wire b1_r1_f3_o,
    output  wire b1_r1_f4_o,
    output  wire b1_r1_f5_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg b1_r1_f1_reg;
  reg [9:0] b1_r1_f2_reg;
  reg b1_r1_f3_reg;
  reg b1_r1_f4_reg;
  reg b1_r1_f5_reg;
  reg b1_r1_wreq;
  reg b1_r1_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
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
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_dat_d0 <= VMEWrData;
      end
  end

  // Register b1_r1
  assign b1_r1_f1_o = b1_r1_f1_reg;
  assign b1_r1_f2_o = b1_r1_f2_reg;
  assign b1_r1_f3_o = b1_r1_f3_reg;
  assign b1_r1_f4_o = b1_r1_f4_reg;
  assign b1_r1_f5_o = b1_r1_f5_reg;
  always @(posedge(Clk))
  begin
    if (!rst_n)
      begin
        b1_r1_f1_reg <= 1'b0;
        b1_r1_f2_reg <= 10'b0000000000;
        b1_r1_f3_reg <= 1'b0;
        b1_r1_f4_reg <= 1'b0;
        b1_r1_f5_reg <= 1'b0;
        b1_r1_wack <= 1'b0;
      end
    else
      begin
        if (b1_r1_wreq == 1'b1)
          begin
            b1_r1_f1_reg <= wr_dat_d0[0];
            b1_r1_f2_reg <= wr_dat_d0[12:3];
            b1_r1_f3_reg <= wr_dat_d0[2];
            b1_r1_f4_reg <= wr_dat_d0[1];
            b1_r1_f5_reg <= wr_dat_d0[13];
          end
        b1_r1_wack <= b1_r1_wreq;
      end
  end

  // Process for write requests.
  always @(wr_req_d0, b1_r1_wack)
  begin
    b1_r1_wreq <= 1'b0;
    // Reg b1_r1
    b1_r1_wreq <= wr_req_d0;
    wr_ack_int <= b1_r1_wack;
  end

  // Process for read requests.
  always @(VMERdMem, b1_r1_f1_reg, b1_r1_f4_reg, b1_r1_f3_reg, b1_r1_f2_reg, b1_r1_f5_reg)
  begin
    // By default ack read requests
    rd_dat_d0 <= {32{1'bx}};
    // Reg b1_r1
    rd_ack_d0 <= VMERdMem;
    rd_dat_d0[0] <= b1_r1_f1_reg;
    rd_dat_d0[1] <= b1_r1_f4_reg;
    rd_dat_d0[2] <= b1_r1_f3_reg;
    rd_dat_d0[12:3] <= b1_r1_f2_reg;
    rd_dat_d0[13] <= b1_r1_f5_reg;
    rd_dat_d0[31:14] <= 18'b0;
  end
endmodule
