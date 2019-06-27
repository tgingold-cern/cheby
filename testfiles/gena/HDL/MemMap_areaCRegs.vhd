library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_areaCRegs is

  -- Ident Code
  constant C_areaCRegs_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_areaCRegs_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  constant C_Area_areaCRegs_area1 : std_logic_vector(19 downto 10) := "0000000001";
  constant C_Area_areaCRegs_area2 : std_logic_vector(19 downto 10) := "0000000010";
  -- Register Addresses : Area area1
  constant C_Reg_areaCRegs_area1_test1_1 : std_logic_vector(9 downto 1) := "000000000";-- : Word address : 0x000; Byte Address : 0x000
  constant C_Reg_areaCRegs_area1_test1_0 : std_logic_vector(9 downto 1) := "000000001";-- : Word address : 0x001; Byte Address : 0x002
  constant C_Reg_areaCRegs_area1_test2_3 : std_logic_vector(9 downto 1) := "000000010";-- : Word address : 0x002; Byte Address : 0x004
  constant C_Reg_areaCRegs_area1_test2_2 : std_logic_vector(9 downto 1) := "000000011";-- : Word address : 0x003; Byte Address : 0x006
  constant C_Reg_areaCRegs_area1_test2_1 : std_logic_vector(9 downto 1) := "000000100";-- : Word address : 0x004; Byte Address : 0x008
  constant C_Reg_areaCRegs_area1_test2_0 : std_logic_vector(9 downto 1) := "000000101";-- : Word address : 0x005; Byte Address : 0x00a

  -- Register Auto Clear Masks : Area area1
  constant C_ACM_areaCRegs_area1_test1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area1_test1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area1_test2_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area1_test2_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area1_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area1_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area1
  constant C_PSM_areaCRegs_area1_test1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area1_test1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area1_test2_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area1_test2_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area1_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area1_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Area area1
  -- Submap Addresses : Area area1
  -- Register Addresses : Area area2
  constant C_Reg_areaCRegs_area2_test1_1 : std_logic_vector(9 downto 1) := "000000000";-- : Word address : 0x000; Byte Address : 0x000
  constant C_Reg_areaCRegs_area2_test1_0 : std_logic_vector(9 downto 1) := "000000001";-- : Word address : 0x001; Byte Address : 0x002
  constant C_Reg_areaCRegs_area2_test3_3 : std_logic_vector(9 downto 1) := "000000010";-- : Word address : 0x002; Byte Address : 0x004
  constant C_Reg_areaCRegs_area2_test3_2 : std_logic_vector(9 downto 1) := "000000011";-- : Word address : 0x003; Byte Address : 0x006
  constant C_Reg_areaCRegs_area2_test3_1 : std_logic_vector(9 downto 1) := "000000100";-- : Word address : 0x004; Byte Address : 0x008
  constant C_Reg_areaCRegs_area2_test3_0 : std_logic_vector(9 downto 1) := "000000101";-- : Word address : 0x005; Byte Address : 0x00a

  -- Register Auto Clear Masks : Area area2
  constant C_ACM_areaCRegs_area2_test1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area2_test1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area2_test3_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area2_test3_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area2_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_area2_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Area area2
  constant C_PSM_areaCRegs_area2_test1_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area2_test1_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area2_test3_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area2_test3_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area2_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_area2_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Area area2
  -- Submap Addresses : Area area2
  -- Register Addresses : Memory Map
  constant C_Reg_areaCRegs_test3_1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_areaCRegs_test3_0 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_areaCRegs_test4_3 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_areaCRegs_test4_2 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_areaCRegs_test4_1 : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008
  constant C_Reg_areaCRegs_test4_0 : std_logic_vector(19 downto 1) := "0000000000000000101";-- : Word address : 0x00005; Byte Address : 0x0000a

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_areaCRegs_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_areaCRegs_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_areaCRegs_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_test4_3 : std_logic_vector(63 downto 48) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_test4_2 : std_logic_vector(47 downto 32) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_test4_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_areaCRegs_test4_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_areaCRegs;
