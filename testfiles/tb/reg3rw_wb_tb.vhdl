entity reg3rw_wb_tb is
end reg3rw_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg3rw_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  type natural_vector is array(natural range <>) of natural;

  signal rrw             : std_logic_vector(63 downto 0);

  signal frrw_f1         : std_logic_vector(11 downto 0);
  signal frrw_f2         : std_logic_vector(15 downto 0);
  signal frrw_f3         : std_logic_vector(23 downto 0);

  signal frrw_ws_f1      : std_logic_vector(11 downto 0);
  signal frrw_ws_f2      : std_logic_vector(15 downto 0);
  signal frrw_ws_f3      : std_logic_vector(23 downto 0);
  signal frrw_ws_wr      : std_logic_vector(1 downto 0);
  signal frrw_ws_wr_count  : natural_vector(1 downto 0);

  signal frrw_rws_f1     : std_logic_vector(11 downto 0);
  signal frrw_rws_f2     : std_logic_vector(15 downto 0);
  signal frrw_rws_f3     : std_logic_vector(23 downto 0);
  signal frrw_rws_wr     : std_logic_vector(1 downto 0);
  signal frrw_rws_rd     : std_logic_vector(1 downto 0);
  signal frrw_rws_wr_count  : natural_vector(1 downto 0);
  signal frrw_rws_rd_count  : natural_vector(1 downto 0);

  signal frrw_rws_rwa_f1 : std_logic_vector(11 downto 0);
  signal frrw_rws_rwa_f2 : std_logic_vector(15 downto 0);
  signal frrw_rws_rwa_f3 : std_logic_vector(23 downto 0);
  signal frrw_rws_rwa_wr : std_logic_vector(1 downto 0);
  signal frrw_rws_rwa_rd : std_logic_vector(1 downto 0);
  signal frrw_rws_rwa_wr_count  : natural_vector(1 downto 0);
  signal frrw_rws_rwa_rd_count  : natural_vector(1 downto 0);
  signal frrw_rws_rwa_wack  : std_logic_vector(1 downto 0);
  signal frrw_rws_rwa_rack  : std_logic_vector(1 downto 0);

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
    wait until end_of_test for 2 us;
    assert end_of_test report "TIMEOUT" severity failure;
    wait;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.reg3rw_wb
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

      rrw_o             => rrw,
      frrw_f1_o         => frrw_f1,
      frrw_f2_o         => frrw_f2,
      frrw_f3_o         => frrw_f3,
      frrw_ws_f1_o      => frrw_ws_f1,
      frrw_ws_f2_o      => frrw_ws_f2,
      frrw_ws_f3_o      => frrw_ws_f3,
      frrw_ws_wr_o      => frrw_ws_wr,
      frrw_rws_f1_o     => frrw_rws_f1,
      frrw_rws_f2_o     => frrw_rws_f2,
      frrw_rws_f3_o     => frrw_rws_f3,
      frrw_rws_wr_o     => frrw_rws_wr,
      frrw_rws_rd_o     => frrw_rws_rd,
      frrw_rws_rwa_f1_o => frrw_rws_rwa_f1,
      frrw_rws_rwa_f2_o => frrw_rws_rwa_f2,
      frrw_rws_rwa_f3_o => frrw_rws_rwa_f3,
      frrw_rws_rwa_wr_o => frrw_rws_rwa_wr,
      frrw_rws_rwa_rd_o => frrw_rws_rwa_rd,
      frrw_rws_rwa_wack_i => frrw_rws_rwa_wack,
      frrw_rws_rwa_rack_i => frrw_rws_rwa_rack);

  process (clk)
  begin
    if rising_edge(clk) then
      for i in frrw_ws_wr'range loop
        if frrw_ws_wr(i) = '1' then
          frrw_ws_wr_count(i) <= frrw_ws_wr_count(i) + 1;
        end if;
      end loop;

      for i in frrw_rws_wr'range loop
        if frrw_rws_wr(i) = '1' then
          frrw_rws_wr_count(i) <= frrw_rws_wr_count(i) + 1;
        end if;
      end loop;
      for i in frrw_rws_rd'range loop
        if frrw_rws_rd(i) = '1' then
          frrw_rws_rd_count(i) <= frrw_rws_rd_count(i) + 1;
        end if;
      end loop;

      for i in frrw_rws_rwa_wr'range loop
        if frrw_rws_rwa_wr(i) = '1' then
          frrw_rws_rwa_wr_count(i) <= frrw_rws_rwa_wr_count(i) + 1;
        end if;
      end loop;
      for i in frrw_rws_rwa_rd'range loop
        if frrw_rws_rwa_rd(i) = '1' then
          frrw_rws_rwa_rd_count(i) <= frrw_rws_rwa_rd_count(i) + 1;
        end if;
      end loop;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      frrw_rws_rwa_wack <= frrw_rws_rwa_wr;
      frrw_rws_rwa_rack <= frrw_rws_rwa_rd;
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
    assert rrw = x"0000_0000_0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"abcd_0000");
    assert rrw = x"abcd_0000_0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"abcd_0004");
    assert rrw = x"abcd_0000_abcd_0004" severity error;

    --  Test frrw
    assert frrw_f1 = x"000" severity error;
    assert frrw_f2 = x"0000" severity error;
    assert frrw_f3 = x"00_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"abcd_1208");
    assert frrw_f1 = x"000" severity error;
    assert frrw_f2 = x"08_00" severity error;
    assert frrw_f3 = x"ab_cd12" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"ef34_560c");
    assert frrw_f1 = x"60c" severity error;
    assert frrw_f2 = x"08_ef" severity error;
    assert frrw_f3 = x"ab_cd12" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"abcd_1208" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"ef00_060c" severity error;

    --  Test frrw_ws
    assert frrw_ws_f1 = x"000" severity error;
    assert frrw_ws_f2 = x"0000" severity error;
    assert frrw_ws_f3 = x"00_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0010", v);
    assert v = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0014", v);
    assert v = x"0000_0000" severity error;
    assert frrw_ws_wr_count = (0, 0) severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0010", x"abcd_1210");
    wait until rising_edge(clk);
    assert frrw_ws_wr_count = (1, 0) severity error;
    assert frrw_ws_f1 = x"000" severity error;
    assert frrw_ws_f2 = x"10_00" severity error;
    assert frrw_ws_f3 = x"ab_cd12" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0014", x"ef34_5614");
    wait until rising_edge(clk);
    assert frrw_ws_wr_count = (1, 1) severity error;
    assert frrw_ws_f1 = x"614" severity error;
    assert frrw_ws_f2 = x"10_ef" severity error;
    assert frrw_ws_f3 = x"ab_cd12" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0010", v);
    assert v = x"abcd_1210" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0014", v);
    assert v = x"ef00_0614" severity error;

    --  Test frrw_rws
    assert frrw_rws_f1 = x"000" severity error;
    assert frrw_rws_f2 = x"0000" severity error;
    assert frrw_rws_f3 = x"00_0000" severity error;
    assert frrw_rws_rd_count = (0, 0) severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0018", v);
    assert frrw_rws_rd_count = (1, 0) severity error;
    assert v = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_001c", v);
    assert frrw_rws_rd_count = (1, 1) severity error;
    assert v = x"0000_0000" severity error;
    assert frrw_rws_wr_count = (0, 0) severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0018", x"abcd_1218");
    wait until rising_edge(clk);
    assert frrw_rws_wr_count = (1, 0) severity error;
    assert frrw_rws_f1 = x"000" severity error;
    assert frrw_rws_f2 = x"18_00" severity error;
    assert frrw_rws_f3 = x"ab_cd12" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_001c", x"ef34_561c");
    wait until rising_edge(clk);
    assert frrw_rws_wr_count = (1, 1) severity error;
    assert frrw_rws_rd_count = (1, 1) severity error;
    assert frrw_rws_f1 = x"61c" severity error;
    assert frrw_rws_f2 = x"18_ef" severity error;
    assert frrw_rws_f3 = x"ab_cd12" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0018", v);
    assert frrw_rws_rd_count = (2, 1) severity error;
    assert v = x"abcd_1218" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_001c", v);
    assert frrw_rws_rd_count = (2, 2) severity error;
    assert v = x"ef00_061c" severity error;

    --  Test frrw_rws_rwa
    assert frrw_rws_rwa_f1 = x"000" severity error;
    assert frrw_rws_rwa_f2 = x"0000" severity error;
    assert frrw_rws_rwa_f3 = x"00_0000" severity error;
    assert frrw_rws_rwa_rd_count = (0, 0) severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0020", v);
    assert frrw_rws_rwa_rd_count = (1, 0) severity error;
    assert v = x"0000_0000" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0024", v);
    assert frrw_rws_rwa_rd_count = (1, 1) severity error;
    assert v = x"0000_0000" severity error;
    assert frrw_rws_rwa_wr_count = (0, 0) severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0020", x"abcd_1220");
    assert frrw_rws_rwa_wr_count = (1, 0) severity error;
    assert frrw_rws_rwa_f1 = x"000" severity error;
    assert frrw_rws_rwa_f2 = x"20_00" severity error;
    assert frrw_rws_rwa_f3 = x"ab_cd12" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0024", x"ef34_5624");
    assert frrw_rws_rwa_wr_count = (1, 1) severity error;
    assert frrw_rws_rwa_rd_count = (1, 1) severity error;
    assert frrw_rws_rwa_f1 = x"624" severity error;
    assert frrw_rws_rwa_f2 = x"20_ef" severity error;
    assert frrw_rws_rwa_f3 = x"ab_cd12" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0020", v);
    assert frrw_rws_rwa_rd_count = (2, 1) severity error;
    assert v = x"abcd_1220" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0024", v);
    assert frrw_rws_rwa_rd_count = (2, 2) severity error;
    assert v = x"ef00_0624" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
