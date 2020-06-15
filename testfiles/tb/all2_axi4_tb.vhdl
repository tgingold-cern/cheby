entity all2_axi4_tb is
end all2_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_tb_pkg.all;

architecture behav of all2_axi4_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wr_in   : t_axi4lite_write_master_in;
  signal wr_out  : t_axi4lite_write_master_out;
  signal rd_in   : t_axi4lite_read_master_in;
  signal rd_out  : t_axi4lite_read_master_out;

  signal reg1 : std_logic_vector(31 downto 0);
  signal sub2_reg1 : std_logic_vector(31 downto 0);
  signal sub2_reg2 : std_logic_vector(31 downto 0);

  signal ram1_adr : std_logic_vector(2 downto 0);
  signal ram1_rd  : std_logic;
  signal ram1_dat : std_logic_vector(31 downto 0);

  --  For sub2.
  signal sub2_wr_in   : t_axi4lite_write_slave_in;
  signal sub2_wr_out  : t_axi4lite_write_slave_out;
  signal sub2_rd_in   : t_axi4lite_read_slave_in;
  signal sub2_rd_out  : t_axi4lite_read_slave_out;

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

  dut : entity work.all2_axi4
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => wr_out.awvalid,
      awready    => wr_in.awready,
      awaddr     => wr_out.awaddr(6 downto 2),
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
      araddr     => rd_out.araddr(6 downto 2),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      reg1_o     => reg1,

      sub2_axi4_awvalid_o  => sub2_wr_in.awvalid,
      sub2_axi4_awready_i  => sub2_wr_out.awready,
      sub2_axi4_awaddr_o   => sub2_wr_in.awaddr(5 downto 2),
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
      sub2_axi4_araddr_o   => sub2_rd_in.araddr(5 downto 2),
      sub2_axi4_arprot_o   => sub2_rd_in.arprot,
      sub2_axi4_rvalid_i   => sub2_rd_out.rvalid,
      sub2_axi4_rready_o   => sub2_rd_in.rready,
      sub2_axi4_rdata_i    => sub2_rd_out.rdata,
      sub2_axi4_rresp_i    => sub2_rd_out.rresp
      );

  sub2_dut : entity work.sub2_axi4
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => sub2_wr_in.awvalid,
      awready    => sub2_wr_out.awready,
      awaddr     => sub2_wr_in.awaddr(5 downto 2),
      awprot     => "010",
      wvalid     => sub2_wr_in.wvalid,
      wready     => sub2_wr_out.wready,
      wdata      => sub2_wr_in.wdata,
      wstrb      => "1111",
      bvalid     => sub2_wr_out.bvalid,
      bready     => sub2_wr_in.bready,
      bresp      => sub2_wr_out.bresp,
      arvalid    => sub2_rd_in.arvalid,
      arready    => sub2_rd_out.arready,
      araddr     => sub2_rd_in.araddr(5 downto 2),
      arprot     => "010",
      rvalid     => sub2_rd_out.rvalid,
      rready     => sub2_rd_in.rready,
      rdata      => sub2_rd_out.rdata,
      rresp      => sub2_rd_out.rresp,

      reg1_o     => sub2_reg1,
      reg2_o     => sub2_reg2,

      ram1_adr_i => ram1_adr,
      ram1_val_rd_i => ram1_rd,
      ram1_val_dat_o => ram1_dat
      );

  ram1_rd <= '0';

  process
    procedure axi4lite_read_slow (
      signal clk_i : in  std_logic;
      signal bus_o : out t_axi4lite_read_master_out;
      signal bus_i : in  t_axi4lite_read_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(31 downto 0)) is
    begin
      bus_o <= (araddr => addr,
                arprot => (others => '0'),
                arvalid => '1',
                rready => '0');
      wait until rising_edge(clk_i);
      --  Wait for arready
      loop
        exit when bus_i.arready = '1';
        wait until rising_edge(clk_i);
      end loop;
      --  Turn off arvalid
      bus_o.arvalid <= '0';
      --  Wait for rvalid.
      loop
        exit when bus_i.rvalid = '1';
        wait until rising_edge(clk_i);
      end loop;
      --  And wait for a few cycles.
      for i in 1 to 5 loop
        wait until rising_edge(clk_i);
      end loop;
      data := bus_i.rdata;
      bus_o.rready <= '1';
      wait until rising_edge(clk_i);
      bus_o.rready <= '0';
      wait until rising_edge(clk_i);
    end axi4lite_read_slow;
      
    variable v : std_logic_vector(31 downto 0);
  begin
    axi4lite_wr_init(wr_out);
    axi4lite_rd_init(rd_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  Testing register all1.reg1
    report "Testing register" severity note;
    if true then
      axi4lite_read_slow (clk, rd_out, rd_in, x"0000_0000", v);
    else
      axi4lite_read (clk, rd_out, rd_in, x"0000_0000", v);
    end if;
    assert v = x"1234_0000" severity error;

    axi4lite_write (clk, wr_out, wr_in, x"0000_0000", x"0000_abcd");
    axi4lite_read (clk, rd_out, rd_in, x"0000_0000", v);
    assert v = x"0000_abcd" severity error;

    --  Testing register all2.reg1
    report "Testing register" severity note;
    axi4lite_read (clk, rd_out, rd_in, x"0000_0040", v);
    assert v = x"1235_0000" severity error;

    axi4lite_write (clk, wr_out, wr_in, x"0000_0040", x"0000_aecd");

    if true then
      axi4lite_read_slow (clk, rd_out, rd_in, x"0000_0040", v);
    else
      axi4lite_read (clk, rd_out, rd_in, x"0000_0040", v);
    end if;
    assert v = x"0000_aecd" severity error;

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
