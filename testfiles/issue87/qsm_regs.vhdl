library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity qsm_regs is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- Control register
    -- Send the Reset state to DIM
    regs_0_control_reset_o : out   std_logic;
    -- Trigger DIM readout
    regs_0_control_trig_o : out   std_logic;
    -- Address of last DIM register (number of registers - 1)
    regs_0_control_last_reg_adr_o : out   std_logic_vector(3 downto 0);
    -- Maximum number of devices present on line
    regs_0_control_max_dim_no_o : out   std_logic_vector(3 downto 0);
    -- Delay between consecutive register reads in microseconds (usually 512 us)
    regs_0_control_read_delay_o : out   std_logic_vector(9 downto 0);

    -- Status register
    -- QSPI master is busy (either in RESET or READOUT)
    regs_0_status_busy_i : in    std_logic;
    -- QSPI master has finished DIM readout
    regs_0_status_done_i : in    std_logic;
    -- Too many devices on DIM line (more than set by 'max_dim_no' register)
    regs_0_status_err_many_i : in    std_logic;
    -- Detected error on QSPI fb line
    regs_0_status_err_fb_i : in    std_logic;
    -- Detected number of DIM devices (can be lower than 'max_dim_no')
    regs_0_status_dim_count_i : in    std_logic_vector(3 downto 0);

    -- Control register
    -- Send the Reset state to DIM
    regs_1_control_reset_o : out   std_logic;
    -- Trigger DIM readout
    regs_1_control_trig_o : out   std_logic;
    -- Address of last DIM register (number of registers - 1)
    regs_1_control_last_reg_adr_o : out   std_logic_vector(3 downto 0);
    -- Maximum number of devices present on line
    regs_1_control_max_dim_no_o : out   std_logic_vector(3 downto 0);
    -- Delay between consecutive register reads in microseconds (usually 512 us)
    regs_1_control_read_delay_o : out   std_logic_vector(9 downto 0);

    -- Status register
    -- QSPI master is busy (either in RESET or READOUT)
    regs_1_status_busy_i : in    std_logic;
    -- QSPI master has finished DIM readout
    regs_1_status_done_i : in    std_logic;
    -- Too many devices on DIM line (more than set by 'max_dim_no' register)
    regs_1_status_err_many_i : in    std_logic;
    -- Detected error on QSPI fb line
    regs_1_status_err_fb_i : in    std_logic;
    -- Detected number of DIM devices (can be lower than 'max_dim_no')
    regs_1_status_dim_count_i : in    std_logic_vector(3 downto 0);

    -- SRAM bus memory_0_mem_readout
    memory_0_mem_readout_addr_o : out   std_logic_vector(8 downto 2);
    memory_0_mem_readout_data_i : in    std_logic_vector(15 downto 0);

    -- SRAM bus memory_1_mem_readout
    memory_1_mem_readout_addr_o : out   std_logic_vector(8 downto 2);
    memory_1_mem_readout_data_i : in    std_logic_vector(15 downto 0)
  );
end qsm_regs;

