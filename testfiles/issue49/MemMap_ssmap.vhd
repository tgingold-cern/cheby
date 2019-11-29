-- Do not edit.  Generated on Fri Nov 29 09:23:16 2019 by tgingold
-- With Cheby 1.4.dev0 and these options:
--  -i ssmap.cheby --gen-gena-memmap

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_ssmap is

  -- Ident Code
  constant C_ssmap_IdentCode : std_logic_vector(31 downto 0) := X"00000000";

  -- Memory Map Version
  constant C_ssmap_MemMapVersion : std_logic_vector(31 downto 0) := X"00000000";--0
  constant C_Area_ssmap_b1 : std_logic_vector(1 downto 2) := "";
  -- Register Addresses : Area b1
  constant C_Reg_ssmap_b1_r1 : std_logic_vector(1 downto 2) := "";-- : Word address : 0x0; Byte Address : 0x0

  -- Register Auto Clear Masks : Area b1
  constant C_ACM_ssmap_b1_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Area b1
  constant C_PSM_ssmap_b1_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Area b1
  -- Submap Addresses : Area b1
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_ssmap;
