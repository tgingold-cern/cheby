library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregsRegsNoRMW is

  -- Ident Code
  constant C_cregsRegsNoRMW_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_cregsRegsNoRMW_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map
  constant C_Reg_cregsRegsNoRMW_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregsRegsNoRMW_test2_3 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_cregsRegsNoRMW_test2_2 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_cregsRegsNoRMW_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_cregsRegsNoRMW_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_cregsRegsNoRMW_test3 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a
  constant C_Reg_cregsRegsNoRMW_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : 0x00006; Byte Address : 0x0000c
  constant C_Reg_cregsRegsNoRMW_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : 0x00007; Byte Address : 0x0000e
  constant C_Reg_cregsRegsNoRMW_test5 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00010
  constant C_Reg_cregsRegsNoRMW_test6_3 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00012
  constant C_Reg_cregsRegsNoRMW_test6_2 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x00014
  constant C_Reg_cregsRegsNoRMW_test6_1 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x00016
  constant C_Reg_cregsRegsNoRMW_test6_0 : std_logic_vector(19 downto 1) := "0000000000000001100";-- : Word address : 0x0000c; Byte Address : 0x00018
  constant C_Reg_cregsRegsNoRMW_test7 : std_logic_vector(19 downto 1) := "0000000000000001101";-- : Word address : 0x0000d; Byte Address : 0x0001a
  constant C_Reg_cregsRegsNoRMW_test8_1 : std_logic_vector(19 downto 1) := "0000000000000001110";-- : Word address : 0x0000e; Byte Address : 0x0001c
  constant C_Reg_cregsRegsNoRMW_test8_0 : std_logic_vector(19 downto 1) := "0000000000000001111";-- : Word address : 0x0000f; Byte Address : 0x0001e

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregsRegsNoRMW_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test2_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test2_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsRegsNoRMW_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregsRegsNoRMW_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test2_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test2_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegsNoRMW_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregsRegsNoRMW;
