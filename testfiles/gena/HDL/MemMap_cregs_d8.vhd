library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregs_d8 is

  -- Ident Code
  constant C_cregs_d8_IdentCode : std_logic_vector(7 downto 0) := X"FF";

  -- Memory Map Version
  constant C_cregs_d8_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregs_d8_test1_3 : std_logic_vector(19 downto 0) := "00000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregs_d8_test1_2 : std_logic_vector(19 downto 0) := "00000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00001
  constant C_Reg_cregs_d8_test1_1 : std_logic_vector(19 downto 0) := "00000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00002
  constant C_Reg_cregs_d8_test1_0 : std_logic_vector(19 downto 0) := "00000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00003
  constant C_Reg_cregs_d8_test2_3 : std_logic_vector(19 downto 0) := "00000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00004
  constant C_Reg_cregs_d8_test2_2 : std_logic_vector(19 downto 0) := "00000000000000000101";-- : Word address : 0x00005; Byte Address : 0x00005
  constant C_Reg_cregs_d8_test2_1 : std_logic_vector(19 downto 0) := "00000000000000000110";-- : Word address : 0x00006; Byte Address : 0x00006
  constant C_Reg_cregs_d8_test2_0 : std_logic_vector(19 downto 0) := "00000000000000000111";-- : Word address : 0x00007; Byte Address : 0x00007
  constant C_Reg_cregs_d8_test3_3 : std_logic_vector(19 downto 0) := "00000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00008
  constant C_Reg_cregs_d8_test3_2 : std_logic_vector(19 downto 0) := "00000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00009
  constant C_Reg_cregs_d8_test3_1 : std_logic_vector(19 downto 0) := "00000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x0000a
  constant C_Reg_cregs_d8_test3_0 : std_logic_vector(19 downto 0) := "00000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x0000b
  constant C_Reg_cregs_d8_test4_3 : std_logic_vector(19 downto 0) := "00000000000000001100";-- : Word address : 0x0000c; Byte Address : 0x0000c
  constant C_Reg_cregs_d8_test4_2 : std_logic_vector(19 downto 0) := "00000000000000001101";-- : Word address : 0x0000d; Byte Address : 0x0000d
  constant C_Reg_cregs_d8_test4_1 : std_logic_vector(19 downto 0) := "00000000000000001110";-- : Word address : 0x0000e; Byte Address : 0x0000e
  constant C_Reg_cregs_d8_test4_0 : std_logic_vector(19 downto 0) := "00000000000000001111";-- : Word address : 0x0000f; Byte Address : 0x0000f
  constant C_Reg_cregs_d8_test5_3 : std_logic_vector(19 downto 0) := "00000000000000010000";-- : Word address : 0x00010; Byte Address : 0x00010
  constant C_Reg_cregs_d8_test5_2 : std_logic_vector(19 downto 0) := "00000000000000010001";-- : Word address : 0x00011; Byte Address : 0x00011
  constant C_Reg_cregs_d8_test5_1 : std_logic_vector(19 downto 0) := "00000000000000010010";-- : Word address : 0x00012; Byte Address : 0x00012
  constant C_Reg_cregs_d8_test5_0 : std_logic_vector(19 downto 0) := "00000000000000010011";-- : Word address : 0x00013; Byte Address : 0x00013
  constant C_Reg_cregs_d8_test6_3 : std_logic_vector(19 downto 0) := "00000000000000010100";-- : Word address : 0x00014; Byte Address : 0x00014
  constant C_Reg_cregs_d8_test6_2 : std_logic_vector(19 downto 0) := "00000000000000010101";-- : Word address : 0x00015; Byte Address : 0x00015
  constant C_Reg_cregs_d8_test6_1 : std_logic_vector(19 downto 0) := "00000000000000010110";-- : Word address : 0x00016; Byte Address : 0x00016
  constant C_Reg_cregs_d8_test6_0 : std_logic_vector(19 downto 0) := "00000000000000010111";-- : Word address : 0x00017; Byte Address : 0x00017
  constant C_Reg_cregs_d8_test7_3 : std_logic_vector(19 downto 0) := "00000000000000011000";-- : Word address : 0x00018; Byte Address : 0x00018
  constant C_Reg_cregs_d8_test7_2 : std_logic_vector(19 downto 0) := "00000000000000011001";-- : Word address : 0x00019; Byte Address : 0x00019
  constant C_Reg_cregs_d8_test7_1 : std_logic_vector(19 downto 0) := "00000000000000011010";-- : Word address : 0x0001a; Byte Address : 0x0001a
  constant C_Reg_cregs_d8_test7_0 : std_logic_vector(19 downto 0) := "00000000000000011011";-- : Word address : 0x0001b; Byte Address : 0x0001b
  constant C_Reg_cregs_d8_test8_3 : std_logic_vector(19 downto 0) := "00000000000000011100";-- : Word address : 0x0001c; Byte Address : 0x0001c
  constant C_Reg_cregs_d8_test8_2 : std_logic_vector(19 downto 0) := "00000000000000011101";-- : Word address : 0x0001d; Byte Address : 0x0001d
  constant C_Reg_cregs_d8_test8_1 : std_logic_vector(19 downto 0) := "00000000000000011110";-- : Word address : 0x0001e; Byte Address : 0x0001e
  constant C_Reg_cregs_d8_test8_0 : std_logic_vector(19 downto 0) := "00000000000000011111";-- : Word address : 0x0001f; Byte Address : 0x0001f

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregs_d8_test1_3 : std_logic_vector(15 downto 12) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test1_2 : std_logic_vector(11 downto 8) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test1_1 : std_logic_vector(7 downto 4) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test1_0 : std_logic_vector(3 downto 0) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test2_3 : std_logic_vector(15 downto 12) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test2_2 : std_logic_vector(11 downto 8) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test2_1 : std_logic_vector(7 downto 4) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test2_0 : std_logic_vector(3 downto 0) := "0000";-- : Value : X"0"
  constant C_ACM_cregs_d8_test3_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test3_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test3_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test3_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test4_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test4_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test4_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test4_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test5_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test5_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test5_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test5_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test6_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test6_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test6_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test6_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test7_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test7_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test7_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test7_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test8_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test8_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test8_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_cregs_d8_test8_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregs_d8_test1_3 : std_logic_vector(15 downto 12) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test1_2 : std_logic_vector(11 downto 8) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test1_1 : std_logic_vector(7 downto 4) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test1_0 : std_logic_vector(3 downto 0) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test2_3 : std_logic_vector(15 downto 12) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test2_2 : std_logic_vector(11 downto 8) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test2_1 : std_logic_vector(7 downto 4) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test2_0 : std_logic_vector(3 downto 0) := "0000";-- : Value : X"0"
  constant C_PSM_cregs_d8_test3_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test3_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test3_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test3_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test4_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test4_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test4_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test4_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test5_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test5_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test5_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test5_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test6_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test6_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test6_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test6_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test7_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test7_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test7_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test7_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test8_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test8_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test8_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_cregs_d8_test8_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregs_d8;
