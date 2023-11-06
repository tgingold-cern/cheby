module cheby_dpssram #(
  parameter g_data_width = 32,
  parameter g_size = 1024,
  parameter g_addr_width = 10,
  parameter g_dual_clock = 1'b1,
  parameter g_use_bwsel = 1'b1
) (
  input logic clk_a_i,
  input logic clk_b_i,
  input logic [g_addr_width - 1:0] addr_a_i,
  input logic [g_addr_width - 1:0] addr_b_i,
  input logic [g_data_width - 1:0] data_a_i,
  input logic [g_data_width - 1:0] data_b_i,
  output logic [g_data_width - 1:0] data_a_o,
  output logic [g_data_width - 1:0] data_b_o,
  input logic [((g_data_width + 7) / 8) - 1:0] bwsel_a_i,
  input logic [((g_data_width + 7) / 8) - 1:0] bwsel_b_i,
  input logic rd_a_i,
  input logic rd_b_i,
  input logic wr_a_i,
  input logic wr_b_i
);

  typedef logic [g_data_width - 1:0] word_t;
  typedef logic [g_addr_width - 1:0] addr_t;

  typedef word_t ram_t[0:(1 << g_addr_width) - 1];
  ram_t ram;
  word_t mask_a;
  word_t mask_b;
  addr_t addr_a;
  addr_t addr_b;

  always @(posedge clk_a_i) begin
    for (int idx = 0; idx < (g_data_width + 7) / 8; idx = idx + 1) begin
      mask_a[idx] <= bwsel_a_i[idx / 8];
    end

    if (wr_a_i) begin
      addr_a <= addr_a_i;
      ram[addr_a] <= (ram[addr_a] & ~mask_a) | (data_a_i & mask_a);
    end
    if (rd_a_i) begin
      addr_a <= addr_a_i;
      data_a_o <= ram[addr_a];
    end
  end;

  always @(posedge clk_b_i) begin
    for (int idx = 0; idx < (g_data_width + 7) / 8; idx = idx + 1) begin
      mask_b[idx] <= bwsel_b_i[idx / 8];
    end

    if (wr_b_i) begin
      addr_b <= addr_b_i;
      ram[addr_b] <= (ram[addr_b] & ~mask_b) | (data_b_i & mask_b);
    end
    if (rd_b_i) begin
      addr_b <= addr_b_i;
      data_b_o <= ram[addr_b];
    end
  end
endmodule