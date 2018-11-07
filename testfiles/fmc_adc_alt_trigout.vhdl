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

    -- Set when WR is enabled
    wr_enable_i          : in    std_logic;

    -- WR link status
    wr_link_i            : in    std_logic;

    -- Set when WR time is valid
    wr_valid_i           : in    std_logic;

    -- Set when the timestamp fifo is not empty
    ts_present_i         : in    std_logic;

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

    -- Cycles
    cycles_i             : in    std_logic_vector(27 downto 0);
    ts_cycles_rd_o       : out   std_logic
  );
end alt_trigout;

architecture syn of alt_trigout is
  signal wb_en                          : std_logic;
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal ack_int                        : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal ch1_enable_reg                 : std_logic;
  signal ch2_enable_reg                 : std_logic;
  signal ch3_enable_reg                 : std_logic;
  signal ch4_enable_reg                 : std_logic;
  signal ext_enable_reg                 : std_logic;
  signal wr_ack_done_int                : std_logic;
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_i.cyc and wb_i.stb;
  rd_int <= wb_en and not wb_i.we;
  wr_int <= wb_en and wb_i.we;
  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- Assign outputs
  ch1_enable_o <= ch1_enable_reg;
  ch2_enable_o <= ch2_enable_reg;
  ch3_enable_o <= ch3_enable_reg;
  ch4_enable_o <= ch4_enable_reg;
  ext_enable_o <= ext_enable_reg;

  -- Process for write requests.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      ch1_enable_reg <= '0';
      ch2_enable_reg <= '0';
      ch3_enable_reg <= '0';
      ch4_enable_reg <= '0';
      ext_enable_reg <= '0';
    elsif rising_edge(clk_i) then
      if wr_int = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case wb_i.adr(4 downto 3) is
        when "00" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register status
            wr_ack_int <= not wr_ack_done_int;
          when "1" => 
            -- Register ctrl
            ch1_enable_reg <= wb_i.dat(0);
            ch2_enable_reg <= wb_i.dat(1);
            ch3_enable_reg <= wb_i.dat(2);
            ch4_enable_reg <= wb_i.dat(3);
            ext_enable_reg <= wb_i.dat(8);
            wr_ack_int <= not wr_ack_done_int;
          when others =>
          end case;
        when "01" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register ts_mask_sec
            wr_ack_int <= not wr_ack_done_int;
          when "1" => 
            -- Register ts_mask_sec
            wr_ack_int <= not wr_ack_done_int;
          when others =>
            wr_ack_int <= not wr_ack_done_int;
          end case;
        when "10" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register ts_cycles
            wr_ack_int <= not wr_ack_done_int;
          when others =>
            wr_ack_int <= not wr_ack_done_int;
          end case;
        when others =>
        end case;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
      ts_cycles_rd_o <= '0';
    elsif rising_edge(clk_i) then
      ts_cycles_rd_o <= '0';
      if rd_int = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        case wb_i.adr(4 downto 3) is
        when "00" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- status
            reg_rdat_int(0) <= wr_enable_i;
            reg_rdat_int(1) <= wr_link_i;
            reg_rdat_int(2) <= wr_valid_i;
            reg_rdat_int(8) <= ts_present_i;
          when "1" => 
            -- ctrl
            reg_rdat_int(0) <= ch1_enable_reg;
            reg_rdat_int(1) <= ch2_enable_reg;
            reg_rdat_int(2) <= ch3_enable_reg;
            reg_rdat_int(3) <= ch4_enable_reg;
            reg_rdat_int(8) <= ext_enable_reg;
          when others =>
          end case;
        when "01" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- ts_mask_sec
            reg_rdat_int(7 downto 0) <= ts_sec_i(39 downto 32);
            reg_rdat_int(16) <= ch1_mask_i;
            reg_rdat_int(17) <= ch2_mask_i;
            reg_rdat_int(18) <= ch3_mask_i;
            reg_rdat_int(19) <= ch4_mask_i;
            reg_rdat_int(24) <= ext_mask_i;
          when "1" => 
            -- ts_mask_sec
            reg_rdat_int <= ts_sec_i(31 downto 0);
          when others =>
          end case;
        when "10" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- ts_cycles
            reg_rdat_int(27 downto 0) <= cycles_i;
            ts_cycles_rd_o <= '1';
          when others =>
          end case;
        when others =>
        end case;
      else
        rd_ack1_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (wb_i.adr, reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    wb_o.dat <= (others => '0');
    rd_ack_int <= '1';
    case wb_i.adr(4 downto 3) is
    when "00" => 
      case wb_i.adr(2 downto 2) is
      when "0" => 
        -- status
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "1" => 
        -- ctrl
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when "01" => 
      case wb_i.adr(2 downto 2) is
      when "0" => 
        -- ts_mask_sec
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "1" => 
        -- ts_mask_sec
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when "10" => 
      case wb_i.adr(2 downto 2) is
      when "0" => 
        -- ts_cycles
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when others =>
    end case;
  end process;
end syn;
