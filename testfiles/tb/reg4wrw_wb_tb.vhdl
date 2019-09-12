entity reg4wrw_wb_tb is
end reg4wrw_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg4wrw_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  type natural_vector is array(natural range <>) of natural;

  signal fwrw_rws_f1_in   : std_logic_vector(11 downto 0);
  signal fwrw_rws_f1_in_val   : std_logic_vector(11 downto 0);
  signal fwrw_rws_f1_out   : std_logic_vector(11 downto 0);
  signal fwrw_rws_f1_out_val   : std_logic_vector(11 downto 0);
  signal fwrw_rws_f2_out   : std_logic_vector(15 downto 0);
  signal fwrw_rws_f2_out_val   : std_logic_vector(15 downto 0);
  signal fwrw_rws_f3_in   : std_logic_vector(23 downto 0);
  signal fwrw_rws_f3_in_val   : std_logic_vector(23 downto 0);
  signal fwrw_rws_f3_out   : std_logic_vector(23 downto 0);
  signal fwrw_rws_f3_out_val   : std_logic_vector(23 downto 0);
  signal fwrw_rws_wr   : std_logic_vector(1 downto 0);
  signal fwrw_rws_rd   : std_logic_vector(1 downto 0);
  signal fwrw_rws_wr_count  : natural_vector(1 downto 0);
  signal fwrw_rws_rd_count  : natural_vector(1 downto 0);

  signal fwrw_rws_rwa_f1_in   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_in_val   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_out   : std_logic_vector(11 downto 0);
  signal fwrw_rws_rwa_f1_out_val   : std_logic_vector(11 downto 0);
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

  dut : entity work.reg4wrw_wb
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

      fwrw_rws_f1_i   => fwrw_rws_f1_in,
      fwrw_rws_f1_o   => fwrw_rws_f1_out,
      fwrw_rws_f2_o   => fwrw_rws_f2_out,
      fwrw_rws_f3_i   => fwrw_rws_f3_in,
      fwrw_rws_f3_o   => fwrw_rws_f3_out,
      fwrw_rws_wr_o   => fwrw_rws_wr,
      fwrw_rws_rd_o   => fwrw_rws_rd,

      fwrw_rws_rwa_f1_i   => fwrw_rws_rwa_f1_in,
      fwrw_rws_rwa_f1_o   => fwrw_rws_rwa_f1_out,
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

  fwrw_rws_f3_in <= fwrw_rws_f3_in_val when fwrw_rws_rd (1) = '1'
              else (others => '1');
  fwrw_rws_f1_in <= fwrw_rws_f1_in_val when fwrw_rws_rd (0) = '1'
                    else (others => '1');

  process (clk)
  begin
    if rising_edge(clk) then
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
        else
          fwrw_rws_rwa_f3_in <= (others => '1');
        end if;
        if fwrw_rws_rwa_rd (0) = '1' then
          fwrw_rws_rwa_f1_in <= fwrw_rws_rwa_f1_in_val;
        else
          fwrw_rws_rwa_f1_in <= (others => '1');
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

    --  Test frrw_rws register
    fwrw_rws_f1_in_val <= x"210";
    fwrw_rws_f3_in_val <= x"87_bac9";
    wait until rising_edge(clk);
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert fwrw_rws_rd_count = (1, 0) severity error;
    assert v = x"87bac9_00" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert fwrw_rws_rd_count = (1, 1) severity error;
    assert v = x"0000_0210" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"dbca_7960");
    assert fwrw_rws_wr_count = (1, 0) severity error;
    assert fwrw_rws_f1_out_val = x"000" severity error;
    assert fwrw_rws_f2_out_val = x"6000" severity error;
    assert fwrw_rws_f3_out_val = x"db_ca79" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0004", x"3214_0ef5");
    assert fwrw_rws_wr_count = (1, 1) severity error;
    assert fwrw_rws_f1_out_val = x"ef5" severity error;
    assert fwrw_rws_f2_out_val = x"6032" severity error;
    assert fwrw_rws_f3_out_val = x"db_ca79" severity error;

    fwrw_rws_f1_in_val <= x"304";
    fwrw_rws_f3_in_val <= x"78_5634";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert fwrw_rws_rd_count = (2, 1) severity error;
    assert v = x"785634_60" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert fwrw_rws_rd_count = (2, 2) severity error;
    assert v = x"3200_0304" severity error;

    --  Test frrw_rws_rwa register
    fwrw_rws_rwa_f1_in_val <= x"218";
    fwrw_rws_rwa_f3_in_val <= x"87_ba9c";
    report "read1";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert fwrw_rws_rwa_rd_count = (1, 0) severity error;
    assert v = x"87ba9c_00" severity error;
    report "read2";
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert fwrw_rws_rwa_rd_count = (1, 1) severity error;
    assert v = x"0000_0218" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"bdac_7968");
    assert fwrw_rws_rwa_wr_count = (1, 0) severity error;
    assert fwrw_rws_rwa_f1_out_val = x"000" severity error;
    assert fwrw_rws_rwa_f2_out_val = x"6800" severity error;
    assert fwrw_rws_rwa_f3_out_val = x"bd_ac79" severity error;
    wb_writel(clk, wb_out, wb_in, x"0000_000c", x"3241_0e5f");
    assert fwrw_rws_rwa_wr_count = (1, 1) severity error;
    assert fwrw_rws_rwa_f1_out_val = x"e5f" severity error;
    assert fwrw_rws_rwa_f2_out_val = x"6832" severity error;
    assert fwrw_rws_rwa_f3_out_val = x"bd_ac79" severity error;

    fwrw_rws_rwa_f1_in_val <= x"304";
    fwrw_rws_rwa_f3_in_val <= x"78_6543";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert fwrw_rws_rwa_rd_count = (2, 1) severity error;
    assert v = x"786543_68" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert fwrw_rws_rwa_rd_count = (2, 2) severity error;
    assert v = x"3200_0304" severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
