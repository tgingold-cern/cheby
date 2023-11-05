
module blockInMap
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [13:2] VMEAddr,
    output  reg [31:0] VMERdData,
    input   wire [31:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
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
      end
  end

  // Process for write requests.
  always @(wr_req_d0)
      wr_ack_int <= wr_req_d0;

  // Process for read requests.
  always @(VMERdMem)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        rd_ack_d0 <= VMERdMem;
      end
endmodule
