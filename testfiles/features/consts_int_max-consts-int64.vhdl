library ieee;
use ieee.std_logic_1164.all;

package bigaddr_Consts is
  constant BIGADDR_SIZE : Natural := 2147483656;
  constant ADDR_BIGADDR_BLK : Natural := 16#80000000#;
  constant ADDR_MASK_BIGADDR_BLK : Natural := 16#fffffff8#;
  constant ADDR_FMASK_BIGADDR_BLK : Natural := 16#fffffff8#;
  constant BIGADDR_BLK_SIZE : Natural := 8;
  constant ADDR_BIGADDR_BLK_REG0 : Natural := 16#80000000#;
  constant ADDR_BIGADDR_BLK_REG1 : Natural := 16#80000004#;
end package bigaddr_Consts;
