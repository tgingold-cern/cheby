library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_mainMap is

  -- Ident Code
  constant C_mainMap_IdentCode : std_logic_vector(31 downto 0) := X"00000001";

  -- Memory Map Version
  constant C_mainMap_MemMapVersion : std_logic_vector(31 downto 0) := X"0134659F";--20211103

  -- Semantic Memory Map Version
  constant C_mainMap_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00010000";--1.0.0
  -- Register Addresses : Memory Map
  constant C_Reg_mainMap_r1 : std_logic_vector(13 downto 2) := "000000000000";-- : Word address : 0x000; Byte Address : 0x0000

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_mainMap_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_mainMap_r1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map

  -- ENUMERATIONS
  constant C_Code_mainMap_r1_yes : std_logic_vector(31 downto 0) := "00000000000000000000000000000001";
  constant C_Code_mainMap_r1_no : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
end MemMap_mainMap;
