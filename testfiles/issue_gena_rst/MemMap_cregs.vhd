library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregs is

  -- Ident Code
  constant C_cregs_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_cregs_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregs_test1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : "00" & X"0000"; Byte Address : X"0000"
  constant C_Reg_cregs_test2 : std_logic_vector(19 downto 2) := "000000000000000001";-- : Word address : "00" & X"0001"; Byte Address : X"0002"
  constant C_Reg_cregs_test3 : std_logic_vector(19 downto 2) := "000000000000000010";-- : Word address : "00" & X"0002"; Byte Address : X"0004"
  constant C_Reg_cregs_test4 : std_logic_vector(19 downto 2) := "000000000000000011";-- : Word address : "00" & X"0003"; Byte Address : X"0006"
  constant C_Reg_cregs_test5 : std_logic_vector(19 downto 2) := "000000000000000100";-- : Word address : "00" & X"0004"; Byte Address : X"0008"
  constant C_Reg_cregs_test6 : std_logic_vector(19 downto 2) := "000000000000000101";-- : Word address : "00" & X"0005"; Byte Address : X"000a"
  constant C_Reg_cregs_test7 : std_logic_vector(19 downto 2) := "000000000000000110";-- : Word address : "00" & X"0006"; Byte Address : X"000c"
  constant C_Reg_cregs_test8 : std_logic_vector(19 downto 2) := "000000000000000111";-- : Word address : "00" & X"0007"; Byte Address : X"000e"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregs_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregs_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_cregs_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_test4 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_test6 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_test7 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_test8 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregs_test1 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregs_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_cregs_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_test4 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_test6 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_test7 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_test8 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregs;
