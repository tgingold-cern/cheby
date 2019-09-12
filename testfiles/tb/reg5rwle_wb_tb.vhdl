entity reg5rwle_wb_tb is
end reg5rwle_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg5rwle_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal frrw_f1   : std_logic_vector(11 downto 0);
  signal frrw_f2   : std_logic_vector(15 downto 0);
  signal frrw_f3   : std_logic_vector(23 downto 0);

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

  --  Watchdog
  process
  begin
    wait until end_of_test for 1 us;
    assert end_of_test report "TIMEOUT" severity failure;
    wait;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.reg5rwle_wb
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_cyc_i   => wb_in.cyc,
      wb_stb_i   => wb_in.stb,
      wb_adr_i   => wb_in.adr(2 downto 2),
      wb_sel_i   => wb_in.sel,
      wb_we_i    => wb_in.we,
      wb_dat_i   => wb_in.dat,
      wb_ack_o   => wb_out.ack,
      wb_err_o   => wb_out.err,
      wb_rty_o   => wb_out.rty,
      wb_stall_o => wb_out.stall,
      wb_dat_o   => wb_out.dat,

      frrw_f1_o   => frrw_f1,
      frrw_f2_o   => frrw_f2,
      frrw_f3_o   => frrw_f3);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Register
    report "Testing register" severity note;

    --  Test frrw register
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"34_000000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"000000_12" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"dbca_7960");
    assert frrw_f1 = x"960" severity error;
    assert frrw_f2 = x"12db" severity error;
    assert frrw_f3 = x"000000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"3214_0ef5");
    assert frrw_f1 = x"960" severity error;
    assert frrw_f2 = x"f5db" severity error;
    assert frrw_f3 = x"32140e" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
