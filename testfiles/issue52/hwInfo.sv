
module hwInfo
  (
    input   wire Clk,
    input   wire Rst,
    input   wire [4:1] VMEAddr,
    output  reg [15:0] VMERdData,
    input   wire [15:0] VMEWrData,
    input   wire VMERdMem,
    input   wire VMEWrMem,
    output  wire VMERdDone,
    output  wire VMEWrDone,

    // HW serial number
    input   wire [63:0] serialNumber_i,

    // Firmware Version
    input   wire [7:0] firmwareVersion_major_i,
    input   wire [7:0] firmwareVersion_minor_i,
    input   wire [7:0] firmwareVersion_patch_i,

    // Memory Map Version
    input   wire [7:0] memMapVersion_major_i,
    input   wire [7:0] memMapVersion_minor_i,
    input   wire [7:0] memMapVersion_patch_i,

    // Echo register
    // This version of the standard foresees only 8bits linked to real memory
    output  wire [7:0] echo_echo_o
  );
  wire rst_n;
  reg rd_ack_int;
  reg wr_ack_int;
  reg [7:0] echo_echo_reg;
  reg [1:0] echo_wreq;
  wire [1:0] echo_wack;
  reg rd_ack_d0;
  reg [15:0] rd_dat_d0;
  reg wr_req_d0;
  reg [4:1] wr_adr_d0;
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
        wr_adr_d0 <= 4'b0000;
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

  // Register stdVersion

  // Register serialNumber

  // Register firmwareVersion

  // Register memMapVersion

  // Register echo
  assign echo_echo_o = echo_echo_reg;
  assign echo_wack = echo_wreq;
  always_ff @(posedge(Clk))
  begin
    if (!rst_n)
      echo_echo_reg <= 8'b00000000;
    else
      if (echo_wreq[0] == 1'b1)
        echo_echo_reg <= wr_dat_d0[7:0];
  end

  // Process for write requests.
  always_comb
  begin
    echo_wreq = 2'b0;
    case (wr_adr_d0[4:1])
    4'b0000:
      // Reg stdVersion
      wr_ack_int = wr_req_d0;
    4'b0001:
      // Reg stdVersion
      wr_ack_int = wr_req_d0;
    4'b0010:
      // Reg serialNumber
      wr_ack_int = wr_req_d0;
    4'b0011:
      // Reg serialNumber
      wr_ack_int = wr_req_d0;
    4'b0100:
      // Reg serialNumber
      wr_ack_int = wr_req_d0;
    4'b0101:
      // Reg serialNumber
      wr_ack_int = wr_req_d0;
    4'b0110:
      // Reg firmwareVersion
      wr_ack_int = wr_req_d0;
    4'b0111:
      // Reg firmwareVersion
      wr_ack_int = wr_req_d0;
    4'b1000:
      // Reg memMapVersion
      wr_ack_int = wr_req_d0;
    4'b1001:
      // Reg memMapVersion
      wr_ack_int = wr_req_d0;
    4'b1010:
      begin
        // Reg echo
        echo_wreq[1] = wr_req_d0;
        wr_ack_int = echo_wack[1];
      end
    4'b1011:
      begin
        // Reg echo
        echo_wreq[0] = wr_req_d0;
        wr_ack_int = echo_wack[0];
      end
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {16{1'bx}};
    case (VMEAddr[4:1])
    4'b0000:
      begin
        // Reg stdVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = 8'b00000001;
        rd_dat_d0[15:8] = 8'b0;
      end
    4'b0001:
      begin
        // Reg stdVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = 8'b00000000;
        rd_dat_d0[15:8] = 8'b00000000;
      end
    4'b0010:
      begin
        // Reg serialNumber
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = serialNumber_i[63:48];
      end
    4'b0011:
      begin
        // Reg serialNumber
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = serialNumber_i[47:32];
      end
    4'b0100:
      begin
        // Reg serialNumber
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = serialNumber_i[31:16];
      end
    4'b0101:
      begin
        // Reg serialNumber
        rd_ack_d0 = VMERdMem;
        rd_dat_d0 = serialNumber_i[15:0];
      end
    4'b0110:
      begin
        // Reg firmwareVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = firmwareVersion_major_i;
        rd_dat_d0[15:8] = 8'b0;
      end
    4'b0111:
      begin
        // Reg firmwareVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = firmwareVersion_patch_i;
        rd_dat_d0[15:8] = firmwareVersion_minor_i;
      end
    4'b1000:
      begin
        // Reg memMapVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = memMapVersion_major_i;
        rd_dat_d0[15:8] = 8'b0;
      end
    4'b1001:
      begin
        // Reg memMapVersion
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = memMapVersion_patch_i;
        rd_dat_d0[15:8] = memMapVersion_minor_i;
      end
    4'b1010:
      begin
        // Reg echo
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[15:0] = 16'b0;
      end
    4'b1011:
      begin
        // Reg echo
        rd_ack_d0 = VMERdMem;
        rd_dat_d0[7:0] = echo_echo_reg;
        rd_dat_d0[15:8] = 8'b0;
      end
    default:
      rd_ack_d0 = VMERdMem;
    endcase
  end
endmodule
