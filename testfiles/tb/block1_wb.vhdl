library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

entity block1_wb is
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    sub1_wb_in  : in  t_wishbone_slave_in;
    sub1_wb_out : out t_wishbone_slave_out);
end block1_wb;

architecture behav of block1_wb is
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
end behav;
