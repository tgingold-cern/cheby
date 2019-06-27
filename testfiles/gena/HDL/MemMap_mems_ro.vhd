library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package MemMap_mems_ro is

  -- Ident Code
  constant C_mems_ro_IdentCode : std_logic_vector(15 downto 0) := X"00FF";

  -- Memory Map Version
  constant C_mems_ro_MemMapVersion : std_logic_vector(31 downto 0) := X"0133A24D";--20161101
  -- Register Addresses : Memory Map

  -- Register Auto Clear Masks : Memory Map

  -- Register Preset Masks : Memory Map

  -- CODE FIELDS
  -- Memory Data : Memory Map
  constant C_Mem_mems_ro_mem1_Sta : std_logic_vector(19 downto 1) := "0000000000000000000";-- : Word address : 0x00000; Byte Address : 0x00000
  constant C_Mem_mems_ro_mem1_End : std_logic_vector(19 downto 1) := "0000000000111111111";-- : Word address : 0x001ff; Byte Address : 0x003fe
  -- Submap Addresses : Memory Map
end MemMap_mems_ro;
