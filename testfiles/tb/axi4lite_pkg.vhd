-------------------------------------------------------------------------------
-- Title      : AXI4-Lite package
-- Project    : Cheby
-------------------------------------------------------------------------------
-- File       : axi4lite_pkg.vhd
-- Company    : CERN
-- Platform   : FPGA-generics
-- Standard   : VHDL-2008
-------------------------------------------------------------------------------
-- Copyright (c) 2011-2025 CERN
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
-------------------------------------------------------------------------------

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package axi4lite_pkg is

  constant c_axi4lite_address_width : integer := 32;
  constant c_axi4lite_data_width    : integer := 32;

  subtype t_axi4lite_address is
    std_logic_vector(c_axi4lite_address_width-1 downto 0);
  subtype t_axi4lite_data is
    std_logic_vector(c_axi4lite_data_width-1 downto 0);
  subtype t_axi4lite_wstrobe is
    std_logic_vector((c_axi4lite_address_width/8)-1 downto 0);
  subtype t_axi4lite_prot is
    std_logic_vector(2 downto 0);
  subtype t_axi4lite_resp is
    std_logic_vector(1 downto 0);

  type t_axi4lite_manager_out is record
    awvalid : std_logic;
    awaddr  : t_axi4lite_address;
    awprot  : t_axi4lite_prot;
    wvalid  : std_logic;
    wdata   : t_axi4lite_data;
    wstrb   : t_axi4lite_wstrobe;
    bready  : std_logic;
    arvalid : std_logic;
    araddr  : t_axi4lite_address;
    arprot  : t_axi4lite_prot;
    rready  : std_logic;
  end record t_axi4lite_manager_out;

  subtype t_axi4lite_subordinate_in is t_axi4lite_manager_out;

  type t_axi4lite_subordinate_out is record
    awready : std_logic;
    wready  : std_logic;
    bvalid  : std_logic;
    bresp   : t_axi4lite_resp;
    arready : std_logic;
    rvalid  : std_logic;
    rdata   : t_axi4lite_data;
    rresp   : t_axi4lite_resp;
  end record t_axi4lite_subordinate_out;

  subtype t_axi4lite_manager_in is t_axi4lite_subordinate_out;

end axi4lite_pkg;
