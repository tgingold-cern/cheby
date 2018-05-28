library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_regs_small is

  -- Ident Code
  constant C_regs_small_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_regs_small_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map
  constant C_Reg_regs_small_test2 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Reg_regs_small_test3 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : "000" & X"0001"; Byte Address : X"0002"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_regs_small_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_small_test3 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"

  -- Register Preset Masks : Memory Map
  constant C_PSM_regs_small_test2 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_regs_small_test3 : std_logic_vector(7 downto 0) := "00000000";-- : Value : X"00"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_regs_small;
