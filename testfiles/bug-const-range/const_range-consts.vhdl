library ieee;
use ieee.std_logic_1164.all;

package const_range_Consts is
  constant CONST_RANGE_SIZE : Natural := 20;
  constant ADDR_CONST_RANGE_LARGE_VAL_0 : Natural := 16#0#;
  constant CONST_RANGE_LARGE_VAL_0_PRESET : std_logic_vector(32-1 downto 0) := x"f38243bb";
  constant ADDR_CONST_RANGE_LARGE_VAL_1 : Natural := 16#4#;
  constant CONST_RANGE_LARGE_VAL_1_PRESET : std_logic_vector(32-1 downto 0) := x"fffffff7";
  constant ADDR_CONST_RANGE_SUPER_LARGE_VAL : Natural := 16#8#;
  constant CONST_RANGE_SUPER_LARGE_VAL_PRESET : std_logic_vector(64-1 downto 0) := x"818734fa9b1e0cf4";
  constant ADDR_CONST_RANGE_SMALL_VAL : Natural := 16#10#;
  constant CONST_RANGE_SMALL_VAL_PRESET : std_logic_vector(32-1 downto 0) := x"00000001";
end package const_range_Consts;
