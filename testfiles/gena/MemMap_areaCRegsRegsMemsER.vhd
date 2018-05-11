library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_areaCRegsRegsMemsER is

  -- Ident Code
  constant C_areaCRegsRegsMemsER_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_areaCRegsRegsMemsER_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  constant C_Area_areaCRegsRegsMemsER_area : std_logic_vector(19 downto 19) := "0";
  -- Register Addresses : Area area
  constant C_Reg_areaCRegsRegsMemsER_area_test1_1 : std_logic_vector(18 downto 1) := "000000000000000000";-- : Word address : "00" & X"0000"; Byte Address : X"0000"
  constant C_Reg_areaCRegsRegsMemsER_area_test1_0 : std_logic_vector(18 downto 1) := "000000000000000001";-- : Word address : "00" & X"0001"; Byte Address : X"0002"
  constant C_Reg_areaCRegsRegsMemsER_area_test2_3 : std_logic_vector(18 downto 1) := "000000000000000010";-- : Word address : "00" & X"0002"; Byte Address : X"0004"
  constant C_Reg_areaCRegsRegsMemsER_area_test2_2 : std_logic_vector(18 downto 1) := "000000000000000011";-- : Word address : "00" & X"0003"; Byte Address : X"0006"
  constant C_Reg_areaCRegsRegsMemsER_area_test2_1 : std_logic_vector(18 downto 1) := "000000000000000100";-- : Word address : "00" & X"0004"; Byte Address : X"0008"
  constant C_Reg_areaCRegsRegsMemsER_area_test2_0 : std_logic_vector(18 downto 1) := "000000000000000101";-- : Word address : "00" & X"0005"; Byte Address : X"000a"
  constant C_Reg_areaCRegsRegsMemsER_area_test3_1 : std_logic_vector(18 downto 1) := "000000000000000110";-- : Word address : "00" & X"0006"; Byte Address : X"000c"
  constant C_Reg_areaCRegsRegsMemsER_area_test3_0 : std_logic_vector(18 downto 1) := "000000000000000111";-- : Word address : "00" & X"0007"; Byte Address : X"000e"
  constant C_Reg_areaCRegsRegsMemsER_area_test4_3 : std_logic_vector(18 downto 1) := "000000000000001000";-- : Word address : "00" & X"0008"; Byte Address : X"0010"
  constant C_Reg_areaCRegsRegsMemsER_area_test4_2 : std_logic_vector(18 downto 1) := "000000000000001001";-- : Word address : "00" & X"0009"; Byte Address : X"0012"
  constant C_Reg_areaCRegsRegsMemsER_area_test4_1 : std_logic_vector(18 downto 1) := "000000000000001010";-- : Word address : "00" & X"000a"; Byte Address : X"0014"
  constant C_Reg_areaCRegsRegsMemsER_area_test4_0 : std_logic_vector(18 downto 1) := "000000000000001011";-- : Word address : "00" & X"000b"; Byte Address : X"0016"
  constant C_Reg_areaCRegsRegsMemsER_area_test5_1 : std_logic_vector(18 downto 1) := "000000000000001100";-- : Word address : "00" & X"000c"; Byte Address : X"0018"
  constant C_Reg_areaCRegsRegsMemsER_area_test5_0 : std_logic_vector(18 downto 1) := "000000000000001101";-- : Word address : "00" & X"000d"; Byte Address : X"001a"
  constant C_Reg_areaCRegsRegsMemsER_area_test6_3 : std_logic_vector(18 downto 1) := "000000000000001110";-- : Word address : "00" & X"000e"; Byte Address : X"001c"
  constant C_Reg_areaCRegsRegsMemsER_area_test6_2 : std_logic_vector(18 downto 1) := "000000000000001111";-- : Word address : "00" & X"000f"; Byte Address : X"001e"
  constant C_Reg_areaCRegsRegsMemsER_area_test6_1 : std_logic_vector(18 downto 1) := "000000000000010000";-- : Word address : "00" & X"0010"; Byte Address : X"0020"
  constant C_Reg_areaCRegsRegsMemsER_area_test6_0 : std_logic_vector(18 downto 1) := "000000000000010001";-- : Word address : "00" & X"0011"; Byte Address : X"0022"
  constant C_Reg_areaCRegsRegsMemsER_area_test7_3 : std_logic_vector(18 downto 1) := "000000000001000000";-- : Word address : "00" & X"0040"; Byte Address : X"0080"
  constant C_Reg_areaCRegsRegsMemsER_area_test7_2 : std_logic_vector(18 downto 1) := "000000000001000001";-- : Word address : "00" & X"0041"; Byte Address : X"0082"
  constant C_Reg_areaCRegsRegsMemsER_area_test7_1 : std_logic_vector(18 downto 1) := "000000000001000010";-- : Word address : "00" & X"0042"; Byte Address : X"0084"
  constant C_Reg_areaCRegsRegsMemsER_area_test7_0 : std_logic_vector(18 downto 1) := "000000000001000011";-- : Word address : "00" & X"0043"; Byte Address : X"0086"
  constant C_Reg_areaCRegsRegsMemsER_area_test8_3 : std_logic_vector(18 downto 1) := "000000000001000100";-- : Word address : "00" & X"0044"; Byte Address : X"0088"
  constant C_Reg_areaCRegsRegsMemsER_area_test8_2 : std_logic_vector(18 downto 1) := "000000000001000101";-- : Word address : "00" & X"0045"; Byte Address : X"008a"
  constant C_Reg_areaCRegsRegsMemsER_area_test8_1 : std_logic_vector(18 downto 1) := "000000000001000110";-- : Word address : "00" & X"0046"; Byte Address : X"008c"
  constant C_Reg_areaCRegsRegsMemsER_area_test8_0 : std_logic_vector(18 downto 1) := "000000000001000111";-- : Word address : "00" & X"0047"; Byte Address : X"008e"

  -- Register Auto Clear Masks : Area area
  constant C_ACM_areaCRegsRegsMemsER_area_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_ACM_areaCRegsRegsMemsER_area_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test7_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test7_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegsRegsMemsER_area_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area
  constant C_PSM_areaCRegsRegsMemsER_area_test1_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test1_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test2_3 : std_logic_vector(31 downto 24) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test2_2 : std_logic_vector(23 downto 16) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test2_1 : std_logic_vector(15 downto 8) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test2_0 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"
  constant C_PSM_areaCRegsRegsMemsER_area_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test5_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test5_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test6_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test6_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test6_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test6_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test7_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test7_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test7_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test7_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test8_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test8_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test8_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegsRegsMemsER_area_test8_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Area area
  constant C_Mem_areaCRegsRegsMemsER_area_mem1_Sta : std_logic_vector(18 downto 1) := "000000001000000000";-- : Word address : "00" & X"0200"; Byte Address : X"0400"
  constant C_Mem_areaCRegsRegsMemsER_area_mem1_End : std_logic_vector(18 downto 1) := "000000001111111111";-- : Word address : "00" & X"03ff"; Byte Address : X"07fe"
  constant C_Mem_areaCRegsRegsMemsER_area_mem2_Sta : std_logic_vector(18 downto 1) := "000000010000000000";-- : Word address : "00" & X"0400"; Byte Address : X"0800"
  constant C_Mem_areaCRegsRegsMemsER_area_mem2_End : std_logic_vector(18 downto 1) := "000000010111111111";-- : Word address : "00" & X"05ff"; Byte Address : X"0bfe"
  -- Submap Addresses : Area area
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_areaCRegsRegsMemsER;
