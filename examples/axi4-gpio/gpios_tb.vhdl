entity gpios_tb is
end gpios_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.wb_tb_pkg.all;

architecture behav of gpios_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

  signal gp_inputs    : std_logic_vector(31 downto 0);
  signal gp_outputs   : std_logic_vector(31 downto 0);

  signal gpio_io_o   : std_logic_vector(31 downto 0);
  signal gpio_io_t   : std_logic_vector(31 downto 0);

  signal gpio2_io_i   : std_logic_vector(31 downto 0);
  signal gpio2_io_t   : std_logic_vector(31 downto 0);

  --  For sub1.
  signal sub1_wb_in  : t_wishbone_slave_in;
  signal sub1_wb_out : t_wishbone_slave_out;

  signal awvalid  : std_logic;
  signal awready  : std_logic;
  signal awaddr   : std_logic_vector(8 downto 2);
  signal awprot   : std_logic_vector(2 downto 0);
  signal wvalid   : std_logic;
  signal wready   : std_logic;
  signal wdata    : std_logic_vector(31 downto 0);
  signal wstrb    : std_logic_vector(3 downto 0);
  signal bvalid   : std_logic;
  signal bready   : std_logic;
  signal bresp    : std_logic_vector(1 downto 0);
  signal arvalid  : std_logic;
  signal arready  : std_logic;
  signal araddr   : std_logic_vector(8 downto 2);
  signal arprot   : std_logic_vector(2 downto 0);
  signal rvalid   : std_logic;
  signal rready   : std_logic;
  signal rdata    : std_logic_vector(31 downto 0);
  signal rresp    : std_logic_vector(1 downto 0);

  signal val : std_logic_Vector(31 downto 0);
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

  axi: entity work.axi_gpio_expanded
    generic map (
      C_ALL_INPUTS => 1,
      C_ALL_OUTPUTS => 0,
      C_IS_DUAL => 1,
      C_ALL_INPUTS_2 => 0,
      C_ALL_OUTPUTS_2 => 1,
      C_INTERRUPT_PRESENT => 0)
    port map (
      aclk => clk,
      aresetn => rst_n,

      awaddr => awaddr,
      awprot => awprot,
      awvalid => awvalid,
      awready => awready,

      wdata => wdata,
      wstrb => wstrb,
      wvalid => wvalid,
      wready => wready,

      bresp => bresp,
      bvalid => bvalid,
      bready => bready,

      araddr => araddr,
      arprot => arprot,
      arvalid => arvalid,
      arready => arready,

      rdata => rdata,
      rresp => rresp,
      rvalid => rvalid,
      rready => rready,

      gpio_io_i => gp_outputs,
      gpio_io_o => gpio_io_o,
      gpio_io_t => gpio_io_t,
      gpio2_io_i => gpio2_io_i,
      gpio2_io_o => gp_inputs,
      gpio2_io_t => gpio2_io_t);

  araddr(8 downto 6) <= (others => '0');
  awaddr(8 downto 6) <= (others => '0');
  dut : entity work.gpios
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_i       => wb_in,
      wb_o       => wb_out,

      inputs_i   => gp_inputs,
      outputs_o  => gp_outputs,

      gpios_axi4_awvalid_o  => awvalid,
      gpios_axi4_awready_i  => awready,
      gpios_axi4_awaddr_o   => awaddr(5 downto 2),
      gpios_axi4_awprot_o   => awprot,
      gpios_axi4_wvalid_o   => wvalid,
      gpios_axi4_wready_i   => wready,
      gpios_axi4_wdata_o    => wdata,
      gpios_axi4_wstrb_o    => wstrb,
      gpios_axi4_bvalid_i   => bvalid,
      gpios_axi4_bready_o   => bready,
      gpios_axi4_bresp_i    => bresp,
      gpios_axi4_arvalid_o  => arvalid,
      gpios_axi4_arready_i  => arready,
      gpios_axi4_araddr_o   => araddr(5 downto 2),
      gpios_axi4_arprot_o   => arprot,
      gpios_axi4_rvalid_i   => rvalid,
      gpios_axi4_rready_o   => rready,
      gpios_axi4_rdata_i    => rdata,
      gpios_axi4_rresp_i    => rresp);

  process
    variable v : std_logic_vector(31 downto 0);
  begin
    wb_init(clk, wb_in, wb_out);

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    --  MAP:
    --  00: reg inputs
    --  04: reg outputs
    --  40: axi4 gpio
    --  40: channel1 data (inputs)
    --  48: channel2 data (outputs)

    --  Set outputs from WB
    wb_writel (clk, wb_in, wb_out, x"0000_0004", x"abcd_0001");
    wait until rising_edge(clk);
    assert gp_outputs = x"abcd_0001" severity error;

    --  Read from axi4
    wb_readl (clk, wb_in, wb_out, x"0000_0040", v);
    wait until rising_edge(clk);
    val <= v;
    wait for 1 ns;
    assert v = x"abcd_0001" report "bad gpio input value" severity error;


    --  Set inputs from axi4
    wb_writel (clk, wb_in, wb_out, x"0000_0048", x"4567_9876");
    wait until rising_edge(clk);
    assert gp_inputs = x"4567_9876" report "bad gp_inputs value" severity error;

    --  Read from WB
    wb_readl (clk, wb_in, wb_out, x"0000_0000", v);
    wait until rising_edge(clk);
    assert v = x"4567_9876" report "bad input reg value" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    report "end of test" severity note;
    wait;
  end process;
end behav;
