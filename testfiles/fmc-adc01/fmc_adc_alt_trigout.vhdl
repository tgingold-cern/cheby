library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity alt_trigout is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- Status register
    -- Set when WR is enabled
    wr_enable_i          : in    std_logic;
    -- WR link status
    wr_link_i            : in    std_logic;
    -- Set when WR time is valid
    wr_valid_i           : in    std_logic;
    -- Set when the timestamp fifo is not empty
    ts_present_i         : in    std_logic;

    -- Control register
    -- Enable channel 1 trigger
    ch1_enable_o         : out   std_logic;
    -- Enable channel 2 trigger
    ch2_enable_o         : out   std_logic;
    -- Enable channel 3 trigger
    ch3_enable_o         : out   std_logic;
    -- Enable channel 4 trigger
    ch4_enable_o         : out   std_logic;
    -- Enable external trigger
    ext_enable_o         : out   std_logic;

    -- Time (seconds) of the last event
    -- Seconds part of the timestamp
    ts_sec_i             : in    std_logic_vector(39 downto 0);
    -- Set if channel 1 triggered
    ch1_mask_i           : in    std_logic;
    -- Set if channel 2 triggered
    ch2_mask_i           : in    std_logic;
    -- Set if channel 3 triggered
    ch3_mask_i           : in    std_logic;
    -- Set if channel 4 triggered
    ch4_mask_i           : in    std_logic;
    -- Set if external trigger
    ext_mask_i           : in    std_logic;

    -- Reading this register discard the entry
    -- Cycles
    cycles_i             : in    std_logic_vector(27 downto 0);
    ts_cycles_rd_o       : out   std_logic
  );
end alt_trigout;

architecture syn of alt_trigout is
  signal adr_int                        : std_logic_vector(4 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal ch1_enable_reg                 : std_logic;
  signal ch2_enable_reg                 : std_logic;
  signal ch3_enable_reg                 : std_logic;
  signal ch4_enable_reg                 : std_logic;
  signal ext_enable_reg                 : std_logic;
  signal ctrl_wreq                      : std_logic;
  signal ctrl_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(4 downto 2);
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb_i.dat;
      end if;
    end if;
  end process;

  -- Register status

  -- Register ctrl
  ch1_enable_o <= ch1_enable_reg;
  ch2_enable_o <= ch2_enable_reg;
  ch3_enable_o <= ch3_enable_reg;
  ch4_enable_o <= ch4_enable_reg;
  ext_enable_o <= ext_enable_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ch1_enable_reg <= '0';
        ch2_enable_reg <= '0';
        ch3_enable_reg <= '0';
        ch4_enable_reg <= '0';
        ext_enable_reg <= '0';
        ctrl_wack <= '0';
      else
        if ctrl_wreq = '1' then
          ch1_enable_reg <= wr_dat_d0(0);
          ch2_enable_reg <= wr_dat_d0(1);
          ch3_enable_reg <= wr_dat_d0(2);
          ch4_enable_reg <= wr_dat_d0(3);
          ext_enable_reg <= wr_dat_d0(8);
        end if;
        ctrl_wack <= ctrl_wreq;
      end if;
    end if;
  end process;

  -- Register ts_mask_sec

  -- Register ts_cycles

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, ctrl_wack) begin
    ctrl_wreq <= '0';
    case wr_adr_d0(4 downto 3) is
    when "00" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg status
        wr_ack_int <= wr_req_d0;
      when "1" => 
        -- Reg ctrl
        ctrl_wreq <= wr_req_d0;
        wr_ack_int <= ctrl_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg ts_mask_sec
        wr_ack_int <= wr_req_d0;
      when "1" => 
        -- Reg ts_mask_sec
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg ts_cycles
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, wr_enable_i, wr_link_i, wr_valid_i, ts_present_i, ch1_enable_reg, ch2_enable_reg, ch3_enable_reg, ch4_enable_reg, ext_enable_reg, ts_sec_i, ch1_mask_i, ch2_mask_i, ch3_mask_i, ch4_mask_i, ext_mask_i, cycles_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ts_cycles_rd_o <= '0';
    case adr_int(4 downto 3) is
    when "00" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- Reg status
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= wr_enable_i;
        rd_dat_d0(1) <= wr_link_i;
        rd_dat_d0(2) <= wr_valid_i;
        rd_dat_d0(7 downto 3) <= (others => '0');
        rd_dat_d0(8) <= ts_present_i;
        rd_dat_d0(31 downto 9) <= (others => '0');
      when "1" => 
        -- Reg ctrl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= ch1_enable_reg;
        rd_dat_d0(1) <= ch2_enable_reg;
        rd_dat_d0(2) <= ch3_enable_reg;
        rd_dat_d0(3) <= ch4_enable_reg;
        rd_dat_d0(7 downto 4) <= (others => '0');
        rd_dat_d0(8) <= ext_enable_reg;
        rd_dat_d0(31 downto 9) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- Reg ts_mask_sec
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= ts_sec_i(39 downto 32);
        rd_dat_d0(15 downto 8) <= (others => '0');
        rd_dat_d0(16) <= ch1_mask_i;
        rd_dat_d0(17) <= ch2_mask_i;
        rd_dat_d0(18) <= ch3_mask_i;
        rd_dat_d0(19) <= ch4_mask_i;
        rd_dat_d0(23 downto 20) <= (others => '0');
        rd_dat_d0(24) <= ext_mask_i;
        rd_dat_d0(31 downto 25) <= (others => '0');
      when "1" => 
        -- Reg ts_mask_sec
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ts_sec_i(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- Reg ts_cycles
        ts_cycles_rd_o <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(27 downto 0) <= cycles_i;
        rd_dat_d0(31 downto 28) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
