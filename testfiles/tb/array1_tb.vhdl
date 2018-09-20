entity array1_tb is
end array1_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.tb_pkg.all;

architecture behav of array1_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

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

  dut : entity work.array1
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_i       => wb_in,
      wb_o       => wb_out,
      areg_adr_i => (others => '0'),
      areg_rd_i  => '0',
      areg_dat_o => open);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_in, wb_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    wait until rising_edge(clk);
    wb_writel (clk, wb_in, wb_out, x"0000_0001", x"abcd_0001");
    wait until rising_edge(clk);
    wb_writel (clk, wb_in, wb_out, x"0000_0003", x"abcd_0203");
    wait until rising_edge(clk);

    wb_readl (clk, wb_in, wb_out, x"0000_0001", v);
    assert v = x"abcd_0001" severity error;

    wait until rising_edge(clk);
    wb_readl (clk, wb_in, wb_out, x"0000_0003", v);
    assert v = x"abcd_0203" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
