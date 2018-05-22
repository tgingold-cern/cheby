library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_regs is

  -- Ident Code
  constant C_regs_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_regs_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map
  constant C_Reg_regs_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Reg_regs_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : "000" & X"0001"; Byte Address : X"0002"
  constant C_Reg_regs_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : "000" & X"0002"; Byte Address : X"0004"
  constant C_Reg_regs_test3 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : "000" & X"0003"; Byte Address : X"0006"
  constant C_Reg_regs_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : "000" & X"0004"; Byte Address : X"0008"
  constant C_Reg_regs_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : "000" & X"0005"; Byte Address : X"000a"
  constant C_Reg_regs_test5 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : "000" & X"0006"; Byte Address : X"000c"
  constant C_Reg_regs_test6_1 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : "000" & X"0007"; Byte Address : X"000e"
  constant C_Reg_regs_test6_0 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : "000" & X"0008"; Byte Address : X"0010"
  constant C_Reg_regs_test7 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : "000" & X"0009"; Byte Address : X"0012"
  constant C_Reg_regs_test8_1 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : "000" & X"000a"; Byte Address : X"0014"
  constant C_Reg_regs_test8_0 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : "000" & X"000b"; Byte Address : X"0016"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_regs_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_regs_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_regs;
