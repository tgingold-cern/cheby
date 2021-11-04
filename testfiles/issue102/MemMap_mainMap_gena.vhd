--- VME memory map mainMap
--- Memory map version 20211103
--- Generated on 2021-11-03 by npittet using VHDLMap (Gena component)

library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;


package MemMap_mainMap is

	-- Ident Code
	constant C_mainMap_IdentCode : std_logic_vector(31 downto 0) := X"00000001";

	-- Memory Map Version
	constant C_mainMap_MemMapVersion : std_logic_vector(31 downto 0) := std_logic_vector(to_unsigned(20211103,32));

	-- Semantic Memory Map Version
	constant C_mainMap_SemanticMemMapVersion : std_logic_vector(31 downto 0) := X"00010000";

	-- Register Addresses : Memory Map
	constant C_Reg_mainMap_r1		:		std_logic_vector(12 downto 2) := "00000000000";-- : Word address : "000" & "000" & X"00"; Byte Address : "000" & X"00"

	-- Register Auto Clear Masks : Memory Map
	constant C_ACM_mainMap_r1		:		std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

	-- Register Preset Masks : Memory Map
	constant C_PSM_mainMap_r1		:		std_logic_vector(31 downto 0) := "00000000000000000000000000000000";-- : Value : X"00000000"

	-- CODE FIELDS
	constant C_Code_mainMap_r1_yes		:		std_logic_vector(31 downto 0) := "00000000000000000000000000000001";
	constant C_Code_mainMap_r1_no		:		std_logic_vector(31 downto 0) := "00000000000000000000000000000000";
	-- Memory Data : Memory Map
	-- Submap Addresses : Memory Map
end;
-- EOF