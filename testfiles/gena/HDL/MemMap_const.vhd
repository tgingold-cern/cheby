library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_const is

  -- Ident Code
  constant C_const_IdentCode : std_logic_vector(31 downto 0) := X"00300010";

  -- Memory Map Version
  constant C_const_MemMapVersion : std_logic_vector(31 downto 0) := X"0134158F";--20190607

  -- Semantic Memory Map Version
  constant C_const_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00010100";--1.1.0
  -- Register Addresses : Memory Map
  constant C_Reg_const_firmwareVersion : std_logic_vector(17 downto 2) := "0000000000000000";-- : Word address : 0x0000; Byte Address : 0x00000
  constant C_Reg_const_memMapVersion : std_logic_vector(17 downto 2) := "0000000000000001";-- : Word address : 0x0001; Byte Address : 0x00004
  constant C_Reg_const_designerID : std_logic_vector(17 downto 2) := "0000000000000010";-- : Word address : 0x0002; Byte Address : 0x00008

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_const_firmwareVersion : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_const_memMapVersion : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_const_designerID : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_const_firmwareVersion : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_const_memMapVersion : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_const_designerID : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_const;
