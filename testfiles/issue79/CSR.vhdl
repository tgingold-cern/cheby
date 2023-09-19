library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity csr is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(15 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- Board identifier
    ident_i              : in    std_logic_vector(63 downto 0);

    -- Firmware version
    version_i            : in    std_logic_vector(31 downto 0);

    -- Calibrator control bits
    -- Calibrator/ADC select: 00=C1/A1, 01=C2/A2, 10=C1+2/A1, 11=C1+2/A2
    cal_ctrl_cal_sel_o   : out   std_logic_vector(1 downto 0);

    -- OpenCores I2C Master
    i2c_master_cyc_o     : out   std_logic;
    i2c_master_stb_o     : out   std_logic;
    i2c_master_adr_o     : out   std_logic_vector(4 downto 2);
    i2c_master_sel_o     : out   std_logic_vector(3 downto 0);
    i2c_master_we_o      : out   std_logic;
    i2c_master_dat_o     : out   std_logic_vector(31 downto 0);
    i2c_master_ack_i     : in    std_logic;
    i2c_master_err_i     : in    std_logic;
    i2c_master_rty_i     : in    std_logic;
    i2c_master_stall_i   : in    std_logic;
    i2c_master_dat_i     : in    std_logic_vector(31 downto 0);

    -- RAM port for adc_offs
    adc_offs_adr_i       : in    std_logic_vector(11 downto 0);
    adc_offs_data_we_i   : in    std_logic;
    adc_offs_data_dat_i  : in    std_logic_vector(31 downto 0);

    -- RAM port for adc_meas
    adc_meas_adr_i       : in    std_logic_vector(11 downto 0);
    adc_meas_data_we_i   : in    std_logic;
    adc_meas_data_dat_i  : in    std_logic_vector(31 downto 0)
  );
end csr;

