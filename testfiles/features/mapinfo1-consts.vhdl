library ieee;
use ieee.std_logic_1164.all;

package semver1_Consts is
  constant SEMVER1_SIZE : Natural := 4;
  constant SEMVER1_MEMMAP_VERSION : Natural := 16#10000#;
  constant SEMVER1_IDENT : Natural := 16#12345678#;
  constant ADDR_SEMVER1_R1 : Natural := 16#0#;
end package semver1_Consts;
