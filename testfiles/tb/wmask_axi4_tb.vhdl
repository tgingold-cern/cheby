library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axi4_tb_pkg.all;


entity wmask_axi4_tb is
end wmask_axi4_tb;


architecture tb of wmask_axi4_tb is
  signal rst_n  : std_logic;
  signal clk    : std_logic;
  signal wr_in  : t_axi4lite_write_master_in;
  signal wr_out : t_axi4lite_write_master_out;
  signal rd_in  : t_axi4lite_read_master_in;
  signal rd_out : t_axi4lite_read_master_out;

  signal reg1   : std_logic_vector(31 downto 0);

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

  dut : entity work.wmask_axi4
    port map (
      aclk            => clk,
      areset_n        => rst_n,
      awvalid         => wr_out.awvalid,
      awready         => wr_in.awready,
      awaddr          => wr_out.awaddr(5 downto 2),
      awprot          => "010",
      wvalid          => wr_out.wvalid,
      wready          => wr_in.wready,
      wdata           => wr_out.wdata,
      wstrb           => wr_out.wstrb,
      bvalid          => wr_in.bvalid,
      bready          => wr_out.bready,
      bresp           => wr_in.bresp,
      arvalid         => rd_out.arvalid,
      arready         => rd_in.arready,
      araddr          => rd_out.araddr(5 downto 2),
      arprot          => "010",
      rvalid          => rd_in.rvalid,
      rready          => rd_out.rready,
      rdata           => rd_in.rdata,
      rresp           => rd_in.rresp,

      reg1_o          => reg1,
      ram1_adr_i      => (others => '0'),
      ram1_row1_rd_i  => '0',
      ram1_row1_dat_o => open
    );

  main : process is
    variable v : std_logic_vector(31 downto 0);
  begin
    axi4lite_wr_init(wr_out);
    axi4lite_rd_init(rd_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    -- Register
    -- Testing regular register read
    report "Testing regular register read" severity note;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0000", v);
    assert reg1 = x"0000_0000" severity error;
    assert v = x"0000_0000" severity error;

    -- Testing regular register write
    report "Testing regular register write" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_0000", x"1234_5678", "1111", C_AXI4_RESP_OK);
    assert reg1 = x"1234_5678" severity error;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0000", v);
    assert v = x"1234_5678" severity error;

    --  Testing register write with mask
    report "Testing register write with mask" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0000_0000", x"9abc_def0", "1010", C_AXI4_RESP_OK);
    assert reg1 = x"9a34_de78" severity error;
    axi4lite_read(clk, rd_out, rd_in, x"0000_0000", v);
    assert v = x"9a34_de78" severity error;

    -- Memory
    -- Testing regular memory write
    report "Testing regular memory write" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0010_0000", x"1234_5678", "1111", C_AXI4_RESP_OK);
    assert reg1 = x"1234_5678" severity error;
    axi4lite_read(clk, rd_out, rd_in, x"0010_0000", v);
    assert v = x"1234_5678" severity error;

    -- Testing memory write with mask
    report "Testing memory write with mask" severity note;
    axi4lite_write(clk, wr_out, wr_in, x"0010_0000", x"9abc_def0", "1010", C_AXI4_RESP_OK);
    assert reg1 = x"9a34_de78" severity error;
    axi4lite_read(clk, rd_out, rd_in, x"0010_0000", v);
    assert v = x"9a34_de78" severity error;

    wait until rising_edge(clk);
    wait until rising_edge(clk);
    report "End of test" severity note;
    end_of_test <= true;
  end process main;

  watchdog : process is
  begin
    wait until end_of_test for 5 us;
    assert end_of_test report "timeout" severity failure;
    wait;
  end process watchdog;

end tb;
