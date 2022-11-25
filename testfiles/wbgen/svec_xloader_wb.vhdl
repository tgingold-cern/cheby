library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity svec_xloader_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_adr_i             : in    std_logic_vector(2 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    -- Port for MONOSTABLE field: 'Start configuration' in reg: 'Control/status register'
    sxldr_csr_start_o    : out   std_logic;
    -- Port for BIT field: 'Configuration done' in reg: 'Control/status register'
    sxldr_csr_done_i     : in    std_logic;
    -- Port for BIT field: 'Configuration error' in reg: 'Control/status register'
    sxldr_csr_error_i    : in    std_logic;
    -- Port for BIT field: 'Loader busy' in reg: 'Control/status register'
    sxldr_csr_busy_i     : in    std_logic;
    -- Port for BIT field: 'Byte order select' in reg: 'Control/status register'
    sxldr_csr_msbf_o     : out   std_logic;
    -- Port for MONOSTABLE field: 'Software resest' in reg: 'Control/status register'
    sxldr_csr_swrst_o    : out   std_logic;
    -- Port for MONOSTABLE field: 'Exit bootloader mode' in reg: 'Control/status register'
    sxldr_csr_exit_o     : out   std_logic;
    -- Port for std_logic_vector field: 'Serial clock divider' in reg: 'Control/status register'
    sxldr_csr_clkdiv_o   : out   std_logic_vector(5 downto 0);
    -- Ports for PASS_THROUGH field: 'Trigger Sequence Input' in reg: 'Bootloader Trigger Register'
    sxldr_btrigr_value_o : out   std_logic_vector(7 downto 0);
    sxldr_btrigr_value_wr_o : out   std_logic;
    -- Port for std_logic_vector field: 'SPI Data' in reg: 'Flash Access Register'
    sxldr_far_data_o     : out   std_logic_vector(7 downto 0);
    sxldr_far_data_i     : in    std_logic_vector(7 downto 0);
    sxldr_far_data_load_o : out   std_logic;
    -- Port for BIT field: 'SPI Start Transfer' in reg: 'Flash Access Register'
    sxldr_far_xfer_o     : out   std_logic;
    -- Port for BIT field: 'SPI Ready' in reg: 'Flash Access Register'
    sxldr_far_ready_i    : in    std_logic;
    -- Port for BIT field: 'SPI Chip Select' in reg: 'Flash Access Register'
    sxldr_far_cs_o       : out   std_logic;
    -- Port for std_logic_vector field: 'Identification code' in reg: 'ID Register'
    sxldr_idr_i          : in    std_logic_vector(31 downto 0);
    -- FIFO read request
    sxldr_fifo_rd_req_i  : in    std_logic;
    -- FIFO full flag
    sxldr_fifo_rd_full_o : out   std_logic;
    -- FIFO empty flag
    sxldr_fifo_rd_empty_o : out   std_logic;
    sxldr_fifo_xsize_o   : out   std_logic_vector(1 downto 0);
    sxldr_fifo_xlast_o   : out   std_logic;
    sxldr_fifo_xdata_o   : out   std_logic_vector(31 downto 0)
  );
end svec_xloader_wb;

