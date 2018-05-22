library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_mems_nodff is

  -- Ident Code
  constant C_mems_nodff_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_mems_nodff_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_mems_nodff_mem1_Sta : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Mem_mems_nodff_mem1_End : std_logic_vector(19 downto 1) := "0000000000111111111";-- : Word address : "000" & X"01ff"; Byte Address : X"03fe"
  constant C_Mem_mems_nodff_mem2_Sta : std_logic_vector(19 downto 1) := "0000000001000000000";-- : Word address : "000" & X"0200"; Byte Address : X"0400"
  constant C_Mem_mems_nodff_mem2_End : std_logic_vector(19 downto 1) := "0000000001111111111";-- : Word address : "000" & X"03ff"; Byte Address : X"07fe"
  constant C_Mem_mems_nodff_mem3_Sta : std_logic_vector(19 downto 1) := "0000000010000000000";-- : Word address : "000" & X"0400"; Byte Address : X"0800"
  constant C_Mem_mems_nodff_mem3_End : std_logic_vector(19 downto 1) := "0000000010111111111";-- : Word address : "000" & X"05ff"; Byte Address : X"0bfe"
  -- Submap Addresses : Memory Map
end MemMap_mems_nodff;
