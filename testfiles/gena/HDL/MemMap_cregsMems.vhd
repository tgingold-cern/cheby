library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregsMems is

  -- Ident Code
  constant C_cregsMems_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_cregsMems_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregsMems_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregsMems_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_cregsMems_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_cregsMems_test3 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_cregsMems_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_cregsMems_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a
  constant C_Reg_cregsMems_test5 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : 0x00006; Byte Address : 0x0000c
  constant C_Reg_cregsMems_test6_1 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : 0x00007; Byte Address : 0x0000e
  constant C_Reg_cregsMems_test6_0 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00010
  constant C_Reg_cregsMems_test7 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00012
  constant C_Reg_cregsMems_test8_1 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x00014
  constant C_Reg_cregsMems_test8_0 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x00016

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregsMems_test1 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregsMems_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregsMems_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregsMems_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregsMems_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregsMems_test1 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregsMems_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregsMems_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregsMems_test3 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsMems_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_cregsMems_mem1_Sta : std_logic_vector(19 downto 1) := "0000000001000000000";-- : Word address : 0x00200; Byte Address : 0x00400
  constant C_Mem_cregsMems_mem1_End : std_logic_vector(19 downto 1) := "0000000001111111111";-- : Word address : 0x003ff; Byte Address : 0x007fe
  constant C_Mem_cregsMems_mem2_Sta : std_logic_vector(19 downto 1) := "0000000010000000000";-- : Word address : 0x00400; Byte Address : 0x00800
  constant C_Mem_cregsMems_mem2_End : std_logic_vector(19 downto 1) := "0000000010111111111";-- : Word address : 0x005ff; Byte Address : 0x00bfe
  -- Submap Addresses : Memory Map
end MemMap_cregsMems;
