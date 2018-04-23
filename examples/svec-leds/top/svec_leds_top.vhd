-------------------------------------------------------------------------------
-- Title      : VME64xCore test design for SVEC
-- Project    : VME64xCore
-- URL        : https://www.ohwr.org/projects/vme64x-core
-------------------------------------------------------------------------------
-- File       : svec_vmecore_test.vhd
-- Author(s)  : Tristan Gingold  <tristan.gingold@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Created    : 2017-09-19
-- Last update: 2018-04-23
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the test design .
--
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
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
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;
use work.wishbone_pkg.all;
use work.vme64x_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity svec_leds_top is
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- Reset from system fpga
    rst_n_i : in std_logic;

    -- Local oscillators
    clk_20m_vcxo_i : in std_logic;                -- 20MHz VCXO clock

--    clk_125m_pllref_p_i : in std_logic;           -- 125 MHz PLL reference
--    clk_125m_pllref_n_i : in std_logic;

--    clk_125m_gtp_n_i : in std_logic;              -- 125 MHz GTP reference
--    clk_125m_gtp_p_i : in std_logic;

    ---------------------------------------------------------------------------
    -- VME interface
    ---------------------------------------------------------------------------

    vme_write_n_i    : in    std_logic;
    vme_sysreset_n_i : in    std_logic;
    vme_retry_oe_o   : out   std_logic;
    vme_retry_n_o    : out   std_logic;
    vme_lword_n_b    : inout std_logic;
    vme_iackout_n_o  : out   std_logic;
    vme_iackin_n_i   : in    std_logic;
    vme_iack_n_i     : in    std_logic;
    vme_gap_i        : in    std_logic;
    vme_dtack_oe_o   : out   std_logic;
    vme_dtack_n_o    : out   std_logic;
    vme_ds_n_i       : in    std_logic_vector(1 downto 0);
    vme_data_oe_n_o  : out   std_logic;
    vme_data_dir_o   : out   std_logic;
    vme_berr_o       : out   std_logic;
    vme_as_n_i       : in    std_logic;
    vme_addr_oe_n_o  : out   std_logic;
    vme_addr_dir_o   : out   std_logic;
    vme_irq_o        : out   std_logic_vector(7 downto 1);
    vme_ga_i         : in    std_logic_vector(4 downto 0);
    vme_data_b       : inout std_logic_vector(31 downto 0);
    vme_am_i         : in    std_logic_vector(5 downto 0);
    vme_addr_b       : inout std_logic_vector(31 downto 1);

    ---------------------------------------------------------------------------
    -- SPI interfaces to DACs
    ---------------------------------------------------------------------------

--    pll20dac_din_o    : out std_logic;
--    pll20dac_sclk_o   : out std_logic;
--    pll20dac_sync_n_o : out std_logic;
--    pll25dac_din_o    : out std_logic;
--    pll25dac_sclk_o   : out std_logic;
--    pll25dac_sync_n_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver
    ---------------------------------------------------------------------------

--    sfp_txp_o         : out   std_logic;
--    sfp_txn_o         : out   std_logic;
--    sfp_rxp_i         : in    std_logic;
--    sfp_rxn_i         : in    std_logic;
--    sfp_mod_def0_i    : in    std_logic;          -- sfp detect
--    sfp_mod_def1_b    : inout std_logic;          -- scl
--    sfp_mod_def2_b    : inout std_logic;          -- sda
--    sfp_rate_select_o : out   std_logic;
--    sfp_tx_fault_i    : in    std_logic;
--    sfp_tx_disable_o  : out   std_logic;
--    sfp_los_i         : in    std_logic;

    ---------------------------------------------------------------------------
    -- Carrier I2C EEPROM
    ---------------------------------------------------------------------------

--    carrier_scl_b : inout std_logic;
--    carrier_sda_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------

--    onewire_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------

--    uart_rxd_i : in  std_logic;
--    uart_txd_o : out std_logic;

    ---------------------------------------------------------------------------
    -- SPI (flash is connected to SFPGA and routed to AFPGA
    -- once the boot process is complete)
    ---------------------------------------------------------------------------

--    spi_sclk_o : out std_logic;
--    spi_ncs_o  : out std_logic;
--    spi_mosi_o : out std_logic;
--    spi_miso_i : in  std_logic;

    ---------------------------------------------------------------------------
    -- Carrier front panel LEDs and IOs
    ---------------------------------------------------------------------------

    fp_led_line_oen_o : out std_logic_vector(1 downto 0);
    fp_led_line_o     : out std_logic_vector(1 downto 0);
    fp_led_column_o   : out std_logic_vector(3 downto 0)

--    fp_gpio1_o      : out std_logic;              -- PPS output
--    fp_gpio2_o      : out std_logic;              -- Ref clock div2 output
--    fp_gpio3_i      : in  std_logic;              -- ext 10MHz clock input
--    fp_gpio4_i      : in  std_logic;              -- ext PPS intput
--    fp_term_en_o    : out std_logic_vector(4 downto 1);
--    fp_gpio1_a2b_o  : out std_logic;
--    fp_gpio2_a2b_o  : out std_logic;
--    fp_gpio34_a2b_o : out std_logic
    );

