library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_muxed is

  -- Ident Code
  constant C_muxed_IdentCode : std_logic_vector(15 downto 0) := X"0000";

  -- Memory Map Version
  constant C_muxed_MemMapVersion : std_logic_vector(31 downto 0) := X"0133EE21";--20180513
  -- Register Addresses : Memory Map
  constant C_Reg_muxed_muxedRegRO_1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : "000" & X"0000"; Byte Address : X"0000"
  constant C_Reg_muxed_muxedRegRO_0 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : "000" & X"0001"; Byte Address : X"0002"
  constant C_Reg_muxed_muxedRegRW_1 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : "000" & X"0002"; Byte Address : X"0004"
  constant C_Reg_muxed_muxedRegRW_0 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : "000" & X"0003"; Byte Address : X"0006"
  constant C_Reg_muxed_regSel : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : "000" & X"0004"; Byte Address : X"0008"

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_muxed_muxedRegRO_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed_muxedRegRO_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed_muxedRegRW_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed_muxedRegRW_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed_regSel : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_muxed_muxedRegRO_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed_muxedRegRO_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed_muxedRegRW_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed_muxedRegRW_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed_regSel : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_muxed_Mem_Sta : std_logic_vector(19 downto 1) := "1000000000000000000";-- : Word address : "100" & X"40000"; Byte Address : X"0000"
  constant C_Mem_muxed_Mem_End : std_logic_vector(19 downto 1) := "1111111111111111111";-- : Word address : "111" & X"7ffff"; Byte Address : X"7fffe"
  -- Submap Addresses : Memory Map
end MemMap_muxed;
