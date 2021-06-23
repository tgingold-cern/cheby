
module crossbar_wb
  (
    t_wishbone.slave wb,

    // WB bus jesdavalon
    t_wishbone.master jesdavalon,

    // WB bus i2ctowb
    t_wishbone.master i2ctowb,

    // WB bus bran
    t_wishbone.master bran
  );
  wire [17:2] adr_int;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg jesdavalon_re;
  reg jesdavalon_we;
  reg jesdavalon_wt;
  reg jesdavalon_rt;
  wire jesdavalon_tr;
  wire jesdavalon_wack;
  wire jesdavalon_rack;
  reg i2ctowb_re;
  reg i2ctowb_we;
  reg i2ctowb_wt;
  reg i2ctowb_rt;
  wire i2ctowb_tr;
  wire i2ctowb_wack;
  wire i2ctowb_rack;
  reg bran_re;
  reg bran_we;
  reg bran_wt;
  reg bran_rt;
  wire bran_tr;
  wire bran_wack;
  wire bran_rack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [17:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;
  reg [3:0] wr_sel_d0;

  // WB decode signals
  assign adr_int = wb.adr[17:2];
  assign wb_en = wb.cyc & wb.stb;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & !wb.we)) & !rd_ack_int;
  end
  assign rd_req_int = (wb_en & !wb.we) & !wb_rip;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb.we)) & !wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb.we) & !wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb.ack = ack_int;
  assign wb.stall = !ack_int & wb_en;
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
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb.dato;
        wr_sel_d0 <= wb.sel;
      end
  end

  // Interface jesdavalon
  assign jesdavalon_tr = jesdavalon_wt | jesdavalon_rt;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        jesdavalon_rt <= 1'b0;
        jesdavalon_wt <= 1'b0;
      end
    else
      begin
        jesdavalon_rt <= (jesdavalon_rt | jesdavalon_re) & !jesdavalon_rack;
        jesdavalon_wt <= (jesdavalon_wt | jesdavalon_we) & !jesdavalon_wack;
      end
  end
  assign jesdavalon.cyc = jesdavalon_tr;
  assign jesdavalon.stb = jesdavalon_tr;
  assign jesdavalon_wack = jesdavalon.ack & jesdavalon_wt;
  assign jesdavalon_rack = jesdavalon.ack & jesdavalon_rt;
  assign jesdavalon.adr = {22'b0, adr_int[9:2], 2'b0};
  assign jesdavalon.sel = wr_sel_d0;
  assign jesdavalon.we = jesdavalon_wt;
  assign jesdavalon.dato = wr_dat_d0;

  // Interface i2ctowb
  assign i2ctowb_tr = i2ctowb_wt | i2ctowb_rt;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        i2ctowb_rt <= 1'b0;
        i2ctowb_wt <= 1'b0;
      end
    else
      begin
        i2ctowb_rt <= (i2ctowb_rt | i2ctowb_re) & !i2ctowb_rack;
        i2ctowb_wt <= (i2ctowb_wt | i2ctowb_we) & !i2ctowb_wack;
      end
  end
  assign i2ctowb.cyc = i2ctowb_tr;
  assign i2ctowb.stb = i2ctowb_tr;
  assign i2ctowb_wack = i2ctowb.ack & i2ctowb_wt;
  assign i2ctowb_rack = i2ctowb.ack & i2ctowb_rt;
  assign i2ctowb.adr = {18'b0, adr_int[13:2], 2'b0};
  assign i2ctowb.sel = wr_sel_d0;
  assign i2ctowb.we = i2ctowb_wt;
  assign i2ctowb.dato = wr_dat_d0;

  // Interface bran
  assign bran_tr = bran_wt | bran_rt;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        bran_rt <= 1'b0;
        bran_wt <= 1'b0;
      end
    else
      begin
        bran_rt <= (bran_rt | bran_re) & !bran_rack;
        bran_wt <= (bran_wt | bran_we) & !bran_wack;
      end
  end
  assign bran.cyc = bran_tr;
  assign bran.stb = bran_tr;
  assign bran_wack = bran.ack & bran_wt;
  assign bran_rack = bran.ack & bran_rt;
  assign bran.adr = {15'b0, adr_int[16:2], 2'b0};
  assign bran.sel = wr_sel_d0;
  assign bran.we = bran_wt;
  assign bran.dato = wr_dat_d0;

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, jesdavalon_wack, i2ctowb_wack, bran_wack) 
      begin
        jesdavalon_we <= 1'b0;
        i2ctowb_we <= 1'b0;
        bran_we <= 1'b0;
        case (wr_adr_d0[17:17])
        1'b0: 
          case (wr_adr_d0[16:14])
          3'b000: 
            begin
              // Submap jesdavalon
              jesdavalon_we <= wr_req_d0;
              wr_ack_int <= jesdavalon_wack;
            end
          3'b001: 
            begin
              // Submap i2ctowb
              i2ctowb_we <= wr_req_d0;
              wr_ack_int <= i2ctowb_wack;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        1'b1: 
          begin
            // Submap bran
            bran_we <= wr_req_d0;
            wr_ack_int <= bran_wack;
          end
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(adr_int, rd_req_int, jesdavalon.dati, jesdavalon_rack, i2ctowb.dati, i2ctowb_rack, bran.dati, bran_rack) 
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        jesdavalon_re <= 1'b0;
        i2ctowb_re <= 1'b0;
        bran_re <= 1'b0;
        case (adr_int[17:17])
        1'b0: 
          case (adr_int[16:14])
          3'b000: 
            begin
              // Submap jesdavalon
              jesdavalon_re <= rd_req_int;
              rd_dat_d0 <= jesdavalon.dati;
              rd_ack_d0 <= jesdavalon_rack;
            end
          3'b001: 
            begin
              // Submap i2ctowb
              i2ctowb_re <= rd_req_int;
              rd_dat_d0 <= i2ctowb.dati;
              rd_ack_d0 <= i2ctowb_rack;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        1'b1: 
          begin
            // Submap bran
            bran_re <= rd_req_int;
            rd_dat_d0 <= bran.dati;
            rd_ack_d0 <= bran_rack;
          end
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
