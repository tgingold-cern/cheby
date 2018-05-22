library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_cregs_resize_nosplit is

  -- Ident Code
  constant C_cregs_resize_nosplit_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_cregs_resize_nosplit_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  -- Register Addresses : Memory Map
  constant C_Reg_cregs_resize_nosplit_test1 : std_logic_vector(19 downto 2) := "000000000000000000";-- : Word address : "00" & X"0000"; Byte Address : X"0000"
  constant C_Reg_cregs_resize_nosplit_test3 : std_logic_vector(19 downto 2) := "000000000000000001";-- : Word address : "00" & X"0001"; Byte Address : X"0002"
  constant C_Reg_cregs_resize_nosplit_test5 : std_logic_vector(19 downto 2) := "000000000000000010";-- : Word address : "00" & X"0002"; Byte Address : X"0004"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_cregs_resize_nosplit_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_resize_nosplit_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_ACM_cregs_resize_nosplit_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_cregs_resize_nosplit_test1 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_resize_nosplit_test3 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"
  constant C_PSM_cregs_resize_nosplit_test5 : std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_cregs_resize_nosplit;
