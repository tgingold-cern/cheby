library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

package wb_tb_pkg is
  procedure wb_init (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in);

  procedure wb_writel (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : in    std_logic_vector (31 downto 0);
    err            : in    std_logic);

  procedure wb_writel (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : in    std_logic_vector (31 downto 0));

  procedure wb_readl (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : out   std_logic_vector (31 downto 0);
    err            : in    std_logic);

  procedure wb_readl (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : out   std_logic_vector (31 downto 0));
end wb_tb_pkg;

package body wb_tb_pkg is
  procedure wb_init (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in) is
  begin
    wb_in.stb <= '0';
    wb_in.cyc <= '0';
  end wb_init;

  procedure wb_cycle (
    signal clk     : in    std_logic;
    signal wb_in   : inout t_wishbone_slave_in;
    signal wb_out  : in    t_wishbone_slave_out;
    addr           : in    std_logic_vector (31 downto 0);
    rdata          : out   std_logic_vector (31 downto 0);
    err            : in    std_logic) is
  begin
    wb_in.cyc <= '1';
    wb_in.stb <= '1';
    wb_in.adr <= addr;
    wb_in.sel <= "1111";

    wait until rising_edge(clk);

    while wb_out.ack = '0' and wb_out.err = '0' loop
      wait until rising_edge(clk);
    end loop;

    if err = '1' then
      assert wb_out.err = '1' report "Expected error, error signal remained deasserted"      severity error;
      assert wb_out.ack = '0' report "Expected error, acknowledge signal was still asserted" severity error;
    else
      assert wb_out.ack = '1' report "Expected acknowledge, acknowledge signal remained deasserted" severity error;
      assert wb_out.err = '0' report "Expected acknowledge, error signal was still asserted"        severity error;
    end if;

    rdata := wb_out.dat;

    wb_in.cyc <= '0';
    wb_in.stb <= '0';

    wait until rising_edge(clk);
    assert (wb_out.ack = '0' and wb_out.err = '0') report "Acknowledge and error signal were not deasserted" severity error;
  end wb_cycle;

  procedure wb_writel (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : in    std_logic_vector (31 downto 0);
    err            : in    std_logic)
  is
    variable rdata : std_logic_vector (31 downto 0);
  begin
    --  W transfer
    wb_in.we <= '1';
    wb_in.dat <= data;

    wb_cycle(clk, wb_in, wb_out, addr, rdata, err);
  end wb_writel;

  procedure wb_writel (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : in    std_logic_vector (31 downto 0)) is
  begin
    wb_writel(clk, wb_out, wb_in, addr, data, '0');
  end wb_writel;

  procedure wb_readl (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : out   std_logic_vector (31 downto 0);
    err            : in    std_logic) is
  begin
    --  R transfer
    wb_in.we <= '0';

    wb_cycle(clk, wb_in, wb_out, addr, data, err);
  end wb_readl;

  procedure wb_readl (
    signal clk     : in    std_logic;
    signal wb_out  : in    t_wishbone_slave_out;
    signal wb_in   : inout t_wishbone_slave_in;
    addr           : in    std_logic_vector (31 downto 0);
    data           : out   std_logic_vector (31 downto 0)) is
  begin
    wb_readl(clk, wb_out, wb_in, addr, data, '0');
  end wb_readl;

end wb_tb_pkg;
