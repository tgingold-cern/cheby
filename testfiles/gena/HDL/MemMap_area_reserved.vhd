library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_area_reserved is

  -- Ident Code
  constant C_area_reserved_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_area_reserved_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  constant C_Area_area_reserved_area : std_logic_vector(19 downto 19) := "1";
  -- Register Addresses : Area area
  constant C_Reg_area_reserved_area_test2 : std_logic_vector(18 downto 2) := "00000000000000000";-- : Word address : "0" & X"0000"; Byte Address : X"0000"

  -- Register Auto Clear Masks : Area area
  constant C_ACM_area_reserved_area_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area
  constant C_PSM_area_reserved_area_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Area area
  -- Submap Addresses : Area area
  -- Register Addresses : Memory Map
  constant C_Reg_area_reserved_test1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : "00" & X"0000"; Byte Address : X"0000"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_area_reserved_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_area_reserved_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_area_reserved;
