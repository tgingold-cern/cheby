
module axi4_submap_wb
  (
    input   wire rst_n_i,
    input   wire clk_i,
    input   wire wb_cyc_i,
    input   wire wb_stb_i,
    input   wire [2:2] wb_adr_i,
    input   wire [3:0] wb_sel_i,
    input   wire wb_we_i,
    input   wire [31:0] wb_dat_i,
    output  wire wb_ack_o,
    output  wire wb_err_o,
    output  wire wb_rty_o,
    output  wire wb_stall_o,
    output  reg [31:0] wb_dat_o,

    // AXI-4 lite bus blk
    output  wire blk_awvalid_o,
    input   wire blk_awready_i,
    output  wire [2:0] blk_awaddr_o,
    output  wire [2:0] blk_awprot_o,
    output  wire blk_wvalid_o,
    input   wire blk_wready_i,
    output  wire [31:0] blk_wdata_o,
    output  reg [3:0] blk_wstrb_o,
    input   wire blk_bvalid_i,
    output  wire blk_bready_o,
    input   wire [1:0] blk_bresp_i,
    output  wire blk_arvalid_o,
    input   wire blk_arready_i,
    output  wire [2:0] blk_araddr_o,
    output  wire [2:0] blk_arprot_o,
    input   wire blk_rvalid_i,
    output  wire blk_rready_o,
    input   wire [31:0] blk_rdata_i,
    input   wire [1:0] blk_rresp_i
  );
  reg [31:0] wr_sel;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg blk_aw_val;
  reg blk_w_val;
  reg blk_ar_val;
  reg blk_rd;
  reg blk_wr;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [2:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [31:0] wr_sel_d0;

  // WB decode signals
  always @(wb_sel_i)
  begin
    wr_sel[7:0] <= {8{wb_sel_i[0]}};
    wr_sel[15:8] <= {8{wb_sel_i[1]}};
    wr_sel[23:16] <= {8{wb_sel_i[2]}};
    wr_sel[31:24] <= {8{wb_sel_i[3]}};
  end
  assign wb_en = wb_cyc_i & wb_stb_i;

  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb_we_i)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb_we_i) & ~wb_rip;

  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb_we_i)) & ~wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb_we_i) & ~wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb_ack_o = ack_int;
  assign wb_stall_o = ~ack_int & wb_en;
  assign wb_rty_o = 1'b0;
  assign wb_err_o = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        rd_ack_int <= 1'b0;
        wb_dat_o <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 1'b0;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
        wr_sel_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wr_sel;
      end
  end

  // Interface blk
  assign blk_awvalid_o = blk_aw_val;
  assign blk_awaddr_o = {wr_adr_d0[2:2], 2'b00};
  assign blk_awprot_o = 3'b000;
  assign blk_wvalid_o = blk_w_val;
  assign blk_wdata_o = wr_dat_d0;
  always @(wr_sel_d0)
  begin
    blk_wstrb_o <= 4'b0;
    if (~(wr_sel_d0[7:0] == 8'b0))
      blk_wstrb_o[0] <= 1'b1;
    if (~(wr_sel_d0[15:8] == 8'b0))
      blk_wstrb_o[1] <= 1'b1;
    if (~(wr_sel_d0[23:16] == 8'b0))
      blk_wstrb_o[2] <= 1'b1;
    if (~(wr_sel_d0[31:24] == 8'b0))
      blk_wstrb_o[3] <= 1'b1;
  end
  assign blk_bready_o = 1'b1;
  assign blk_arvalid_o = blk_ar_val;
  assign blk_araddr_o = {wb_adr_i[2:2], 2'b00};
  assign blk_arprot_o = 3'b000;
  assign blk_rready_o = 1'b1;
  always @(posedge(clk_i))
  begin
    if (!rst_n_i)
      begin
        blk_aw_val <= 1'b0;
        blk_w_val <= 1'b0;
        blk_ar_val <= 1'b0;
      end
    else
      begin
        blk_aw_val <= blk_wr | (blk_aw_val & ~blk_awready_i);
        blk_w_val <= blk_wr | (blk_w_val & ~blk_wready_i);
        blk_ar_val <= blk_rd | (blk_ar_val & ~blk_arready_i);
      end
  end

  // Process for write requests.
  always @(wr_req_d0, blk_bvalid_i)
  begin
    blk_wr <= 1'b0;
    // Submap blk
    blk_wr <= wr_req_d0;
    wr_ack_int <= blk_bvalid_i;
  end

  // Process for read requests.
  always @(rd_req_int, blk_rdata_i, blk_rvalid_i)
  begin
    // By default ack read requests
    rd_dat_d0 <= {32{1'bx}};
    blk_rd <= 1'b0;
    // Submap blk
    blk_rd <= rd_req_int;
    rd_dat_d0 <= blk_rdata_i;
    rd_ack_d0 <= blk_rvalid_i;
  end
endmodule
