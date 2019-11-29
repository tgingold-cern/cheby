library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_mainMap is

  -- Ident Code
  constant C_mainMap_IdentCode : std_logic_vector(31 downto 0) := X"00000000";

  -- Memory Map Version
  constant C_mainMap_MemMapVersion : std_logic_vector(31 downto 0) := X"00000000";--0
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
  constant C_Submap_mainMap_ssmap2 : std_logic_vector(9 downto 2) := "00000000";-- : Word address : 0x00; Byte Address : 0x000
end MemMap_mainMap;
