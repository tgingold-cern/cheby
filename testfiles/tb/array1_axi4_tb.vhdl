entity array1_axi4_tb is
end array1_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.axi4_tb_pkg.all;

architecture behav of array1_axi4_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wr_in   : t_axi4lite_write_master_in;
  signal wr_out  : t_axi4lite_write_master_out;
  signal rd_in   : t_axi4lite_read_master_in;
  signal rd_out  : t_axi4lite_read_master_out;

  signal end_of_test : boolean := false;
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

  dut : entity work.array1_axi4
    port map (
      aclk       => clk,
      areset_n   => rst_n,
      awvalid    => wr_out.awvalid,
      awready    => wr_in.awready,
      awaddr     => wr_out.awaddr(5 downto 2),
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
      araddr     => rd_out.araddr(5 downto 2),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      ram1_adr_i => (others => '0'),
      ram1_rd_i  => '0',
      ram1_dat_o => open);

  process
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

    report "Testing memory" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0024", x"abcd_0001");
    axi4lite_write (clk, wr_out, wr_in, x"0000_002c", x"abcd_0203");

    axi4lite_read (clk, rd_out, rd_in, x"0000_0024", v);
    assert v = x"abcd_0001" severity error;

    wait until rising_edge(clk);
    axi4lite_read (clk, rd_out, rd_in, x"0000_002c", v);
    assert v = x"abcd_0203" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    wait;
  end process;
end behav;
