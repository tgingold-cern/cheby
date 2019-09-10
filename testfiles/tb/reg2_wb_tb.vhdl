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

  signal rwo     : std_logic_vector(31 downto 0);

  signal rwo_st     : std_logic_vector(31 downto 0);
  signal rwo_st_wr  : std_logic;
  signal rwo_st_wr_count : natural := 0;

  signal rwo_sa     : std_logic_vector(31 downto 0);
  signal rwo_sa_val : std_logic_vector(31 downto 0);
  signal rwo_sa_wr  : std_logic;
  signal rwo_sa_wr_count : natural := 0;
  signal rwo_sa_wack : std_logic;

  signal wwo_st     : std_logic_vector(31 downto 0);
  signal wwo_st_val : std_logic_vector(31 downto 0);
  signal wwo_st_wr  : std_logic;
  signal wwo_st_wr_count : natural := 0;

  signal wwo_sa     : std_logic_vector(31 downto 0);
  signal wwo_sa_val : std_logic_vector(31 downto 0);
  signal wwo_sa_wr  : std_logic;
  signal wwo_sa_wr_count : natural := 0;
  signal wwo_sa_wack : std_logic;

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

  dut : entity work.reg2_wb
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

      reg1_o     => reg1,
      reg2_o     => reg2,
      reg2_wr_o  => reg2_wr,

      rwo_o         => rwo,
      rwo_st_o      => rwo_st,
      rwo_st_wr_o   => rwo_st_wr,
      rwo_sa_o      => rwo_sa,
      rwo_sa_wr_o   => rwo_sa_wr,
      rwo_sa_wack_i => rwo_sa_wack,

      wwo_st_o      => wwo_st,
      wwo_st_wr_o   => wwo_st_wr,
      wwo_sa_o      => wwo_sa,
      wwo_sa_wr_o   => wwo_sa_wr,
      wwo_sa_wack_i => wwo_sa_wack);

  assert reg2_wr |-> not reg2_wr
    report "reg2_wr must be a pulse" severity failure;

  process (clk)
  begin
    if rising_edge(clk) and reg2_wr = '1' then
      reg2_wr_count <= reg2_wr_count + 1;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) and rwo_st_wr = '1' then
      rwo_st_wr_count <= rwo_st_wr_count + 1;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) and rwo_sa_wr = '1' then
      rwo_sa_wr_count <= rwo_sa_wr_count + 1;
      rwo_sa_val <= rwo_sa;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      rwo_sa_wack <= rwo_sa_wr;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) and wwo_st_wr = '1' then
      wwo_st_wr_count <= wwo_st_wr_count + 1;
      wwo_st_val <= wwo_st;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) and wwo_sa_wr = '1' then
      wwo_sa_wr_count <= wwo_sa_wr_count + 1;
      wwo_sa_val <= wwo_sa;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      wwo_sa_wack <= wwo_sa_wr;
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

    --  Test rwo register
    assert rwo = x"0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"1234_0008");
    wait until rising_edge(clk);
    assert rwo = x"1234_0008" severity error;

    --  Test rwo_st register
    assert rwo_st = x"0000_0000" severity error;
    assert rwo_st_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"1234_000c");
    wait until rising_edge(clk);
    assert rwo_st_wr_count = 1 severity error;
    assert rwo_st = x"1234_000c" severity error;

    --  Test rwo_sa register
    assert rwo_sa = x"0000_0000" severity error;
    assert rwo_sa_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0010", x"1234_0010");
    wait until rising_edge(clk);
    assert rwo_sa_wr_count = 1 severity error;
    assert rwo_sa = x"1234_0010" severity error;
    assert rwo_sa_val = x"1234_0010" severity warning; --  FIXME

    --  Test wwo_st register
    assert wwo_st_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0014", x"1234_0014");
    wait until rising_edge(clk);
    wb_in.dat <= x"87654321";
    wait until rising_edge(clk);
    assert wwo_st_wr_count = 1 severity error;
    assert wwo_st = x"87654321" severity error;
    assert wwo_st_val = x"1234_0014" severity error;

    --  Test wwo_sa register
    assert wwo_sa_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0018", x"1234_0018");
    wait until rising_edge(clk);
    wb_in.dat <= x"87654321";
    wait until rising_edge(clk);
    assert wwo_sa_wr_count = 1 severity error;
    assert wwo_sa = x"87654321" severity error;
    assert wwo_sa_val = x"1234_0018" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
