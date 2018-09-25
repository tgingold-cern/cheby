entity array1_axi4_tb is
end array1_axi4_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;
use work.axi4_tb_pkg.all;

architecture behav of array1_axi4_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wr_in   : t_axi4lite_write_master_in;
  signal wr_out  : t_axi4lite_write_master_out;
  signal rd_in   : t_axi4lite_read_master_in;
  signal rd_out  : t_axi4lite_read_master_out;

  --  For sub1.
  signal sub1_wb_in  : t_wishbone_slave_in;
  signal sub1_wb_out : t_wishbone_slave_out;

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
      awaddr     => wr_out.awaddr(12 downto 2),
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
      araddr     => rd_out.araddr(12 downto 2),
      arprot     => "010",
      rvalid     => rd_in.rvalid,
      rready     => rd_out.rready,
      rdata      => rd_in.rdata,
      rresp      => rd_in.rresp,

      ram1_adr_i => (others => '0'),
      ram1_rd_i  => '0',
      ram1_dat_o => open,

      sub1_wb_cyc_o => sub1_wb_in.cyc,
      sub1_wb_stb_o => sub1_wb_in.stb,
      sub1_wb_adr_o => sub1_wb_in.adr(9 downto 0),
      sub1_wb_sel_o => sub1_wb_in.sel,
      sub1_wb_we_o  => sub1_wb_in.we,
      sub1_wb_dat_o => sub1_wb_in.dat,
      sub1_wb_ack_i => sub1_wb_out.ack,
      sub1_wb_err_i => sub1_wb_out.err,
      sub1_wb_rty_i => sub1_wb_out.rty,
      sub1_wb_stall_i => sub1_wb_out.stall,
      sub1_wb_dat_i => sub1_wb_out.dat);

  b1: block
  begin
    sub1_wb_out.err <= '0';
    sub1_wb_out.rty <= '0';
    sub1_wb_out.stall <= '0';

    process(clk)
    begin
      if rising_edge(clk) then
        if (sub1_wb_in.cyc and sub1_wb_in.stb) = '1' then
          if sub1_wb_in.adr(9) = '1' then
            --  Discard write, read addr
            sub1_wb_out.dat( 7 downto  0) <= sub1_wb_in.adr(7 downto 0);
            sub1_wb_out.dat(15 downto  8) <= not sub1_wb_in.adr(7 downto 0);
            sub1_wb_out.dat(23 downto 16) <= not sub1_wb_in.adr(7 downto 0);
            sub1_wb_out.dat(31 downto 24) <= sub1_wb_in.adr(7 downto 0);
          else
            --  0.
            sub1_wb_out.dat <= (others => '0');
          end if;
          sub1_wb_out.ack <= '1';
        else
          sub1_wb_out.ack <= '0';
        end if;
      end if;
    end process;
  end block;

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

    --  Testing memory
    report "Testing memory" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_0024", x"abcd_0001");
    axi4lite_write (clk, wr_out, wr_in, x"0000_002c", x"abcd_0203");

    axi4lite_read (clk, rd_out, rd_in, x"0000_0024", v);
    assert v = x"abcd_0001" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_002c", v);
    assert v = x"abcd_0203" severity error;

    --  Testing WB
    report "Testing wishbone" severity note;
    axi4lite_write (clk, wr_out, wr_in, x"0000_1000", x"9876_5432");

    axi4lite_read (clk, rd_out, rd_in, x"0000_1804", v);
    assert v = x"01fe_fe01" severity error;

    axi4lite_read (clk, rd_out, rd_in, x"0000_1004", v);
    assert v = x"0000_0000" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    wait;
  end process;
end behav;
