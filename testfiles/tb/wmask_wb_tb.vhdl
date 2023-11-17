library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;


entity wmask_wb_tb is
end wmask_wb_tb;


architecture tb of wmask_wb_tb is
  signal rst_n  : std_logic;
  signal clk    : std_logic;
  signal wb_in  : t_wishbone_slave_in;
  signal wb_out : t_wishbone_slave_out;

  signal reg_rw       : std_logic_vector(31 downto 0);
  signal wire_rw_in   : std_logic_vector(31 downto 0);
  signal wire_rw_out  : std_logic_vector(31 downto 0);
  signal wire_rw_mask : std_logic_vector(31 downto 0);

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

  dut : entity work.wmask_wb
    port map (
      rst_n_i         => rst_n,
      clk_i           => clk,
      wb_cyc_i        => wb_in.cyc,
      wb_stb_i        => wb_in.stb,
      wb_adr_i        => wb_in.adr(5 downto 2),
      wb_sel_i        => wb_in.sel,
      wb_we_i         => wb_in.we,
      wb_dat_i        => wb_in.dat,
      wb_ack_o        => wb_out.ack,
      wb_err_o        => wb_out.err,
      wb_rty_o        => wb_out.rty,
      wb_stall_o      => wb_out.stall,
      wb_dat_o        => wb_out.dat,

      reg_rw_o        => reg_rw,
      reg_ro_i        => (others => '0'),
      reg_wo_o        => open,
      wire_rw_i       => wire_rw_in,
      wire_rw_o       => wire_rw_out,
      wire_rw_wmask_o => wire_rw_mask,
      wire_ro_i       => (others => '0'),
      wire_wo_o       => open,
      wire_wo_wmask_o => open,
      ram1_adr_i      => (others => '0'),
      ram1_row1_rd_i  => '0',
      ram1_row1_dat_o => open
    );

  wire_rw_in <= wire_rw_out;

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_out, wb_in);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    -- Register
    -- Testing regular register read
    report "Testing regular register read" severity note;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert reg_rw = x"0000_0000" severity error;
    assert v = x"0000_0000" severity error;

    -- Testing regular register write
    report "Testing regular register write" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"1234_5678", "1111");
    assert reg_rw = x"1234_5678" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"1234_5678" severity error;

    --  Testing register write with mask
    report "Testing register write with mask" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0000", x"9abc_def0", "1010");
    assert reg_rw = x"9a34_de78" severity error;
    wb_readl(clk, wb_out, wb_in, x"0000_0000", v);
    assert v = x"9a34_de78" severity error;

    -- Wire
    -- Testing regular write write
    report "Testing regular wire write" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"3456_789a", "1111");
    assert wire_rw_out = x"3456_789a" severity error;
    assert wire_rw_mask = x"ffff_ffff" severity error;

    report "Testing wire write with mask" severity note;
    wb_writel(clk, wb_out, wb_in, x"0000_0008", x"bcde_f012", "0101");
    assert wire_rw_out = x"bcde_f012" severity error;
    assert wire_rw_mask = x"00ff_00ff" severity error;

    -- Memory
    -- Testing regular memory write
    report "Testing regular memory write" severity note;
    wb_writel(clk, wb_out, wb_in, x"0010_0000", x"1234_5678", "1111");
    assert reg_rw = x"1234_5678" severity error;
    wb_readl(clk, wb_out, wb_in, x"0010_0000", v);
    assert v = x"1234_5678" severity error;

    -- Testing memory write with mask
    report "Testing memory write with mask" severity note;
    wb_writel(clk, wb_out, wb_in, x"0010_0000", x"9abc_def0", "1010");
    assert reg_rw = x"9a34_de78" severity error;
    wb_readl(clk, wb_out, wb_in, x"0010_0000", v);
    assert v = x"9a34_de78" severity error;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    report "End of test" severity note;
    end_of_test <= true;
  end process main;

  watchdog : process is
  begin
    wait until end_of_test for 5 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process watchdog;

end tb;
