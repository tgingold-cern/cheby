entity reg2ro_wb_tb is
end reg2ro_wb_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg2ro_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal wro     : std_logic_vector(31 downto 0);

  signal wro_st     : std_logic_vector(31 downto 0);
  signal wro_st_val : std_logic_vector(31 downto 0);
  signal wro_st_rd  : std_logic;
  signal wro_st_rd_count : natural := 0;

  signal wro_sa     : std_logic_vector(31 downto 0);
  signal wro_sa_val : std_logic_vector(31 downto 0);
  signal wro_sa_rd  : std_logic;
  signal wro_sa_rd_count : natural := 0;
  signal wro_sa_rack : std_logic;

  signal wro_sa2     : std_logic_vector(31 downto 0);
  signal wro_sa2_val : std_logic_vector(31 downto 0);
  signal wro_sa2_rd  : std_logic;
  signal wro_sa2_rd_d1  : std_logic;
  signal wro_sa2_rd_d2  : std_logic;
  signal wro_sa2_rack : std_logic;
  signal wro_sa2_rd_count : natural := 0;

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

  dut : entity work.reg2ro_wb
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

      wro_i         => wro,

      wro_st_i      => wro_st,
      wro_st_rd_o   => wro_st_rd,

      wro_sa_i      => wro_sa,
      wro_sa_rd_o   => wro_sa_rd,
      wro_sa_rack_i => wro_sa_rack,

      wro_sa2_i      => wro_sa2,
      wro_sa2_rd_o   => wro_sa2_rd,
      wro_sa2_rack_i => wro_sa2_rack);

  process (clk)
  begin
    if rising_edge(clk) and wro_st_rd = '1' then
      wro_st_rd_count <= wro_st_rd_count + 1;
    end if;
  end process;

  wro_st <= wro_st_val when wro_st_rd = '1' else not wro_st_val;

  process (clk)
  begin
    if rising_edge(clk) and wro_sa_rd = '1' then
      wro_sa_rd_count <= wro_sa_rd_count + 1;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      wro_sa_rack <= wro_sa_rd;
      wro_sa <= wro_sa_val when wro_sa_rd = '1' else not wro_sa_val;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) and wro_sa2_rd = '1' then
      wro_sa2_rd_count <= wro_sa2_rd_count + 1;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        wro_sa2_rack <= '0';
        wro_sa2_rd_d1 <= '0';
        wro_sa2_rd_d2 <= '0';
      else
        wro_sa2_rd_d1 <= wro_sa2_rd;
        wro_sa2_rd_d2 <= wro_sa2_rd_d1;
        wro_sa2_rack <= wro_sa2_rd_d2;
      end if;
      wro_sa2 <= wro_sa2_val when wro_sa2_rd_d2 = '1' else not wro_sa2_val;
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

    --  Test rwo register
    wro <= x"1234_0000";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1234_0000" severity error;
    wro <= x"1234_abcd";
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1234_abcd" severity error;

    --  Test wro_st register
    assert wro_st_rd_count = 0 severity error;
    wro_st_val <= x"1234_0004";
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"1234_0004" severity error;
    assert wro_st_rd_count = 1 severity error;
    wro_st_val <= x"1234_4abc";
    wb_readl(clk, wb_out, wb_in, x"0000_0004", v);
    assert v = x"1234_4abc" severity error;
    assert wro_st_rd_count = 2 severity error;

    --  Test wro_sa register
    assert wro_sa_rd_count = 0 severity error;
    wro_sa_val <= x"1234_0008";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"1234_0008" severity error;
    assert wro_sa_rd_count = 1 severity error;
    wro_sa_val <= x"1234_8abc";
    wb_readl(clk, wb_out, wb_in, x"0000_0008", v);
    assert v = x"1234_8abc" severity error;
    assert wro_sa_rd_count = 2 severity error;

    --  Test wro_sa2 register
    assert wro_sa2_rd_count = 0 severity error;
    wro_sa2_val <= x"1234_000c";
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"1234_000c" severity error;
    assert wro_sa2_rd_count = 1 severity error;
    wro_sa2_val <= x"1234_cabc";
    wb_readl(clk, wb_out, wb_in, x"0000_000c", v);
    assert v = x"1234_cabc" severity error;
    assert wro_sa2_rd_count = 2 severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
