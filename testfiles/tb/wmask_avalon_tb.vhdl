library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.avalon_tb_pkg.all;


entity wmask_avalon_tb is
end wmask_avalon_tb;


architecture tb of wmask_avalon_tb is
  signal rst        : std_logic;
  signal clk        : std_logic;
  signal avalon_in  : t_avmm_master_in;
  signal avalon_out : t_avmm_master_out;

  signal reg_rw  : std_logic_vector(31 downto 0);
  signal wire_rw : std_logic_vector(31 downto 0);

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

  rst <= '1' after 0 ns, '0' after 20 ns;

  dut : entity work.wmask_avalon
    port map (
      clk             => clk,
      reset           => rst,
      address         => avalon_out.address(5 downto 2),
      readdata        => avalon_in.readdata,
      writedata       => avalon_out.writedata,
      byteenable      => avalon_out.byteenable,
      read            => avalon_out.read,
      write           => avalon_out.write,
      readdatavalid   => avalon_in.readdatavalid,
      waitrequest     => avalon_in.waitrequest,

      reg_rw_o        => reg_rw,
      reg_ro_i        => (others => '0'),
      reg_wo_o        => open,
      wire_rw_i       => wire_rw,
      wire_rw_o       => wire_rw,
      wire_ro_i       => (others => '0'),
      wire_wo_o       => open,
      ram1_adr_i      => (others => '0'),
      ram1_row1_rd_i  => '0',
      ram1_row1_dat_o => open
    );

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    avmm_init(clk, avalon_in, avalon_out);

    -- Wait after reset.
    wait until rising_edge(clk) and rst = '0';

    -- Register
    -- Testing regular register read
    report "Testing regular register read" severity note;
    avmm_readl(clk, avalon_in, avalon_out, x"0000_0000", v);
    assert reg_rw = x"0000_0000" severity error;
    assert v = x"0000_0000" severity error;

    -- Testing regular register write
    report "Testing regular register write" severity note;
    avmm_writel(clk, avalon_in, avalon_out, x"0000_0000", x"1234_5678", "1111");
    assert reg_rw = x"1234_5678" severity error;
    avmm_readl(clk, avalon_in, avalon_out, x"0000_0000", v);
    assert v = x"1234_5678" severity error;

    --  Testing register write with mask
    report "Testing register write with mask" severity note;
    avmm_writel(clk, avalon_in, avalon_out, x"0000_0000", x"9abc_def0", "1010");
    assert reg_rw = x"9a34_de78" severity error;
    avmm_readl(clk, avalon_in, avalon_out, x"0000_0000", v);
    assert v = x"9a34_de78" severity error;

    -- Memory
    -- Testing regular memory write
    report "Testing regular memory write" severity note;
    avmm_writel(clk, avalon_in, avalon_out, x"0010_0000", x"1234_5678", "1111");
    assert reg_rw = x"1234_5678" severity error;
    avmm_readl(clk, avalon_in, avalon_out, x"0010_0000", v);
    assert v = x"1234_5678" severity error;

    -- Testing memory write with mask
    report "Testing memory write with mask" severity note;
    avmm_writel(clk, avalon_in, avalon_out, x"0010_0000", x"9abc_def0", "1010");
    assert reg_rw = x"9a34_de78" severity error;
    avmm_readl(clk, avalon_in, avalon_out, x"0010_0000", v);
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
