interface t_pg_registers;
  logic [31:0] sample3_b32;
  logic [31:0] sample2_b32;
  logic [31:0] sample1_b32;
  logic [31:0] sample0_b32;
  logic [31:0] constant_b32;
  modport master(
    output sample3_b32,
    output sample2_b32,
    output sample1_b32,
    output sample0_b32,
    output constant_b32
  );
  modport slave(
    input sample3_b32,
    input sample2_b32,
    input sample1_b32,
    input sample0_b32,
    input constant_b32
  );
endinterface


module pg_wb
  (
    t_wishbone.slave wb,

    // REG Ctrl
    output  wire [3:0] enable_pg_b4,

    // REG Stat
    input   wire [3:0] enabled_pg_b4,
    t_pg_registers.master CH0,
    t_pg_registers.master CH1,
    t_pg_registers.master CH2,
    t_pg_registers.master CH3,

    // REG Token
    input   wire [31:0] Token_b32
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
  reg [3:0] Ctrl_EnablePGChannel_reg;
  reg Ctrl_wreq;
  wire Ctrl_wack;
  reg [31:0] CH0_os_Sample3_reg;
  reg CH0_os_Sample3_wreq;
  wire CH0_os_Sample3_wack;
  reg [31:0] CH0_os_Sample2_reg;
  reg CH0_os_Sample2_wreq;
  wire CH0_os_Sample2_wack;
  reg [31:0] CH0_os_Sample1_reg;
  reg CH0_os_Sample1_wreq;
  wire CH0_os_Sample1_wack;
  reg [31:0] CH0_os_Sample0_reg;
  reg CH0_os_Sample0_wreq;
  wire CH0_os_Sample0_wack;
  reg [31:0] CH0_os_Constant_reg;
  reg CH0_os_Constant_wreq;
  wire CH0_os_Constant_wack;
  reg [31:0] CH1_os_Sample3_reg;
  reg CH1_os_Sample3_wreq;
  wire CH1_os_Sample3_wack;
  reg [31:0] CH1_os_Sample2_reg;
  reg CH1_os_Sample2_wreq;
  wire CH1_os_Sample2_wack;
  reg [31:0] CH1_os_Sample1_reg;
  reg CH1_os_Sample1_wreq;
  wire CH1_os_Sample1_wack;
  reg [31:0] CH1_os_Sample0_reg;
  reg CH1_os_Sample0_wreq;
  wire CH1_os_Sample0_wack;
  reg [31:0] CH1_os_Constant_reg;
  reg CH1_os_Constant_wreq;
  wire CH1_os_Constant_wack;
  reg [31:0] CH2_os_Sample3_reg;
  reg CH2_os_Sample3_wreq;
  wire CH2_os_Sample3_wack;
  reg [31:0] CH2_os_Sample2_reg;
  reg CH2_os_Sample2_wreq;
  wire CH2_os_Sample2_wack;
  reg [31:0] CH2_os_Sample1_reg;
  reg CH2_os_Sample1_wreq;
  wire CH2_os_Sample1_wack;
  reg [31:0] CH2_os_Sample0_reg;
  reg CH2_os_Sample0_wreq;
  wire CH2_os_Sample0_wack;
  reg [31:0] CH2_os_Constant_reg;
  reg CH2_os_Constant_wreq;
  wire CH2_os_Constant_wack;
  reg [31:0] CH3_os_Sample3_reg;
  reg CH3_os_Sample3_wreq;
  wire CH3_os_Sample3_wack;
  reg [31:0] CH3_os_Sample2_reg;
  reg CH3_os_Sample2_wreq;
  wire CH3_os_Sample2_wack;
  reg [31:0] CH3_os_Sample1_reg;
  reg CH3_os_Sample1_wreq;
  wire CH3_os_Sample1_wack;
  reg [31:0] CH3_os_Sample0_reg;
  reg CH3_os_Sample0_wreq;
  wire CH3_os_Sample0_wack;
  reg [31:0] CH3_os_Constant_reg;
  reg CH3_os_Constant_wreq;
  wire CH3_os_Constant_wack;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [7:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always_comb
  ;
  assign adr_int = wb.adr[7:2];
  assign wb_en = wb.cyc & wb.stb;

  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb.we)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb.we) & ~wb_rip;

  always_ff @(posedge(wb.clk))
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
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      begin
        rd_ack_int <= 1'b0;
        wb.dati <= 32'b00000000000000000000000000000000;
        wr_req_d0 <= 1'b0;
        wr_adr_d0 <= 6'b000000;
        wr_dat_d0 <= 32'b00000000000000000000000000000000;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb.dati <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb.dato;
      end
  end

  // Register Ctrl
  assign enable_pg_b4 = Ctrl_EnablePGChannel_reg;
  assign Ctrl_wack = Ctrl_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      Ctrl_EnablePGChannel_reg <= 4'b0000;
    else
      if (Ctrl_wreq == 1'b1)
        Ctrl_EnablePGChannel_reg <= wr_dat_d0[3:0];
  end

  // Register Stat

  // Register CH0_os_Sample3
  assign CH0.sample3_b32 = CH0_os_Sample3_reg;
  assign CH0_os_Sample3_wack = CH0_os_Sample3_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH0_os_Sample3_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH0_os_Sample3_wreq == 1'b1)
        CH0_os_Sample3_reg <= wr_dat_d0;
  end

  // Register CH0_os_Sample2
  assign CH0.sample2_b32 = CH0_os_Sample2_reg;
  assign CH0_os_Sample2_wack = CH0_os_Sample2_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH0_os_Sample2_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH0_os_Sample2_wreq == 1'b1)
        CH0_os_Sample2_reg <= wr_dat_d0;
  end

  // Register CH0_os_Sample1
  assign CH0.sample1_b32 = CH0_os_Sample1_reg;
  assign CH0_os_Sample1_wack = CH0_os_Sample1_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH0_os_Sample1_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH0_os_Sample1_wreq == 1'b1)
        CH0_os_Sample1_reg <= wr_dat_d0;
  end

  // Register CH0_os_Sample0
  assign CH0.sample0_b32 = CH0_os_Sample0_reg;
  assign CH0_os_Sample0_wack = CH0_os_Sample0_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH0_os_Sample0_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH0_os_Sample0_wreq == 1'b1)
        CH0_os_Sample0_reg <= wr_dat_d0;
  end

  // Register CH0_os_Constant
  assign CH0.constant_b32 = CH0_os_Constant_reg;
  assign CH0_os_Constant_wack = CH0_os_Constant_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH0_os_Constant_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH0_os_Constant_wreq == 1'b1)
        CH0_os_Constant_reg <= wr_dat_d0;
  end

  // Register CH1_os_Sample3
  assign CH1.sample3_b32 = CH1_os_Sample3_reg;
  assign CH1_os_Sample3_wack = CH1_os_Sample3_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH1_os_Sample3_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH1_os_Sample3_wreq == 1'b1)
        CH1_os_Sample3_reg <= wr_dat_d0;
  end

  // Register CH1_os_Sample2
  assign CH1.sample2_b32 = CH1_os_Sample2_reg;
  assign CH1_os_Sample2_wack = CH1_os_Sample2_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH1_os_Sample2_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH1_os_Sample2_wreq == 1'b1)
        CH1_os_Sample2_reg <= wr_dat_d0;
  end

  // Register CH1_os_Sample1
  assign CH1.sample1_b32 = CH1_os_Sample1_reg;
  assign CH1_os_Sample1_wack = CH1_os_Sample1_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH1_os_Sample1_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH1_os_Sample1_wreq == 1'b1)
        CH1_os_Sample1_reg <= wr_dat_d0;
  end

  // Register CH1_os_Sample0
  assign CH1.sample0_b32 = CH1_os_Sample0_reg;
  assign CH1_os_Sample0_wack = CH1_os_Sample0_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH1_os_Sample0_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH1_os_Sample0_wreq == 1'b1)
        CH1_os_Sample0_reg <= wr_dat_d0;
  end

  // Register CH1_os_Constant
  assign CH1.constant_b32 = CH1_os_Constant_reg;
  assign CH1_os_Constant_wack = CH1_os_Constant_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH1_os_Constant_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH1_os_Constant_wreq == 1'b1)
        CH1_os_Constant_reg <= wr_dat_d0;
  end

  // Register CH2_os_Sample3
  assign CH2.sample3_b32 = CH2_os_Sample3_reg;
  assign CH2_os_Sample3_wack = CH2_os_Sample3_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH2_os_Sample3_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH2_os_Sample3_wreq == 1'b1)
        CH2_os_Sample3_reg <= wr_dat_d0;
  end

  // Register CH2_os_Sample2
  assign CH2.sample2_b32 = CH2_os_Sample2_reg;
  assign CH2_os_Sample2_wack = CH2_os_Sample2_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH2_os_Sample2_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH2_os_Sample2_wreq == 1'b1)
        CH2_os_Sample2_reg <= wr_dat_d0;
  end

  // Register CH2_os_Sample1
  assign CH2.sample1_b32 = CH2_os_Sample1_reg;
  assign CH2_os_Sample1_wack = CH2_os_Sample1_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH2_os_Sample1_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH2_os_Sample1_wreq == 1'b1)
        CH2_os_Sample1_reg <= wr_dat_d0;
  end

  // Register CH2_os_Sample0
  assign CH2.sample0_b32 = CH2_os_Sample0_reg;
  assign CH2_os_Sample0_wack = CH2_os_Sample0_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH2_os_Sample0_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH2_os_Sample0_wreq == 1'b1)
        CH2_os_Sample0_reg <= wr_dat_d0;
  end

  // Register CH2_os_Constant
  assign CH2.constant_b32 = CH2_os_Constant_reg;
  assign CH2_os_Constant_wack = CH2_os_Constant_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH2_os_Constant_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH2_os_Constant_wreq == 1'b1)
        CH2_os_Constant_reg <= wr_dat_d0;
  end

  // Register CH3_os_Sample3
  assign CH3.sample3_b32 = CH3_os_Sample3_reg;
  assign CH3_os_Sample3_wack = CH3_os_Sample3_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH3_os_Sample3_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH3_os_Sample3_wreq == 1'b1)
        CH3_os_Sample3_reg <= wr_dat_d0;
  end

  // Register CH3_os_Sample2
  assign CH3.sample2_b32 = CH3_os_Sample2_reg;
  assign CH3_os_Sample2_wack = CH3_os_Sample2_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH3_os_Sample2_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH3_os_Sample2_wreq == 1'b1)
        CH3_os_Sample2_reg <= wr_dat_d0;
  end

  // Register CH3_os_Sample1
  assign CH3.sample1_b32 = CH3_os_Sample1_reg;
  assign CH3_os_Sample1_wack = CH3_os_Sample1_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH3_os_Sample1_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH3_os_Sample1_wreq == 1'b1)
        CH3_os_Sample1_reg <= wr_dat_d0;
  end

  // Register CH3_os_Sample0
  assign CH3.sample0_b32 = CH3_os_Sample0_reg;
  assign CH3_os_Sample0_wack = CH3_os_Sample0_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH3_os_Sample0_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH3_os_Sample0_wreq == 1'b1)
        CH3_os_Sample0_reg <= wr_dat_d0;
  end

  // Register CH3_os_Constant
  assign CH3.constant_b32 = CH3_os_Constant_reg;
  assign CH3_os_Constant_wack = CH3_os_Constant_wreq;
  always_ff @(posedge(wb.clk))
  begin
    if (!wb.rst_n)
      CH3_os_Constant_reg <= 32'b00000000000000000000000000000000;
    else
      if (CH3_os_Constant_wreq == 1'b1)
        CH3_os_Constant_reg <= wr_dat_d0;
  end

  // Register Token

  // Process for write requests.
  always_comb
  begin
    Ctrl_wreq = 1'b0;
    CH0_os_Sample3_wreq = 1'b0;
    CH0_os_Sample2_wreq = 1'b0;
    CH0_os_Sample1_wreq = 1'b0;
    CH0_os_Sample0_wreq = 1'b0;
    CH0_os_Constant_wreq = 1'b0;
    CH1_os_Sample3_wreq = 1'b0;
    CH1_os_Sample2_wreq = 1'b0;
    CH1_os_Sample1_wreq = 1'b0;
    CH1_os_Sample0_wreq = 1'b0;
    CH1_os_Constant_wreq = 1'b0;
    CH2_os_Sample3_wreq = 1'b0;
    CH2_os_Sample2_wreq = 1'b0;
    CH2_os_Sample1_wreq = 1'b0;
    CH2_os_Sample0_wreq = 1'b0;
    CH2_os_Constant_wreq = 1'b0;
    CH3_os_Sample3_wreq = 1'b0;
    CH3_os_Sample2_wreq = 1'b0;
    CH3_os_Sample1_wreq = 1'b0;
    CH3_os_Sample0_wreq = 1'b0;
    CH3_os_Constant_wreq = 1'b0;
    case (wr_adr_d0[7:2])
    6'b000000:
      begin
        // Reg Ctrl
        Ctrl_wreq = wr_req_d0;
        wr_ack_int = Ctrl_wack;
      end
    6'b000001:
      // Reg Stat
      wr_ack_int = wr_req_d0;
    6'b001000:
      begin
        // Reg CH0_os_Sample3
        CH0_os_Sample3_wreq = wr_req_d0;
        wr_ack_int = CH0_os_Sample3_wack;
      end
    6'b001001:
      begin
        // Reg CH0_os_Sample2
        CH0_os_Sample2_wreq = wr_req_d0;
        wr_ack_int = CH0_os_Sample2_wack;
      end
    6'b001010:
      begin
        // Reg CH0_os_Sample1
        CH0_os_Sample1_wreq = wr_req_d0;
        wr_ack_int = CH0_os_Sample1_wack;
      end
    6'b001011:
      begin
        // Reg CH0_os_Sample0
        CH0_os_Sample0_wreq = wr_req_d0;
        wr_ack_int = CH0_os_Sample0_wack;
      end
    6'b001100:
      begin
        // Reg CH0_os_Constant
        CH0_os_Constant_wreq = wr_req_d0;
        wr_ack_int = CH0_os_Constant_wack;
      end
    6'b010000:
      begin
        // Reg CH1_os_Sample3
        CH1_os_Sample3_wreq = wr_req_d0;
        wr_ack_int = CH1_os_Sample3_wack;
      end
    6'b010001:
      begin
        // Reg CH1_os_Sample2
        CH1_os_Sample2_wreq = wr_req_d0;
        wr_ack_int = CH1_os_Sample2_wack;
      end
    6'b010010:
      begin
        // Reg CH1_os_Sample1
        CH1_os_Sample1_wreq = wr_req_d0;
        wr_ack_int = CH1_os_Sample1_wack;
      end
    6'b010011:
      begin
        // Reg CH1_os_Sample0
        CH1_os_Sample0_wreq = wr_req_d0;
        wr_ack_int = CH1_os_Sample0_wack;
      end
    6'b010100:
      begin
        // Reg CH1_os_Constant
        CH1_os_Constant_wreq = wr_req_d0;
        wr_ack_int = CH1_os_Constant_wack;
      end
    6'b011000:
      begin
        // Reg CH2_os_Sample3
        CH2_os_Sample3_wreq = wr_req_d0;
        wr_ack_int = CH2_os_Sample3_wack;
      end
    6'b011001:
      begin
        // Reg CH2_os_Sample2
        CH2_os_Sample2_wreq = wr_req_d0;
        wr_ack_int = CH2_os_Sample2_wack;
      end
    6'b011010:
      begin
        // Reg CH2_os_Sample1
        CH2_os_Sample1_wreq = wr_req_d0;
        wr_ack_int = CH2_os_Sample1_wack;
      end
    6'b011011:
      begin
        // Reg CH2_os_Sample0
        CH2_os_Sample0_wreq = wr_req_d0;
        wr_ack_int = CH2_os_Sample0_wack;
      end
    6'b011100:
      begin
        // Reg CH2_os_Constant
        CH2_os_Constant_wreq = wr_req_d0;
        wr_ack_int = CH2_os_Constant_wack;
      end
    6'b100000:
      begin
        // Reg CH3_os_Sample3
        CH3_os_Sample3_wreq = wr_req_d0;
        wr_ack_int = CH3_os_Sample3_wack;
      end
    6'b100001:
      begin
        // Reg CH3_os_Sample2
        CH3_os_Sample2_wreq = wr_req_d0;
        wr_ack_int = CH3_os_Sample2_wack;
      end
    6'b100010:
      begin
        // Reg CH3_os_Sample1
        CH3_os_Sample1_wreq = wr_req_d0;
        wr_ack_int = CH3_os_Sample1_wack;
      end
    6'b100011:
      begin
        // Reg CH3_os_Sample0
        CH3_os_Sample0_wreq = wr_req_d0;
        wr_ack_int = CH3_os_Sample0_wack;
      end
    6'b100100:
      begin
        // Reg CH3_os_Constant
        CH3_os_Constant_wreq = wr_req_d0;
        wr_ack_int = CH3_os_Constant_wack;
      end
    6'b101000:
      // Reg Token
      wr_ack_int = wr_req_d0;
    default:
      wr_ack_int = wr_req_d0;
    endcase
  end

  // Process for read requests.
  always_comb
  begin
    // By default ack read requests
    rd_dat_d0 = {32{1'bx}};
    case (adr_int[7:2])
    6'b000000:
      begin
        // Reg Ctrl
        rd_ack_d0 = rd_req_int;
        rd_dat_d0[3:0] = Ctrl_EnablePGChannel_reg;
        rd_dat_d0[31:4] = 28'b0;
      end
    6'b000001:
      begin
        // Reg Stat
        rd_ack_d0 = rd_req_int;
        rd_dat_d0[3:0] = enabled_pg_b4;
        rd_dat_d0[31:4] = 28'b0;
      end
    6'b001000:
      begin
        // Reg CH0_os_Sample3
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH0_os_Sample3_reg;
      end
    6'b001001:
      begin
        // Reg CH0_os_Sample2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH0_os_Sample2_reg;
      end
    6'b001010:
      begin
        // Reg CH0_os_Sample1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH0_os_Sample1_reg;
      end
    6'b001011:
      begin
        // Reg CH0_os_Sample0
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH0_os_Sample0_reg;
      end
    6'b001100:
      begin
        // Reg CH0_os_Constant
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH0_os_Constant_reg;
      end
    6'b010000:
      begin
        // Reg CH1_os_Sample3
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH1_os_Sample3_reg;
      end
    6'b010001:
      begin
        // Reg CH1_os_Sample2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH1_os_Sample2_reg;
      end
    6'b010010:
      begin
        // Reg CH1_os_Sample1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH1_os_Sample1_reg;
      end
    6'b010011:
      begin
        // Reg CH1_os_Sample0
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH1_os_Sample0_reg;
      end
    6'b010100:
      begin
        // Reg CH1_os_Constant
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH1_os_Constant_reg;
      end
    6'b011000:
      begin
        // Reg CH2_os_Sample3
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH2_os_Sample3_reg;
      end
    6'b011001:
      begin
        // Reg CH2_os_Sample2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH2_os_Sample2_reg;
      end
    6'b011010:
      begin
        // Reg CH2_os_Sample1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH2_os_Sample1_reg;
      end
    6'b011011:
      begin
        // Reg CH2_os_Sample0
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH2_os_Sample0_reg;
      end
    6'b011100:
      begin
        // Reg CH2_os_Constant
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH2_os_Constant_reg;
      end
    6'b100000:
      begin
        // Reg CH3_os_Sample3
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH3_os_Sample3_reg;
      end
    6'b100001:
      begin
        // Reg CH3_os_Sample2
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH3_os_Sample2_reg;
      end
    6'b100010:
      begin
        // Reg CH3_os_Sample1
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH3_os_Sample1_reg;
      end
    6'b100011:
      begin
        // Reg CH3_os_Sample0
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH3_os_Sample0_reg;
      end
    6'b100100:
      begin
        // Reg CH3_os_Constant
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = CH3_os_Constant_reg;
      end
    6'b101000:
      begin
        // Reg Token
        rd_ack_d0 = rd_req_int;
        rd_dat_d0 = Token_b32;
      end
    default:
      rd_ack_d0 = rd_req_int;
    endcase
  end
endmodule
