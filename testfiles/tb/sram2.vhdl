library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram2 is
  port (
    clk_i  : std_logic;
    addr_i : std_logic_vector(4 downto 2);
    data_i : std_logic_vector(31 downto 0);
    data_o : out std_logic_vector(31 downto 0);
    wr_i   : std_logic);
end sram2;

architecture behav of sram2 is
begin
  process (clk_i, addr_i)
    type mem_type is array (0 to 7) of std_logic_vector (31 downto 0);
    variable mem : mem_type;
    variable addr : natural range 0 to 7;
  begin
    if rising_edge(clk_i) then
      addr := to_integer (unsigned (addr_i));
      data_o <= mem (addr);
      if wr_i = '1' then
        mem (addr) := data_i;
      end if;
    end if;
  end process;
end behav;
