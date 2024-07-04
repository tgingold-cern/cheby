entity reg2rw_wb_tb is
end reg2rw_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg2rw_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal rrw              : std_logic_vector(31 downto 0);

  signal rrw_rs           : std_logic_vector(31 downto 0);
  signal rrw_rs_rd        : std_logic;
  signal rrw_rs_rd_count  : natural;

  signal rrw_ws           : std_logic_vector(31 downto 0);
  signal rrw_ws_wr        : std_logic;
  signal rrw_ws_wr_count  : natural;

  signal rrw_rws          : std_logic_vector(31 downto 0);
  signal rrw_rws_wr       : std_logic;
  signal rrw_rws_rd       : std_logic;
  signal rrw_rws_wr_count : natural;
  signal rrw_rws_rd_count : natural;

  signal rrw_ws_wa        : std_logic_vector(31 downto 0);
  signal rrw_ws_wa_wr     : std_logic;
  signal rrw_ws_wa_wr_count : natural;
  signal rrw_ws_wa_wack   : std_logic;

  signal wrw_ws_in        : std_logic_vector(31 downto 0);
  signal wrw_ws_out       : std_logic_vector(31 downto 0);
  signal wrw_ws_out_val   : std_logic_vector(31 downto 0);
  signal wrw_ws_wr        : std_logic;
  signal wrw_ws_wr_count : natural;

  signal wrw_rws_in       : std_logic_vector(31 downto 0);
  signal wrw_rws_out      : std_logic_vector(31 downto 0);
  signal wrw_rws_out_val  : std_logic_vector(31 downto 0);
  signal wrw_rws_wr       : std_logic;
  signal wrw_rws_rd       : std_logic;
  signal wrw_rws_wr_count : natural;
  signal wrw_rws_rd_count : natural;

  signal wrw_ws_wa_in     : std_logic_vector(31 downto 0);
  signal wrw_ws_wa_out    : std_logic_vector(31 downto 0);
  signal wrw_ws_wa_out_val   : std_logic_vector(31 downto 0);
  signal wrw_ws_wa_wr     : std_logic;
  signal wrw_ws_wa_wr_count : natural;
  signal wrw_ws_wa_wack   : std_logic;
  signal wrw_ws_wa_wack_d   : std_logic;

  signal wrw_rws_wa_in    : std_logic_vector(31 downto 0);
  signal wrw_rws_wa_out   : std_logic_vector(31 downto 0);
  signal wrw_rws_wa_out_val   : std_logic_vector(31 downto 0);
  signal wrw_rws_wa_wr    : std_logic;
  signal wrw_rws_wa_rd    : std_logic;
  signal wrw_rws_wa_wr_count : natural;
  signal wrw_rws_wa_rd_count : natural;
  signal wrw_rws_wa_wack  : std_logic;

  signal wrw_rws_ra_in    : std_logic_vector(31 downto 0);
  signal wrw_rws_ra_out   : std_logic_vector(31 downto 0);
  signal wrw_rws_ra_in_val    : std_logic_vector(31 downto 0);
  signal wrw_rws_ra_out_val   : std_logic_vector(31 downto 0);
  signal wrw_rws_ra_wr    : std_logic;
  signal wrw_rws_ra_rd    : std_logic;
  signal wrw_rws_ra_wr_count : natural;
  signal wrw_rws_ra_rd_count : natural;
  signal wrw_rws_ra_rack  : std_logic;
  signal wrw_rws_ra_rack_d1  : std_logic;
  signal wrw_rws_ra_rack_d2  : std_logic;

  signal wrw_rws_rwa_in   : std_logic_vector(31 downto 0);
  signal wrw_rws_rwa_out  : std_logic_vector(31 downto 0);
  signal wrw_rws_rwa_in_val    : std_logic_vector(31 downto 0);
  signal wrw_rws_rwa_out_val   : std_logic_vector(31 downto 0);
  signal wrw_rws_rwa_wr   : std_logic;
  signal wrw_rws_rwa_rd   : std_logic;
  signal wrw_rws_rwa_wr_count : natural;
  signal wrw_rws_rwa_rd_count : natural;
  signal wrw_rws_rwa_wack : std_logic;
  signal wrw_rws_rwa_rack : std_logic;

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

  dut : entity work.reg2rw_wb
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_cyc_i   => wb_in.cyc,
      wb_stb_i   => wb_in.stb,
      wb_adr_i   => wb_in.adr(5 downto 2),
      wb_sel_i   => wb_in.sel,
      wb_we_i    => wb_in.we,
      wb_dat_i   => wb_in.dat,
      wb_ack_o   => wb_out.ack,
      wb_err_o   => wb_out.err,
      wb_rty_o   => wb_out.rty,
      wb_stall_o => wb_out.stall,
      wb_dat_o   => wb_out.dat,

      rrw_o              => rrw,
      rrw_rs_o           => rrw_rs,
      rrw_rs_rd_o        => rrw_rs_rd,
      rrw_ws_o           => rrw_ws,
      rrw_ws_wr_o        => rrw_ws_wr,
      rrw_rws_o          => rrw_rws,
      rrw_rws_wr_o       => rrw_rws_wr,
      rrw_rws_rd_o       => rrw_rws_rd,
      rrw_ws_wa_o        => rrw_ws_wa,
      rrw_ws_wa_wr_o     => rrw_ws_wa_wr,
      rrw_ws_wa_wack_i   => rrw_ws_wa_wack,
      wrw_ws_i           => wrw_ws_in,
      wrw_ws_o           => wrw_ws_out,
      wrw_ws_wr_o        => wrw_ws_wr,
      wrw_rws_i          => wrw_rws_in,
      wrw_rws_o          => wrw_rws_out,
      wrw_rws_wr_o       => wrw_rws_wr,
      wrw_rws_rd_o       => wrw_rws_rd,
      wrw_ws_wa_i        => wrw_ws_wa_in,
      wrw_ws_wa_o        => wrw_ws_wa_out,
      wrw_ws_wa_wr_o     => wrw_ws_wa_wr,
      wrw_ws_wa_wack_i   => wrw_ws_wa_wack,
      wrw_rws_wa_i       => wrw_rws_wa_in,
      wrw_rws_wa_o       => wrw_rws_wa_out,
      wrw_rws_wa_wr_o    => wrw_rws_wa_wr,
      wrw_rws_wa_rd_o    => wrw_rws_wa_rd,
      wrw_rws_wa_wack_i  => wrw_rws_wa_wack,
      wrw_rws_ra_i       => wrw_rws_ra_in,
      wrw_rws_ra_o       => wrw_rws_ra_out,
      wrw_rws_ra_wr_o    => wrw_rws_ra_wr,
      wrw_rws_ra_rd_o    => wrw_rws_ra_rd,
      wrw_rws_ra_rack_i  => wrw_rws_ra_rack,
      wrw_rws_rwa_i      => wrw_rws_rwa_in,
      wrw_rws_rwa_o      => wrw_rws_rwa_out,
      wrw_rws_rwa_wr_o   => wrw_rws_rwa_wr,
      wrw_rws_rwa_rd_o   => wrw_rws_rwa_rd,
      wrw_rws_rwa_wack_i => wrw_rws_rwa_wack,
      wrw_rws_rwa_rack_i => wrw_rws_rwa_rack);

  process(clk)
  begin
    if rising_edge(clk) then
      if rrw_rs_rd = '1' then
        rrw_rs_rd_count <= rrw_rs_rd_count + 1;
      end if;
      if rrw_ws_wr = '1' then
        rrw_ws_wr_count <= rrw_ws_wr_count + 1;
      end if;
      if rrw_rws_rd = '1' then
        rrw_rws_rd_count <= rrw_rws_rd_count + 1;
      end if;
      if rrw_rws_wr = '1' then
        rrw_rws_wr_count <= rrw_rws_wr_count + 1;
      end if;
      if rrw_ws_wa_wr = '1' then
        rrw_ws_wa_wr_count <= rrw_ws_wa_wr_count + 1;
      end if;
      if wrw_ws_wr = '1' then
        wrw_ws_wr_count <= wrw_ws_wr_count + 1;
        wrw_ws_out_val <= wrw_ws_out;
      end if;

      if wrw_rws_rd = '1' then
        wrw_rws_rd_count <= wrw_rws_rd_count + 1;
      end if;
      if wrw_rws_wr = '1' then
        wrw_rws_wr_count <= wrw_rws_wr_count + 1;
        wrw_rws_out_val <= wrw_rws_out;
      end if;

      if wrw_ws_wa_wr = '1' then
        wrw_ws_wa_wr_count <= wrw_ws_wa_wr_count + 1;
        wrw_ws_wa_out_val <= wrw_ws_wa_out;
      end if;

      if wrw_rws_wa_wr = '1' then
        wrw_rws_wa_wr_count <= wrw_rws_wa_wr_count + 1;
        wrw_rws_wa_out_val <= wrw_rws_wa_out;
      end if;
      if wrw_rws_wa_rd = '1' then
        wrw_rws_wa_rd_count <= wrw_rws_wa_rd_count + 1;
      end if;

      if wrw_rws_ra_wr = '1' then
        wrw_rws_ra_wr_count <= wrw_rws_ra_wr_count + 1;
        wrw_rws_ra_out_val <= wrw_rws_ra_out;
      end if;
      if wrw_rws_ra_rd = '1' then
        wrw_rws_ra_rd_count <= wrw_rws_ra_rd_count + 1;
      end if;

      if wrw_rws_rwa_wr = '1' then
        wrw_rws_rwa_wr_count <= wrw_rws_rwa_wr_count + 1;
        wrw_rws_rwa_out_val <= wrw_rws_rwa_out;
      end if;
      if wrw_rws_rwa_rd = '1' then
        wrw_rws_rwa_rd_count <= wrw_rws_rwa_rd_count + 1;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      rrw_ws_wa_wack <= rrw_ws_wa_wr;

      wrw_ws_wa_wack_d <= wrw_ws_wa_wr;
      wrw_ws_wa_wack <= wrw_ws_wa_wack_d;

      wrw_rws_wa_wack <= wrw_rws_wa_wr;

      wrw_rws_ra_rack_d1 <= wrw_rws_ra_rd;
      wrw_rws_ra_rack_d2 <= wrw_rws_ra_rack_d1;
      wrw_rws_ra_rack <= wrw_rws_ra_rack_d2;
      if wrw_rws_ra_rack_d2 = '1' then
        wrw_rws_ra_in <= wrw_rws_ra_in_val;
      else
        wrw_rws_ra_in <= not wrw_rws_ra_in_val;
      end if;

      wrw_rws_rwa_wack <= wrw_rws_rwa_wr;
      wrw_rws_rwa_rack <= wrw_rws_rwa_rd;
      if wrw_rws_rwa_rd = '1' then
        wrw_rws_rwa_in <= wrw_rws_rwa_in_val;
      else
        wrw_rws_rwa_in <= not wrw_rws_rwa_in_val;
      end if;
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

    --  Test rrw register
    assert rrw = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"abcd_0000");
    assert rrw = x"abcd_0000" severity error;

    --  rrw_rs register
    assert rrw_rs = x"0000_0000" severity error;
    assert rrw_rs_rd_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"abcd_0004");
    assert rrw_rs = x"abcd_0004" severity error;
    assert rrw_rs_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"abcd_0004" severity error;
    assert rrw_rs_rd_count = 1 severity error;

    --  rrw_ws register
    assert rrw_ws = x"0000_0000" severity error;
    assert rrw_ws_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"abcd_0008");
    wait until rising_edge(clk);
    assert rrw_ws = x"abcd_0008" severity error;
    assert rrw_ws_wr_count = 1 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"abcd_0008" severity error;
    assert rrw_ws_wr_count = 1 severity error;

    --  rrw_rws register
    assert rrw_rws = x"0000_0000" severity error;
    assert rrw_rws_wr_count = 0 severity error;
    assert rrw_rws_rd_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"abcd_000c");
    wait until rising_edge(clk);
    assert rrw_rws = x"abcd_000c" severity error;
    assert rrw_rws_wr_count = 1 severity error;
    assert rrw_rws_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"abcd_000c" severity error;
    assert rrw_rws_wr_count = 1 severity error;
    assert rrw_rws_rd_count = 1 severity error;

    --  rrw_ws_wa
    assert rrw_ws_wa = x"0000_0000" severity error;
    assert rrw_ws_wa_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0010", x"abcd_0010");
    assert rrw_ws_wa = x"abcd_0010" severity error;
    assert rrw_ws_wa_wr_count = 1 severity error;

    --  Check the state of the other registers has not changed.
    assert rrw = x"abcd_0000" severity error;

    assert rrw_rs = x"abcd_0004" severity error;
    assert rrw_rs_rd_count = 1 severity error;

    assert rrw_ws = x"abcd_0008" severity error;
    assert rrw_ws_wr_count = 1 severity error;

    assert rrw_rws = x"abcd_000c" severity error;
    assert rrw_rws_wr_count = 1 severity error;
    assert rrw_rws_rd_count = 1 severity error;

    --  wrw_ws register
    wrw_ws_in <= x"89ab_0014";
    assert wrw_ws_wr_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0014", v);
    assert v = x"89ab_0014" severity error;
    assert wrw_ws_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0014", x"56ef_0014");
    assert wrw_ws_out_val = x"56ef_0014" severity error;
    assert wrw_ws_wr_count = 1 severity error;

    --  wrw_rws register
    wrw_rws_in <= x"89ab_0018";
    assert wrw_rws_wr_count = 0 severity error;
    assert wrw_rws_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0018", v);
    assert v = x"89ab_0018" severity error;
    assert wrw_rws_wr_count = 0 severity error;
    assert wrw_rws_rd_count = 1 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0018", x"56ef_0018");
    assert wrw_rws_out_val = x"56ef_0018" severity error;
    assert wrw_rws_wr_count = 1 severity error;
    assert wrw_rws_rd_count = 1 severity error;

    --  wrw_ws_wa register
    wrw_ws_wa_in <= x"89ab_001c";
    assert wrw_ws_wa_wr_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_001c", v);
    assert v = x"89ab_001c" severity error;
    assert wrw_ws_wa_wr_count = 0 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_001c", x"56ef_001c");
    assert wrw_ws_wa_out_val = x"56ef_001c" severity error;
    assert wrw_ws_wa_wr_count = 1 severity error;

    --  wrw_rws_wa register
    wrw_rws_wa_in <= x"89ab_0020";
    assert wrw_rws_wa_wr_count = 0 severity error;
    assert wrw_rws_wa_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0020", v);
    assert v = x"89ab_0020" severity error;
    assert wrw_rws_wa_wr_count = 0 severity error;
    assert wrw_rws_wa_rd_count = 1 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0020", x"56ef_0020");
    assert wrw_rws_wa_out_val = x"56ef_0020" severity error;
    assert wrw_rws_wa_wr_count = 1 severity error;
    assert wrw_rws_wa_rd_count = 1 severity error;

    --  wrw_rws_ra register
    wrw_rws_ra_in_val <= x"89ab_0024";
    assert wrw_rws_ra_wr_count = 0 severity error;
    assert wrw_rws_ra_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0024", v);
    assert v = x"89ab_0024" severity error;
    assert wrw_rws_ra_wr_count = 0 severity error;
    assert wrw_rws_ra_rd_count = 1 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0024", x"56ef_0024");
    assert wrw_rws_ra_out_val = x"56ef_0024" severity error;
    assert wrw_rws_ra_wr_count = 1 severity error;
    assert wrw_rws_ra_rd_count = 1 severity error;

    --  wrw_rws_rwa register
    wrw_rws_rwa_in_val <= x"89ab_0028";
    assert wrw_rws_rwa_wr_count = 0 severity error;
    assert wrw_rws_rwa_rd_count = 0 severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0028", v);
    assert v = x"89ab_0028" severity error;
    assert wrw_rws_rwa_wr_count = 0 severity error;
    assert wrw_rws_rwa_rd_count = 1 severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0028", x"56ef_0028");
    assert wrw_rws_rwa_out_val = x"56ef_0028" severity error;
    assert wrw_rws_rwa_wr_count = 1 severity error;
    assert wrw_rws_rwa_rd_count = 1 severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
