
module sramro
  (
    t_wishbone.slave wb,

    // SRAM bus mymem
    output  wire [7:2] mymem_addr_o,
    input   wire [31:0] mymem_data_i
  );
  wire [7:2] adr_int;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg mymem_rack;
  reg mymem_re;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;

  // WB decode signals
  always @(wb.sel)
      ;
  assign adr_int = wb.adr[7:2];
  assign wb_en = wb.cyc & wb.stb;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb.we)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb.we) & ~wb_rip;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb.we)) & ~wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb.we) & ~wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb.ack = ack_int;
  assign wb.stall = ~ack_int & wb_en;
  assign wb.rty = 1'b0;
  assign wb.err = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb.dati <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
      end
  end

  // Interface mymem
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      mymem_rack <= 1'b0;
    else
      mymem_rack <= mymem_re & ~mymem_rack;
  end
  assign mymem_addr_o = adr_int[7:2];

  // Process for write requests.
  always @(wr_req_d0)
      // Memory mymem
      wr_ack_int <= wr_req_d0;

  // Process for read requests.
  always @(mymem_data_i, mymem_rack, rd_req_int)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        mymem_re <= 1'b0;
        // Memory mymem
        rd_dat_d0 <= mymem_data_i;
        rd_ack_d0 <= mymem_rack;
        mymem_re <= rd_req_int;
      end
endmodule
