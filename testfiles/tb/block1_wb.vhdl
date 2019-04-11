library ieee;
use ieee.std_logic_1164.all;

use work.wishbone_pkg.all;

-- A 4KB slave.
entity block1_wb is
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    sub1_wb_in  : in  t_wishbone_slave_in;
    sub1_wb_out : out t_wishbone_slave_out);
end block1_wb;

architecture behav of block1_wb is
  signal done : std_logic;
begin
    sub1_wb_out.err <= '0';
    sub1_wb_out.rty <= '0';
    sub1_wb_out.stall <= '0';

    process(clk)
      --  One line of memory.
      variable mem : std_logic_vector(31 downto 0) := x"0000_1000";

      variable pattern : std_logic_vector(31 downto 0);

      constant max_ws : natural := 3;
      variable cur_ws : natural := 1;
      variable ws : integer := 0;
    begin
      if rising_edge(clk) then
        if (sub1_wb_in.cyc and sub1_wb_in.stb) = '1' then
          --  Transaction in progress.
          if ws < cur_ws then
            --  Wait.
            ws := ws + 1;
            sub1_wb_out.ack <= '0';
          else
            --  Handle the transaction.
            if sub1_wb_in.we = '1' then
              --  That's a write.
              if sub1_wb_in.adr(11 downto 2) = (11 downto 2 => '0') then
                --  Write mem.
                mem := sub1_wb_in.dat;
              else
                --  Check pattern
                pattern( 7 downto  0) := not sub1_wb_in.adr(9 downto 2);
                pattern(15 downto  8) := sub1_wb_in.adr(9 downto 2);
                pattern(23 downto 16) := sub1_wb_in.adr(9 downto 2);
                pattern(31 downto 24) := not sub1_wb_in.adr(9 downto 2);

                assert sub1_wb_in.dat = pattern
                  report "block1_wb: write error" severity error;
              end if;
            else
              --  That's a read.
              if sub1_wb_in.adr(11 downto 2) = (11 downto 2 => '0') then
                --  Read mem
                sub1_wb_out.dat <= mem;
              else
                pattern( 7 downto  0) := sub1_wb_in.adr(9 downto 2);
                pattern(15 downto  8) := not sub1_wb_in.adr(9 downto 2);
                pattern(23 downto 16) := not sub1_wb_in.adr(9 downto 2);
                pattern(31 downto 24) := sub1_wb_in.adr(9 downto 2);

                sub1_wb_out.dat <= pattern;
              end if;
            end if;
            --  Ack.
            sub1_wb_out.ack <= '1';
            ws := -1;
            cur_ws := (cur_ws + 1) mod max_ws;
          end if;
        else
          sub1_wb_out.ack <= '0';
        end if;
      end if;
    end process;
end behav;
