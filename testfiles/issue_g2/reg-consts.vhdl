library ieee;
use ieee.std_logic_1164.all;

package header_block_Consts is
  constant HEADER_BLOCK_SIZE : Natural := 8;
  constant ADDR_HEADER_BLOCK_REG_000_DRAWING_NUMBER : Natural := 16#0#;
  constant HEADER_BLOCK_REG_000_DRAWING_NUMBER_PRESET : std_logic_vector(32-1 downto 0) := x"08000101";
  constant ADDR_HEADER_BLOCK_REG_001_VERSION_REVISION : Natural := 16#4#;
  constant HEADER_BLOCK_REG_001_VERSION_REVISION_VERSION_OFFSET : Natural := 0;
  constant HEADER_BLOCK_REG_001_VERSION_REVISION_REVISION_OFFSET : Natural := 4;
  constant HEADER_BLOCK_REG_001_VERSION_REVISION_BUILD_DATE_OFFSET : Natural := 12;
end package header_block_Consts;
