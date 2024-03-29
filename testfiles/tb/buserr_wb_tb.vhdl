library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;


entity buserr_wb_tb is
end buserr_wb_tb;


architecture tb of buserr_wb_tb is
  signal rst_n  : std_logic;
  signal clk    : std_logic;
  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal reg_rw0 : std_logic_vector(31 downto 0);
  signal reg_rw1 : std_logic_vector(31 downto 0);
  signal reg_rw2 : std_logic_vector(31 downto 0);
  signal reg_ro0 : std_logic_vector(31 downto 0);
  signal reg_wo0 : std_logic_vector(31 downto 0);

  signal end_of_test : boolean := False;
begin
  --  Clock and reset
  clk_rst : process is
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;

    if end_of_test then
      wait;
    end if;
  end process clk_rst;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.buserr_wb
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
      wb_dat_o   => wb_out.dat,

      rw0_o      => reg_rw0,
      rw1_o      => reg_rw1,
      rw2_o      => reg_rw2,
      ro0_i      => reg_ro0,
      wo0_o      => reg_wo0
    );

  reg_ro0 <= x"4567_89ab";

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing regular read
    report "Testing regular read" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v, '0');
    assert reg_rw0 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    -- Testing regular write
    report "Testing regular write" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"9abc_def0", '0');
    assert reg_rw1 = x"9abc_def0" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v, '0');
    assert v = x"9abc_def0" severity error;

    --  Testing erroneous read
    report "Testing erroneous read" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_0014", v, '1');

    --  Testing regular read 2
    report "Testing regular read 2" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v, '0');
    assert reg_rw2 = x"3456_789a" severity error;
    assert v = x"3456_789a" severity error;

    --  Testing erroneous write
    report "Testing erroneous write" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0014", x"5678_9abc", '1');

    --  Testing regular read 3
    report "Testing regular read 3" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v, '0');
    assert reg_ro0 = x"4567_89ab" severity error;
    assert v = x"4567_89ab" severity error;

    --  Testing erroneous write to read-only register
    report "Testing erroneous write to read-only register" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"1234_5678", '1');

    --  Testing regular write 2
    report "Testing regular write 2" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0010", x"1234_5678", '0');
    wait until rising_edge(clk);
    assert reg_wo0 = x"1234_5678" severity error;

    --  Testing erroneous read to write-only register
    report "Testing erroneous read to write-only register" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_0010", v, '1');

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    report "End of test" severity note;
    end_of_test <= true;
  end process main;

  watchdog : process is
  begin
    wait until end_of_test for 7 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process watchdog;

end tb;
