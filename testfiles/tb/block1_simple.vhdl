library ieee;
use ieee.std_logic_1164.all;

use work.simple_tb_pkg.all;

-- A 4KB slave.
entity block1_simple is
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    bus_in      : in  t_simple_slave_in;
    bus_out     : out t_simple_slave_out);
end block1_simple;

architecture behav of block1_simple is
begin
    process(clk)
      --  One line of memory.
      variable mem : std_logic_vector(31 downto 0) := x"0000_6000";

      variable pattern : std_logic_vector(31 downto 0);

      --  Transactions.
      variable wt : boolean;
      variable rt : boolean;

      --  Wait states
      constant max_ws : natural := 3;
      variable cur_ws : natural := 1;
      variable ws : integer := 0;
    begin
      if rising_edge(clk) then
        if rst_n = '0' then
          bus_out.rack <= '0';
          bus_out.wack <= '0';
          wt := false;
          rt := false;
        else
          if bus_in.rd = '1' then
            rt := True;
          end if;
          if bus_in.wr = '1' then
            wt := True;
          end if;

          if rt then
            if ws < cur_ws then
              ws := ws + 1;
            elsif ws = cur_ws then
              --  It's a read.
              if bus_in.adr(11 downto 2) = (11 downto 2 => '0') then
                bus_out.dato <= mem;
              else
                pattern( 7 downto  0) := bus_in.adr(9 downto 2);
                pattern(15 downto  8) := not bus_in.adr(9 downto 2);
                pattern(23 downto 16) := not bus_in.adr(9 downto 2);
                pattern(31 downto 24) := bus_in.adr(9 downto 2);
                bus_out.dato <= pattern;
              end if;

              bus_out.rack <= '1';
              ws := ws + 1;
            else
              bus_out.rack <= '0';
              ws := 0;
              cur_ws := (cur_ws + 1) mod max_ws;
              rt := False;
            end if;
          end if;

          if wt then
            if ws < cur_ws then
              ws := ws + 1;
            elsif ws = cur_ws then
              --  It's a write.
              if bus_in.adr(11 downto 2) = (11 downto 2 => '0') then
                mem := bus_in.dati;
              else
                pattern( 7 downto  0) := not bus_in.adr(9 downto 2);
                pattern(15 downto  8) := bus_in.adr(9 downto 2);
                pattern(23 downto 16) := bus_in.adr(9 downto 2);
                pattern(31 downto 24) := not bus_in.adr(9 downto 2);
                assert bus_in.dati = pattern
                  report "block1_simple: write error" severity error;
              end if;
              bus_out.wack <= '1';
              ws := ws + 1;
            else
              bus_out.wack <= '0';
              ws := 0;
              cur_ws := (cur_ws + 1) mod max_ws;
              wt := False;
            end if;
          end if;
        end if;
      end if;
    end process;
end behav;