end entity svec_leds_top;

architecture top of svec_leds_top is

  -- Wishbone bus from master
  signal master_out : t_wishbone_master_out;
  signal master_in  : t_wishbone_master_in;

  -- clock and reset
  signal clk_sys_62m5   : std_logic;
  signal rst_sys_62m5_n : std_logic;
  signal clk_ref_125m   : std_logic;
  signal clk_ref_div2   : std_logic;
  signal clk_ext_ref    : std_logic;

  -- VME
  signal vme_data_b_out    : std_logic_vector(31 downto 0);
  signal vme_addr_b_out    : std_logic_vector(31 downto 1);
  signal vme_lword_n_b_out : std_logic;
  signal vme_data_dir_int  : std_logic;
  signal vme_addr_dir_int  : std_logic;
  signal vme_ga            : std_logic_vector(5 downto 0);
  signal vme_berr_n_o      : std_logic;
  signal vme_irq_n_o       : std_logic_vector(7 downto 1);

  -- LEDs and GPIO
  signal pps         : std_logic;
  signal pps_led     : std_logic;
  signal pps_ext_in  : std_logic;
  signal svec_led    : std_logic_vector(15 downto 0);

  signal pllout_clk_fb_sys, pllout_clk_sys : std_logic;
  signal clk_20m_vcxo_buf                  : std_logic;
  signal clk_sys                           : std_logic;
  signal local_reset_n                     : std_logic;

  signal powerup_reset_cnt : unsigned(7 downto 0) := "00000000";
  signal powerup_rst_n     : std_logic            := '0';
  signal sys_locked        : std_logic;
begin  -- architecture top

  p_powerup_reset : process(clk_sys)
  begin
    if rising_edge(clk_sys) then
      if(vme_sysreset_n_i = '0' or rst_n_i = '0') then
        powerup_rst_n <= '0';
      elsif sys_locked = '1' then
        if(powerup_reset_cnt = "11111111") then
          powerup_rst_n <= '1';
        else
          powerup_rst_n     <= '0';
          powerup_reset_cnt <= powerup_reset_cnt + 1;
        end if;
      else
        powerup_rst_n     <= '0';
        powerup_reset_cnt <= "00000000";
      end if;
    end if;
  end process;


