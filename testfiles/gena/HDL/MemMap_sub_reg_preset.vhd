library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_sub_reg_preset is

  -- Ident Code
  constant C_sub_reg_preset_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_sub_reg_preset_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_sub_reg_preset_test1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : "00" & X"0000"; Byte Address : X"0000"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_sub_reg_preset_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_sub_reg_preset_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000001100";-- : Value : X"0000000c"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_sub_reg_preset;
