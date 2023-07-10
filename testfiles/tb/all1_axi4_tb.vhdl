entity all1_axi4_tb is
end all1_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.axi4_tb_pkg.all;
use work.cernbe_tb_pkg.all;
use work.avalon_tb_pkg.all;
use work.apb_tb_pkg.all;


architecture behav of all1_axi4_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wr_in   : t_axi4lite_write_master_in;
  signal wr_out  : t_axi4lite_write_master_out;
  signal rd_in   : t_axi4lite_read_master_in;
  signal rd_out  : t_axi4lite_read_master_out;

  signal ram_ro_adr     : std_logic_vector(2 downto 0);
  signal ram_ro_val_we  : std_logic;
  signal ram_ro_val_dat : std_logic_vector(31 downto 0);

  signal ram2_addr          : std_logic_vector(4 downto 2);
  signal ram2_data_in       : std_logic_vector(31 downto 0);
  signal ram2_data_out      : std_logic_vector(31 downto 0);
  signal ram2_wr            : std_logic;

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

  --  For sub4
  signal sub4_in      : t_avmm_master_out;
  signal sub4_out     : t_avmm_master_in;

  --  For sub5: APB
  signal sub5_in  : t_apb_slave_in;
  signal sub5_out : t_apb_slave_out;

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

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.all1_axi4
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => wr_out.awvalid,
      awready    => wr_in.awready,
      awaddr     => wr_out.awaddr(14 downto 2),
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
      araddr     => rd_out.araddr(14 downto 2),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      ram1_adr_i     => (others => '0'),
      ram1_val_rd_i  => '0',
      ram1_val_dat_o => open,

      ram_ro_adr_i     => ram_ro_adr,
      ram_ro_val_we_i  => ram_ro_val_we,
      ram_ro_val_dat_i => ram_ro_val_dat,

      ram2_addr_o      => ram2_addr,
      ram2_data_i      => ram2_data_out,
      ram2_data_o      => ram2_data_in,
      ram2_wr_o        => ram2_wr,

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
      sub3_cernbe_VMEWrDone_i => sub3_out.VMEWrDone,

      sub4_avalon_address_o => sub4_in.address(11 downto 2),
      sub4_avalon_readdata_i => sub4_out.readdata,
      sub4_avalon_writedata_o => sub4_in.writedata,
      sub4_avalon_byteenable_o => sub4_in.byteenable,
      sub4_avalon_read_o  => sub4_in.read,
      sub4_avalon_write_o => sub4_in.write,
      sub4_avalon_readdatavalid_i => sub4_out.readdatavalid,
      sub4_avalon_waitrequest_i => sub4_out.waitrequest,

      sub5_apb_paddr_o   => sub5_in.paddr(11 downto 2),
      sub5_apb_psel_o    => sub5_in.psel,
      sub5_apb_pwrite_o  => sub5_in.pwrite,
      sub5_apb_penable_o => sub5_in.penable,
      sub5_apb_pready_i  => sub5_out.pready,
      sub5_apb_pwdata_o  => sub5_in.pwdata,
      sub5_apb_pstrb_o   => sub5_in.pstrb,
      sub5_apb_prdata_i  => sub5_out.prdata,
      sub5_apb_pslverr_i => sub5_out.pslverr
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

  --  Avalon target
  b4: entity work.block1_avmm
    port map (clk => clk,
              rst_n => rst_n,
              av_in => sub4_in,
              av_out => sub4_out);

  -- APB target
  b5 : entity work.block1_apb
    port map (
      clk     => clk,
      rst_n   => rst_n,
      bus_in  => sub5_in,
      bus_out => sub5_out);

  bram2 : entity work.sram2
    port map (clk_i => clk,
              addr_i => ram2_addr,
              data_i => ram2_data_in,
              data_o => ram2_data_out,
              wr_i   => ram2_wr);

  --  Init RAM.
  process
  begin
    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    for i in 0 to 7 loop
      ram_ro_adr <= std_logic_vector (to_unsigned(i, 3));
      ram_ro_val_we <= '1';
      ram_ro_val_dat <= (others => '0');
      ram_ro_val_dat (26 downto 24) <= std_logic_vector (to_unsigned(i, 3));
      wait until rising_edge(clk);
    end loop;

    ram_ro_val_we <= '0';
    wait;
  end process;

  process
    procedure test_bus (
      name    : string;
      addr    : std_logic_vector(31 downto 0);
      test_rw : boolean := True
    )
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

      --  Test with various ws.
      axi4lite_write (clk, wr_out, wr_in, addr or x"0000_0008", x"fd02_02fd");

      axi4lite_write (clk, wr_out, wr_in, addr or x"0000_000c", x"fc03_03fc");

      axi4lite_write (clk, wr_out, wr_in, addr or x"0000_0010", x"fb04_04fb");

      report "Testing " & name & " (read)" severity note;
      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0004", v);
      assert v = x"01fe_fe01" severity error;

      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0000", v);
      wait until rising_edge(clk);
      assert v = (addr or x"9876_0432") severity error;

      --  Various ws.
      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0008", v);
      assert v = x"02fd_fd02" severity error;

      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_000c", v);
      assert v = x"03fc_fc03" severity error;

      axi4lite_read (clk, rd_out, rd_in, addr or x"0000_0010", v);
      assert v = x"04fb_fb04" severity error;

      --  Simultaneous R&W
      if test_rw then
        report "Testing " & name & " (read+write)" severity note;
        axi4lite_rw(clk, rd_out, rd_in, wr_out, wr_in,
                    addr or x"0000_0008", v,
                    addr, addr or x"8765_cdef");
        assert v = x"02fd_fd02" severity error;

        axi4lite_rw(clk, rd_out, rd_in, wr_out, wr_in,
                    addr or x"0000_0000", v,
                    addr or x"0000_000c",  x"fc03_03fc");
        assert v = (addr or x"8765_cdef");

        axi4lite_rw(clk, rd_out, rd_in, wr_out, wr_in,
                    addr or x"0000_0010", v,
                    addr or x"0000_0014",  x"fa05_05fa");
        assert v = x"04fb_fb04" severity error;
      end if;
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

    --  Testing memory (rw)
    report "Testing memory (write)" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0024", x"abcd_0001");
    axi4lite_write (clk, wr_out, wr_in, x"0000_002c", x"abcd_0203");

    report "Testing memory (read)" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0024", v);
    assert v = x"abcd_0001" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_002c", v);
    assert v = x"abcd_0203" severity error;

    --  Testing memory (ro)
    report "Testing memory RO" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0044", v);
    assert v = x"0100_0000" severity error;
    axi4lite_read (clk, rd_out, rd_in, x"0000_004c", v);
    assert v = x"0300_0000" severity error;

    --  Testing memory ram2 (rw)
    report "Testing memory ram2 (write)" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0074", x"abcd_0001");
    axi4lite_write (clk, wr_out, wr_in, x"0000_006c", x"abcd_0203");

    report "Testing memory ram2 (read)" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0074", v);
    assert v = x"abcd_0001" severity error;

    --  Testing WB
    test_bus ("wishbone", x"0000_1000");

    --  Testing AXI4
    test_bus ("AXI4", x"0000_2000");

    --  Testing CERNBE
    test_bus ("cernbe", x"0000_3000");

    --  Testing AVALON
    test_bus ("avalon", x"0000_4000");

    --  Testing APB
    test_bus ("apb", x"0000_5000", False);

    --  Test bug when first writing a reg and then read in a submap.
    --  Check with the wb submap.
    axi4lite_write (clk, wr_out, wr_in, x"0000_1000", x"def7_0000");
    axi4lite_write (clk, wr_out, wr_in, x"0000_0004", x"def7_8505");
    axi4lite_read (clk, rd_out, rd_in, x"0000_1000", v);
    assert v = x"def7_0000" severity error;

    --  Check with the axi submap.
    axi4lite_write (clk, wr_out, wr_in, x"0000_2000", x"def6_0000");
    axi4lite_write (clk, wr_out, wr_in, x"0000_0004", x"def6_8505");
    axi4lite_read (clk, rd_out, rd_in, x"0000_2000", v);
    assert v = x"def6_0000" severity error;

    --  Check with the cernbe submap.
    axi4lite_write (clk, wr_out, wr_in, x"0000_3000", x"def8_0000");
    axi4lite_write (clk, wr_out, wr_in, x"0000_0004", x"def8_8505");
    axi4lite_read (clk, rd_out, rd_in, x"0000_3000", v);
    assert v = x"def8_0000" severity error;

    wait until rising_edge(clk);

    report "end of test" severity note;

    end_of_test <= true;
    wait;
  end process;

  --  Watchdog.
  process
  begin
    wait until end_of_test for 8 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process;
end behav;
