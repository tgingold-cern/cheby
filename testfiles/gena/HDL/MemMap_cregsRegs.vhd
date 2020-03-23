library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregsRegs is

  -- Ident Code
  constant C_cregsRegs_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_cregsRegs_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregsRegs_test1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregsRegs_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_cregsRegs_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_cregsRegs_test3 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_cregsRegs_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_cregsRegs_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a
  constant C_Reg_cregsRegs_test5 : std_logic_vector(19 downto 1) := "0000000000000000110";-- : Word address : 0x00006; Byte Address : 0x0000c
  constant C_Reg_cregsRegs_test6_1 : std_logic_vector(19 downto 1) := "0000000000000000111";-- : Word address : 0x00007; Byte Address : 0x0000e
  constant C_Reg_cregsRegs_test6_0 : std_logic_vector(19 downto 1) := "0000000000000001000";-- : Word address : 0x00008; Byte Address : 0x00010
  constant C_Reg_cregsRegs_test7 : std_logic_vector(19 downto 1) := "0000000000000001001";-- : Word address : 0x00009; Byte Address : 0x00012
  constant C_Reg_cregsRegs_test8_1 : std_logic_vector(19 downto 1) := "0000000000000001010";-- : Word address : 0x0000a; Byte Address : 0x00014
  constant C_Reg_cregsRegs_test8_0 : std_logic_vector(19 downto 1) := "0000000000000001011";-- : Word address : 0x0000b; Byte Address : 0x00016

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
  constant C_PSM_cregsRegs_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test5 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test6_1 : std_logic_vector(31 downto 16) := "1000001111000011";-- : Value : X"83c3"
  constant C_PSM_cregsRegs_test6_0 : std_logic_vector(15 downto 0) := "1100001111000001";-- : Value : X"c3c1"
  constant C_PSM_cregsRegs_test7 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregsRegs_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map

  -- ENUMERATIONS
  constant C_Code_test1_hello : std_logic_vector(7 downto 0) := "00000000";
  constant C_Code_test1_World : std_logic_vector(7 downto 0) := "00000001";
  constant C_Code_test2_msBit_hello : std_logic_vector(0 downto 0) := "0";
  constant C_Code_test2_msBit_world : std_logic_vector(0 downto 0) := "1";
  constant C_Code_test2_msReg_hello : std_logic_vector(3 downto 0) := "0000";
  constant C_Code_test2_msReg_world : std_logic_vector(3 downto 0) := "0001";
  constant C_Code_test4_msBit_hello : std_logic_vector(0 downto 0) := "0";
  constant C_Code_test4_msBit_world : std_logic_vector(0 downto 0) := "1";
  constant C_Code_test4_msReg_hello : std_logic_vector(3 downto 0) := "0000";
  constant C_Code_test4_msReg_world : std_logic_vector(3 downto 0) := "0001";
  constant C_Code_test6_msBit_hello : std_logic_vector(0 downto 0) := "0";
  constant C_Code_test6_msBit_world : std_logic_vector(0 downto 0) := "1";
  constant C_Code_test6_msReg_hello : std_logic_vector(3 downto 0) := "0000";
  constant C_Code_test6_msReg_world : std_logic_vector(3 downto 0) := "0001";
  constant C_Code_test8_msBit_hello : std_logic_vector(0 downto 0) := "0";
  constant C_Code_test8_msBit_world : std_logic_vector(0 downto 0) := "1";
  constant C_Code_test8_msReg_hello : std_logic_vector(3 downto 0) := "0000";
  constant C_Code_test8_msReg_world : std_logic_vector(3 downto 0) := "0001";
end MemMap_cregsRegs;
