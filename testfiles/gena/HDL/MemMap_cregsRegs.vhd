library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregsRegs is

  -- Ident Code
  constant C_cregsRegs_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_cregsRegs_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregsRegs_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Reg_cregsRegs_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : "000" & X"0001"; Byte Address : X"0002"
  constant C_Reg_cregsRegs_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : "000" & X"0002"; Byte Address : X"0004"
  constant C_Reg_cregsRegs_test3 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : "000" & X"0003"; Byte Address : X"0006"
  constant C_Reg_cregsRegs_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : "000" & X"0004"; Byte Address : X"0008"
  constant C_Reg_cregsRegs_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : "000" & X"0005"; Byte Address : X"000a"
  constant C_Reg_cregsRegs_test5 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : "000" & X"0006"; Byte Address : X"000c"
  constant C_Reg_cregsRegs_test6_1 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : "000" & X"0007"; Byte Address : X"000e"
  constant C_Reg_cregsRegs_test6_0 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : "000" & X"0008"; Byte Address : X"0010"
  constant C_Reg_cregsRegs_test7 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : "000" & X"0009"; Byte Address : X"0012"
  constant C_Reg_cregsRegs_test8_1 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : "000" & X"000a"; Byte Address : X"0014"
  constant C_Reg_cregsRegs_test8_0 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : "000" & X"000b"; Byte Address : X"0016"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregsRegs_test1 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregsRegs_test2_1 : std_logic_vector(31 downto 16) := "1000001111000011";-- : Value : X"83c3"
  constant C_ACM_cregsRegs_test2_0 : std_logic_vector(15 downto 0) := "1100001111000001";-- : Value : X"c3c1"
  constant C_ACM_cregsRegs_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegs_test4_0 : std_logic_vector(15 downto 0) := "0011110000111110";-- : Value : X"3c3e"
  constant C_ACM_cregsRegs_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegs_test6_1 : std_logic_vector(31 downto 16) := "1000001111000011";-- : Value : X"83c3"
  constant C_ACM_cregsRegs_test6_0 : std_logic_vector(15 downto 0) := "1100001111000001";-- : Value : X"c3c1"
  constant C_ACM_cregsRegs_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegs_test8_1 : std_logic_vector(31 downto 16) := "0111110000111100";-- : Value : X"7c3c"
  constant C_ACM_cregsRegs_test8_0 : std_logic_vector(15 downto 0) := "0011110000111110";-- : Value : X"3c3e"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregsRegs_test1 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregsRegs_test2_1 : std_logic_vector(31 downto 16) := "1000001111000011";-- : Value : X"83c3"
  constant C_PSM_cregsRegs_test2_0 : std_logic_vector(15 downto 0) := "1100001111000001";-- : Value : X"c3c1"
  constant C_PSM_cregsRegs_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test4_0 : std_logic_vector(15 downto 0) := "0011110000111110";-- : Value : X"3c3e"
  constant C_PSM_cregsRegs_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test6_1 : std_logic_vector(31 downto 16) := "1000001111000011";-- : Value : X"83c3"
  constant C_PSM_cregsRegs_test6_0 : std_logic_vector(15 downto 0) := "1100001111000001";-- : Value : X"c3c1"
  constant C_PSM_cregsRegs_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test8_1 : std_logic_vector(31 downto 16) := "0111110000111100";-- : Value : X"7c3c"
  constant C_PSM_cregsRegs_test8_0 : std_logic_vector(15 downto 0) := "0011110000111110";-- : Value : X"3c3e"

  -- CODE FIELDS
  constant C_Code_cregsRegs_test8_msBit_hello : std_logic_vector(31 downto 31) := "0";
  constant C_Code_cregsRegs_test8_msBit_world : std_logic_vector(31 downto 31) := "1";
  constant C_Code_cregsRegs_test8_msReg_hello : std_logic_vector(25 downto 22) := "0000";
  constant C_Code_cregsRegs_test8_msReg_world : std_logic_vector(25 downto 22) := "0001";
  constant C_Code_cregsRegs_test6_msBit_hello : std_logic_vector(31 downto 31) := "0";
  constant C_Code_cregsRegs_test6_msBit_world : std_logic_vector(31 downto 31) := "1";
  constant C_Code_cregsRegs_test6_msReg_hello : std_logic_vector(25 downto 22) := "0000";
  constant C_Code_cregsRegs_test6_msReg_world : std_logic_vector(25 downto 22) := "0001";
  constant C_Code_cregsRegs_test4_msBit_hello : std_logic_vector(31 downto 31) := "0";
  constant C_Code_cregsRegs_test4_msBit_world : std_logic_vector(31 downto 31) := "1";
  constant C_Code_cregsRegs_test4_msReg_hello : std_logic_vector(25 downto 22) := "0000";
  constant C_Code_cregsRegs_test4_msReg_world : std_logic_vector(25 downto 22) := "0001";
  constant C_Code_cregsRegs_test2_msBit_hello : std_logic_vector(31 downto 31) := "0";
  constant C_Code_cregsRegs_test2_msBit_world : std_logic_vector(31 downto 31) := "1";
  constant C_Code_cregsRegs_test2_msReg_hello : std_logic_vector(25 downto 22) := "0000";
  constant C_Code_cregsRegs_test2_msReg_world : std_logic_vector(25 downto 22) := "0001";
  constant C_Code_cregsRegs_test1_hello : std_logic_vector(7 downto 0) := "00000000";
  constant C_Code_cregsRegs_test1_World : std_logic_vector(7 downto 0) := "00000001";
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregsRegs;
