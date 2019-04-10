library ieee;
use ieee.std_logic_1164.all;

use work.cernbe_tb_pkg.all;

-- A 4KB slave.
entity block1_cernbe is
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    bus_in      : in  t_cernbe_slave_in;
    bus_out     : out t_cernbe_slave_out);
end block1_cernbe;

architecture behav of block1_cernbe is
  type t_state is (IDLE, RD, WR);
  signal state : t_state;
begin
    process(clk)
      --  One line of memory.
      variable mem : std_logic_vector(31 downto 0) := x"0000_3000";

      variable pattern : std_logic_vector(31 downto 0);
    begin
      if rising_edge(clk) then
        if rst_n = '0' then
          state <= IDLE;
          bus_out.VMERdDone <= '0';
          bus_out.VMEWrDone <= '0';
        else
          case state is
            when IDLE =>
              if bus_in.VMERdMem = '1' then
                --  It's a read.
                if bus_in.VMEAddr(11 downto 2) = (11 downto 2 => '0') then
                  bus_out.VMERdData <= mem;
                else
                  pattern( 7 downto  0) := bus_in.VMEAddr(9 downto 2);
                  pattern(15 downto  8) := not bus_in.VMEAddr(9 downto 2);
                  pattern(23 downto 16) := not bus_in.VMEAddr(9 downto 2);
                  pattern(31 downto 24) := bus_in.VMEAddr(9 downto 2);
                  bus_out.VMERdData <= pattern;
                end if;

                bus_out.VMERdDone <= '1';
                state <= RD;
              end if;
              if bus_in.VMEWrMem = '1' then
                --  It's a write.
                if bus_in.VMEAddr(11 downto 2) = (11 downto 2 => '0') then
                  mem := bus_in.VMEWrData;
                else
                  pattern( 7 downto  0) := bus_in.VMEAddr(9 downto 2);
                  pattern(15 downto  8) := not bus_in.VMEAddr(9 downto 2);
                  pattern(23 downto 16) := not bus_in.VMEAddr(9 downto 2);
                  pattern(31 downto 24) := bus_in.VMEAddr(9 downto 2);
                  assert bus_in.VMEWrData = pattern
                    report "block1_cernbe: write error" severity error;
                end if;
                bus_out.VMEWrDone <= '1';
                state <= WR;
              end if;
            when RD =>
              bus_out.VMERdDone <= '0';
              state <= IDLE;
            when WR =>
              bus_out.VMEWrDone <= '0';
              state <= IDLE;
          end case;
        end if;
      end if;
    end process;
end behav;
