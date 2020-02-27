library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_m1 is

  -- Ident Code
  constant C_m1_IdentCode : std_logic_vector(31 downto 0) := X"00000001";

  -- Memory Map Version
  constant C_m1_MemMapVersion : std_logic_vector(31 downto 0) := X"01343B1D";--20200221

  -- Semantic Memory Map Version
  constant C_m1_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00100000";--1.0.0
  -- Register Addresses : Memory Map
  constant C_Reg_m1_r1_1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_m1_r1_0 : std_logic_vector(19 downto 2) := "000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00004

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_m1_r1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_m1_r1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_m1_r1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_m1_r1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_m1;
