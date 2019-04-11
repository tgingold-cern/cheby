entity all1_cernbe_tb is
end all1_cernbe_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.axi4_tb_pkg.all;
use work.cernbe_tb_pkg.all;

architecture behav of all1_cernbe_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal bus_in   : t_cernbe_master_in;
  signal bus_out  : t_cernbe_master_out;

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

  dut : entity work.all1_cernbe
    port map (
      Clk       => clk,
      Rst       => rst_n,
      VMEAddr   => bus_out.VMEAddr(13 downto 2),
      VMERdData => bus_in.VMERdData,
      VMEWRData => bus_out.VMEWrData,
      VMERdMem  => bus_out.VMERdMem,
      VMEWrMem  => bus_out.VMEWrMem,
      VMERdDone => bus_in.VMERdDone,
      VMEWrDone => bus_in.VMEWrDone,

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
      cernbe_read  (clk, bus_out, bus_in, addr or x"0000_0000", v);
      assert v = addr severity error;

      report "Testing " & name & " (write)" severity note;
      cernbe_write (clk, bus_out, bus_in, addr or x"0000_0000",
                    addr or x"9876_0432");

      --  Test with various ws.
      cernbe_write (clk, bus_out, bus_in, addr or x"0000_0008", x"fd02_02fd");
      cernbe_write (clk, bus_out, bus_in, addr or x"0000_000c", x"fc03_03fc");
      cernbe_write (clk, bus_out, bus_in, addr or x"0000_0010", x"fb04_04fb");

      report "Testing " & name & " (read)" severity note;
      cernbe_read  (clk, bus_out, bus_in, addr or x"0000_0004", v);
      assert v = x"01fe_fe01" severity error;

      cernbe_read (clk, bus_out, bus_in, addr or x"0000_0000", v);
      assert v = (addr or x"9876_0432") severity error;

      --  Various ws.
      cernbe_read  (clk, bus_out, bus_in, addr or x"0000_0008", v);
      assert v = x"02fd_fd02" severity error;

      cernbe_read  (clk, bus_out, bus_in, addr or x"0000_000c", v);
      assert v = x"03fc_fc03" severity error;

      cernbe_read  (clk, bus_out, bus_in, addr or x"0000_0010", v);
      assert v = x"04fb_fb04" severity error;
    end test_bus;

    variable v : std_logic_vector(31 downto 0);
  begin
    cernbe_init(bus_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing register
    report "Testing register" severity note;
    cernbe_read (clk, bus_out, bus_in, x"0000_0000", v);
    assert v = x"1234_0000" severity error;

    cernbe_write (clk, bus_out, bus_in, x"0000_0000", x"0000_abcd");
    cernbe_read (clk, bus_out, bus_in, x"0000_0000", v);
    assert v = x"0000_abcd" severity error;

    --  Testing memory
    report "Testing memory (write)" severity note;
    cernbe_write (clk, bus_out, bus_in, x"0000_0024", x"abcd_0001");
    cernbe_write (clk, bus_out, bus_in, x"0000_002c", x"abcd_0203");

    report "Testing memory (read)" severity note;
    cernbe_read (clk, bus_out, bus_in, x"0000_0024", v);
    assert v = x"abcd_0001" severity error;

    cernbe_read (clk, bus_out, bus_in, x"0000_002c", v);
    assert v = x"abcd_0203" severity error;

    --  Testing wishbone
    test_bus("wishbone", x"0000_1000");

    --  Testing AXI4
    test_bus("AXI4", x"0000_2000");

    --  Testing cernbe
    test_bus("cernbe", x"0000_3000");

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
