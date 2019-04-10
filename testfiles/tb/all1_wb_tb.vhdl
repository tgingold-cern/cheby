entity all1_wb_tb is
end all1_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;
use work.axi4_tb_pkg.all;
use work.cernbe_tb_pkg.all;

architecture behav of all1_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal reg1    : std_logic_vector(31 downto 0);
  signal reg2    : std_logic_vector(31 downto 0);

  --  For sub1.
  signal sub1_wb_in  : t_wishbone_slave_in;
  signal sub1_wb_out : t_wishbone_slave_out;

  --  For sub2.
  signal sub2_wr_in   : t_axi4lite_write_slave_in;
  signal sub2_wr_out  : t_axi4lite_write_slave_out;
  signal sub2_rd_in   : t_axi4lite_read_slave_in;
  signal sub2_rd_out  : t_axi4lite_read_slave_out;

  --  For sub3.
  signal sub3_in      : t_cernbe_slave_in;
  signal sub3_out     : t_cernbe_slave_out;

  signal end_of_test : boolean := false;
begin
  --  Clock and reset
  process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;

    if end_of_test then
      wait;
    end if;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.all1_wb
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_i       => wb_in,
      wb_o       => wb_out,

      reg1_o     => reg1,
      reg2_o     => reg2,

      ram1_adr_i     => (others => '0'),
      ram1_val_rd_i  => '0',
      ram1_val_dat_o => open,

      sub1_wb_cyc_o => sub1_wb_in.cyc,
      sub1_wb_stb_o => sub1_wb_in.stb,
      sub1_wb_adr_o => sub1_wb_in.adr(11 downto 2),
      sub1_wb_sel_o => sub1_wb_in.sel,
      sub1_wb_we_o  => sub1_wb_in.we,
      sub1_wb_dat_o => sub1_wb_in.dat,
      sub1_wb_ack_i => sub1_wb_out.ack,
      sub1_wb_err_i => sub1_wb_out.err,
      sub1_wb_rty_i => sub1_wb_out.rty,
      sub1_wb_stall_i => sub1_wb_out.stall,
      sub1_wb_dat_i => sub1_wb_out.dat,

      sub2_axi4_awvalid_o  => sub2_wr_in.awvalid,
      sub2_axi4_awready_i  => sub2_wr_out.awready,
      sub2_axi4_awaddr_o   => sub2_wr_in.awaddr(11 downto 2),
      sub2_axi4_awprot_o   => sub2_wr_in.awprot,
      sub2_axi4_wvalid_o   => sub2_wr_in.wvalid,
      sub2_axi4_wready_i   => sub2_wr_out.wready,
      sub2_axi4_wdata_o    => sub2_wr_in.wdata,
      sub2_axi4_wstrb_o    => sub2_wr_in.wstrb,
      sub2_axi4_bvalid_i   => sub2_wr_out.bvalid,
      sub2_axi4_bready_o   => sub2_wr_in.bready,
      sub2_axi4_bresp_i    => sub2_wr_out.bresp,
      sub2_axi4_arvalid_o  => sub2_rd_in.arvalid,
      sub2_axi4_arready_i  => sub2_rd_out.arready,
      sub2_axi4_araddr_o   => sub2_rd_in.araddr(11 downto 2),
      sub2_axi4_arprot_o   => sub2_rd_in.arprot,
      sub2_axi4_rvalid_i   => sub2_rd_out.rvalid,
      sub2_axi4_rready_o   => sub2_rd_in.rready,
      sub2_axi4_rdata_i    => sub2_rd_out.rdata,
      sub2_axi4_rresp_i    => sub2_rd_out.rresp,

      sub3_cernbe_VMEAddr_o => sub3_in.VMEAddr(11 downto 2),
      sub3_cernbe_VMERdData_i => sub3_out.VMERdData,
      sub3_cernbe_VMEWrData_o => sub3_in.VMEWrData,
      sub3_cernbe_VMERdMem_o  => sub3_in.VMERdMem,
      sub3_cernbe_VMEWrMem_o  => sub3_in.VMEWrMem,
      sub3_cernbe_VMERdDone_i => sub3_out.VMERdDone,
      sub3_cernbe_VMEWrDone_i => sub3_out.VMEWrDone
      );

    --  WB target
  b1: entity work.block1_wb
    port map (clk => clk,
              rst_n => rst_n,
              sub1_wb_in => sub1_wb_in,
              sub1_wb_out => sub1_wb_out);

  --  AXI4-lite target
  b2: entity work.block1_axi4
    port map (clk => clk,
              rst_n => rst_n,
              sub2_wr_in => sub2_wr_in,
              sub2_wr_out => sub2_wr_out,
              sub2_rd_in => sub2_rd_in,
              sub2_rd_out => sub2_rd_out);

  --  CERNBE target
  b3: entity work.block1_cernbe
    port map (clk => clk,
              rst_n => rst_n,
              bus_in => sub3_in,
              bus_out => sub3_out);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Register
    report "Testing register" severity note;
    wait until rising_edge(clk);
    wb_readl (clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1234_0000" severity error;
    assert reg1 = x"1234_0000" severity error;

    wb_readl (clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"1234_0002" severity error;
    assert reg2 = x"1234_0002" severity error;

    wb_writel (clk, wb_out, wb_in, x"0000_0000", x"abcd_0001");
    wait until rising_edge(clk);
    wb_readl (clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"abcd_0001" severity error;
    wait until rising_edge(clk);

    --  Memory
    report "Testing memory (write)" severity note;
    wb_writel (clk, wb_out, wb_in, x"0000_0024", x"abcd_0203");
    wait until rising_edge(clk);
    report "Testing memory (read)" severity note;
    wb_readl (clk, wb_out, wb_in, x"0000_0024", v);
    assert v = x"abcd_0203" severity error;

    --  Testing WB
    report "Testing wishbone (write)" severity note;
    wb_writel (clk, wb_out, wb_in, x"0000_1000", x"9876_5432");

    report "Testing wishbone (read)" severity note;
    wb_readl (clk, wb_out, wb_in, x"0000_1004", v);
    wait until rising_edge(clk);
    assert v = x"01fe_fe01" severity error;

    wb_readl (clk, wb_out, wb_in, x"0000_1000", v);
    assert v = x"9876_5432" severity error;

    --  Testing AXI4
    report "Testing AXI4 (read)" severity note;
    wb_readl (clk, wb_out, wb_in, x"0000_2004", v);
    assert v = x"01fe_fe01" severity error;

    report "Testing AXI4 (write)" severity note;
    wb_writel (clk, wb_out, wb_in, x"0000_2000", x"5555_aaaa");

    wb_writel (clk, wb_out, wb_in, x"0000_2004", x"fe01_01fe");

    wb_readl (clk, wb_out, wb_in, x"0000_2008", v);
    assert v = x"02fd_fd02" severity error;

    wb_readl (clk, wb_out, wb_in, x"0000_2000", v);
    assert v = x"5555_aaaa" severity error;

    --  Testing CERNBE
    report "Testing cernbe (write)" severity note;
    wb_writel (clk, wb_out, wb_in, x"0000_3000", x"9876_5432");

    report "Testing cernbe (read)" severity note;
    wb_readl (clk, wb_out, wb_in, x"0000_3004", v);
    wait until rising_edge(clk);
    assert v = x"01fe_fe01" severity error;

    wb_readl (clk, wb_out, wb_in, x"0000_3000", v);
    assert v = x"9876_5432" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;

  --  Watchdog.
  process
  begin
    wait until end_of_test for 1 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process;
end behav;
