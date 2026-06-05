library ieee;
use ieee.std_logic_1164.all;

package bigaddr_Consts is
  constant BIGADDR_SIZE : std_logic_vector(32-1 downto 0) := x"80000008";
  constant ADDR_BIGADDR_REG0 : std_logic_vector(32-1 downto 0) := x"80000000";
  constant ADDR_BIGADDR_REG1 : std_logic_vector(32-1 downto 0) := x"80000004";
end package bigaddr_Consts;
