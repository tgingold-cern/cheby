library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregs_library is

  -- Ident Code
  constant C_cregs_library_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_cregs_library_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregs_library_test1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_cregs_library_test3_1 : std_logic_vector(19 downto 2) := "000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00004
  constant C_Reg_cregs_library_test3_0 : std_logic_vector(19 downto 2) := "000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00008
  constant C_Reg_cregs_library_test5 : std_logic_vector(19 downto 2) := "000000000000000011";-- : Word address : 0x00003; Byte Address : 0x0000c
  constant C_Reg_cregs_library_test7 : std_logic_vector(19 downto 2) := "000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00010

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregs_library_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_library_test3_1 : std_logic_vector(63 downto 32) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_library_test3_0 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_library_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_library_test7 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregs_library_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_library_test3_1 : std_logic_vector(63 downto 32) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_library_test3_0 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_library_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_library_test7 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregs_library;
