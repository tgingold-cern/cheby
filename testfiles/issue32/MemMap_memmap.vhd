library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_memmap is

  -- Ident Code
  constant C_memmap_IdentCode : std_logic_vector(15 downto 0) := X"0000";

  -- Memory Map Version
  constant C_memmap_MemMapVersion : std_logic_vector(31 downto 0) := X"00000000";--0
  -- Register Addresses : Memory Map
  constant C_Reg_memmap_reg1_1 : std_logic_vector(1 downto 1) := "0";-- : Word address : 0x0; Byte Address : 0x0
  constant C_Reg_memmap_reg1_0 : std_logic_vector(1 downto 1) := "1";-- : Word address : 0x1; Byte Address : 0x2

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_memmap_reg1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_memmap_reg1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_memmap_reg1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_memmap_reg1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_memmap;
