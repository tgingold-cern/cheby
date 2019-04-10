entity reg2_wb_tb is
end reg2_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg2_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal reg1    : std_logic_vector(31 downto 0);
  signal reg2    : std_logic_vector(31 downto 0);

  signal reg2_wr : std_logic;
  signal reg2_wr_count : natural := 0;

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

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.reg2_wb
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

      reg1_o     => reg1,
      reg2_o     => reg2,
      reg2_wr_o  => reg2_wr);

  assert reg2_wr |-> not reg2_wr
    report "reg2_wr must be a pulse" severity failure;

  process (clk)
  begin
    if rising_edge(clk) and reg2_wr = '1' then
      reg2_wr_count <= reg2_wr_count + 1;
    end if;
  end process;

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
    assert v = x"abcd_1234" severity error;
    assert reg1 = x"abcd_1234" severity error;

    wb_readl (clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"abcd_1004" severity error;
    assert reg2 = x"abcd_1004" severity error;

    wb_writel (clk, wb_out, wb_in, x"0000_0000", x"abcd_0001");
    wait until rising_edge(clk);
    wb_readl (clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"abcd_0001" severity error;
    wait until rising_edge(clk);

    assert reg2_wr_count = 0 severity error;
    wb_writel (clk, wb_out, wb_in, x"0000_0004", x"abcd_0003");
    wait until rising_edge(clk);
    assert reg2_wr_count = 1 severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
