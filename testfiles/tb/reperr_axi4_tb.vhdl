library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_tb_pkg.all;


entity reperr_axi4_tb is
end reperr_axi4_tb;


architecture tb of reperr_axi4_tb is
  signal rst_n  : std_logic;
  signal clk    : std_logic;
  signal wr_in  : t_axi4lite_write_master_in;
  signal wr_out : t_axi4lite_write_master_out;
  signal rd_in  : t_axi4lite_read_master_in;
  signal rd_out : t_axi4lite_read_master_out;

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

  dut : entity work.reperr_axi4
    port map (
      aclk     => clk,
      areset_n => rst_n,
      awvalid  => wr_out.awvalid,
      awready  => wr_in.awready,
      awaddr   => wr_out.awaddr(3 downto 2),
      awprot   => "010",
      wvalid   => wr_out.wvalid,
      wready   => wr_in.wready,
      wdata    => wr_out.wdata,
      wstrb    => "1111",
      bvalid   => wr_in.bvalid,
      bready   => wr_out.bready,
      bresp    => wr_in.bresp,
      arvalid  => rd_out.arvalid,
      arready  => rd_in.arready,
      araddr   => rd_out.araddr(3 downto 2),
      arprot   => "010",
      rvalid   => rd_in.rvalid,
      rready   => rd_out.rready,
      rdata    => rd_in.rdata,
      rresp    => rd_in.rresp,

      reg1_o   => reg1,
      reg2_o   => reg2,
      reg3_o   => reg3
    );

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    axi4lite_wr_init(wr_out);
    axi4lite_rd_init(rd_out);

    -- Wait signals to be applied
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- Verify all handshakes are accepted and error is returned
    report "Verifying initial signals" severity note;
    assert wr_in.awready = '1' severity error;
    assert wr_in.wready = '1' severity error;
    assert wr_in.bvalid = '1' severity error;
    assert wr_in.bresp = C_AXI4_RESP_SLVERR severity error;
    assert rd_in.arready = '1' severity error;
    assert rd_in.rvalid = '1' severity error;
    assert rd_in.rresp = C_AXI4_RESP_SLVERR severity error;

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing regular read
    report "Testing regular read" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0000", v, C_AXI4_RESP_OK);
    assert reg1 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    -- Testing regular write
    report "Testing regular write" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0004", x"9abc_def0", C_AXI4_RESP_OK);
    assert reg2 = x"9abc_def0" severity error;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0004", v, C_AXI4_RESP_OK);
    assert v = x"9abc_def0" severity error;

    --  Testing erroneous read
    report "Testing erroneous read" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_000c", v, C_AXI4_RESP_SLVERR);

    --  Testing regular read 2
    report "Testing regular read 2" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0008", v, C_AXI4_RESP_OK);
    assert reg3 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    --  Testing erroneous write
    report "Testing erroneous write" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_000c", x"5678_9abc", C_AXI4_RESP_SLVERR);

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
