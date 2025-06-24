library ieee;
use ieee.std_logic_1164.all;

package pkg_fid_top_axi_consts is
  constant FID_TOP_AXI_MEMMAP_VERSION : Natural := 16#100#;
  constant ADDR_FID_TOP_AXI_IP : Natural := 16#0#;
  constant ADDR_MASK_FID_TOP_AXI_IP : Natural := 16#0#;
  constant ADDR_FMASK_FID_TOP_AXI_IP : Natural := 16#0#;
  constant FID_TOP_AXI_IP_SIZE : Natural := 4;
end package pkg_fid_top_axi_consts;
