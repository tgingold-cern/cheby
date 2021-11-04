library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_semver is

  -- Ident Code
  constant C_semver_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_semver_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031

  -- Semantic Memory Map Version
  constant C_semver_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00010203";--1.2.3
  -- Register Addresses : Memory Map
  constant C_Reg_semver_test3 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_semver_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_semver_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_semver;
