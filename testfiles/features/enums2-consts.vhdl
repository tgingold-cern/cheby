library ieee;
use ieee.std_logic_1164.all;

package enums2_Consts is
  constant ENUMS2_SIZE : Natural := 4;
  constant ADDR_ENUMS2_R1 : Natural := 16#0#;
  constant ADDR_ENUMS2_R1_F1 : Natural := 16#0#;
  constant ENUMS2_R1_F1_WIDTH : Natural := 8;
  constant ENUMS2_R1_F1_OFFSET : Natural := 0;
  constant C_enum1_hello : std_logic_vector (7 downto 0) := "00000000";
  constant C_enum1_World : std_logic_vector (7 downto 0) := "00000001";
  constant C_enum2_hello : std_logic_vector (0 downto 0) := "0";
  constant C_enum2_world : std_logic_vector (0 downto 0) := "1";
end package enums2_Consts;
