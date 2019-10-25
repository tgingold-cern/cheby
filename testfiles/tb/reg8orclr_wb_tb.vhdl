entity reg8orclr_wb_tb is
end reg8orclr_wb_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg8orclr_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal reg1 :   std_logic_vector(31 downto 0);

  signal reg2_f1 :   std_logic;
  signal reg2_f2 :   std_logic_vector(1 downto 0);

  signal reg3_f1 :   std_logic;
  signal reg3_f2 :   std_logic_vector(3 downto 0);
  signal reg3_f3 :   std_logic_vector(15 downto 0);
  signal reg3_f4 :   std_logic_vector(3 downto 0);

  signal end_of_test : boolean := false;

  default clock is clk;
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

  --  Watchdog
  process
  begin
    wait until end_of_test for 1 us;
    assert end_of_test report "TIMEOUT" severity failure;
    wait;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.reg8orclr_wb
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_cyc_i   => wb_in.cyc,
      wb_stb_i   => wb_in.stb,
      wb_adr_i   => wb_in.adr(3 downto 2),
      wb_sel_i   => wb_in.sel,
      wb_we_i    => wb_in.we,
      wb_dat_i   => wb_in.dat,
      wb_ack_o   => wb_out.ack,
      wb_err_o   => wb_out.err,
      wb_rty_o   => wb_out.rty,
      wb_stall_o => wb_out.stall,
      wb_dat_o   => wb_out.dat,

      reg1_i     => reg1,

      reg2_f1_i  => reg2_f1,
      reg2_f2_i  => reg2_f2,

      reg3_f1_i  => reg3_f1,
      reg3_f2_i  => reg3_f2,
      reg3_f3_i  => reg3_f3,
      reg3_f4_i  => reg3_f4);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    reg1 <= (31 downto 0 => '0');

    reg2_f1 <= '0';
    reg2_f2 <= (1 downto 0 => '0');

    reg3_f1 <= '0';
    reg3_f2 <= (3 downto 0 => '0');
    reg3_f3 <= (15 downto 0 => '0');
    reg3_f4 <= (3 downto 0 => '0');

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Register
    report "Testing register" severity note;
    wait until rising_edge(clk);

    --  Reg1
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"0000_0000" severity error;
    reg1 <= x"1001_0880";
    wait until rising_edge(clk);
    reg1 <= x"0000_0000";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1001_0880" report "reg1=" & to_hstring(v) severity error;
    reg1 <= x"0aa9_5703";
    wait until rising_edge(clk);
    reg1 <= x"0000_0000";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1aa9_5f83" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"1aa9_ff00");
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"0000_0083" severity error;

    --  Reg2
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"0003_0001" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"ffff_ffff");
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"0000_0000" severity error;
    reg2_f1 <= '1';
    reg2_f2 <= "01";
    wait until rising_edge(clk);
    reg2_f1 <= '0';
    reg2_f2 <= "00";
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"0001_0001" severity error;

    --  Reg3
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"a000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"0000_0001" severity error;
    reg3_f2 <= "1001";
    wait until rising_edge(clk);
    reg3_f2 <= "0000";
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"0090_0001" severity error;
    reg3_f3 <= x"bcde";
    wait until rising_edge(clk);
    reg3_f3 <= x"0000";
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"de90_0001" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"a000_00bc" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"ffff_0000");
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"0000_ffff");
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"0000_0001" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"a000_0000" severity error;
    reg3_f4 <= x"5";
    wait until rising_edge(clk);
    reg3_f4 <= x"0";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"f000_0000" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
