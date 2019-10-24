entity reg7const_wb_tb is
end reg7const_wb_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg7const_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

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

  dut : entity work.reg7const_wb
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_cyc_i   => wb_in.cyc,
      wb_stb_i   => wb_in.stb,
      wb_adr_i   => wb_in.adr(4 downto 2),
      wb_sel_i   => wb_in.sel,
      wb_we_i    => wb_in.we,
      wb_dat_i   => wb_in.dat,
      wb_ack_o   => wb_out.ack,
      wb_err_o   => wb_out.err,
      wb_rty_o   => wb_out.rty,
      wb_stall_o => wb_out.stall,
      wb_dat_o   => wb_out.dat);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Register
    report "Testing register" severity note;
    wait until rising_edge(clk);

    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"abcd1234" severity error;

    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"0003_0001" severity error;

    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"a000_00cb" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"a950_0001" severity error;

    wb_readl(clk, wb_out, wb_in, x"0000_0010", v);
    assert v = x"abcd1234" severity error;

    wb_readl(clk, wb_out, wb_in, x"0000_0014", v);
    assert v = x"567890ef" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
