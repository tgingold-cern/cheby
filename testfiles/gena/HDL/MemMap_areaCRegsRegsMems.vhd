library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_areaCRegsRegsMems is

  -- Ident Code
  constant C_areaCRegsRegsMems_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_areaCRegsRegsMems_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  constant C_Area_areaCRegsRegsMems_area : std_logic_vector(19 downto 19) := "1";
  -- Register Addresses : Area area
  constant C_Reg_areaCRegsRegsMems_area_test1_1 : std_logic_vector(18 downto 1) := "000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_areaCRegsRegsMems_area_test1_0 : std_logic_vector(18 downto 1) := "000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_areaCRegsRegsMems_area_test2_3 : std_logic_vector(18 downto 1) := "000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_areaCRegsRegsMems_area_test2_2 : std_logic_vector(18 downto 1) := "000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_areaCRegsRegsMems_area_test2_1 : std_logic_vector(18 downto 1) := "000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_areaCRegsRegsMems_area_test2_0 : std_logic_vector(18 downto 1) := "000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a
  constant C_Reg_areaCRegsRegsMems_area_test3_1 : std_logic_vector(18 downto 1) := "000000000000000110";-- : Word address : 0x00006; Byte Address : 0x0000c
  constant C_Reg_areaCRegsRegsMems_area_test3_0 : std_logic_vector(18 downto 1) := "000000000000000111";-- : Word address : 0x00007; Byte Address : 0x0000e
  constant C_Reg_areaCRegsRegsMems_area_test4_3 : std_logic_vector(18 downto 1) := "000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00010
  constant C_Reg_areaCRegsRegsMems_area_test4_2 : std_logic_vector(18 downto 1) := "000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00012
  constant C_Reg_areaCRegsRegsMems_area_test4_1 : std_logic_vector(18 downto 1) := "000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x00014
  constant C_Reg_areaCRegsRegsMems_area_test4_0 : std_logic_vector(18 downto 1) := "000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x00016
  constant C_Reg_areaCRegsRegsMems_area_test5_1 : std_logic_vector(18 downto 1) := "000000000000001100";-- : Word address : 0x0000c; Byte Address : 0x00018
  constant C_Reg_areaCRegsRegsMems_area_test5_0 : std_logic_vector(18 downto 1) := "000000000000001101";-- : Word address : 0x0000d; Byte Address : 0x0001a
  constant C_Reg_areaCRegsRegsMems_area_test6_3 : std_logic_vector(18 downto 1) := "000000000000001110";-- : Word address : 0x0000e; Byte Address : 0x0001c
  constant C_Reg_areaCRegsRegsMems_area_test6_2 : std_logic_vector(18 downto 1) := "000000000000001111";-- : Word address : 0x0000f; Byte Address : 0x0001e
  constant C_Reg_areaCRegsRegsMems_area_test6_1 : std_logic_vector(18 downto 1) := "000000000000010000";-- : Word address : 0x00010; Byte Address : 0x00020
  constant C_Reg_areaCRegsRegsMems_area_test6_0 : std_logic_vector(18 downto 1) := "000000000000010001";-- : Word address : 0x00011; Byte Address : 0x00022
  constant C_Reg_areaCRegsRegsMems_area_test7_3 : std_logic_vector(18 downto 1) := "000000000001000000";-- : Word address : 0x00040; Byte Address : 0x00080
  constant C_Reg_areaCRegsRegsMems_area_test7_2 : std_logic_vector(18 downto 1) := "000000000001000001";-- : Word address : 0x00041; Byte Address : 0x00082
  constant C_Reg_areaCRegsRegsMems_area_test7_1 : std_logic_vector(18 downto 1) := "000000000001000010";-- : Word address : 0x00042; Byte Address : 0x00084
  constant C_Reg_areaCRegsRegsMems_area_test7_0 : std_logic_vector(18 downto 1) := "000000000001000011";-- : Word address : 0x00043; Byte Address : 0x00086
  constant C_Reg_areaCRegsRegsMems_area_test8_3 : std_logic_vector(18 downto 1) := "000000000001000100";-- : Word address : 0x00044; Byte Address : 0x00088
  constant C_Reg_areaCRegsRegsMems_area_test8_2 : std_logic_vector(18 downto 1) := "000000000001000101";-- : Word address : 0x00045; Byte Address : 0x0008a
  constant C_Reg_areaCRegsRegsMems_area_test8_1 : std_logic_vector(18 downto 1) := "000000000001000110";-- : Word address : 0x00046; Byte Address : 0x0008c
  constant C_Reg_areaCRegsRegsMems_area_test8_0 : std_logic_vector(18 downto 1) := "000000000001000111";-- : Word address : 0x00047; Byte Address : 0x0008e

  -- Register Auto Clear Masks : Area area
  constant C_ACM_areaCRegsRegsMems_area_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_area_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test7_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test7_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_area_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area
  constant C_PSM_areaCRegsRegsMems_area_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_area_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test7_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test7_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_area_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Area area
  constant C_Mem_areaCRegsRegsMems_area_mem1_Sta : std_logic_vector(18 downto 1) := "000000001000000000";-- : Word address : 0x00200; Byte Address : 0x00400
  constant C_Mem_areaCRegsRegsMems_area_mem1_End : std_logic_vector(18 downto 1) := "000000001111111111";-- : Word address : 0x003ff; Byte Address : 0x007fe
  constant C_Mem_areaCRegsRegsMems_area_mem2_Sta : std_logic_vector(18 downto 1) := "000000010000000000";-- : Word address : 0x00400; Byte Address : 0x00800
  constant C_Mem_areaCRegsRegsMems_area_mem2_End : std_logic_vector(18 downto 1) := "000000010111111111";-- : Word address : 0x005ff; Byte Address : 0x00bfe
  -- Submap Addresses : Area area
  -- Register Addresses : Memory Map
  constant C_Reg_areaCRegsRegsMems_test1_1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_areaCRegsRegsMems_test1_0 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_areaCRegsRegsMems_test2_3 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_areaCRegsRegsMems_test2_2 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_areaCRegsRegsMems_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_areaCRegsRegsMems_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a
  constant C_Reg_areaCRegsRegsMems_test3_1 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : 0x00006; Byte Address : 0x0000c
  constant C_Reg_areaCRegsRegsMems_test3_0 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : 0x00007; Byte Address : 0x0000e
  constant C_Reg_areaCRegsRegsMems_test4_3 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00010
  constant C_Reg_areaCRegsRegsMems_test4_2 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00012
  constant C_Reg_areaCRegsRegsMems_test4_1 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x00014
  constant C_Reg_areaCRegsRegsMems_test4_0 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x00016
  constant C_Reg_areaCRegsRegsMems_test5_1 : std_logic_vector(19 downto 1) := "0000000000000001100";-- : Word address : 0x0000c; Byte Address : 0x00018
  constant C_Reg_areaCRegsRegsMems_test5_0 : std_logic_vector(19 downto 1) := "0000000000000001101";-- : Word address : 0x0000d; Byte Address : 0x0001a
  constant C_Reg_areaCRegsRegsMems_test6_3 : std_logic_vector(19 downto 1) := "0000000000000001110";-- : Word address : 0x0000e; Byte Address : 0x0001c
  constant C_Reg_areaCRegsRegsMems_test6_2 : std_logic_vector(19 downto 1) := "0000000000000001111";-- : Word address : 0x0000f; Byte Address : 0x0001e
  constant C_Reg_areaCRegsRegsMems_test6_1 : std_logic_vector(19 downto 1) := "0000000000000010000";-- : Word address : 0x00010; Byte Address : 0x00020
  constant C_Reg_areaCRegsRegsMems_test6_0 : std_logic_vector(19 downto 1) := "0000000000000010001";-- : Word address : 0x00011; Byte Address : 0x00022
  constant C_Reg_areaCRegsRegsMems_test7_1 : std_logic_vector(19 downto 1) := "0000000000001000000";-- : Word address : 0x00040; Byte Address : 0x00080
  constant C_Reg_areaCRegsRegsMems_test7_0 : std_logic_vector(19 downto 1) := "0000000000001000001";-- : Word address : 0x00041; Byte Address : 0x00082
  constant C_Reg_areaCRegsRegsMems_test8_3 : std_logic_vector(19 downto 1) := "0000000000001000010";-- : Word address : 0x00042; Byte Address : 0x00084
  constant C_Reg_areaCRegsRegsMems_test8_2 : std_logic_vector(19 downto 1) := "0000000000001000011";-- : Word address : 0x00043; Byte Address : 0x00086
  constant C_Reg_areaCRegsRegsMems_test8_1 : std_logic_vector(19 downto 1) := "0000000000001000100";-- : Word address : 0x00044; Byte Address : 0x00088
  constant C_Reg_areaCRegsRegsMems_test8_0 : std_logic_vector(19 downto 1) := "0000000000001000101";-- : Word address : 0x00045; Byte Address : 0x0008a

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_areaCRegsRegsMems_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMems_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMems_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_areaCRegsRegsMems_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMems_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMems_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_areaCRegsRegsMems_mem1_Sta : std_logic_vector(19 downto 1) := "0000000001000000000";-- : Word address : 0x00200; Byte Address : 0x00400
  constant C_Mem_areaCRegsRegsMems_mem1_End : std_logic_vector(19 downto 1) := "0000000001111111111";-- : Word address : 0x003ff; Byte Address : 0x007fe
  constant C_Mem_areaCRegsRegsMems_mem2_Sta : std_logic_vector(19 downto 1) := "0000000010000000000";-- : Word address : 0x00400; Byte Address : 0x00800
  constant C_Mem_areaCRegsRegsMems_mem2_End : std_logic_vector(19 downto 1) := "0000000010111111111";-- : Word address : 0x005ff; Byte Address : 0x00bfe
  -- Submap Addresses : Memory Map
end MemMap_areaCRegsRegsMems;
