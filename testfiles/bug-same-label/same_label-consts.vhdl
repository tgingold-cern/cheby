library ieee;
use ieee.std_logic_1164.all;

package same_label_reg_Consts is
  constant SAME_LABEL_REG_SIZE : Natural := 16;
  constant ADDR_SAME_LABEL_REG_NO_FIELDS : Natural := 16#0#;
  constant SAME_LABEL_REG_NO_FIELDS_PRESET : std_logic_vector(8-1 downto 0) := x"20";
  constant ADDR_SAME_LABEL_REG_SAME_NAME : Natural := 16#4#;
  constant SAME_LABEL_REG_SAME_NAME_WIDTH : Natural := 1;
  constant SAME_LABEL_REG_SAME_NAME_OFFSET : Natural := 0;
  constant ADDR_SAME_LABEL_REG_SAME_NAME_MULTI : Natural := 16#8#;
  constant SAME_LABEL_REG_SAME_NAME_MULTI_WIDTH : Natural := 12;
  constant SAME_LABEL_REG_SAME_NAME_MULTI_OFFSET : Natural := 0;
  constant ADDR_SAME_LABEL_REG_NOT_SAME_REG : Natural := 16#c#;
  constant ADDR_SAME_LABEL_REG_NOT_SAME : Natural := 16#c#;
  constant SAME_LABEL_REG_NOT_SAME_WIDTH : Natural := 1;
  constant SAME_LABEL_REG_NOT_SAME_OFFSET : Natural := 0;
end package same_label_reg_Consts;
