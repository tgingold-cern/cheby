library ieee;
use ieee.std_logic_1164.all;

package bigaddr_Consts is
  constant BIGADDR_SIZE_SLV : std_logic_vector(32-1 downto 0) := x"80000008";
  constant ADDR_BIGADDR_BLK_SLV : std_logic_vector(32-1 downto 0) := x"80000000";
  constant ADDR_MASK_BIGADDR_BLK_SLV : std_logic_vector(32-1 downto 0) := x"fffffff8";
  constant ADDR_FMASK_BIGADDR_BLK_SLV : std_logic_vector(32-1 downto 0) := x"fffffff8";
  constant BIGADDR_BLK_SIZE : Natural := 8;
  constant ADDR_BIGADDR_BLK_REG0_SLV : std_logic_vector(32-1 downto 0) := x"80000000";
  constant ADDR_BIGADDR_BLK_REG1_SLV : std_logic_vector(32-1 downto 0) := x"80000004";
end package bigaddr_Consts;
