library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_timing is

  -- Ident Code
  constant C_timing_IdentCode : std_logic_vector(15 downto 0) := X"0000";

  -- Memory Map Version
  constant C_timing_MemMapVersion : std_logic_vector(31 downto 0) := X"0133EEE6";--20180710

  -- Semantic Memory Map Version
  constant C_timing_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00100401";--1.1.1
  -- Register Addresses : Memory Map
  constant C_Reg_timing_r1 : std_logic_vector(7 downto 1) := "0000000";-- : Word address : 0x00; Byte Address : 0x00
  constant C_Reg_timing_r2 : std_logic_vector(7 downto 1) := "0000001";-- : Word address : 0x01; Byte Address : 0x02

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_timing_r1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_timing_r2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_timing_r1 : std_logic_vector(15 downto 0) := "0000000000100001";-- : Value : X"0021"
  constant C_PSM_timing_r2 : std_logic_vector(15 downto 0) := "0000000000010010";-- : Value : X"0012"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_timing;
