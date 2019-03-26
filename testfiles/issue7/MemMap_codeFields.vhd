library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_codeFields is

  -- Ident Code
  constant C_codeFields_IdentCode : std_logic_vector(15 downto 0) := X"0001";

  -- Memory Map Version
  constant C_codeFields_MemMapVersion : std_logic_vector(31 downto 0) := X"013413FC";--20190204
  constant C_Area_codeFields_area1 : std_logic_vector(13 downto 10) := "0000";
  constant C_Area_codeFields_area2 : std_logic_vector(13 downto 10) := "0001";
  -- Register Addresses : Area area1
  constant C_Reg_codeFields_area1_myRegister : std_logic_vector(9 downto 1) := "000000000";-- : Word address : "0" & X"00"; Byte Address : X"00"

  -- Register Auto Clear Masks : Area area1
  constant C_ACM_codeFields_area1_myRegister : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area1
  constant C_PSM_codeFields_area1_myRegister : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  constant C_Code_codeFields_area1_myRegister_problematicCodeField : std_logic_vector(15 downto 0) := "0000000000000000";
  -- Memory Data : Area area1
  -- Submap Addresses : Area area1
  -- Register Addresses : Area area2
  constant C_Reg_codeFields_area2_myRegister : std_logic_vector(9 downto 1) := "000000000";-- : Word address : "0" & X"00"; Byte Address : X"00"

  -- Register Auto Clear Masks : Area area2
  constant C_ACM_codeFields_area2_myRegister : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area2
  constant C_PSM_codeFields_area2_myRegister : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  constant C_Code_codeFields_area2_myRegister_problematicCodeField : std_logic_vector(15 downto 0) := "0000000000000000";
  -- Memory Data : Area area2
  -- Submap Addresses : Area area2
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_codeFields;