architecture syn of qsm_regs is
  signal adr_int                        : std_logic_vector(10 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal regs_0_control_reset_reg       : std_logic;
  signal regs_0_control_trig_reg        : std_logic;
  signal regs_0_control_last_reg_adr_reg : std_logic_vector(3 downto 0);
  signal regs_0_control_max_dim_no_reg  : std_logic_vector(3 downto 0);
  signal regs_0_control_read_delay_reg  : std_logic_vector(9 downto 0);
  signal regs_0_control_wreq            : std_logic;
  signal regs_0_control_wack            : std_logic;
  signal regs_1_control_reset_reg       : std_logic;
  signal regs_1_control_trig_reg        : std_logic;
  signal regs_1_control_last_reg_adr_reg : std_logic_vector(3 downto 0);
  signal regs_1_control_max_dim_no_reg  : std_logic_vector(3 downto 0);
  signal regs_1_control_read_delay_reg  : std_logic_vector(9 downto 0);
  signal regs_1_control_wreq            : std_logic;
  signal regs_1_control_wack            : std_logic;
  signal memory_0_mem_readout_rack      : std_logic;
  signal memory_0_mem_readout_re        : std_logic;
  signal memory_1_mem_readout_rack      : std_logic;
  signal memory_1_mem_readout_re        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(10 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(10 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wb_o.dat <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb_i.dat;
      end if;
    end if;
  end process;

  -- Register regs_0_control
  regs_0_control_reset_o <= regs_0_control_reset_reg;
  regs_0_control_trig_o <= regs_0_control_trig_reg;
  regs_0_control_last_reg_adr_o <= regs_0_control_last_reg_adr_reg;
  regs_0_control_max_dim_no_o <= regs_0_control_max_dim_no_reg;
  regs_0_control_read_delay_o <= regs_0_control_read_delay_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        regs_0_control_reset_reg <= '0';
        regs_0_control_trig_reg <= '0';
        regs_0_control_last_reg_adr_reg <= "0000";
        regs_0_control_max_dim_no_reg <= "0000";
        regs_0_control_read_delay_reg <= "0000000000";
        regs_0_control_wack <= '0';
      else
        if regs_0_control_wreq = '1' then
          regs_0_control_reset_reg <= wr_dat_d0(0);
          regs_0_control_trig_reg <= wr_dat_d0(1);
          regs_0_control_last_reg_adr_reg <= wr_dat_d0(5 downto 2);
          regs_0_control_max_dim_no_reg <= wr_dat_d0(9 downto 6);
          regs_0_control_read_delay_reg <= wr_dat_d0(19 downto 10);
        else
          regs_0_control_reset_reg <= '0';
          regs_0_control_trig_reg <= '0';
        end if;
        regs_0_control_wack <= regs_0_control_wreq;
      end if;
    end if;
  end process;

  -- Register regs_0_status

  -- Register regs_1_control
  regs_1_control_reset_o <= regs_1_control_reset_reg;
  regs_1_control_trig_o <= regs_1_control_trig_reg;
  regs_1_control_last_reg_adr_o <= regs_1_control_last_reg_adr_reg;
  regs_1_control_max_dim_no_o <= regs_1_control_max_dim_no_reg;
  regs_1_control_read_delay_o <= regs_1_control_read_delay_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        regs_1_control_reset_reg <= '0';
        regs_1_control_trig_reg <= '0';
        regs_1_control_last_reg_adr_reg <= "0000";
        regs_1_control_max_dim_no_reg <= "0000";
        regs_1_control_read_delay_reg <= "0000000000";
        regs_1_control_wack <= '0';
      else
        if regs_1_control_wreq = '1' then
          regs_1_control_reset_reg <= wr_dat_d0(0);
          regs_1_control_trig_reg <= wr_dat_d0(1);
          regs_1_control_last_reg_adr_reg <= wr_dat_d0(5 downto 2);
          regs_1_control_max_dim_no_reg <= wr_dat_d0(9 downto 6);
          regs_1_control_read_delay_reg <= wr_dat_d0(19 downto 10);
        else
          regs_1_control_reset_reg <= '0';
          regs_1_control_trig_reg <= '0';
        end if;
        regs_1_control_wack <= regs_1_control_wreq;
      end if;
    end if;
  end process;

  -- Register regs_1_status

  -- Interface memory_0_mem_readout
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        memory_0_mem_readout_rack <= '0';
      else
        memory_0_mem_readout_rack <= memory_0_mem_readout_re and not memory_0_mem_readout_rack;
      end if;
    end if;
  end process;
  memory_0_mem_readout_addr_o <= adr_int(8 downto 2);

  -- Interface memory_1_mem_readout
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        memory_1_mem_readout_rack <= '0';
      else
        memory_1_mem_readout_rack <= memory_1_mem_readout_re and not memory_1_mem_readout_rack;
      end if;
    end if;
  end process;
  memory_1_mem_readout_addr_o <= adr_int(8 downto 2);

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, regs_0_control_wack, regs_1_control_wack) begin
    regs_0_control_wreq <= '0';
    regs_1_control_wreq <= '0';
    case wr_adr_d0(10 downto 9) is
    when "00" =>
      case wr_adr_d0(8 downto 2) is
      when "0000000" =>
        -- Reg regs_0_control
        regs_0_control_wreq <= wr_req_d0;
        wr_ack_int <= regs_0_control_wack;
      when "0000001" =>
        -- Reg regs_0_status
        wr_ack_int <= wr_req_d0;
      when "0000010" =>
        -- Reg regs_1_control
        regs_1_control_wreq <= wr_req_d0;
        wr_ack_int <= regs_1_control_wack;
      when "0000011" =>
        -- Reg regs_1_status
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" =>
      -- Memory memory_0_mem_readout
      wr_ack_int <= wr_req_d0;
    when "11" =>
      -- Memory memory_1_mem_readout
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, regs_0_control_last_reg_adr_reg,
           regs_0_control_max_dim_no_reg, regs_0_control_read_delay_reg,
           regs_0_status_busy_i, regs_0_status_done_i,
           regs_0_status_err_many_i, regs_0_status_err_fb_i,
           regs_0_status_dim_count_i, regs_1_control_last_reg_adr_reg,
           regs_1_control_max_dim_no_reg, regs_1_control_read_delay_reg,
           regs_1_status_busy_i, regs_1_status_done_i,
           regs_1_status_err_many_i, regs_1_status_err_fb_i,
           regs_1_status_dim_count_i, memory_0_mem_readout_data_i,
           memory_0_mem_readout_rack, memory_1_mem_readout_data_i,
           memory_1_mem_readout_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    memory_0_mem_readout_re <= '0';
    memory_1_mem_readout_re <= '0';
    case adr_int(10 downto 9) is
    when "00" =>
      case adr_int(8 downto 2) is
      when "0000000" =>
        -- Reg regs_0_control
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= '0';
        rd_dat_d0(5 downto 2) <= regs_0_control_last_reg_adr_reg;
        rd_dat_d0(9 downto 6) <= regs_0_control_max_dim_no_reg;
        rd_dat_d0(19 downto 10) <= regs_0_control_read_delay_reg;
        rd_dat_d0(31 downto 20) <= (others => '0');
      when "0000001" =>
        -- Reg regs_0_status
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= regs_0_status_busy_i;
        rd_dat_d0(1) <= regs_0_status_done_i;
        rd_dat_d0(2) <= regs_0_status_err_many_i;
        rd_dat_d0(3) <= regs_0_status_err_fb_i;
        rd_dat_d0(7 downto 4) <= regs_0_status_dim_count_i;
        rd_dat_d0(31 downto 8) <= (others => '0');
      when "0000010" =>
        -- Reg regs_1_control
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= '0';
        rd_dat_d0(1) <= '0';
        rd_dat_d0(5 downto 2) <= regs_1_control_last_reg_adr_reg;
        rd_dat_d0(9 downto 6) <= regs_1_control_max_dim_no_reg;
        rd_dat_d0(19 downto 10) <= regs_1_control_read_delay_reg;
        rd_dat_d0(31 downto 20) <= (others => '0');
      when "0000011" =>
        -- Reg regs_1_status
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= regs_1_status_busy_i;
        rd_dat_d0(1) <= regs_1_status_done_i;
        rd_dat_d0(2) <= regs_1_status_err_many_i;
        rd_dat_d0(3) <= regs_1_status_err_fb_i;
        rd_dat_d0(7 downto 4) <= regs_1_status_dim_count_i;
        rd_dat_d0(31 downto 8) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" =>
      -- Memory memory_0_mem_readout
      rd_dat_d0(15 downto 0) <= memory_0_mem_readout_data_i;
      rd_ack_d0 <= memory_0_mem_readout_rack;
      memory_0_mem_readout_re <= rd_req_int;
    when "11" =>
      -- Memory memory_1_mem_readout
      rd_dat_d0(15 downto 0) <= memory_1_mem_readout_data_i;
      rd_ack_d0 <= memory_1_mem_readout_rack;
      memory_1_mem_readout_re <= rd_req_int;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
