
module buserr_mem_sram
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [7:2] awaddr,
    input   wire [2:0] awprot,
    input   wire wvalid,
    output  wire wready,
    input   wire [31:0] wdata,
    input   wire [3:0] wstrb,
    output  wire bvalid,
    input   wire bready,
    output  wire [1:0] bresp,
    input   wire arvalid,
    output  wire arready,
    input   wire [7:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // REG scratch
    output  wire [31:0] scratch_o,

    // SRAM bus lut
    output  reg [6:2] lut_addr_o,
    input   wire [31:0] lut_data_i,
    output  wire [31:0] lut_data_o,
    output  reg lut_wr_o
  );
  reg wr_req;
  reg wr_ack;
  reg wr_err;
  reg [7:2] wr_addr;
  reg [31:0] wr_data;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg [1:0] axi_werr;
  reg rd_req;
  reg rd_ack;
  reg rd_err;
  reg [7:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg [1:0] axi_rerr;
  reg [31:0] scratch_reg;
  reg scratch_wreq;
  wire scratch_wack;
  reg lut_rack;
  reg lut_re;
  reg rd_ack_d0;
  reg rd_err_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [7:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg lut_wp;
  wire lut_we;

  // AW, W and B channels
  assign awready = ~axi_awset;
  assign wready = ~axi_wset;
  assign bvalid = axi_wdone | ~areset_n;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        wr_req <= 1'b0;
        axi_awset <= 1'b0;
        axi_wset <= 1'b0;
        // During reset, return error (BVALID is forced by the reset signal)
        axi_wdone <= 1'b0;
        axi_werr <= 2'b10;
      end
    else
      begin
        wr_req <= 1'b0;
        if (awvalid == 1'b1 & axi_awset == 1'b0)
          begin
            wr_addr <= awaddr;
            axi_awset <= 1'b1;
            wr_req <= axi_wset;
          end
        if (wvalid == 1'b1 & axi_wset == 1'b0)
          begin
            wr_data <= wdata;
            axi_wset <= 1'b1;
            wr_req <= axi_awset | awvalid;
          end
        if ((axi_wdone & bready) == 1'b1)
          begin
            axi_wset <= 1'b0;
            axi_awset <= 1'b0;
            axi_wdone <= 1'b0;
          end
        if (wr_ack == 1'b1)
          begin
            axi_wdone <= 1'b1;
            if (wr_err == 1'b0)
              axi_werr <= 2'b00;
            else
              axi_werr <= 2'b10;
          end
      end
  end
  assign bresp = axi_werr;

  // AR and R channels
  assign arready = ~axi_arset;
  assign rvalid = axi_rdone | ~areset_n;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        // During reset, return error (RVALID is forced by the reset signal)
        axi_rdone <= 1'b0;
        axi_rerr <= 2'b10;
        rdata <= 32'b0;
      end
    else
      begin
        rd_req <= 1'b0;
        if (arvalid == 1'b1 & axi_arset == 1'b0)
          begin
            rd_addr <= araddr;
            axi_arset <= 1'b1;
            rd_req <= 1'b1;
          end
        if ((axi_rdone & rready) == 1'b1)
          begin
            axi_arset <= 1'b0;
            axi_rdone <= 1'b0;
          end
        if (rd_ack == 1'b1)
          begin
            axi_rdone <= 1'b1;
            rdata <= rd_data;
            if (rd_err == 1'b0)
              axi_rerr <= 2'b00;
            else
              axi_rerr <= 2'b10;
          end
      end
  end
  assign rresp = axi_rerr;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_ack <= 1'b0;
        rd_err <= 1'b0;
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 6'b000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end
  end

  // Register scratch
  assign scratch_o = scratch_reg;
  assign scratch_wack = scratch_wreq;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      scratch_reg <= 32'b00000000000000000000000000000000;
    else
      if (scratch_wreq == 1'b1)
        scratch_reg <= wr_dat_d0;
  end

  // Interface lut
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      lut_rack <= 1'b0;
    else
      lut_rack <= lut_re & ~lut_rack;
  end
  assign lut_data_o = wr_dat_d0;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      lut_wp <= 1'b0;
    else
      lut_wp <= (wr_req_d0 | lut_wp) & rd_req;
  end
  assign lut_we = (wr_req_d0 | lut_wp) & ~rd_req;
  always_comb
  if (lut_re == 1'b1)
    lut_addr_o = rd_addr[6:2];
  else
    lut_addr_o = wr_adr_d0[6:2];

  // Process for write requests.
  always_comb
  begin
    scratch_wreq = 1'b0;
    lut_wr_o = 1'b0;
    case (wr_adr_d0[7:7])
    1'b0:
      case (wr_adr_d0[6:2])
      5'b00000:
        begin
          // Reg scratch
          scratch_wreq = wr_req_d0;
          wr_ack = scratch_wack;
          wr_err = 1'b0;
        end
      default:
        begin
          wr_ack = wr_req_d0;
          wr_err = wr_req_d0;
        end
      endcase
    1'b1:
      begin
        // Memory lut
        lut_wr_o = lut_we;
        wr_ack = lut_we;
        wr_err = 1'b0;
      end
    default:
      begin
        wr_ack = wr_req_d0;
        wr_err = wr_req_d0;
      end
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    lut_re = 1'b0;
    case (rd_addr[7:7])
    1'b0:
      case (rd_addr[6:2])
      5'b00000:
        begin
          // Reg scratch
          rd_ack_d0 = rd_req;
          rd_err_d0 = 1'b0;
          rd_dat_d0 = scratch_reg;
        end
      default:
        begin
          rd_ack_d0 = rd_req;
          rd_err_d0 = rd_req;
        end
      endcase
    1'b1:
      begin
        // Memory lut
        rd_dat_d0 = lut_data_i;
        rd_ack_d0 = lut_rack;
        lut_re = rd_req;
        rd_err_d0 = 1'b0;
      end
    default:
      begin
        rd_ack_d0 = rd_req;
        rd_err_d0 = rd_req;
      end
    endcase
  end
endmodule
