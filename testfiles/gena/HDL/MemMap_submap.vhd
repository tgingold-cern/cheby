library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_submap is

  -- Ident Code
  constant C_submap_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_submap_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
  constant C_Submap_submap_submap1 : std_logic_vector(19 downto 10) := "0000000000";-- : Word address : 0x000; Byte Address : 0x000
end MemMap_submap;
