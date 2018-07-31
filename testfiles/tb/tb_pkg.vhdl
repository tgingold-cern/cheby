library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

package tb_pkg is
  procedure wb_init(signal clk     : std_logic;
                    signal wb_in   : inout t_wishbone_slave_in;
                    signal wb_out  : t_wishbone_slave_out);

  procedure wb_writel (signal clk     : std_logic;
                       signal wb_in   : inout t_wishbone_slave_in;
                       signal wb_out  : t_wishbone_slave_out;
                       addr : std_logic_vector (31 downto 0);
                       data : std_logic_vector (31 downto 0));

  procedure wb_readl (signal clk     : std_logic;
                      signal wb_in   : inout t_wishbone_slave_in;
                      signal wb_out  : t_wishbone_slave_out;
                      addr : std_logic_vector (31 downto 0);
                      data : out std_logic_vector (31 downto 0));
end tb_pkg;

package body tb_pkg is
  procedure wb_init(signal clk     : std_logic;
                    signal wb_in   : inout t_wishbone_slave_in;
                    signal wb_out  : t_wishbone_slave_out) is
    begin
      wb_in.stb <= '0';
      wb_in.cyc <= '0';
    end wb_init;

    procedure wb_cycle(signal clk     : std_logic;
                       signal wb_in   : inout t_wishbone_slave_in;
                       signal wb_out  : t_wishbone_slave_out;
                       addr : std_logic_vector (31 downto 0)) is
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

    procedure wb_writel (signal clk     : std_logic;
                         signal wb_in   : inout t_wishbone_slave_in;
                         signal wb_out  : t_wishbone_slave_out;
                         addr : std_logic_vector (31 downto 0);
                         data : std_logic_vector (31 downto 0)) is
    begin
      --  W transfer
      wb_in.we <= '1';
      wb_in.dat <= data;

      wb_cycle(clk, wb_in, wb_out, addr);
    end wb_writel;

    procedure wb_readl (signal clk     : std_logic;
                        signal wb_in   : inout t_wishbone_slave_in;
                        signal wb_out  : t_wishbone_slave_out;
                        addr : std_logic_vector (31 downto 0);
                        data : out std_logic_vector (31 downto 0)) is
    begin
      --  R transfer
      wb_in.we <= '0';
      wb_cycle(clk, wb_in, wb_out, addr);
      data := wb_out.dat;
    end wb_readl;
end tb_pkg;
