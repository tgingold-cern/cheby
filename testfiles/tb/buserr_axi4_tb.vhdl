library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_tb_pkg.all;


entity buserr_axi4_tb is
end buserr_axi4_tb;


architecture tb of buserr_axi4_tb is
  signal rst_n  : std_logic;
  signal clk    : std_logic;
  signal wr_in  : t_axi4lite_write_master_in;
  signal wr_out : t_axi4lite_write_master_out;
  signal rd_in  : t_axi4lite_read_master_in;
  signal rd_out : t_axi4lite_read_master_out;

  signal reg_rw0 : std_logic_vector(31 downto 0);
  signal reg_rw1 : std_logic_vector(31 downto 0);
  signal reg_rw2 : std_logic_vector(31 downto 0);
  signal reg_ro0 : std_logic_vector(31 downto 0);
  signal reg_wo0 : std_logic_vector(31 downto 0);

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

  dut : entity work.buserr_axi4
    port map (
      aclk     => clk,
      areset_n => rst_n,
      awvalid  => wr_out.awvalid,
      awready  => wr_in.awready,
      awaddr   => wr_out.awaddr(4 downto 2),
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
      araddr   => rd_out.araddr(4 downto 2),
      arprot   => "010",
      rvalid   => rd_in.rvalid,
      rready   => rd_out.rready,
      rdata    => rd_in.rdata,
      rresp    => rd_in.rresp,

      rw0_o    => reg_rw0,
      rw1_o    => reg_rw1,
      rw2_o    => reg_rw2,
      ro0_i    => reg_ro0,
      wo0_o    => reg_wo0
    );

  reg_ro0 <= x"4567_89ab";

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
    axi4lite_read(clk, rd_out, rd_in, x"0000_0000", v, C_AXI4_RESP_OK);
    assert reg_rw0 = x"1234_5678" severity error;
    assert v = x"1234_5678" severity error;

    -- Testing regular write
    report "Testing regular write" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_0004", x"9abc_def0", C_AXI4_RESP_OK);
    assert reg_rw1 = x"9abc_def0" severity error;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0004", v, C_AXI4_RESP_OK);
    assert v = x"9abc_def0" severity error;

    --  Testing erroneous read
    report "Testing erroneous read" severity note;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0014", v, C_AXI4_RESP_SLVERR);

    --  Testing regular read 2
    report "Testing regular read 2" severity note;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0008", v, C_AXI4_RESP_OK);
    assert reg_rw2 = x"3456_789a" severity error;
    assert v = x"3456_789a" severity error;

    --  Testing erroneous write
    report "Testing erroneous write" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_0014", x"5678_9abc", C_AXI4_RESP_SLVERR);

    --  Testing regular read 3
    report "Testing regular read 3" severity note;
    axi4lite_read(clk, rd_out, rd_in, x"0000_000c", v, C_AXI4_RESP_OK);
    assert reg_ro0 = x"4567_89ab" severity error;
    assert v = x"4567_89ab" severity error;

    --  Testing erroneous write to read-only register
    report "Testing erroneous write to read-only register" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_000c", x"1234_5678", C_AXI4_RESP_SLVERR);

    --  Testing regular write 2
    report "Testing regular write 2" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_0010", x"1234_5678", C_AXI4_RESP_OK);
    wait until rising_edge(clk);
    assert reg_wo0 = x"1234_5678" severity error;

    --  Testing erroneous read to write-only register
    report "Testing erroneous read to write-only register" severity note;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0010", v, C_AXI4_RESP_SLVERR);

    --  Regression for issue #86: with bus-error enabled, RVALID must stay
    --  asserted (with stable RDATA/RRESP) until RREADY is sampled high, and
    --  must not be a one-cycle pulse.  The always-ready BFM above cannot catch
    --  this, so drive RREADY low by hand for several cycles.
    report "Testing read with delayed RREADY (issue #86)" severity note;
    rd_out.araddr  <= x"0000_0000";
    rd_out.arvalid <= '1';
    rd_out.rready  <= '0';
    wait until rising_edge(clk);
    loop
      if rd_in.arready = '1' then
        rd_out.arvalid <= '0';
      end if;
      exit when rd_in.rvalid = '1';
      wait until rising_edge(clk);
    end loop;
    for i in 0 to 4 loop
      assert rd_in.rvalid = '1'
        report "RVALID dropped before RREADY (issue #86)" severity error;
      assert rd_in.rdata = x"1234_5678"
        report "RDATA not stable while RVALID held (issue #86)" severity error;
      assert rd_in.rresp = C_AXI4_RESP_OK
        report "RRESP not stable while RVALID held (issue #86)" severity error;
      wait until rising_edge(clk);
    end loop;
    rd_out.rready <= '1';
    wait until rising_edge(clk);
    rd_out.rready <= '0';

    --  Regression for issue #86: BVALID must stay asserted (with stable BRESP)
    --  until BREADY is sampled high.
    report "Testing write with delayed BREADY (issue #86)" severity note;
    wr_out.awaddr  <= x"0000_0008";
    wr_out.wdata   <= x"cafe_babe";
    wr_out.awvalid <= '1';
    wr_out.wvalid  <= '1';
    wr_out.bready  <= '0';
    wait until rising_edge(clk);
    loop
      if wr_in.awready = '1' then
        wr_out.awvalid <= '0';
      end if;
      if wr_in.wready = '1' then
        wr_out.wvalid <= '0';
      end if;
      exit when wr_in.bvalid = '1';
      wait until rising_edge(clk);
    end loop;
    for i in 0 to 4 loop
      assert wr_in.bvalid = '1'
        report "BVALID dropped before BREADY (issue #86)" severity error;
      assert wr_in.bresp = C_AXI4_RESP_OK
        report "BRESP not stable while BVALID held (issue #86)" severity error;
      wait until rising_edge(clk);
    end loop;
    wr_out.bready <= '1';
    wait until rising_edge(clk);
    wr_out.bready <= '0';
    assert reg_rw2 = x"cafe_babe"
      report "write with delayed BREADY did not update the register (issue #86)"
      severity error;

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
