library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_muxed2 is

  -- Ident Code
  constant C_muxed2_IdentCode : std_logic_vector(15 downto 0) := X"0000";

  -- Memory Map Version
  constant C_muxed2_MemMapVersion : std_logic_vector(31 downto 0) := X"0133EE21";--20180513
  -- Register Addresses : Memory Map
  constant C_Reg_muxed2_muxedRegRO_1 : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Reg_muxed2_muxedRegRO_0 : std_logic_vector(19 downto 1) := "0000000000000000001";-- : Word address : 0x00001; Byte Address : 0x00002
  constant C_Reg_muxed2_muxedRegRW_1 : std_logic_vector(19 downto 1) := "0000000000000000010";-- : Word address : 0x00002; Byte Address : 0x00004
  constant C_Reg_muxed2_muxedRegRW_0 : std_logic_vector(19 downto 1) := "0000000000000000011";-- : Word address : 0x00003; Byte Address : 0x00006
  constant C_Reg_muxed2_regSel : std_logic_vector(19 downto 1) := "0000000000000000100";-- : Word address : 0x00004; Byte Address : 0x00008

  -- Register Auto Clear Masks : Memory Map
  constant C_ACM_muxed2_muxedRegRO_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed2_muxedRegRO_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed2_muxedRegRW_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed2_muxedRegRW_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_ACM_muxed2_regSel : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- Register Preset Masks : Memory Map
  constant C_PSM_muxed2_muxedRegRO_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed2_muxedRegRO_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed2_muxedRegRW_1 : std_logic_vector(31 downto 16) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed2_muxedRegRW_0 : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"
  constant C_PSM_muxed2_regSel : std_logic_vector(15 downto 0) := "0000000000000000";-- : Value : X"0000"

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_muxed2_Mem_Sta : std_logic_vector(19 downto 1) := "1000000000000000000";-- : Word address : 0x40000; Byte Address : 0x80000
  constant C_Mem_muxed2_Mem_End : std_logic_vector(19 downto 1) := "1111111111111111111";-- : Word address : 0x7ffff; Byte Address : 0xffffe
  -- Submap Addresses : Memory Map
end MemMap_muxed2;
