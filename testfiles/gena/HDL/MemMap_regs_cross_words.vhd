library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_regs_cross_words is

  -- Ident Code
  constant C_regs_cross_words_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_regs_cross_words_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map
  constant C_Reg_regs_cross_words_test2_1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Reg_regs_cross_words_test2_0 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : "000" & X"0001"; Byte Address : X"0002"
  constant C_Reg_regs_cross_words_test3_1 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : "000" & X"0002"; Byte Address : X"0004"
  constant C_Reg_regs_cross_words_test3_0 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : "000" & X"0003"; Byte Address : X"0006"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_regs_cross_words_test2_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_cross_words_test2_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_cross_words_test3_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_regs_cross_words_test3_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_regs_cross_words_test2_1 : std_logic_vector(31 downto 16) := "1010101111001101";-- : Value : X"abcd"
  constant C_PSM_regs_cross_words_test2_0 : std_logic_vector(15 downto 0) := "0001001000110100";-- : Value : X"1234"
  constant C_PSM_regs_cross_words_test3_1 : std_logic_vector(31 downto 16) := "1010101111001101";-- : Value : X"abcd"
  constant C_PSM_regs_cross_words_test3_0 : std_logic_vector(15 downto 0) := "0001001000110100";-- : Value : X"1234"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_regs_cross_words;