architecture syn of svec_xloader_wb is

  signal sxldr_csr_start_dly0           : std_logic;
  signal sxldr_csr_start_int            : std_logic;
  signal sxldr_csr_msbf_int             : std_logic;
  signal sxldr_csr_swrst_dly0           : std_logic;
  signal sxldr_csr_swrst_int            : std_logic;
  signal sxldr_csr_exit_dly0            : std_logic;
  signal sxldr_csr_exit_int             : std_logic;
  signal sxldr_csr_clkdiv_int           : std_logic_vector(5 downto 0);
  signal sxldr_far_xfer_int             : std_logic;
  signal sxldr_far_cs_int               : std_logic;
  signal sxldr_fifo_rst_n               : std_logic;
  signal sxldr_fifo_in_int              : std_logic_vector(34 downto 0);
  signal sxldr_fifo_out_int             : std_logic_vector(34 downto 0);
  signal sxldr_fifo_wrreq_int           : std_logic;
  signal sxldr_fifo_full_int            : std_logic;
  signal sxldr_fifo_empty_int           : std_logic;
  signal sxldr_fifo_clear_bus_int       : std_logic;
  signal sxldr_fifo_usedw_int           : std_logic_vector(7 downto 0);
  signal ack_sreg                       : std_logic_vector(9 downto 0);
  signal rddata_reg                     : std_logic_vector(31 downto 0);
  signal wrdata_reg                     : std_logic_vector(31 downto 0);
  signal bwsel_reg                      : std_logic_vector(3 downto 0);
  signal rwaddr_reg                     : std_logic_vector(2 downto 0);
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
      sxldr_csr_start_int <= '0';
      sxldr_csr_msbf_int <= '0';
      sxldr_csr_swrst_int <= '0';
      sxldr_csr_exit_int <= '0';
      sxldr_csr_clkdiv_int <= "000000";
      sxldr_btrigr_value_wr_o <= '0';
      sxldr_far_data_load_o <= '0';
      sxldr_far_xfer_int <= '0';
      sxldr_far_cs_int <= '0';
      sxldr_fifo_clear_bus_int <= '0';
      sxldr_fifo_wrreq_int <= '0';
    elsif rising_edge(clk_sys_i) then
      -- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          sxldr_csr_start_int <= '0';
          sxldr_csr_swrst_int <= '0';
          sxldr_csr_exit_int <= '0';
          sxldr_btrigr_value_wr_o <= '0';
          sxldr_far_data_load_o <= '0';
          sxldr_fifo_wrreq_int <= '0';
          sxldr_fifo_clear_bus_int <= '0';
          ack_in_progress <= '0';
        else
          sxldr_btrigr_value_wr_o <= '0';
          sxldr_far_data_load_o <= '0';
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          case rwaddr_reg(2 downto 0) is
          when "000" =>
            if (wb_we_i = '1') then
              sxldr_csr_start_int <= wrdata_reg(0);
              sxldr_csr_msbf_int <= wrdata_reg(4);
              sxldr_csr_swrst_int <= wrdata_reg(5);
              sxldr_csr_exit_int <= wrdata_reg(6);
              sxldr_csr_clkdiv_int <= wrdata_reg(13 downto 8);
            end if;
            rddata_reg(0) <= '0';
            rddata_reg(1) <= sxldr_csr_done_i;
            rddata_reg(2) <= sxldr_csr_error_i;
            rddata_reg(3) <= sxldr_csr_busy_i;
            rddata_reg(4) <= sxldr_csr_msbf_int;
            rddata_reg(5) <= '0';
            rddata_reg(6) <= '0';
            rddata_reg(13 downto 8) <= sxldr_csr_clkdiv_int;
            rddata_reg(21 downto 14) <= "00000011";
            rddata_reg(7) <= 'X';
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
          when "001" =>
            if (wb_we_i = '1') then
              sxldr_btrigr_value_wr_o <= '1';
            end if;
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
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "010" =>
            if (wb_we_i = '1') then
              sxldr_far_data_load_o <= '1';
              sxldr_far_xfer_int <= wrdata_reg(8);
              sxldr_far_cs_int <= wrdata_reg(10);
            end if;
            rddata_reg(7 downto 0) <= sxldr_far_data_i;
            rddata_reg(8) <= sxldr_far_xfer_int;
            rddata_reg(9) <= sxldr_far_ready_i;
            rddata_reg(10) <= sxldr_far_cs_int;
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
          when "011" =>
            if (wb_we_i = '1') then
            end if;
            rddata_reg(31 downto 0) <= sxldr_idr_i;
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "100" =>
            if (wb_we_i = '1') then
              sxldr_fifo_in_int(1 downto 0) <= wrdata_reg(1 downto 0);
              sxldr_fifo_in_int(2) <= wrdata_reg(2);
            end if;
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
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "101" =>
            if (wb_we_i = '1') then
              sxldr_fifo_in_int(34 downto 3) <= wrdata_reg(31 downto 0);
              sxldr_fifo_wrreq_int <= '1';
            end if;
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
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when "110" =>
            if (wb_we_i = '1') then
              if (wrdata_reg(18) = '1') then
                sxldr_fifo_clear_bus_int <= '1';
              end if;
            end if;
            rddata_reg(16) <= sxldr_fifo_full_int;
            rddata_reg(17) <= sxldr_fifo_empty_int;
            rddata_reg(18) <= '0';
            rddata_reg(7 downto 0) <= sxldr_fifo_usedw_int;
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
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
  -- Start configuration
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sxldr_csr_start_dly0 <= '0';
      sxldr_csr_start_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sxldr_csr_start_dly0 <= sxldr_csr_start_int;
      sxldr_csr_start_o <= sxldr_csr_start_int and (not sxldr_csr_start_dly0);
    end if;
  end process;


  -- Configuration done
  -- Configuration error
  -- Loader busy
  -- Byte order select
  sxldr_csr_msbf_o <= sxldr_csr_msbf_int;
  -- Software resest
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sxldr_csr_swrst_dly0 <= '0';
      sxldr_csr_swrst_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sxldr_csr_swrst_dly0 <= sxldr_csr_swrst_int;
      sxldr_csr_swrst_o <= sxldr_csr_swrst_int and (not sxldr_csr_swrst_dly0);
    end if;
  end process;


  -- Exit bootloader mode
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      sxldr_csr_exit_dly0 <= '0';
      sxldr_csr_exit_o <= '0';
    elsif rising_edge(clk_sys_i) then
      sxldr_csr_exit_dly0 <= sxldr_csr_exit_int;
      sxldr_csr_exit_o <= sxldr_csr_exit_int and (not sxldr_csr_exit_dly0);
    end if;
  end process;


  -- Serial clock divider
  sxldr_csr_clkdiv_o <= sxldr_csr_clkdiv_int;
  -- Trigger Sequence Input
  -- pass-through field: Trigger Sequence Input in register: Bootloader Trigger Register
  sxldr_btrigr_value_o <= wrdata_reg(7 downto 0);
  -- SPI Data
  sxldr_far_data_o <= wrdata_reg(7 downto 0);
  -- SPI Start Transfer
  sxldr_far_xfer_o <= sxldr_far_xfer_int;
  -- SPI Ready
  -- SPI Chip Select
  sxldr_far_cs_o <= sxldr_far_cs_int;
  -- Identification code
  -- extra code for reg/fifo/mem: Bitstream FIFO
  sxldr_fifo_xsize_o <= sxldr_fifo_out_int(1 downto 0);
  sxldr_fifo_xlast_o <= sxldr_fifo_out_int(2);
  sxldr_fifo_xdata_o <= sxldr_fifo_out_int(34 downto 3);
  sxldr_fifo_rst_n <= rst_n_i and (not sxldr_fifo_clear_bus_int);
  sxldr_fifo_INST: wbgen2_fifo_sync
    generic map (
      g_size               => 256,
      g_width              => 35,
      g_usedw_size         => 8
    )
    port map (
      rd_req_i             => sxldr_fifo_rd_req_i,
      rd_full_o            => sxldr_fifo_rd_full_o,
      rd_empty_o           => sxldr_fifo_rd_empty_o,
      wr_full_o            => sxldr_fifo_full_int,
      wr_empty_o           => sxldr_fifo_empty_int,
      wr_usedw_o           => sxldr_fifo_usedw_int,
      wr_req_i             => sxldr_fifo_wrreq_int,
      rst_n_i              => sxldr_fifo_rst_n,
      clk_i                => clk_sys_i,
      wr_data_i            => sxldr_fifo_in_int,
      rd_data_o            => sxldr_fifo_out_int
    );
  
  -- extra code for reg/fifo/mem: FIFO 'Bitstream FIFO' data input register 0
  -- extra code for reg/fifo/mem: FIFO 'Bitstream FIFO' data input register 1
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
