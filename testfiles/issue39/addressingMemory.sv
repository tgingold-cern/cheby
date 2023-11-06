
module eda02175v2
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [20:1] VMEAddr,
    output  reg [15:0] VMERdData,
    input   wire [15:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // ViewPort to the internal acquisition RAM/SRAM blocs
    output  reg [16:1] acqVP_VMEAddr_o,
    input   wire [15:0] acqVP_VMERdData_i,
    output  wire [15:0] acqVP_VMEWrData_o,
    output  reg acqVP_VMERdMem_o,
    output  wire acqVP_VMEWrMem_o,
    input   wire acqVP_VMERdDone_i,
    input   wire acqVP_VMEWrDone_i,

    // Resets the system part of the logic in the FPGA. ONLY FOR LAB PURPOSES
    output  wire softReset_reset_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg softReset_reset_reg;
  reg softReset_wreq;
  reg softReset_wack;
  reg rd_ack_d0;
  reg [15:0] rd_dat_d0;
  reg wr_req_d0;
  reg [20:1] wr_adr_d0;
  reg [15:0] wr_dat_d0;
  reg acqVP_ws;
  reg acqVP_wt;
  assign rst_n = ~Rst;
  assign VMERdDone = rd_ack_int;
  assign VMEWrDone = wr_ack_int;

  // pipelining for wr-in+rd-out
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        rd_ack_int <= 1'b0;
        VMERdData <= 16'b0000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 20'b00000000000000000000;
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

  // Interface acqVP
  assign acqVP_VMEWrData_o = wr_dat_d0;
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      acqVP_wt <= 1'b0;
    else
      acqVP_wt <= (acqVP_wt | acqVP_ws) & ~acqVP_VMEWrDone_i;
  end
  assign acqVP_VMEWrMem_o = acqVP_ws;
  always @(VMEAddr, wr_adr_d0, acqVP_wt, acqVP_ws)
      if ((acqVP_ws | acqVP_wt) == 1'b1)
        acqVP_VMEAddr_o <= wr_adr_d0[16:1];
      else
        acqVP_VMEAddr_o <= VMEAddr[16:1];

  // Register softReset
  assign softReset_reset_o = softReset_reset_reg;
  always @(posedge(Clk) or negedge(rst_n))
  begin
    if (!rst_n)
      begin
        softReset_reset_reg <= 1'b0;
        softReset_wack <= 1'b0;
      end
    else
      begin
        if (softReset_wreq == 1'b1)
          softReset_reset_reg <= wr_dat_d0[0];
        softReset_wack <= softReset_wreq;
      end
  end

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, acqVP_VMEWrDone_i, softReset_wack)
      begin
        acqVP_ws <= 1'b0;
        softReset_wreq <= 1'b0;
        case (wr_adr_d0[20:20])
        1'b0:
          begin
            // Memory acqVP
            acqVP_ws <= wr_req_d0;
            wr_ack_int <= acqVP_VMEWrDone_i;
          end
        1'b1:
          case (wr_adr_d0[19:1])
          19'b0000000000000000000:
            begin
              // Reg softReset
              softReset_wreq <= wr_req_d0;
              wr_ack_int <= softReset_wack;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(VMEAddr, VMERdMem, acqVP_VMERdData_i, acqVP_VMERdDone_i, softReset_reset_reg)
      begin
        // By default ack read requests
        rd_dat_d0 <= {16{1'bx}};
        acqVP_VMERdMem_o <= 1'b0;
        case (VMEAddr[20:20])
        1'b0:
          begin
            // Memory acqVP
            acqVP_VMERdMem_o <= VMERdMem;
            rd_dat_d0 <= acqVP_VMERdData_i;
            rd_ack_d0 <= acqVP_VMERdDone_i;
          end
        1'b1:
          case (VMEAddr[19:1])
          19'b0000000000000000000:
            begin
              // Reg softReset
              rd_ack_d0 <= VMERdMem;
              rd_dat_d0[0] <= softReset_reset_reg;
              rd_dat_d0[15:1] <= 15'b0;
            end
          default:
            rd_ack_d0 <= VMERdMem;
          endcase
        default:
          rd_ack_d0 <= VMERdMem;
        endcase
      end
endmodule