architecture syn of csr is
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal cal_ctrl_cal_sel_reg           : std_logic_vector(1 downto 0);
  signal cal_ctrl_wreq                  : std_logic;
  signal cal_ctrl_wack                  : std_logic;
  signal i2c_master_re                  : std_logic;
  signal i2c_master_we                  : std_logic;
  signal i2c_master_wt                  : std_logic;
  signal i2c_master_rt                  : std_logic;
  signal i2c_master_tr                  : std_logic;
  signal i2c_master_wack                : std_logic;
  signal i2c_master_rack                : std_logic;
  signal adc_offs_data_int_dato         : std_logic_vector(31 downto 0);
  signal adc_offs_data_ext_dat          : std_logic_vector(31 downto 0);
  signal adc_offs_data_rreq             : std_logic;
  signal adc_offs_data_rack             : std_logic;
  signal adc_meas_data_int_dato         : std_logic_vector(31 downto 0);
  signal adc_meas_data_ext_dat          : std_logic_vector(31 downto 0);
  signal adc_meas_data_rreq             : std_logic;
  signal adc_meas_data_rack             : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(15 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
  signal adc_offs_sel_int               : std_logic_vector(3 downto 0);
  signal adc_meas_sel_int               : std_logic_vector(3 downto 0);
begin

  -- WB decode signals
  process (wb_sel_i) begin
    wr_sel(7 downto 0) <= (others => wb_sel_i(0));
    wr_sel(15 downto 8) <= (others => wb_sel_i(1));
    wr_sel(23 downto 16) <= (others => wb_sel_i(2));
    wr_sel(31 downto 24) <= (others => wb_sel_i(3));
  end process;
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Register ident

  -- Register version

  -- Register cal_ctrl
  cal_ctrl_cal_sel_o <= cal_ctrl_cal_sel_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        cal_ctrl_cal_sel_reg <= "00";
        cal_ctrl_wack <= '0';
      else
        if cal_ctrl_wreq = '1' then
          cal_ctrl_cal_sel_reg <= wr_dat_d0(1 downto 0);
        end if;
        cal_ctrl_wack <= cal_ctrl_wreq;
      end if;
    end if;
  end process;

  -- Interface i2c_master
  i2c_master_tr <= i2c_master_wt or i2c_master_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        i2c_master_rt <= '0';
        i2c_master_wt <= '0';
      else
        i2c_master_rt <= (i2c_master_rt or i2c_master_re) and not i2c_master_rack;
        i2c_master_wt <= (i2c_master_wt or i2c_master_we) and not i2c_master_wack;
      end if;
    end if;
  end process;
  i2c_master_cyc_o <= i2c_master_tr;
  i2c_master_stb_o <= i2c_master_tr;
  i2c_master_wack <= i2c_master_ack_i and i2c_master_wt;
  i2c_master_rack <= i2c_master_ack_i and i2c_master_rt;
  i2c_master_adr_o <= wb_adr_i(4 downto 2);
  process (wr_sel_d0) begin
    i2c_master_sel_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      i2c_master_sel_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      i2c_master_sel_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      i2c_master_sel_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      i2c_master_sel_o(3) <= '1';
    end if;
  end process;
  i2c_master_we_o <= i2c_master_wt;
  i2c_master_dat_o <= wr_dat_d0;

  -- Memory adc_offs
  adc_offs_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 4096,
      g_addr_width         => 12,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => wb_adr_i(13 downto 2),
      bwsel_a_i            => adc_offs_sel_int,
      data_a_i             => (others => 'X'),
      data_a_o             => adc_offs_data_int_dato,
      rd_a_i               => adc_offs_data_rreq,
      wr_a_i               => '0',
      addr_b_i             => adc_offs_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => adc_offs_data_dat_i,
      data_b_o             => adc_offs_data_ext_dat,
      rd_b_i               => '0',
      wr_b_i               => adc_offs_data_we_i
    );
  
  process (wr_sel_d0) begin
    adc_offs_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      adc_offs_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      adc_offs_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      adc_offs_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      adc_offs_sel_int(3) <= '1';
    end if;
  end process;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        adc_offs_data_rack <= '0';
      else
        adc_offs_data_rack <= adc_offs_data_rreq;
      end if;
    end if;
  end process;

  -- Memory adc_meas
  adc_meas_data_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 4096,
      g_addr_width         => 12,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => wb_adr_i(13 downto 2),
      bwsel_a_i            => adc_meas_sel_int,
      data_a_i             => (others => 'X'),
      data_a_o             => adc_meas_data_int_dato,
      rd_a_i               => adc_meas_data_rreq,
      wr_a_i               => '0',
      addr_b_i             => adc_meas_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => adc_meas_data_dat_i,
      data_b_o             => adc_meas_data_ext_dat,
      rd_b_i               => '0',
      wr_b_i               => adc_meas_data_we_i
    );
  
  process (wr_sel_d0) begin
    adc_meas_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      adc_meas_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      adc_meas_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      adc_meas_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      adc_meas_sel_int(3) <= '1';
    end if;
  end process;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        adc_meas_data_rack <= '0';
      else
        adc_meas_data_rack <= adc_meas_data_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, cal_ctrl_wack, i2c_master_wack) begin
    cal_ctrl_wreq <= '0';
    i2c_master_we <= '0';
    case wr_adr_d0(15 downto 14) is
    when "00" =>
      case wr_adr_d0(13 downto 5) is
      when "000000000" =>
        case wr_adr_d0(4 downto 3) is
        when "00" =>
          case wr_adr_d0(2 downto 2) is
          when "0" =>
            -- Reg ident
            wr_ack_int <= wr_req_d0;
          when "1" =>
            -- Reg ident
            wr_ack_int <= wr_req_d0;
          when others =>
            wr_ack_int <= wr_req_d0;
          end case;
        when "01" =>
          case wr_adr_d0(2 downto 2) is
          when "0" =>
            -- Reg version
            wr_ack_int <= wr_req_d0;
          when "1" =>
            -- Reg cal_ctrl
            cal_ctrl_wreq <= wr_req_d0;
            wr_ack_int <= cal_ctrl_wack;
          when others =>
            wr_ack_int <= wr_req_d0;
          end case;
        when others =>
          wr_ack_int <= wr_req_d0;
        end case;
      when "000000001" =>
        -- Submap i2c_master
        i2c_master_we <= wr_req_d0;
        wr_ack_int <= i2c_master_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" =>
      -- Memory adc_offs
      wr_ack_int <= wr_req_d0;
    when "10" =>
      -- Memory adc_meas
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, ident_i, version_i, cal_ctrl_cal_sel_reg,
           i2c_master_dat_i, i2c_master_rack, adc_offs_data_int_dato,
           adc_offs_data_rack, adc_meas_data_int_dato, adc_meas_data_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    i2c_master_re <= '0';
    adc_offs_data_rreq <= '0';
    adc_meas_data_rreq <= '0';
    case wb_adr_i(15 downto 14) is
    when "00" =>
      case wb_adr_i(13 downto 5) is
      when "000000000" =>
        case wb_adr_i(4 downto 3) is
        when "00" =>
          case wb_adr_i(2 downto 2) is
          when "0" =>
            -- Reg ident
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= ident_i(63 downto 32);
          when "1" =>
            -- Reg ident
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= ident_i(31 downto 0);
          when others =>
            rd_ack_d0 <= rd_req_int;
          end case;
        when "01" =>
          case wb_adr_i(2 downto 2) is
          when "0" =>
            -- Reg version
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0 <= version_i;
          when "1" =>
            -- Reg cal_ctrl
            rd_ack_d0 <= rd_req_int;
            rd_dat_d0(1 downto 0) <= cal_ctrl_cal_sel_reg;
            rd_dat_d0(31 downto 2) <= (others => '0');
          when others =>
            rd_ack_d0 <= rd_req_int;
          end case;
        when others =>
          rd_ack_d0 <= rd_req_int;
        end case;
      when "000000001" =>
        -- Submap i2c_master
        i2c_master_re <= rd_req_int;
        rd_dat_d0 <= i2c_master_dat_i;
        rd_ack_d0 <= i2c_master_rack;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" =>
      -- Memory adc_offs
      rd_dat_d0 <= adc_offs_data_int_dato;
      adc_offs_data_rreq <= rd_req_int;
      rd_ack_d0 <= adc_offs_data_rack;
    when "10" =>
      -- Memory adc_meas
      rd_dat_d0 <= adc_meas_data_int_dato;
      adc_meas_data_rreq <= rd_req_int;
      rd_ack_d0 <= adc_meas_data_rack;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
