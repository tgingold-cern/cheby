library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_areaMems is

  -- Ident Code
  constant C_areaMems_IdentCode : std_logic_vector(31 downto 0) := X"000000FF";

  -- Memory Map Version
  constant C_areaMems_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A207";--20161031
  constant C_Area_areaMems_area : std_logic_vector(19 downto 19) := "0";
  -- Register Addresses : Area area

  -- Register Auto Clear Masks : Area area

  -- Register Preset Masks : Area area

  -- CODE FIELDS
  -- Memory Data : Area area
  constant C_Mem_areaMems_area_mem1_Sta : std_logic_vector(18 downto 2) := "00000000000000000";-- : Word address : "0" & X"0000"; Byte Address : X"0000"
  constant C_Mem_areaMems_area_mem1_End : std_logic_vector(18 downto 2) := "00000000011111111";-- : Word address : "0" & X"00ff"; Byte Address : X"01fe"
  constant C_Mem_areaMems_area_mem2_Sta : std_logic_vector(18 downto 2) := "00000000100000000";-- : Word address : "0" & X"0100"; Byte Address : X"0200"
  constant C_Mem_areaMems_area_mem2_End : std_logic_vector(18 downto 2) := "00000000111111111";-- : Word address : "0" & X"01ff"; Byte Address : X"03fe"
  constant C_Mem_areaMems_area_mem3_Sta : std_logic_vector(18 downto 2) := "00000001000000000";-- : Word address : "0" & X"0200"; Byte Address : X"0400"
  constant C_Mem_areaMems_area_mem3_End : std_logic_vector(18 downto 2) := "00000001011111111";-- : Word address : "0" & X"02ff"; Byte Address : X"05fe"
  -- Submap Addresses : Area area
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  -- Submap Addresses : Memory Map
end MemMap_areaMems;
