library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_regs_nodff is

  -- Ident Code
  constant C_regs_nodff_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_regs_nodff_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map
  constant C_Reg_regs_nodff_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_regs_nodff_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_regs_nodff_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_regs_nodff_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_nodff_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_nodff_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_regs_nodff_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_nodff_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_nodff_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_regs_nodff;
