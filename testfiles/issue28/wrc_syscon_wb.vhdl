library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wrc_syscon_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_adr_i             : in    std_logic_vector(4 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    -- Ports for PASS_THROUGH field: 'Reset trigger' in reg: 'Syscon reset register'
    sysc_rstr_trig_o     : out   std_logic_vector(27 downto 0);
    sysc_rstr_trig_wr_o  : out   std_logic;
    -- Port for BIT field: 'Reset line state value' in reg: 'Syscon reset register'
    sysc_rstr_rst_o      : out   std_logic;
    -- Port for MONOSTABLE field: 'Status LED' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_led_stat_o : out   std_logic;
    -- Port for MONOSTABLE field: 'Link LED' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_led_link_o : out   std_logic;
    -- Ports for BIT field: 'FMC I2C bitbanged SCL' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_fmc_scl_o  : out   std_logic;
    sysc_gpsr_fmc_scl_i  : in    std_logic;
    sysc_gpsr_fmc_scl_load_o : out   std_logic;
    -- Ports for BIT field: 'FMC I2C bitbanged SDA' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_fmc_sda_o  : out   std_logic;
    sysc_gpsr_fmc_sda_i  : in    std_logic;
    sysc_gpsr_fmc_sda_load_o : out   std_logic;
    -- Port for MONOSTABLE field: 'Network AP reset' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_net_rst_o  : out   std_logic;
    -- Port for BIT field: 'SPEC Pushbutton 1 state' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_btn1_i     : in    std_logic;
    -- Port for BIT field: 'SPEC Pushbutton 2 state' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_btn2_i     : in    std_logic;
    -- Port for BIT field: 'SFP detect (MOD_DEF0 signal)' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_sfp_det_i  : in    std_logic;
    -- Ports for BIT field: 'SFP I2C bitbanged SCL' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_sfp_scl_o  : out   std_logic;
    sysc_gpsr_sfp_scl_i  : in    std_logic;
    sysc_gpsr_sfp_scl_load_o : out   std_logic;
    -- Ports for BIT field: 'SFP I2C bitbanged SDA' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_sfp_sda_o  : out   std_logic;
    sysc_gpsr_sfp_sda_i  : in    std_logic;
    sysc_gpsr_sfp_sda_load_o : out   std_logic;
    -- Ports for BIT field: 'SPI bitbanged SCLK' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_spi_sclk_o : out   std_logic;
    sysc_gpsr_spi_sclk_i : in    std_logic;
    sysc_gpsr_spi_sclk_load_o : out   std_logic;
    -- Ports for BIT field: 'SPI bitbanged NCS' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_spi_ncs_o  : out   std_logic;
    sysc_gpsr_spi_ncs_i  : in    std_logic;
    sysc_gpsr_spi_ncs_load_o : out   std_logic;
    -- Ports for BIT field: 'SPI bitbanged MOSI' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_spi_mosi_o : out   std_logic;
    sysc_gpsr_spi_mosi_i : in    std_logic;
    sysc_gpsr_spi_mosi_load_o : out   std_logic;
    -- Ports for BIT field: 'SPI bitbanged MISO' in reg: 'GPIO Set/Readback Register'
    sysc_gpsr_spi_miso_i : in    std_logic;
    -- Port for MONOSTABLE field: 'Status LED' in reg: 'GPIO Clear Register'
    sysc_gpcr_led_stat_o : out   std_logic;
    -- Port for MONOSTABLE field: 'Link LED' in reg: 'GPIO Clear Register'
    sysc_gpcr_led_link_o : out   std_logic;
    -- Port for MONOSTABLE field: 'FMC I2C bitbanged SCL' in reg: 'GPIO Clear Register'
    sysc_gpcr_fmc_scl_o  : out   std_logic;
    -- Port for MONOSTABLE field: 'FMC I2C bitbanged SDA' in reg: 'GPIO Clear Register'
    sysc_gpcr_fmc_sda_o  : out   std_logic;
    -- Port for MONOSTABLE field: 'SFP I2C bitbanged SCL' in reg: 'GPIO Clear Register'
    sysc_gpcr_sfp_scl_o  : out   std_logic;
    -- Port for MONOSTABLE field: 'FMC I2C bitbanged SDA' in reg: 'GPIO Clear Register'
    sysc_gpcr_sfp_sda_o  : out   std_logic;
    -- Port for MONOSTABLE field: 'SPI bitbanged SCLK' in reg: 'GPIO Clear Register'
    sysc_gpcr_spi_sclk_o : out   std_logic;
    -- Port for MONOSTABLE field: 'SPI bitbanged CS' in reg: 'GPIO Clear Register'
    sysc_gpcr_spi_cs_o   : out   std_logic;
    -- Port for MONOSTABLE field: 'SPI bitbanged MOSI' in reg: 'GPIO Clear Register'
    sysc_gpcr_spi_mosi_o : out   std_logic;
    -- Port for std_logic_vector field: 'Memory size' in reg: 'Hardware Feature Register'
    sysc_hwfr_memsize_i  : in    std_logic_vector(3 downto 0);
    -- Port for std_logic_vector field: 'Board name' in reg: 'Hardware Info Register'
    sysc_hwir_name_i     : in    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Timer Divider' in reg: 'Timer Control Register'
    sysc_tcr_tdiv_i      : in    std_logic_vector(11 downto 0);
    -- Port for BIT field: 'Timer Enable' in reg: 'Timer Control Register'
    sysc_tcr_enable_o    : out   std_logic;
    -- Port for std_logic_vector field: 'Timer Counter Value' in reg: 'Timer Counter Value Register'
    sysc_tvr_i           : in    std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Ver' in reg: 'User Diag: version register'
    sysc_diag_info_ver_i : in    std_logic_vector(15 downto 0);
    -- Port for std_logic_vector field: 'Id' in reg: 'User Diag: version register'
    sysc_diag_info_id_i  : in    std_logic_vector(15 downto 0);
    -- Port for std_logic_vector field: 'Read/write words' in reg: 'User Diag: number of words'
    sysc_diag_nw_rw_i    : in    std_logic_vector(15 downto 0);
    -- Port for std_logic_vector field: 'Read-only words' in reg: 'User Diag: number of words'
    sysc_diag_nw_ro_i    : in    std_logic_vector(15 downto 0);
    -- Port for std_logic_vector field: 'Address' in reg: 'User Diag: Control Register'
    sysc_diag_cr_adr_o   : out   std_logic_vector(15 downto 0);
    sysc_diag_cr_adr_i   : in    std_logic_vector(15 downto 0);
    sysc_diag_cr_adr_load_o : out   std_logic;
    -- Port for BIT field: 'R/W' in reg: 'User Diag: Control Register'
    sysc_diag_cr_rw_o    : out   std_logic;
    -- Port for std_logic_vector field: 'Data' in reg: 'User Diag: data to read/write'
    sysc_diag_dat_o      : out   std_logic_vector(31 downto 0);
    sysc_diag_dat_i      : in    std_logic_vector(31 downto 0);
    sysc_diag_dat_load_o : out   std_logic;
    -- Port for BIT field: 'WR DIAG data valid' in reg: 'WRPC Diag: ctrl'
    sysc_wdiag_ctrl_data_valid_o : out   std_logic;
    -- Port for BIT field: 'WR DIAG data snapshot' in reg: 'WRPC Diag: ctrl'
    sysc_wdiag_ctrl_data_snapshot_i : in    std_logic;
    -- Port for BIT field: 'WR valid' in reg: 'WRPC Diag: servo status'
    sysc_wdiag_sstat_wr_mode_o : out   std_logic;
    -- Port for std_logic_vector field: 'Servo State' in reg: 'WRPC Diag: servo status'
    sysc_wdiag_sstat_servostate_o : out   std_logic_vector(3 downto 0);
    -- Port for BIT field: 'Link Status' in reg: 'WRPC Diag: Port status'
    sysc_wdiag_pstat_link_o : out   std_logic;
    -- Port for BIT field: 'PLL Locked' in reg: 'WRPC Diag: Port status'
    sysc_wdiag_pstat_locked_o : out   std_logic;
    -- Port for std_logic_vector field: 'PTP State' in reg: 'WRPC Diag: PTP state'
    sysc_wdiag_ptpstat_ptpstate_o : out   std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'AUX channel' in reg: 'WRPC Diag: AUX state'
    sysc_wdiag_astat_aux_o : out   std_logic_vector(7 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Tx PTP Frame cnts'
    sysc_wdiag_txfcnt_o  : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Rx PTP Frame cnts'
    sysc_wdiag_rxfcnt_o  : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag:local time [msb of s]'
    sysc_wdiag_sec_msb_o : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: local time [lsb of s]'
    sysc_wdiag_sec_lsb_o : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: local time [ns]'
    sysc_wdiag_ns_o      : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Round trip (mu) [msb of ps]'
    sysc_wdiag_mu_msb_o  : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Round trip (mu) [lsb of ps]'
    sysc_wdiag_mu_lsb_o  : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Master-slave delay (dms) [msb of ps]'
    sysc_wdiag_dms_msb_o : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Master-slave delay (dms) [lsb of ps]'
    sysc_wdiag_dms_lsb_o : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Total link asymmetry [ps]'
    sysc_wdiag_asym_o    : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Clock offset (cko) [ps]'
    sysc_wdiag_cko_o     : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Phase setpoint (setp) [ps]'
    sysc_wdiag_setp_o    : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Update counter (ucnt)'
    sysc_wdiag_ucnt_o    : out   std_logic_vector(31 downto 0);
    -- Port for std_logic_vector field: 'Data' in reg: 'WRPC Diag: Board temperature [C degree]'
    sysc_wdiag_temp_o    : out   std_logic_vector(31 downto 0)
  );
end wrc_syscon_wb;

architecture syn of wrc_syscon_wb is

  signal sysc_rstr_rst_int              : std_logic;
  signal sysc_gpsr_led_stat_dly0        : std_logic;
  signal sysc_gpsr_led_stat_int         : std_logic;
  signal sysc_gpsr_led_link_dly0        : std_logic;
  signal sysc_gpsr_led_link_int         : std_logic;
  signal sysc_gpsr_net_rst_dly0         : std_logic;
  signal sysc_gpsr_net_rst_int          : std_logic;
  signal sysc_gpcr_led_stat_dly0        : std_logic;
  signal sysc_gpcr_led_stat_int         : std_logic;
  signal sysc_gpcr_led_link_dly0        : std_logic;
  signal sysc_gpcr_led_link_int         : std_logic;
  signal sysc_gpcr_fmc_scl_dly0         : std_logic;
  signal sysc_gpcr_fmc_scl_int          : std_logic;
  signal sysc_gpcr_fmc_sda_dly0         : std_logic;
  signal sysc_gpcr_fmc_sda_int          : std_logic;
  signal sysc_gpcr_sfp_scl_dly0         : std_logic;
  signal sysc_gpcr_sfp_scl_int          : std_logic;
  signal sysc_gpcr_sfp_sda_dly0         : std_logic;
  signal sysc_gpcr_sfp_sda_int          : std_logic;
  signal sysc_gpcr_spi_sclk_dly0        : std_logic;
  signal sysc_gpcr_spi_sclk_int         : std_logic;
  signal sysc_gpcr_spi_cs_dly0          : std_logic;
  signal sysc_gpcr_spi_cs_int           : std_logic;
  signal sysc_gpcr_spi_mosi_dly0        : std_logic;
  signal sysc_gpcr_spi_mosi_int         : std_logic;
  signal sysc_tcr_enable_int            : std_logic;
  signal sysc_diag_cr_rw_int            : std_logic;
  signal sysc_wdiag_ctrl_data_valid_int : std_logic;
  signal sysc_wdiag_sstat_wr_mode_int   : std_logic;
  signal sysc_wdiag_sstat_servostate_int : std_logic_vector(3 downto 0);
  signal sysc_wdiag_pstat_link_int      : std_logic;
  signal sysc_wdiag_pstat_locked_int    : std_logic;
  signal sysc_wdiag_ptpstat_ptpstate_int : std_logic_vector(7 downto 0);
  signal sysc_wdiag_astat_aux_int       : std_logic_vector(7 downto 0);
  signal sysc_wdiag_txfcnt_int          : std_logic_vector(31 downto 0);
  signal sysc_wdiag_rxfcnt_int          : std_logic_vector(31 downto 0);
  signal sysc_wdiag_sec_msb_int         : std_logic_vector(31 downto 0);
  signal sysc_wdiag_sec_lsb_int         : std_logic_vector(31 downto 0);
  signal sysc_wdiag_ns_int              : std_logic_vector(31 downto 0);
  signal sysc_wdiag_mu_msb_int          : std_logic_vector(31 downto 0);
  signal sysc_wdiag_mu_lsb_int          : std_logic_vector(31 downto 0);
  signal sysc_wdiag_dms_msb_int         : std_logic_vector(31 downto 0);
  signal sysc_wdiag_dms_lsb_int         : std_logic_vector(31 downto 0);
  signal sysc_wdiag_asym_int            : std_logic_vector(31 downto 0);
  signal sysc_wdiag_cko_int             : std_logic_vector(31 downto 0);
  signal sysc_wdiag_setp_int            : std_logic_vector(31 downto 0);
  signal sysc_wdiag_ucnt_int            : std_logic_vector(31 downto 0);
  signal sysc_wdiag_temp_int            : std_logic_vector(31 downto 0);
  signal ack_sreg                       : std_logic_vector(9 downto 0);
  signal rddata_reg                     : std_logic_vector(31 downto 0);
  signal wrdata_reg                     : std_logic_vector(31 downto 0);
  signal bwsel_reg                      : std_logic_vector(3 downto 0);
  signal rwaddr_reg                     : std_logic_vector(4 downto 0);
  signal ack_in_progress                : std_logic;
  signal wr_int                         : std_logic;
  signal rd_int                         : std_logic;
  signal allones                        : std_logic_vector(31 downto 0);
  signal allzeros                       : std_logic_vector(31 downto 0);

begin
  -- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
  wrdata_reg <= wb_dat_i;
  bwsel_reg <= wb_sel_i;
  rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
  wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
  allones <= (others => '1');
  allzeros <= (others => '0');
  -- 
  -- Main register bank access process.
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      ack_sreg <= "0000000000";
      ack_in_progress <= '0';
      rddata_reg <= "00000000000000000000000000000000";
      sysc_rstr_trig_wr_o <= '0';
      sysc_rstr_rst_int <= '0';
      sysc_gpsr_led_stat_int <= '0';
      sysc_gpsr_led_link_int <= '0';
      sysc_gpsr_fmc_scl_load_o <= '0';
      sysc_gpsr_fmc_sda_load_o <= '0';
      sysc_gpsr_net_rst_int <= '0';
      sysc_gpsr_sfp_scl_load_o <= '0';
      sysc_gpsr_sfp_sda_load_o <= '0';
      sysc_gpsr_spi_sclk_load_o <= '0';
      sysc_gpsr_spi_ncs_load_o <= '0';
      sysc_gpsr_spi_mosi_load_o <= '0';
      sysc_gpcr_led_stat_int <= '0';
      sysc_gpcr_led_link_int <= '0';
      sysc_gpcr_fmc_scl_int <= '0';
      sysc_gpcr_fmc_sda_int <= '0';
      sysc_gpcr_sfp_scl_int <= '0';
      sysc_gpcr_sfp_sda_int <= '0';
      sysc_gpcr_spi_sclk_int <= '0';
      sysc_gpcr_spi_cs_int <= '0';
      sysc_gpcr_spi_mosi_int <= '0';
      sysc_tcr_enable_int <= '0';
      sysc_diag_cr_adr_load_o <= '0';
      sysc_diag_cr_rw_int <= '0';
      sysc_diag_dat_load_o <= '0';
      sysc_wdiag_ctrl_data_valid_int <= '0';
      sysc_wdiag_sstat_wr_mode_int <= '0';
      sysc_wdiag_sstat_servostate_int <= "0000";
      sysc_wdiag_pstat_link_int <= '0';
      sysc_wdiag_pstat_locked_int <= '0';
      sysc_wdiag_ptpstat_ptpstate_int <= "00000000";
      sysc_wdiag_astat_aux_int <= "00000000";
      sysc_wdiag_txfcnt_int <= "00000000000000000000000000000000";
      sysc_wdiag_rxfcnt_int <= "00000000000000000000000000000000";
      sysc_wdiag_sec_msb_int <= "00000000000000000000000000000000";
      sysc_wdiag_sec_lsb_int <= "00000000000000000000000000000000";
      sysc_wdiag_ns_int <= "00000000000000000000000000000000";
      sysc_wdiag_mu_msb_int <= "00000000000000000000000000000000";
      sysc_wdiag_mu_lsb_int <= "00000000000000000000000000000000";
      sysc_wdiag_dms_msb_int <= "00000000000000000000000000000000";
      sysc_wdiag_dms_lsb_int <= "00000000000000000000000000000000";
      sysc_wdiag_asym_int <= "00000000000000000000000000000000";
      sysc_wdiag_cko_int <= "00000000000000000000000000000000";
      sysc_wdiag_setp_int <= "00000000000000000000000000000000";
      sysc_wdiag_ucnt_int <= "00000000000000000000000000000000";
      sysc_wdiag_temp_int <= "00000000000000000000000000000000";
    elsif rising_edge(clk_sys_i) then
      -- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          sysc_rstr_trig_wr_o <= '0';
          sysc_gpsr_led_stat_int <= '0';
          sysc_gpsr_led_link_int <= '0';
          sysc_gpsr_fmc_scl_load_o <= '0';
          sysc_gpsr_fmc_sda_load_o <= '0';
          sysc_gpsr_net_rst_int <= '0';
          sysc_gpsr_sfp_scl_load_o <= '0';
          sysc_gpsr_sfp_sda_load_o <= '0';
          sysc_gpsr_spi_sclk_load_o <= '0';
          sysc_gpsr_spi_ncs_load_o <= '0';
          sysc_gpsr_spi_mosi_load_o <= '0';
          sysc_gpcr_led_stat_int <= '0';
          sysc_gpcr_led_link_int <= '0';
          sysc_gpcr_fmc_scl_int <= '0';
          sysc_gpcr_fmc_sda_int <= '0';
          sysc_gpcr_sfp_scl_int <= '0';
          sysc_gpcr_sfp_sda_int <= '0';
          sysc_gpcr_spi_sclk_int <= '0';
          sysc_gpcr_spi_cs_int <= '0';
          sysc_gpcr_spi_mosi_int <= '0';
          sysc_diag_cr_adr_load_o <= '0';
          sysc_diag_dat_load_o <= '0';
          ack_in_progress <= '0';
        else
          sysc_rstr_trig_wr_o <= '0';
          sysc_gpsr_fmc_scl_load_o <= '0';
          sysc_gpsr_fmc_sda_load_o <= '0';
          sysc_gpsr_sfp_scl_load_o <= '0';
          sysc_gpsr_sfp_sda_load_o <= '0';
          sysc_gpsr_spi_sclk_load_o <= '0';
          sysc_gpsr_spi_ncs_load_o <= '0';
          sysc_gpsr_spi_mosi_load_o <= '0';
          sysc_diag_cr_adr_load_o <= '0';
          sysc_diag_dat_load_o <= '0';
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          case rwaddr_reg(4 downto 0) is
          when "00000" => 
            if (wb_we_i = '1') then
              sysc_rstr_trig_wr_o <= '1';
              sysc_rstr_rst_int <= wrdata_reg(28);
            end if;
            rddata_reg(28) <= sysc_rstr_rst_int;
            rddata_reg(0) <= 'X';
            rddata_reg(1) <= 'X';
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00001" => 
            if (wb_we_i = '1') then
              sysc_gpsr_led_stat_int <= wrdata_reg(0);
              sysc_gpsr_led_link_int <= wrdata_reg(1);
              sysc_gpsr_fmc_scl_load_o <= '1';
              sysc_gpsr_fmc_sda_load_o <= '1';
              sysc_gpsr_net_rst_int <= wrdata_reg(4);
              sysc_gpsr_sfp_scl_load_o <= '1';
              sysc_gpsr_sfp_sda_load_o <= '1';
              sysc_gpsr_spi_sclk_load_o <= '1';
              sysc_gpsr_spi_ncs_load_o <= '1';
              sysc_gpsr_spi_mosi_load_o <= '1';
            end if;
            rddata_reg(0) <= '0';
            rddata_reg(1) <= '0';
            rddata_reg(2) <= sysc_gpsr_fmc_scl_i;
            rddata_reg(3) <= sysc_gpsr_fmc_sda_i;
            rddata_reg(4) <= '0';
            rddata_reg(5) <= sysc_gpsr_btn1_i;
            rddata_reg(6) <= sysc_gpsr_btn2_i;
            rddata_reg(7) <= sysc_gpsr_sfp_det_i;
            rddata_reg(8) <= sysc_gpsr_sfp_scl_i;
            rddata_reg(9) <= sysc_gpsr_sfp_sda_i;
            rddata_reg(10) <= sysc_gpsr_spi_sclk_i;
            rddata_reg(11) <= sysc_gpsr_spi_ncs_i;
            rddata_reg(12) <= sysc_gpsr_spi_mosi_i;
            rddata_reg(13) <= sysc_gpsr_spi_miso_i;
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(2) <= '1';
            ack_in_progress <= '1';
          when "00010" => 
            if (wb_we_i = '1') then
              sysc_gpcr_led_stat_int <= wrdata_reg(0);
              sysc_gpcr_led_link_int <= wrdata_reg(1);
              sysc_gpcr_fmc_scl_int <= wrdata_reg(2);
              sysc_gpcr_fmc_sda_int <= wrdata_reg(3);
              sysc_gpcr_sfp_scl_int <= wrdata_reg(8);
              sysc_gpcr_sfp_sda_int <= wrdata_reg(9);
              sysc_gpcr_spi_sclk_int <= wrdata_reg(10);
              sysc_gpcr_spi_cs_int <= wrdata_reg(11);
              sysc_gpcr_spi_mosi_int <= wrdata_reg(12);
            end if;
            rddata_reg(0) <= '0';
            rddata_reg(1) <= '0';
            rddata_reg(2) <= '0';
            rddata_reg(3) <= '0';
            rddata_reg(8) <= '0';
            rddata_reg(9) <= '0';
            rddata_reg(10) <= '0';
            rddata_reg(11) <= '0';
            rddata_reg(12) <= '0';
            rddata_reg(0) <= 'X';
            rddata_reg(1) <= 'X';
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(2) <= '1';
            ack_in_progress <= '1';
          when "00011" => 
            if (wb_we_i = '1') then
            end if;
            rddata_reg(3 downto 0) <= sysc_hwfr_memsize_i;
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00100" => 
            if (wb_we_i = '1') then
            end if;
            rddata_reg(31 downto 0) <= sysc_hwir_name_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00101" => 
            if (wb_we_i = '1') then
              sysc_tcr_enable_int <= wrdata_reg(31);
            end if;
            rddata_reg(11 downto 0) <= sysc_tcr_tdiv_i;
            rddata_reg(31) <= sysc_tcr_enable_int;
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00110" => 
            if (wb_we_i = '1') then
            end if;
            rddata_reg(31 downto 0) <= sysc_tvr_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "00111" => 
            if (wb_we_i = '1') then
            end if;
            rddata_reg(15 downto 0) <= sysc_diag_info_ver_i;
            rddata_reg(31 downto 16) <= sysc_diag_info_id_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01000" => 
            if (wb_we_i = '1') then
            end if;
            rddata_reg(15 downto 0) <= sysc_diag_nw_rw_i;
            rddata_reg(31 downto 16) <= sysc_diag_nw_ro_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01001" => 
            if (wb_we_i = '1') then
              sysc_diag_cr_adr_load_o <= '1';
              sysc_diag_cr_rw_int <= wrdata_reg(31);
            end if;
            rddata_reg(15 downto 0) <= sysc_diag_cr_adr_i;
            rddata_reg(31) <= sysc_diag_cr_rw_int;
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01010" => 
            if (wb_we_i = '1') then
              sysc_diag_dat_load_o <= '1';
            end if;
            rddata_reg(31 downto 0) <= sysc_diag_dat_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01011" => 
            if (wb_we_i = '1') then
              sysc_wdiag_ctrl_data_valid_int <= wrdata_reg(0);
            end if;
            rddata_reg(0) <= sysc_wdiag_ctrl_data_valid_int;
            rddata_reg(8) <= sysc_wdiag_ctrl_data_snapshot_i;
            rddata_reg(1) <= 'X';
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01100" => 
            if (wb_we_i = '1') then
              sysc_wdiag_sstat_wr_mode_int <= wrdata_reg(0);
              sysc_wdiag_sstat_servostate_int <= wrdata_reg(11 downto 8);
            end if;
            rddata_reg(0) <= sysc_wdiag_sstat_wr_mode_int;
            rddata_reg(11 downto 8) <= sysc_wdiag_sstat_servostate_int;
            rddata_reg(1) <= 'X';
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01101" => 
            if (wb_we_i = '1') then
              sysc_wdiag_pstat_link_int <= wrdata_reg(0);
              sysc_wdiag_pstat_locked_int <= wrdata_reg(1);
            end if;
            rddata_reg(0) <= sysc_wdiag_pstat_link_int;
            rddata_reg(1) <= sysc_wdiag_pstat_locked_int;
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01110" => 
            if (wb_we_i = '1') then
              sysc_wdiag_ptpstat_ptpstate_int <= wrdata_reg(7 downto 0);
            end if;
            rddata_reg(7 downto 0) <= sysc_wdiag_ptpstat_ptpstate_int;
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "01111" => 
            if (wb_we_i = '1') then
              sysc_wdiag_astat_aux_int <= wrdata_reg(7 downto 0);
            end if;
            rddata_reg(7 downto 0) <= sysc_wdiag_astat_aux_int;
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(16) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10000" => 
            if (wb_we_i = '1') then
              sysc_wdiag_txfcnt_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_txfcnt_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10001" => 
            if (wb_we_i = '1') then
              sysc_wdiag_rxfcnt_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_rxfcnt_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10010" => 
            if (wb_we_i = '1') then
              sysc_wdiag_sec_msb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_sec_msb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10011" => 
            if (wb_we_i = '1') then
              sysc_wdiag_sec_lsb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_sec_lsb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10100" => 
            if (wb_we_i = '1') then
              sysc_wdiag_ns_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_ns_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10101" => 
            if (wb_we_i = '1') then
              sysc_wdiag_mu_msb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_mu_msb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10110" => 
            if (wb_we_i = '1') then
              sysc_wdiag_mu_lsb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_mu_lsb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "10111" => 
            if (wb_we_i = '1') then
              sysc_wdiag_dms_msb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_dms_msb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11000" => 
            if (wb_we_i = '1') then
              sysc_wdiag_dms_lsb_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_dms_lsb_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11001" => 
            if (wb_we_i = '1') then
              sysc_wdiag_asym_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_asym_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11010" => 
            if (wb_we_i = '1') then
              sysc_wdiag_cko_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_cko_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11011" => 
            if (wb_we_i = '1') then
              sysc_wdiag_setp_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_setp_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11100" => 
            if (wb_we_i = '1') then
              sysc_wdiag_ucnt_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_ucnt_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "11101" => 
            if (wb_we_i = '1') then
              sysc_wdiag_temp_int <= wrdata_reg(31 downto 0);
            end if;
            rddata_reg(31 downto 0) <= sysc_wdiag_temp_int;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when others =>
            -- prevent the slave from hanging the bus on invalid address
            ack_in_progress <= '1';
            ack_sreg(0) <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;


  -- Drive the data output bus
  wb_dat_o <= rddata_reg;
  -- Reset trigger
  -- pass-through field: Reset trigger in register: Syscon reset register
  sysc_rstr_trig_o <= wrdata_reg(27 downto 0);
  -- Reset line state value
  sysc_rstr_rst_o <= sysc_rstr_rst_int;
  -- Status LED
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpsr_led_stat_dly0 <= '0';
      sysc_gpsr_led_stat_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpsr_led_stat_dly0 <= sysc_gpsr_led_stat_int;
      sysc_gpsr_led_stat_o <= sysc_gpsr_led_stat_int and (not sysc_gpsr_led_stat_dly0);
    end if;
  end process;


  -- Link LED
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpsr_led_link_dly0 <= '0';
      sysc_gpsr_led_link_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpsr_led_link_dly0 <= sysc_gpsr_led_link_int;
      sysc_gpsr_led_link_o <= sysc_gpsr_led_link_int and (not sysc_gpsr_led_link_dly0);
    end if;
  end process;


  -- FMC I2C bitbanged SCL
  sysc_gpsr_fmc_scl_o <= wrdata_reg(2);
  -- FMC I2C bitbanged SDA
  sysc_gpsr_fmc_sda_o <= wrdata_reg(3);
  -- Network AP reset
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpsr_net_rst_dly0 <= '0';
      sysc_gpsr_net_rst_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpsr_net_rst_dly0 <= sysc_gpsr_net_rst_int;
      sysc_gpsr_net_rst_o <= sysc_gpsr_net_rst_int and (not sysc_gpsr_net_rst_dly0);
    end if;
  end process;


  -- SPEC Pushbutton 1 state
  -- SPEC Pushbutton 2 state
  -- SFP detect (MOD_DEF0 signal)
  -- SFP I2C bitbanged SCL
  sysc_gpsr_sfp_scl_o <= wrdata_reg(8);
  -- SFP I2C bitbanged SDA
  sysc_gpsr_sfp_sda_o <= wrdata_reg(9);
  -- SPI bitbanged SCLK
  sysc_gpsr_spi_sclk_o <= wrdata_reg(10);
  -- SPI bitbanged NCS
  sysc_gpsr_spi_ncs_o <= wrdata_reg(11);
  -- SPI bitbanged MOSI
  sysc_gpsr_spi_mosi_o <= wrdata_reg(12);
  -- SPI bitbanged MISO
  -- Status LED
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_led_stat_dly0 <= '0';
      sysc_gpcr_led_stat_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_led_stat_dly0 <= sysc_gpcr_led_stat_int;
      sysc_gpcr_led_stat_o <= sysc_gpcr_led_stat_int and (not sysc_gpcr_led_stat_dly0);
    end if;
  end process;


  -- Link LED
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_led_link_dly0 <= '0';
      sysc_gpcr_led_link_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_led_link_dly0 <= sysc_gpcr_led_link_int;
      sysc_gpcr_led_link_o <= sysc_gpcr_led_link_int and (not sysc_gpcr_led_link_dly0);
    end if;
  end process;


  -- FMC I2C bitbanged SCL
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_fmc_scl_dly0 <= '0';
      sysc_gpcr_fmc_scl_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_fmc_scl_dly0 <= sysc_gpcr_fmc_scl_int;
      sysc_gpcr_fmc_scl_o <= sysc_gpcr_fmc_scl_int and (not sysc_gpcr_fmc_scl_dly0);
    end if;
  end process;


  -- FMC I2C bitbanged SDA
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_fmc_sda_dly0 <= '0';
      sysc_gpcr_fmc_sda_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_fmc_sda_dly0 <= sysc_gpcr_fmc_sda_int;
      sysc_gpcr_fmc_sda_o <= sysc_gpcr_fmc_sda_int and (not sysc_gpcr_fmc_sda_dly0);
    end if;
  end process;


  -- SFP I2C bitbanged SCL
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_sfp_scl_dly0 <= '0';
      sysc_gpcr_sfp_scl_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_sfp_scl_dly0 <= sysc_gpcr_sfp_scl_int;
      sysc_gpcr_sfp_scl_o <= sysc_gpcr_sfp_scl_int and (not sysc_gpcr_sfp_scl_dly0);
    end if;
  end process;


  -- FMC I2C bitbanged SDA
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_sfp_sda_dly0 <= '0';
      sysc_gpcr_sfp_sda_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_sfp_sda_dly0 <= sysc_gpcr_sfp_sda_int;
      sysc_gpcr_sfp_sda_o <= sysc_gpcr_sfp_sda_int and (not sysc_gpcr_sfp_sda_dly0);
    end if;
  end process;


  -- SPI bitbanged SCLK
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_spi_sclk_dly0 <= '0';
      sysc_gpcr_spi_sclk_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_spi_sclk_dly0 <= sysc_gpcr_spi_sclk_int;
      sysc_gpcr_spi_sclk_o <= sysc_gpcr_spi_sclk_int and (not sysc_gpcr_spi_sclk_dly0);
    end if;
  end process;


  -- SPI bitbanged CS
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_spi_cs_dly0 <= '0';
      sysc_gpcr_spi_cs_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_spi_cs_dly0 <= sysc_gpcr_spi_cs_int;
      sysc_gpcr_spi_cs_o <= sysc_gpcr_spi_cs_int and (not sysc_gpcr_spi_cs_dly0);
    end if;
  end process;


  -- SPI bitbanged MOSI
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sysc_gpcr_spi_mosi_dly0 <= '0';
      sysc_gpcr_spi_mosi_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sysc_gpcr_spi_mosi_dly0 <= sysc_gpcr_spi_mosi_int;
      sysc_gpcr_spi_mosi_o <= sysc_gpcr_spi_mosi_int and (not sysc_gpcr_spi_mosi_dly0);
    end if;
  end process;


  -- Memory size
  -- Board name
  -- Timer Divider
  -- Timer Enable
  sysc_tcr_enable_o <= sysc_tcr_enable_int;
  -- Timer Counter Value
  -- Ver
  -- Id
  -- Read/write words
  -- Read-only words
  -- Address
  sysc_diag_cr_adr_o <= wrdata_reg(15 downto 0);
  -- R/W
  sysc_diag_cr_rw_o <= sysc_diag_cr_rw_int;
  -- Data
  sysc_diag_dat_o <= wrdata_reg(31 downto 0);
  -- WR DIAG data valid
  sysc_wdiag_ctrl_data_valid_o <= sysc_wdiag_ctrl_data_valid_int;
  -- WR DIAG data snapshot
  -- WR valid
  sysc_wdiag_sstat_wr_mode_o <= sysc_wdiag_sstat_wr_mode_int;
  -- Servo State
  sysc_wdiag_sstat_servostate_o <= sysc_wdiag_sstat_servostate_int;
  -- Link Status
  sysc_wdiag_pstat_link_o <= sysc_wdiag_pstat_link_int;
  -- PLL Locked
  sysc_wdiag_pstat_locked_o <= sysc_wdiag_pstat_locked_int;
  -- PTP State
  sysc_wdiag_ptpstat_ptpstate_o <= sysc_wdiag_ptpstat_ptpstate_int;
  -- AUX channel
  sysc_wdiag_astat_aux_o <= sysc_wdiag_astat_aux_int;
  -- Data
  sysc_wdiag_txfcnt_o <= sysc_wdiag_txfcnt_int;
  -- Data
  sysc_wdiag_rxfcnt_o <= sysc_wdiag_rxfcnt_int;
  -- Data
  sysc_wdiag_sec_msb_o <= sysc_wdiag_sec_msb_int;
  -- Data
  sysc_wdiag_sec_lsb_o <= sysc_wdiag_sec_lsb_int;
  -- Data
  sysc_wdiag_ns_o <= sysc_wdiag_ns_int;
  -- Data
  sysc_wdiag_mu_msb_o <= sysc_wdiag_mu_msb_int;
  -- Data
  sysc_wdiag_mu_lsb_o <= sysc_wdiag_mu_lsb_int;
  -- Data
  sysc_wdiag_dms_msb_o <= sysc_wdiag_dms_msb_int;
  -- Data
  sysc_wdiag_dms_lsb_o <= sysc_wdiag_dms_lsb_int;
  -- Data
  sysc_wdiag_asym_o <= sysc_wdiag_asym_int;
  -- Data
  sysc_wdiag_cko_o <= sysc_wdiag_cko_int;
  -- Data
  sysc_wdiag_setp_o <= sysc_wdiag_setp_int;
  -- Data
  sysc_wdiag_ucnt_o <= sysc_wdiag_ucnt_int;
  -- Data
  sysc_wdiag_temp_o <= sysc_wdiag_temp_int;
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
