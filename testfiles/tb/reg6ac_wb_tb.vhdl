entity reg6ac_wb_tb is
end reg6ac_wb_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of reg6ac_wb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal reg1 :   std_logic_vector(31 downto 0);

  signal reg2_f1 :   std_logic;
  signal reg2_f2 :   std_logic_vector(1 downto 0);

  signal reg3_f1 :   std_logic;
  signal reg3_f2 :   std_logic_vector(3 downto 0);
  signal reg3_f3 :   std_logic_vector(3 downto 0);


  signal reg1_sum : unsigned(31 downto 0);
  signal reg2_f1_sum : unsigned(7 downto 0);
  signal reg2_f2_sum : unsigned(15 downto 0);

  signal reg3_f1_sum : unsigned(7 downto 0);
  signal reg3_f2_sum : unsigned(15 downto 0);
  signal reg3_f3_sum : unsigned(15 downto 0);

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

  dut : entity work.reg6ac_wb
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

      reg1_o     => reg1,

      reg2_f1_o  => reg2_f1,
      reg2_f2_o  => reg2_f2,

      reg3_f1_o  => reg3_f1,
      reg3_f2_o  => reg3_f2,
      reg3_f3_o  => reg3_f3);

  --  Counters.
  process (clk)
  begin
    if rising_edge(clk) then
      if rst_n = '0' then
        reg1_sum <= (others => '0');
        reg2_f1_sum <= (others => '0');
        reg2_f2_sum <= (others => '0');
        reg3_f1_sum <= (others => '0');
        reg3_f2_sum <= (others => '0');
        reg3_f3_sum <= (others => '0');
      else
        reg1_sum <= reg1_sum + unsigned(reg1);

        reg2_f1_sum <= reg2_f1_sum + unsigned'(0 => reg2_f1);
        reg2_f2_sum <= reg2_f2_sum + unsigned(reg2_f2);

        reg3_f1_sum <= reg3_f1_sum + unsigned'(0 => reg3_f1);
        reg3_f2_sum <= reg3_f2_sum + unsigned(reg3_f2);
        reg3_f3_sum <= reg3_f3_sum + unsigned(reg3_f3);
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
    wait until rising_edge(clk);

    assert reg1_sum = 16#10# severity error;
    wb_writel (clk, wb_out, wb_in, x"0000_0000", x"0000_1001");
    assert reg1_sum = x"0000_1011" severity error;

    assert reg2_f1_sum = 0 severity error;
    assert reg2_f2_sum = 0 severity error;
    wb_writel (clk, wb_out, wb_in, x"0000_0004", x"0002_0001");
    assert reg2_f1_sum = 1 severity error;
    assert reg2_f2_sum = 2 report "sum = 0x" & to_hstring(reg2_f2_sum) severity error;

    assert reg3_f1_sum = 0 severity error;
    assert reg3_f2_sum = 0 severity error;
    assert reg3_f3_sum = 0 severity error;
    wb_writel (clk, wb_out, wb_in, x"0000_000c", x"0050_0001");
    assert reg3_f1_sum = 1 severity error;
    assert reg3_f2_sum = 5 severity error;
    assert reg3_f3_sum = 0 severity error;
    wb_writel (clk, wb_out, wb_in, x"0000_0008", x"afff_ffff");
    assert reg3_f1_sum = 1 severity error;
    assert reg3_f2_sum = 5 severity error;
    assert reg3_f3_sum = 10 severity error;

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
