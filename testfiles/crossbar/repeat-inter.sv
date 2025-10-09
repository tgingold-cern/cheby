interface t_rfgen;
  logic [31:0] ctrl;
  logic [7:2] bstmem_adr_o;
  logic [31:0] bstmem_dato_i;
  logic [31:0] bstmem_dati_o;
  logic bstmem_rd_o;
  logic bstmem_wr_o;
  logic bstmem_rack_i;
  logic bstmem_wack_i;
  modport master(
    input bstmem_dato_i,
    input bstmem_rack_i,
    input bstmem_wack_i,
    output ctrl,
    output bstmem_adr_o,
    output bstmem_dati_o,
    output bstmem_rd_o,
    output bstmem_wr_o
  );
  modport slave(
    output bstmem_dato_i,
    output bstmem_rack_i,
    output bstmem_wack_i,
    input ctrl,
    input bstmem_adr_o,
    input bstmem_dati_o,
    input bstmem_rd_o,
    input bstmem_wr_o
  );
endinterface


module repinter
  (
    input   wire aclk,
    input   wire areset_n,
    input   wire awvalid,
    output  wire awready,
    input   wire [12:2] awaddr,
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
    input   wire [12:2] araddr,
    input   wire [2:0] arprot,
    output  wire rvalid,
    input   wire rready,
    output  reg [31:0] rdata,
    output  wire [1:0] rresp,

    // REG fp_oe
    output  wire [31:0] fp_oe_o,

    // REPEAT rfgen
    t_rfgen.master rfgen[2]
  );
  reg wr_req;
  reg wr_ack;
  reg [12:2] wr_addr;
  reg [31:0] wr_data;
  reg axi_awset;
  reg axi_wset;
  reg axi_wdone;
  reg rd_req;
  reg rd_ack;
  reg [12:2] rd_addr;
  reg [31:0] rd_data;
  reg axi_arset;
  reg axi_rdone;
  reg [31:0] fp_oe_reg;
  reg fp_oe_wreq;
  wire fp_oe_wack;
  reg [31:0] rfgen_0_ctrl_reg;
  reg rfgen_0_ctrl_wreq;
  wire rfgen_0_ctrl_wack;
  reg rfgen_0_bstmem_wr;
  reg rfgen_0_bstmem_rr;
  wire rfgen_0_bstmem_ws;
  wire rfgen_0_bstmem_rs;
  reg rfgen_0_bstmem_re;
  reg rfgen_0_bstmem_we;
  reg rfgen_0_bstmem_wt;
  reg rfgen_0_bstmem_rt;
  reg [31:0] rfgen_1_ctrl_reg;
  reg rfgen_1_ctrl_wreq;
  wire rfgen_1_ctrl_wack;
  reg rfgen_1_bstmem_wr;
  reg rfgen_1_bstmem_rr;
  wire rfgen_1_bstmem_ws;
  wire rfgen_1_bstmem_rs;
  reg rfgen_1_bstmem_re;
  reg rfgen_1_bstmem_we;
  reg rfgen_1_bstmem_wt;
  reg rfgen_1_bstmem_rt;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [12:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // AW, W and B channels
  assign awready = ~axi_awset;
  assign wready = ~axi_wset;
  assign bvalid = axi_wdone;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        wr_req <= 1'b0;
        axi_awset <= 1'b0;
        axi_wset <= 1'b0;
        axi_wdone <= 1'b0;
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
          axi_wdone <= 1'b1;
      end
  end
  assign bresp = 2'b00;

  // AR and R channels
  assign arready = ~axi_arset;
  assign rvalid = axi_rdone;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_req <= 1'b0;
        axi_arset <= 1'b0;
        axi_rdone <= 1'b0;
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
          end
      end
  end
  assign rresp = 2'b00;

  // pipelining for wr-in+rd-out
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rd_ack <= 1'b0;
        rd_data <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 11'b00000000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end
  end

  // Register fp_oe
  assign fp_oe_o = fp_oe_reg;
  assign fp_oe_wack = fp_oe_wreq;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      fp_oe_reg <= 32'b00000000000000000000000000000000;
    else
      if (fp_oe_wreq == 1'b1)
        fp_oe_reg <= wr_dat_d0;
  end

  // Register rfgen_0_ctrl
  assign rfgen[0].ctrl = rfgen_0_ctrl_reg;
  assign rfgen_0_ctrl_wack = rfgen_0_ctrl_wreq;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      rfgen_0_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (rfgen_0_ctrl_wreq == 1'b1)
        rfgen_0_ctrl_reg <= wr_dat_d0;
  end

  // Interface rfgen_0_bstmem
  assign rfgen[0].bstmem_dati_o = wr_dat_d0;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rfgen_0_bstmem_wr <= 1'b0;
        rfgen_0_bstmem_wt <= 1'b0;
        rfgen_0_bstmem_rr <= 1'b0;
        rfgen_0_bstmem_rt <= 1'b0;
      end
    else
      begin
        rfgen_0_bstmem_wr <= (rfgen_0_bstmem_wr | rfgen_0_bstmem_we) & ~rfgen[0].bstmem_wack_i;
        rfgen_0_bstmem_wt <= (rfgen_0_bstmem_wt | rfgen_0_bstmem_ws) & ~rfgen[0].bstmem_wack_i;
        rfgen_0_bstmem_rr <= (rfgen_0_bstmem_rr | rfgen_0_bstmem_re) & ~rfgen[0].bstmem_rack_i;
        rfgen_0_bstmem_rt <= (rfgen_0_bstmem_rt | rfgen_0_bstmem_rs) & ~rfgen[0].bstmem_rack_i;
      end
  end
  assign rfgen_0_bstmem_rs = rfgen_0_bstmem_rr & ~(rfgen_0_bstmem_wr | (rfgen_0_bstmem_rt | rfgen_0_bstmem_wt));
  assign rfgen_0_bstmem_ws = rfgen_0_bstmem_wr & ~(rfgen_0_bstmem_rt | rfgen_0_bstmem_wt);
  always_comb
  if ((rfgen_0_bstmem_ws | rfgen_0_bstmem_wt) == 1'b1)
    rfgen[0].bstmem_adr_o = wr_adr_d0[7:2];
  else
    rfgen[0].bstmem_adr_o = rd_addr[7:2];

  // Register rfgen_1_ctrl
  assign rfgen[1].ctrl = rfgen_1_ctrl_reg;
  assign rfgen_1_ctrl_wack = rfgen_1_ctrl_wreq;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      rfgen_1_ctrl_reg <= 32'b00000000000000000000000000000000;
    else
      if (rfgen_1_ctrl_wreq == 1'b1)
        rfgen_1_ctrl_reg <= wr_dat_d0;
  end

  // Interface rfgen_1_bstmem
  assign rfgen[1].bstmem_dati_o = wr_dat_d0;
  always_ff @(posedge(aclk))
  begin
    if (!areset_n)
      begin
        rfgen_1_bstmem_wr <= 1'b0;
        rfgen_1_bstmem_wt <= 1'b0;
        rfgen_1_bstmem_rr <= 1'b0;
        rfgen_1_bstmem_rt <= 1'b0;
      end
    else
      begin
        rfgen_1_bstmem_wr <= (rfgen_1_bstmem_wr | rfgen_1_bstmem_we) & ~rfgen[1].bstmem_wack_i;
        rfgen_1_bstmem_wt <= (rfgen_1_bstmem_wt | rfgen_1_bstmem_ws) & ~rfgen[1].bstmem_wack_i;
        rfgen_1_bstmem_rr <= (rfgen_1_bstmem_rr | rfgen_1_bstmem_re) & ~rfgen[1].bstmem_rack_i;
        rfgen_1_bstmem_rt <= (rfgen_1_bstmem_rt | rfgen_1_bstmem_rs) & ~rfgen[1].bstmem_rack_i;
      end
  end
  assign rfgen_1_bstmem_rs = rfgen_1_bstmem_rr & ~(rfgen_1_bstmem_wr | (rfgen_1_bstmem_rt | rfgen_1_bstmem_wt));
  assign rfgen_1_bstmem_ws = rfgen_1_bstmem_wr & ~(rfgen_1_bstmem_rt | rfgen_1_bstmem_wt);
  always_comb
  if ((rfgen_1_bstmem_ws | rfgen_1_bstmem_wt) == 1'b1)
    rfgen[1].bstmem_adr_o = wr_adr_d0[7:2];
  else
    rfgen[1].bstmem_adr_o = rd_addr[7:2];

  // Process for write requests.
  always_comb
  begin
    fp_oe_wreq = 1'b0;
    rfgen_0_ctrl_wreq = 1'b0;
    rfgen_0_bstmem_we = 1'b0;
    rfgen[0].bstmem_wr_o = 1'b0;
    rfgen_1_ctrl_wreq = 1'b0;
    rfgen_1_bstmem_we = 1'b0;
    rfgen[1].bstmem_wr_o = 1'b0;
    case (wr_adr_d0[12:8])
    5'b00000:
      case (wr_adr_d0[7:2])
      6'b000000:
        begin
          // Reg fp_oe
          fp_oe_wreq = wr_req_d0;
          wr_ack = fp_oe_wack;
        end
      default:
        wr_ack = wr_req_d0;
      endcase
    5'b11000:
      case (wr_adr_d0[7:2])
      6'b000000:
        begin
          // Reg rfgen_0_ctrl
          rfgen_0_ctrl_wreq = wr_req_d0;
          wr_ack = rfgen_0_ctrl_wack;
        end
      default:
        wr_ack = wr_req_d0;
      endcase
    5'b11001:
      begin
        // Submap rfgen_0_bstmem
        rfgen_0_bstmem_we = wr_req_d0;
        rfgen[0].bstmem_wr_o = rfgen_0_bstmem_ws;
        wr_ack = rfgen[0].bstmem_wack_i;
      end
    5'b11010:
      case (wr_adr_d0[7:2])
      6'b000000:
        begin
          // Reg rfgen_1_ctrl
          rfgen_1_ctrl_wreq = wr_req_d0;
          wr_ack = rfgen_1_ctrl_wack;
        end
      default:
        wr_ack = wr_req_d0;
      endcase
    5'b11011:
      begin
        // Submap rfgen_1_bstmem
        rfgen_1_bstmem_we = wr_req_d0;
        rfgen[1].bstmem_wr_o = rfgen_1_bstmem_ws;
        wr_ack = rfgen[1].bstmem_wack_i;
      end
    default:
      wr_ack = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    rfgen[0].bstmem_rd_o = 1'b0;
    rfgen_0_bstmem_re = 1'b0;
    rfgen[1].bstmem_rd_o = 1'b0;
    rfgen_1_bstmem_re = 1'b0;
    case (rd_addr[12:8])
    5'b00000:
      case (rd_addr[7:2])
      6'b000000:
        begin
          // Reg fp_oe
          rd_ack_d0 = rd_req;
          rd_dat_d0 = fp_oe_reg;
        end
      default:
        rd_ack_d0 = rd_req;
      endcase
    5'b11000:
      case (rd_addr[7:2])
      6'b000000:
        begin
          // Reg rfgen_0_ctrl
          rd_ack_d0 = rd_req;
          rd_dat_d0 = rfgen_0_ctrl_reg;
        end
      default:
        rd_ack_d0 = rd_req;
      endcase
    5'b11001:
      begin
        // Submap rfgen_0_bstmem
        rfgen_0_bstmem_re = rd_req;
        rfgen[0].bstmem_rd_o = rfgen_0_bstmem_rs;
        rd_dat_d0 = rfgen[0].bstmem_dato_i;
        rd_ack_d0 = rfgen[0].bstmem_rack_i;
      end
    5'b11010:
      case (rd_addr[7:2])
      6'b000000:
        begin
          // Reg rfgen_1_ctrl
          rd_ack_d0 = rd_req;
          rd_dat_d0 = rfgen_1_ctrl_reg;
        end
      default:
        rd_ack_d0 = rd_req;
      endcase
    5'b11011:
      begin
        // Submap rfgen_1_bstmem
        rfgen_1_bstmem_re = rd_req;
        rfgen[1].bstmem_rd_o = rfgen_1_bstmem_rs;
        rd_dat_d0 = rfgen[1].bstmem_dato_i;
        rd_ack_d0 = rfgen[1].bstmem_rack_i;
      end
    default:
      rd_ack_d0 = rd_req;
    endcase
  end
endmodule
