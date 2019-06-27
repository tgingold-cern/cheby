library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregsNoRMW is

  -- Ident Code
  constant C_cregsNoRMW_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_cregsNoRMW_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregsNoRMW_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregsNoRMW_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_cregsNoRMW_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_cregsNoRMW_test3 : std_logic_vector(19 downto 1) := "0000000000000100000";-- : Word address : 0x00020; Byte Address : 0x00040
  constant C_Reg_cregsNoRMW_test4_1 : std_logic_vector(19 downto 1) := "0000000000000100001";-- : Word address : 0x00021; Byte Address : 0x00042
  constant C_Reg_cregsNoRMW_test4_0 : std_logic_vector(19 downto 1) := "0000000000000100010";-- : Word address : 0x00022; Byte Address : 0x00044
  constant C_Reg_cregsNoRMW_test5 : std_logic_vector(19 downto 1) := "0000000000000100011";-- : Word address : 0x00023; Byte Address : 0x00046
  constant C_Reg_cregsNoRMW_test6_1 : std_logic_vector(19 downto 1) := "0000000000000100100";-- : Word address : 0x00024; Byte Address : 0x00048
  constant C_Reg_cregsNoRMW_test6_0 : std_logic_vector(19 downto 1) := "0000000000000100101";-- : Word address : 0x00025; Byte Address : 0x0004a
  constant C_Reg_cregsNoRMW_test7 : std_logic_vector(19 downto 1) := "0000000000000100110";-- : Word address : 0x00026; Byte Address : 0x0004c
  constant C_Reg_cregsNoRMW_test8_1 : std_logic_vector(19 downto 1) := "0000000000000100111";-- : Word address : 0x00027; Byte Address : 0x0004e
  constant C_Reg_cregsNoRMW_test8_0 : std_logic_vector(19 downto 1) := "0000000000000101000";-- : Word address : 0x00028; Byte Address : 0x00050

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregsNoRMW_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsNoRMW_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregsNoRMW_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsNoRMW_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregsNoRMW;
