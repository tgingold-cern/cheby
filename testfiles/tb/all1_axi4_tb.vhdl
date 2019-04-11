entity all1_axi4_tb is
end all1_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.axi4_tb_pkg.all;
use work.cernbe_tb_pkg.all;

architecture behav of all1_axi4_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wr_in   : t_axi4lite_write_master_in;
  signal wr_out  : t_axi4lite_write_master_out;
  signal rd_in   : t_axi4lite_read_master_in;
  signal rd_out  : t_axi4lite_read_master_out;

  --  For sub1.
  signal sub1_wb_in  : t_wishbone_slave_in;
  signal sub1_wb_out : t_wishbone_slave_out;

  --  For sub2.
  signal sub2_wr_in   : t_axi4lite_write_slave_in;
  signal sub2_wr_out  : t_axi4lite_write_slave_out;
  signal sub2_rd_in   : t_axi4lite_read_slave_in;
  signal sub2_rd_out  : t_axi4lite_read_slave_out;

  --  For sub3.
  signal sub3_in      : t_cernbe_slave_in;
  signal sub3_out     : t_cernbe_slave_out;

  signal end_of_test : boolean := False;
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
    wait until end_of_test for 2 us;
    assert end_of_test report "Timeout" severity error;
    wait;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.all1_axi4
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => wr_out.awvalid,
      awready    => wr_in.awready,
      awaddr     => wr_out.awaddr(13 downto 2),
      awprot     => "010",
      wvalid     => wr_out.wvalid,
      wready     => wr_in.wready,
      wdata      => wr_out.wdata,
      wstrb      => "1111",
      bvalid     => wr_in.bvalid,
      bready     => wr_out.bready,
      bresp      => wr_in.bresp,
      arvalid    => rd_out.arvalid,
      arready    => rd_in.arready,
      araddr     => rd_out.araddr(13 downto 2),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      ram1_adr_i     => (others => '0'),
      ram1_val_rd_i  => '0',
      ram1_val_dat_o => open,

      sub1_wb_cyc_o => sub1_wb_in.cyc,
      sub1_wb_stb_o => sub1_wb_in.stb,
      sub1_wb_adr_o => sub1_wb_in.adr(11 downto 2),
      sub1_wb_sel_o => sub1_wb_in.sel,
      sub1_wb_we_o  => sub1_wb_in.we,
      sub1_wb_dat_o => sub1_wb_in.dat,
      sub1_wb_ack_i => sub1_wb_out.ack,
      sub1_wb_err_i => sub1_wb_out.err,
      sub1_wb_rty_i => sub1_wb_out.rty,
      sub1_wb_stall_i => sub1_wb_out.stall,
      sub1_wb_dat_i => sub1_wb_out.dat,

      sub2_axi4_awvalid_o  => sub2_wr_in.awvalid,
      sub2_axi4_awready_i  => sub2_wr_out.awready,
      sub2_axi4_awaddr_o   => sub2_wr_in.awaddr(11 downto 2),
      sub2_axi4_awprot_o   => sub2_wr_in.awprot,
      sub2_axi4_wvalid_o   => sub2_wr_in.wvalid,
      sub2_axi4_wready_i   => sub2_wr_out.wready,
      sub2_axi4_wdata_o    => sub2_wr_in.wdata,
      sub2_axi4_wstrb_o    => sub2_wr_in.wstrb,
      sub2_axi4_bvalid_i   => sub2_wr_out.bvalid,
      sub2_axi4_bready_o   => sub2_wr_in.bready,
      sub2_axi4_bresp_i    => sub2_wr_out.bresp,
      sub2_axi4_arvalid_o  => sub2_rd_in.arvalid,
      sub2_axi4_arready_i  => sub2_rd_out.arready,
      sub2_axi4_araddr_o   => sub2_rd_in.araddr(11 downto 2),
      sub2_axi4_arprot_o   => sub2_rd_in.arprot,
      sub2_axi4_rvalid_i   => sub2_rd_out.rvalid,
      sub2_axi4_rready_o   => sub2_rd_in.rready,
      sub2_axi4_rdata_i    => sub2_rd_out.rdata,
      sub2_axi4_rresp_i    => sub2_rd_out.rresp,

      sub3_cernbe_VMEAddr_o => sub3_in.VMEAddr(11 downto 2),
      sub3_cernbe_VMERdData_i => sub3_out.VMERdData,
      sub3_cernbe_VMEWrData_o => sub3_in.VMEWrData,
      sub3_cernbe_VMERdMem_o  => sub3_in.VMERdMem,
      sub3_cernbe_VMEWrMem_o  => sub3_in.VMEWrMem,
      sub3_cernbe_VMERdDone_i => sub3_out.VMERdDone,
      sub3_cernbe_VMEWrDone_i => sub3_out.VMEWrDone
      );

  --  WB target
  b1: entity work.block1_wb
    port map (clk => clk,
              rst_n => rst_n,
              sub1_wb_in => sub1_wb_in,
              sub1_wb_out => sub1_wb_out);

  --  AXI4-lite target
  b2: entity work.block1_axi4
    port map (clk => clk,
              rst_n => rst_n,
              sub2_wr_in => sub2_wr_in,
              sub2_wr_out => sub2_wr_out,
              sub2_rd_in => sub2_rd_in,
              sub2_rd_out => sub2_rd_out);

  --  CERNBE target
  b3: entity work.block1_cernbe
    port map (clk => clk,
              rst_n => rst_n,
              bus_in => sub3_in,
              bus_out => sub3_out);

  process
    procedure test_bus(name : string; addr : std_logic_vector(31 downto 0))
    is
      variable v : std_logic_vector(31 downto 0);
    begin
      --  The initial value of the memory line depends on the bus.
      --  This is just to test the right model is connected.
      report "Testing " & name & " (read id)" severity note;
      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0000", v);
      assert v = addr severity error;

      report "Testing " & name & " (write)" severity note;
      axi4lite_write (clk, wr_out, wr_in, addr or x"0000_0000",
                    addr or x"9876_0432");

      axi4lite_write (clk, wr_out, wr_in, addr or x"0000_0008", x"fd02_02fd");

      report "Testing " & name & " (read)" severity note;
      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0004", v);
      assert v = x"01fe_fe01" severity error;

      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0000", v);
      assert v = (addr or x"9876_0432") severity error;
    end test_bus;
    variable v : std_logic_vector(31 downto 0);
  begin
    axi4lite_wr_init(wr_out);
    axi4lite_rd_init(rd_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing register
    report "Testing register" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0000", v);
    assert v = x"1234_0000" severity error;

    axi4lite_write (clk, wr_out, wr_in, x"0000_0000", x"0000_abcd");
    axi4lite_read (clk, rd_out, rd_in, x"0000_0000", v);
    assert v = x"0000_abcd" severity error;

    --  Testing memory
    report "Testing memory (write)" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0024", x"abcd_0001");
    axi4lite_write (clk, wr_out, wr_in, x"0000_002c", x"abcd_0203");

    report "Testing memory (read)" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0024", v);
    assert v = x"abcd_0001" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_002c", v);
    assert v = x"abcd_0203" severity error;

    --  Testing WB
    test_bus ("wishbone", x"0000_1000");

    --  Testing AXI4
    test_bus ("AXI4", x"0000_2000");

    --  Testing CERNBE
    test_bus ("cernbe", x"0000_3000");

    wait until rising_edge(clk);

    report "end of test" severity note;

    end_of_test <= true;
    wait;
  end process;

  --  Watchdog.
  process
  begin
    wait until end_of_test for 2 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process;
end behav;
