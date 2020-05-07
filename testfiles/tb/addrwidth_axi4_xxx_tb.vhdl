entity addrwidth_axi4_GRANULARITY_tb is
end addrwidth_axi4_GRANULARITY_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.wishbone_pkg.all;
use work.axi4_tb_pkg.all;
use work.cernbe_tb_pkg.all;

architecture behav of addrwidth_axi4_GRANULARITY_tb is
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

  --  For sub2.
  signal sub2_wr_in   : t_axi4lite_write_slave_in;
  signal sub2_wr_out  : t_axi4lite_write_slave_out;
  signal sub2_rd_in   : t_axi4lite_read_slave_in;
  signal sub2_rd_out  : t_axi4lite_read_slave_out;

  function ite (cond : boolean; t, f : natural) return natural is
  begin
    if cond then
      return t;
    else
      return f;
    end if;
  end ite;

  constant lo : natural := ite ("GRANULARITY" = string'("word"), 2, 0);

  constant sub_lo : natural := ite ("SLAVE" = string'("word"), 2, 0);

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

  dut : entity work.addrwidth_axi4_GRANULARITY
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => wr_out.awvalid,
      awready    => wr_in.awready,
      awaddr     => wr_out.awaddr(3 downto lo),
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
      araddr     => rd_out.araddr(3 downto lo),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      sub2_axi4_awvalid_o  => sub2_wr_in.awvalid,
      sub2_axi4_awready_i  => sub2_wr_out.awready,
      sub2_axi4_awaddr_o   => sub2_wr_in.awaddr(2 downto sub_lo),
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
      sub2_axi4_araddr_o   => sub2_rd_in.araddr(2 downto sub_lo),
      sub2_axi4_arprot_o   => sub2_rd_in.arprot,
      sub2_axi4_rvalid_i   => sub2_rd_out.rvalid,
      sub2_axi4_rready_o   => sub2_rd_in.rready,
      sub2_axi4_rdata_i    => sub2_rd_out.rdata,
      sub2_axi4_rresp_i    => sub2_rd_out.rresp
      );

  dut2 : entity work.addrwidth_axi4_sub_SLAVE
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => sub2_wr_in.awvalid,
      awready    => sub2_wr_out.awready,
      awaddr     => sub2_wr_in.awaddr(2 downto sub_lo),
      awprot     => sub2_wr_in.awprot,
      wvalid     => sub2_wr_in.wvalid,
      wready     => sub2_wr_out.wready,
      wdata      => sub2_wr_in.wdata,
      wstrb      => sub2_wr_in.wstrb,
      bvalid     => sub2_wr_out.bvalid,
      bready     => sub2_wr_in.bready,
      bresp      => sub2_wr_out.bresp,
      arvalid    => sub2_rd_in.arvalid,
      arready    => sub2_rd_out.arready,
      araddr     => sub2_rd_in.araddr(2 downto sub_lo),
      arprot     => sub2_rd_in.arprot,
      rvalid     => sub2_rd_out.rvalid,
      rready     => sub2_rd_in.rready,
      rdata      => sub2_rd_out.rdata,
      rresp      => sub2_rd_out.rresp
      );
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
    assert v = x"bb00_0011" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_0008", v);
    assert v = x"aa00_1111" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_000c", v);
    assert v = x"aa00_1122" severity error;

    wait until rising_edge(clk);

    report "end of test" severity note;

    end_of_test <= true;
    wait;
  end process;

  --  Watchdog.
  process
  begin
    wait until end_of_test for 6 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process;
end behav;
