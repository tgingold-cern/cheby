library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.apb_tb_pkg.all;


entity lock_apb_tb is
end lock_apb_tb;


architecture tb of lock_apb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal apb_in  : t_apb_master_in;
  signal apb_out : t_apb_master_out;

  signal scantest : std_logic;

  signal reg0        : std_logic_vector(31 downto 0);
  signal reg1        : std_logic_vector(31 downto 0);
  signal reg2_field0 : std_logic_vector(3 downto 0);
  signal reg2_field1 : std_logic_vector(3 downto 0);

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

  dut : entity work.lock_apb
    port map (
      pclk          => clk,
      presetn       => rst_n,
      paddr         => apb_out.paddr(3 downto 2),
      psel          => apb_out.psel,
      pwrite        => apb_out.pwrite,
      penable       => apb_out.penable,
      pready        => apb_in.pready,
      pwdata        => apb_out.pwdata,
      pstrb         => apb_out.pstrb,
      prdata        => apb_in.prdata,
      pslverr       => apb_in.pslverr,
      scantest      => scantest,
      reg0_o        => reg0,
      reg1_o        => reg1,
      reg2_field0_o => reg2_field0,
      reg2_field1_o => reg2_field1
    );

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    scantest <= '0';
    apb_init(apb_out);

    -- Wait signals to be applied
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- Verify all handshakes are accepted and error is returned
    report "Verifying initial signals" severity note;
    assert apb_in.pready = '0' severity error;
    assert apb_in.pslverr = '0' severity error;

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing regular read
    report "Testing regular read" severity note;
    apb_read(clk, apb_out, apb_in, x"0000_0000", v, '0');
    assert reg0 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    --  Testing regular write
    report "Testing regular write" severity note;
    apb_write(clk, apb_out, apb_in, x"0000_0000", x"0102_0304", '0');
    assert reg0 = x"0102_0304" severity error;

    --  Testing write with lock
    report "Testing write with lock" severity note;
    scantest <= '1';
    apb_write(clk, apb_out, apb_in, x"0000_0000", x"0506_0708", '0');
    assert reg0 = x"0102_0304" severity error;
    scantest <= '0';

    --  Testing lock value
    report "Testing lock value" severity note;

    wait until rising_edge(clk);
    assert reg1 = x"2345_6789" severity error;

    wait until rising_edge(clk);
    scantest <= '1';

    wait until rising_edge(clk);
    assert reg1 = x"9876_5432" severity error;

    wait until rising_edge(clk);
    scantest <= '0';

    --  Testing field write with lock
    report "Testing field write with lock" severity note;
    scantest <= '1';
    apb_write(clk, apb_out, apb_in, x"0000_0008", x"0000_00ff", '0');
    assert reg2_field0 = x"3" severity error;
    scantest <= '0';

    --  Testing field lock value
    report "Testing field lock value" severity note;

    wait until rising_edge(clk);
    assert reg2_field1 = x"f" severity error;

    wait until rising_edge(clk);
    scantest <= '1';

    wait until rising_edge(clk);
    assert reg2_field1 = x"5" severity error;

    wait until rising_edge(clk);
    scantest <= '0';

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
