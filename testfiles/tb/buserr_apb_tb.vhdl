library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.apb_tb_pkg.all;


entity buserr_apb_tb is
end buserr_apb_tb;


architecture tb of buserr_apb_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal apb_in  : t_apb_master_in;
  signal apb_out : t_apb_master_out;

  signal reg1   : std_logic_vector(31 downto 0);
  signal reg2   : std_logic_vector(31 downto 0);
  signal reg3   : std_logic_vector(31 downto 0);

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

  dut : entity work.buserr_apb
    port map (
      pclk    => clk,
      presetn => rst_n,
      paddr   => apb_out.paddr(3 downto 2),
      psel    => apb_out.psel,
      pwrite  => apb_out.pwrite,
      penable => apb_out.penable,
      pready  => apb_in.pready,
      pwdata  => apb_out.pwdata,
      pstrb   => apb_out.pstrb,
      prdata  => apb_in.prdata,
      pslverr => apb_in.pslverr,
      reg1_o  => reg1,
      reg2_o  => reg2,
      reg3_o  => reg3
    );

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
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
    apb_read (clk, apb_out, apb_in, x"0000_0000", v, '0');
    assert reg1 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    -- Testing regular write
    report "Testing regular write" severity note;
    apb_write (clk, apb_out, apb_in, x"0000_0004", x"9abc_def0", '0');
    assert reg2 = x"9abc_def0" severity error;
    apb_read (clk, apb_out, apb_in, x"0000_0004", v, '0');
    assert v = x"9abc_def0" severity error;

    --  Testing erroneous read
    report "Testing erroneous read" severity note;
    apb_read (clk, apb_out, apb_in, x"0000_000c", v, '1');

    --  Testing regular read 2
    report "Testing regular read 2" severity note;
    apb_read (clk, apb_out, apb_in, x"0000_0008", v, '0');
    assert reg3 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    --  Testing erroneous write
    report "Testing erroneous write" severity note;
    apb_write (clk, apb_out, apb_in, x"0000_000c", x"5678_9abc", '1');

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    report "End of test" severity note;
    end_of_test <= true;
  end process main;

  watchdog : process is
  begin
    wait until end_of_test for 7 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process watchdog;

end tb;
