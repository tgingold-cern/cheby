entity reg3wrw_wb_tb is
end reg3wrw_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg3wrw_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  type natural_vector is array(natural range <>) of natural;

  signal wrw_in            : std_logic_vector(63 downto 0);
  signal wrw_out           : std_logic_vector(63 downto 0);
  signal wrw_in_val        : std_logic_vector(63 downto 0);
  signal wrw_out_val       : std_logic_vector(63 downto 0) := (others => '0');
  signal wrw_wr            : std_logic_vector(1 downto 0);
  signal wrw_rd            : std_logic_vector(1 downto 0);
  signal wrw_wr_count      : natural_vector(1 downto 0);
  signal wrw_rd_count      : natural_vector(1 downto 0);
  signal wrw_wack          : std_logic_vector(1 downto 0);
  signal wrw_rack          : std_logic_vector(1 downto 0);

  signal fwrw_ws_f1_in     : std_logic_vector(11 downto 0);
  signal fwrw_ws_f1_out    : std_logic_vector(11 downto 0);
  signal fwrw_ws_f1_out_val : std_logic_vector(11 downto 0);
  signal fwrw_ws_f2_in     : std_logic_vector(15 downto 0);
  signal fwrw_ws_f2_out    : std_logic_vector(15 downto 0);
  signal fwrw_ws_f2_out_val : std_logic_vector(15 downto 0);
  signal fwrw_ws_f3_in     : std_logic_vector(23 downto 0);
  signal fwrw_ws_f3_out    : std_logic_vector(23 downto 0);
  signal fwrw_ws_f3_out_val : std_logic_vector(23 downto 0);
  signal fwrw_ws_wr        : std_logic_vector(1 downto 0);
  signal fwrw_ws_wr_count  : natural_vector(1 downto 0);

  signal fwrw_rws_f1_in       : std_logic_vector(11 downto 0);
  signal fwrw_rws_f1_out      : std_logic_vector(11 downto 0);
  signal fwrw_rws_f1_out_val  : std_logic_vector(11 downto 0);
  signal fwrw_rws_f2_in       : std_logic_vector(15 downto 0);
  signal fwrw_rws_f2_out      : std_logic_vector(15 downto 0);
  signal fwrw_rws_f2_out_val  : std_logic_vector(15 downto 0);
  signal fwrw_rws_f3_in       : std_logic_vector(23 downto 0);
  signal fwrw_rws_f3_out      : std_logic_vector(23 downto 0);
  signal fwrw_rws_f3_out_val  : std_logic_vector(23 downto 0);
  signal fwrw_rws_wr       : std_logic_vector(1 downto 0);
  signal fwrw_rws_rd       : std_logic_vector(1 downto 0);
  signal fwrw_rws_wr_count  : natural_vector(1 downto 0);
  signal fwrw_rws_rd_count  : natural_vector(1 downto 0);

  signal fwrw_rws_rwa_f1_in   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_in_val   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_out   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_out_val   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f2_in   : std_logic_vector(15 downto 0);
  signal fwrw_rws_rwa_f2_in_val   : std_logic_vector(15 downto 0);
  signal fwrw_rws_rwa_f2_out   : std_logic_vector(15 downto 0);
  signal fwrw_rws_rwa_f2_out_val   : std_logic_vector(15 downto 0);
  signal fwrw_rws_rwa_f3_in   : std_logic_vector(23 downto 0);
  signal fwrw_rws_rwa_f3_in_val   : std_logic_vector(23 downto 0);
  signal fwrw_rws_rwa_f3_out   : std_logic_vector(23 downto 0);
  signal fwrw_rws_rwa_f3_out_val   : std_logic_vector(23 downto 0);
  signal fwrw_rws_rwa_wr   : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_rd   : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_wr_count  : natural_vector(1 downto 0);
  signal fwrw_rws_rwa_rd_count  : natural_vector(1 downto 0);
  signal fwrw_rws_rwa_wack : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_rack : std_logic_vector(1 downto 0);

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

  dut : entity work.reg3wrw_wb
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

      wrw_i               => wrw_in,
      wrw_o               => wrw_out,
      wrw_wr_o            => wrw_wr,
      wrw_rd_o            => wrw_rd,
      wrw_wack_i          => wrw_wack,
      wrw_rack_i          => wrw_rack,

      fwrw_ws_f1_i        => fwrw_ws_f1_in,
      fwrw_ws_f1_o        => fwrw_ws_f1_out,
      fwrw_ws_f2_i        => fwrw_ws_f2_in,
      fwrw_ws_f2_o        => fwrw_ws_f2_out,
      fwrw_ws_f3_i        => fwrw_ws_f3_in,
      fwrw_ws_f3_o        => fwrw_ws_f3_out,
      fwrw_ws_wr_o        => fwrw_ws_wr,

      fwrw_rws_f1_i       => fwrw_rws_f1_in,
      fwrw_rws_f1_o       => fwrw_rws_f1_out,
      fwrw_rws_f2_i       => fwrw_rws_f2_in,
      fwrw_rws_f2_o       => fwrw_rws_f2_out,
      fwrw_rws_f3_i       => fwrw_rws_f3_in,
      fwrw_rws_f3_o       => fwrw_rws_f3_out,
      fwrw_rws_wr_o       => fwrw_rws_wr,
      fwrw_rws_rd_o       => fwrw_rws_rd,

      fwrw_rws_rwa_f1_i   => fwrw_rws_rwa_f1_in,
      fwrw_rws_rwa_f1_o   => fwrw_rws_rwa_f1_out,
      fwrw_rws_rwa_f2_i   => fwrw_rws_rwa_f2_in,
      fwrw_rws_rwa_f2_o   => fwrw_rws_rwa_f2_out,
      fwrw_rws_rwa_f3_i   => fwrw_rws_rwa_f3_in,
      fwrw_rws_rwa_f3_o   => fwrw_rws_rwa_f3_out,
      fwrw_rws_rwa_wr_o   => fwrw_rws_rwa_wr,
      fwrw_rws_rwa_rd_o   => fwrw_rws_rwa_rd,
      fwrw_rws_rwa_wack_i => fwrw_rws_rwa_wack,
      fwrw_rws_rwa_rack_i => fwrw_rws_rwa_rack);

  process (clk)
  begin
    if rising_edge(clk) then
      for i in wrw_wr'range loop
        if wrw_wr(i) = '1' then
          wrw_wr_count(i) <= wrw_wr_count(i) + 1;
        end if;
      end loop;
      for i in wrw_rd'range loop
        if wrw_rd(i) = '1' then
          wrw_rd_count(i) <= wrw_rd_count(i) + 1;
        end if;
      end loop;

      for i in fwrw_ws_wr'range loop
        if fwrw_ws_wr(i) = '1' then
          fwrw_ws_wr_count(i) <= fwrw_ws_wr_count(i) + 1;
        end if;
      end loop;

      for i in fwrw_rws_wr'range loop
        if fwrw_rws_wr(i) = '1' then
          fwrw_rws_wr_count(i) <= fwrw_rws_wr_count(i) + 1;
        end if;
      end loop;
      for i in fwrw_rws_rd'range loop
        if fwrw_rws_rd(i) = '1' then
          fwrw_rws_rd_count(i) <= fwrw_rws_rd_count(i) + 1;
        end if;
      end loop;

      for i in fwrw_rws_rwa_wr'range loop
        if fwrw_rws_rwa_wr(i) = '1' then
          fwrw_rws_rwa_wr_count(i) <= fwrw_rws_rwa_wr_count(i) + 1;
        end if;
      end loop;
      for i in fwrw_rws_rwa_rd'range loop
        if fwrw_rws_rwa_rd(i) = '1' then
          fwrw_rws_rwa_rd_count(i) <= fwrw_rws_rwa_rd_count(i) + 1;
        end if;
      end loop;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      wrw_wack <= wrw_wr;
      wrw_rack <= wrw_rd;
      if wrw_wr (1) = '1' then
        wrw_out_val (63 downto 32) <= wrw_out (63 downto 32);
      end if;
      if wrw_wr (0) = '1' then
        wrw_out_val (31 downto 0) <= wrw_out (31 downto 0);
      end if;
      if wrw_rd (1) = '1' then
        wrw_in (63 downto 32) <= wrw_in_val (63 downto 32);
      else
        wrw_in (63 downto 32) <= not wrw_in_val (63 downto 32);
      end if;
      if wrw_rd (0) = '1' then
        wrw_in (31 downto 0) <= wrw_in_val (31 downto 0);
      else
        wrw_in (31 downto 0) <= not wrw_in_val (31 downto 0);
      end if;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        fwrw_ws_f1_out_val <= (others => '0');
        fwrw_ws_f2_out_val <= (others => '0');
        fwrw_ws_f3_out_val <= (others => '0');
      else
        if fwrw_ws_wr (1) = '1' then
          fwrw_ws_f3_out_val <= fwrw_ws_f3_out;
          fwrw_ws_f2_out_val (15 downto 8) <= fwrw_ws_f2_out (15 downto 8);
        end if;
        if fwrw_ws_wr (0) = '1' then
          fwrw_ws_f1_out_val <= fwrw_ws_f1_out;
          fwrw_ws_f2_out_val (7 downto 0) <= fwrw_ws_f2_out (7 downto 0);
        end if;
      end if;

      if rst_n = '0' then
        fwrw_rws_f1_out_val <= (others => '0');
        fwrw_rws_f2_out_val <= (others => '0');
        fwrw_rws_f3_out_val <= (others => '0');
      else
        if fwrw_rws_wr (1) = '1' then
          fwrw_rws_f3_out_val <= fwrw_rws_f3_out;
          fwrw_rws_f2_out_val (15 downto 8) <= fwrw_rws_f2_out (15 downto 8);
        end if;
        if fwrw_rws_wr (0) = '1' then
          fwrw_rws_f1_out_val <= fwrw_rws_f1_out;
          fwrw_rws_f2_out_val (7 downto 0) <= fwrw_rws_f2_out (7 downto 0);
        end if;
      end if;

      if rst_n = '0' then
        fwrw_rws_rwa_f1_out_val <= (others => '0');
        fwrw_rws_rwa_f2_out_val <= (others => '0');
        fwrw_rws_rwa_f3_out_val <= (others => '0');
        fwrw_rws_rwa_wack <= (others => '0');
      else
        fwrw_rws_rwa_wack <= fwrw_rws_rwa_wr;
        if fwrw_rws_rwa_wr (1) = '1' then
          fwrw_rws_rwa_f3_out_val <= fwrw_rws_rwa_f3_out;
          fwrw_rws_rwa_f2_out_val (15 downto 8) <= fwrw_rws_rwa_f2_out (15 downto 8);
        end if;
        if fwrw_rws_rwa_wr (0) = '1' then
          fwrw_rws_rwa_f1_out_val <= fwrw_rws_rwa_f1_out;
          fwrw_rws_rwa_f2_out_val (7 downto 0) <= fwrw_rws_rwa_f2_out (7 downto 0);
        end if;
      end if;
      if rst_n = '0' then
        fwrw_rws_rwa_rack <= (others => '0');
      else
        fwrw_rws_rwa_rack <= fwrw_rws_rwa_rd;
        if fwrw_rws_rwa_rd (1) = '1' then
          fwrw_rws_rwa_f3_in <= fwrw_rws_rwa_f3_in_val;
          fwrw_rws_rwa_f2_in (15 downto 8) <= fwrw_rws_rwa_f2_in_val (15 downto 8);
        else
          fwrw_rws_rwa_f3_in <= (others => '1');
          fwrw_rws_rwa_f2_in (15 downto 8) <= (others => '1');
        end if;
        if fwrw_rws_rwa_rd (0) = '1' then
          fwrw_rws_rwa_f1_in <= fwrw_rws_rwa_f1_in_val;
          fwrw_rws_rwa_f2_in (7 downto 0) <= fwrw_rws_rwa_f2_in_val (7 downto 0);
        else
          fwrw_rws_rwa_f1_in <= (others => '1');
          fwrw_rws_rwa_f2_in (7 downto 0) <= (others => '1');
        end if;
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
    wrw_in_val <= x"1234_5678_9abc_def0";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert wrw_rd_count = (1, 0) severity error;
    assert v = x"1234_5678" report "v=" & to_hstring(v) severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert wrw_rd_count = (1, 1) severity error;
    assert v = x"9abc_def0" severity error;
    assert wrw_out_val = x"0000_0000_0000_0000" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"abcd_0000");
    assert wrw_wr_count = (1, 0) severity error;
    assert wrw_out_val = x"abcd_0000_0000_0000"
      report "v=" & to_hstring(v) severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"abcd_0004");
    assert wrw_wr_count = (1, 1) severity error;
    assert wrw_rd_count = (1, 1) severity error;
    assert wrw_out_val = x"abcd_0000_abcd_0004" severity error;

    --  Test frrw_ws register
    fwrw_ws_f1_in <= x"120";
    fwrw_ws_f2_in <= x"3456";
    fwrw_ws_f3_in <= x"78_9abc";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"789a_bc34" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"5600_0120" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"abcd_9876");
    assert fwrw_ws_wr_count = (1, 0) severity error;
    assert fwrw_ws_f1_out_val = x"000" severity error;
    assert fwrw_ws_f2_out_val = x"7600" severity error;
    assert fwrw_ws_f3_out_val = x"ab_cd98" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"4321_ef05");
    assert wrw_wr_count = (1, 1) severity error;
    assert fwrw_ws_f1_out_val = x"f05" severity error;
    assert fwrw_ws_f2_out_val = x"7643" severity error;
    assert fwrw_ws_f3_out_val = x"ab_cd98" severity error;

    --  Test frrw_rws register
    fwrw_rws_f1_in <= x"210";
    fwrw_rws_f2_in <= x"3546";
    fwrw_rws_f3_in <= x"87_a9bc";
    wb_readl(clk, wb_out, wb_in, x"0000_0010", v);
    assert fwrw_rws_rd_count = (1, 0) severity error;
    assert v = x"87a9_bc35" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0014", v);
    assert fwrw_rws_rd_count = (1, 1) severity error;
    assert v = x"4600_0210" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0010", x"badc_9786");
    assert fwrw_rws_wr_count = (1, 0) severity error;
    assert fwrw_rws_f1_out_val = x"000" severity error;
    assert fwrw_rws_f2_out_val = x"8600" severity error;
    assert fwrw_rws_f3_out_val = x"ba_dc97" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0014", x"3421_e0f5");
    assert fwrw_rws_wr_count = (1, 1) severity error;
    assert fwrw_rws_f1_out_val = x"0f5" severity error;
    assert fwrw_rws_f2_out_val = x"8634" severity error;
    assert fwrw_rws_f3_out_val = x"ba_dc97" severity error;

    --  Test frrw_rws_rwa register
    fwrw_rws_rwa_f1_in_val <= x"218";
    fwrw_rws_rwa_f2_in_val <= x"3564";
    fwrw_rws_rwa_f3_in_val <= x"87_ba9c";
    wb_readl(clk, wb_out, wb_in, x"0000_0018", v);
    assert fwrw_rws_rwa_rd_count = (1, 0) severity error;
    assert v = x"87ba9c_35" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_001c", v);
    assert fwrw_rws_rwa_rd_count = (1, 1) severity error;
    assert v = x"6400_0218" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0018", x"bdac_7968");
    assert fwrw_rws_rwa_wr_count = (1, 0) severity error;
    assert fwrw_rws_rwa_f1_out_val = x"000" severity error;
    assert fwrw_rws_rwa_f2_out_val = x"6800" severity error;
    assert fwrw_rws_rwa_f3_out_val = x"bd_ac79" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_001c", x"3241_0e5f");
    assert fwrw_rws_rwa_wr_count = (1, 1) severity error;
    assert fwrw_rws_rwa_f1_out_val = x"e5f" severity error;
    assert fwrw_rws_rwa_f2_out_val = x"6832" severity error;
    assert fwrw_rws_rwa_f3_out_val = x"bd_ac79" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
