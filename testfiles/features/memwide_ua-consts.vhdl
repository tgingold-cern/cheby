library ieee;
use ieee.std_logic_1164.all;

package memwide_ua_Consts is
  constant MEMWIDE_UA_SIZE : Natural := 256;
  constant ADDR_MEMWIDE_UA_REGA : Natural := 16#0#;
  constant ADDR_MEMWIDE_UA_REGA_FIELD0 : Natural := 16#0#;
  constant MEMWIDE_UA_REGA_FIELD0_OFFSET : Natural := 1;
  constant ADDR_MEMWIDE_UA_TS : Natural := 16#80#;
  constant MEMWIDE_UA_TS_SIZE : Natural := 16;
  constant ADDR_MEMWIDE_UA_TS_RISE_SEC : Natural := 16#0#;
  constant ADDR_MEMWIDE_UA_TS_RISE_NS : Natural := 16#4#;
  constant ADDR_MEMWIDE_UA_TS_FALL_SEC : Natural := 16#8#;
end package memwide_ua_Consts;
