library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_submap_internal is

  -- Ident Code
  constant C_submap_internal_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_submap_internal_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
  constant C_Submap_submap_internal_submap1 : std_logic_vector(19 downto 10) := "0000000000";-- : Word address : "00" & X"00"; Byte Address : X"00"
end MemMap_submap_internal;
