entity array1_tb is
end array1_tb;

library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

architecture behav of array1_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_in   : t_wishbone_slave_in;
  signal wb_out  : t_wishbone_slave_out;

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

  dut : entity work.array1
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_i       => wb_in,
      wb_o       => wb_out,
      areg_adr_i => (others => '0'),
      areg_rd_i  => '0',
      areg_dat_o => open);

  process
    procedure wb_cycle(addr : std_logic_vector (31 downto 0)) is
    begin
      wb_in.cyc <= '1';
      wb_in.stb <= '1';
      wb_in.adr <= addr;
      wb_in.sel <= "1111";

      wait until rising_edge(clk);

      while wb_out.ack = '0' loop
        wait until rising_edge(clk);
      end loop;

      wb_in.cyc <= '0';
      wb_in.stb <= '0';
    end wb_cycle;

    procedure wb_writel (addr : std_logic_vector (31 downto 0);
                         data : std_logic_vector (31 downto 0)) is
    begin
      --  W transfer
      wb_in.we <= '1';
      wb_in.dat <= data;

      wb_cycle(addr);
    end wb_writel;

    procedure wb_readl (addr : std_logic_vector (31 downto 0);
                        data : out std_logic_vector (31 downto 0)) is
    begin
      --  R transfer
      wb_in.we <= '0';
      wb_cycle(addr);
      data := wb_out.dat;
    end wb_readl;

    variable v : std_logic_vector(31 downto 0);
  begin
    wb_in.stb <= '0';
    wb_in.cyc <= '0';

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    wait until rising_edge(clk);
    wb_writel (x"0000_0001", x"abcd_0001");
    wait until rising_edge(clk);
    wb_writel (x"0000_0003", x"abcd_0203");
    wait until rising_edge(clk);

    wb_readl (x"0000_0001", v);
    assert v = x"abcd_0001" severity error;

    wait until rising_edge(clk);
    wb_readl (x"0000_0003", v);
    assert v = x"abcd_0203" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    wait;
  end process;
end behav;