-------------------------------------------------------------------------------
-- Clock distribution/PLL and reset
-------------------------------------------------------------------------------

  --  Input is 20Mhz
  U_cmp_sys_pll : PLL_BASE
    generic map (
      BANDWIDTH          => "OPTIMIZED",
      CLK_FEEDBACK       => "CLKFBOUT",
      COMPENSATION       => "INTERNAL",
      DIVCLK_DIVIDE      => 1,
      CLKFBOUT_MULT      => 50,  -- 1Ghz
      CLKFBOUT_PHASE     => 0.000,
      CLKOUT0_DIVIDE     => 8,         -- 2*62.5 MHz
      CLKOUT0_PHASE      => 0.000,
      CLKOUT0_DUTY_CYCLE => 0.500,
      CLKOUT1_DIVIDE     => 8,         -- 2*62.5 MHz
      CLKOUT1_PHASE      => 0.000,
      CLKOUT1_DUTY_CYCLE => 0.500,
      CLKOUT2_DIVIDE     => 8,
      CLKOUT2_PHASE      => 0.000,
      CLKOUT2_DUTY_CYCLE => 0.500,
      CLKIN_PERIOD       => 50.0,
      REF_JITTER         => 0.016)
    port map (
      CLKFBOUT => pllout_clk_fb_sys,
      CLKOUT0  => pllout_clk_sys,
      CLKOUT1  => open,                 -- pllout_clk_sys,
      CLKOUT2  => open,
      CLKOUT3  => open,
      CLKOUT4  => open,
      CLKOUT5  => open,
      LOCKED   => sys_locked,
      RST      => '0',
      CLKFBIN  => pllout_clk_fb_sys,
      CLKIN    => clk_20m_vcxo_buf);


  U_Sync_Reset : gc_sync_ffs
    port map (
      clk_i    => clk_sys,
      rst_n_i  => '1',
      data_i   => powerup_rst_n,
      synced_o => local_reset_n);

  U_cmp_clk_vcxo_buf : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_20m_vcxo_i);

  U_cmp_clk_sys_buf : BUFG
    port map (
      O => clk_sys,
      I => pllout_clk_sys);

  -----------------------------------------------------------------------------
  -- VME64x Core and buffers
  -----------------------------------------------------------------------------

  --  BERR and IRQ vme signals are inverted by the drivers. See schematics.
  vme_berr_o <= not vme_berr_n_o;
  vme_irq_o <= not vme_irq_n_o;

  inst_vme_core : xvme64x_core
    generic map (
      g_CLOCK_PERIOD => 8,
      g_DECODE_AM => True,
      g_USER_CSR_EXT => False,
      g_WB_GRANULARITY => WORD,

      g_MANUFACTURER_ID => c_CERN_ID,
      g_BOARD_ID        => c_SVEC_ID,
      g_REVISION_ID     => c_SVEC_REVISION_ID,
      g_PROGRAM_ID      => c_SVEC_PROGRAM_ID)
    port map (
      clk_i           => clk_sys,
      rst_n_i         => local_reset_n,
      vme_i.as_n      => vme_as_n_i,
      vme_i.rst_n     => vme_sysreset_n_i,
      vme_i.write_n   => vme_write_n_i,
      vme_i.am        => vme_am_i,
      vme_i.ds_n      => vme_ds_n_i,
      vme_i.ga        => vme_ga,
      vme_i.lword_n   => vme_lword_n_b,
      vme_i.addr      => vme_addr_b,
      vme_i.data      => vme_data_b,
      vme_i.iack_n    => vme_iack_n_i,
      vme_i.iackin_n  => vme_iackin_n_i,
      vme_o.berr_n    => vme_berr_n_o,
      vme_o.dtack_n   => vme_dtack_n_o,
      vme_o.retry_n   => vme_retry_n_o,
      vme_o.retry_oe  => vme_retry_oe_o,
      vme_o.lword_n   => vme_lword_n_b_out,
      vme_o.data      => vme_data_b_out,
      vme_o.addr      => vme_addr_b_out,
      vme_o.irq_n     => vme_irq_n_o,
      vme_o.iackout_n => vme_iackout_n_o,
      vme_o.dtack_oe  => vme_dtack_oe_o,
      vme_o.data_dir  => vme_data_dir_int,
      vme_o.data_oe_n => vme_data_oe_n_o,
      vme_o.addr_dir  => vme_addr_dir_int,
      vme_o.addr_oe_n => vme_addr_oe_n_o,
      wb_i   => master_in,
      wb_o   => master_out);

  vme_ga <= vme_gap_i & vme_ga_i;

  -- VME tri-state buffers
  vme_data_b    <= vme_data_b_out    when vme_data_dir_int = '1'
                   else (others => 'Z');
  vme_addr_b    <= vme_addr_b_out    when vme_addr_dir_int = '1'
                   else (others => 'Z');
  vme_lword_n_b <= vme_lword_n_b_out when vme_addr_dir_int = '1'
                   else 'Z';

  vme_addr_dir_o <= vme_addr_dir_int;
  vme_data_dir_o <= vme_data_dir_int;

  -- tri-state Carrier EEPROM
--  carrier_sda_b <= 'Z';
--  carrier_scl_b <= 'Z';

  -- Tristates for SFP EEPROM
--  sfp_mod_def1_b <= 'Z';
--  sfp_mod_def2_b <= 'Z';

  -- tri-state onewire access
--  onewire_b    <= 'Z';

  ------------------------------------------------------------------------------
  -- Carrier front panel LEDs and LEMOs
  ------------------------------------------------------------------------------

  cmp_led_controller : gc_bicolor_led_ctrl
    generic map(
      g_nb_column    => 4,
      g_nb_line      => 2,
      g_clk_freq     => 62_500_000,               -- in Hz
      g_refresh_rate => 250                       -- in Hz
      )
    port map(
      rst_n_i => local_reset_n,
      clk_i   => clk_sys,

      led_intensity_i => "1100100",               -- in %

      led_state_i => svec_led,

      column_o   => fp_led_column_o,
      line_o     => fp_led_line_o,
      line_oen_o => fp_led_line_oen_o);

  inst_test: entity work.led_demo
    port map (rst_n_i  => local_reset_n,
              clk_i    => clk_sys,
              wb_adr_i => master_out.adr(4 downto 0),
              wb_dat_i => master_out.dat,
              wb_dat_o => master_in.dat,
              wb_cyc_i => master_out.cyc,
              wb_sel_i => master_out.sel,
              wb_stb_i => master_out.stb,
              wb_we_i  => master_out.we,
              wb_ack_o => master_in.ack,
              wb_stall_o => master_in.stall,
              led_demo_leds_led0_en_o => svec_led(0),
              led_demo_leds_led1_en_o => svec_led(2),
              led_demo_leds_led2_en_o => svec_led(4),
              led_demo_leds_led3_en_o => svec_led(6),
              led_demo_leds_led4_en_o => svec_led(8),
              led_demo_leds_led5_en_o => svec_led(10),
              led_demo_leds_led6_en_o => svec_led(12),
              led_demo_leds_led7_en_o => svec_led(14));

  svec_led(1) <= '0';
  svec_led(3) <= '0';
  svec_led(5) <= '0';
  svec_led(7) <= '0';
  svec_led(9) <= '0';
  svec_led(11) <= '0';
  svec_led(13) <= '0';
  svec_led(15) <= '0';

end architecture top;
