entity all2_axi4_tb is
end all2_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4lite_pkg.all;
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
  signal sub2_wr_in   : t_axi4lite_subordinate_in;
  signal sub2_wr_out  : t_axi4lite_subordinate_out;
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

      axi4l_i.awvalid    => wr_out.awvalid,
      axi4l_i.awaddr     => wr_out.awaddr,
      axi4l_i.awprot     => "010",
      axi4l_i.wvalid     => wr_out.wvalid,
      axi4l_i.wdata      => wr_out.wdata,
      axi4l_i.wstrb      => "1111",
      axi4l_i.bready     => wr_out.bready,
      axi4l_i.arvalid    => rd_out.arvalid,
      axi4l_i.araddr     => rd_out.araddr,
      axi4l_i.arprot     => "010",
      axi4l_i.rready     => rd_out.rready,
      axi4l_o.awready    => wr_in.awready,
      axi4l_o.wready     => wr_in.wready,
      axi4l_o.bvalid     => wr_in.bvalid,
      axi4l_o.bresp      => wr_in.bresp,
      axi4l_o.arready    => rd_in.arready,
      axi4l_o.rvalid     => rd_in.rvalid,
      axi4l_o.rdata      => rd_in.rdata,
      axi4l_o.rresp      => rd_in.rresp,

      reg1_o     => reg1,

      sub2_i => sub2_wr_out,
      sub2_o => sub2_wr_in
      );


  sub2_wr_in.awprot <= "010";
  sub2_wr_in.wstrb  <= "1111";
  sub2_wr_in.arprot <= "010";
  sub2_dut : entity work.sub2
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      axi4l_i    => sub2_wr_in,
      axi4l_o    => sub2_wr_out,

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
