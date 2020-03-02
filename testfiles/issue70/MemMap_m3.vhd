library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_m3 is
  -- Register Addresses : Memory Map
  constant C_Reg_m3_r1 : std_logic_vector(1 downto 2) := "";-- : Word address : 0x0; Byte Address : 0x0

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_m3_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_m3_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_m3;
