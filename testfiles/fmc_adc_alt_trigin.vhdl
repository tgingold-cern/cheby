library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity alt_trigin is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- Enable trigger, cleared when triggered
    ctrl_enable_i        : in    std_logic;

    -- Enable trigger, cleared when triggered
    ctrl_enable_o        : out   std_logic;
    ctrl_wr_o            : out   std_logic;

    -- Time (seconds) to trigger
    seconds_i            : in    std_logic_vector(63 downto 0);

    -- Time (cycles) to trigger
    cycles_i             : in    std_logic_vector(31 downto 0)
  );
end alt_trigin;

architecture syn of alt_trigin is
  signal wb_en                          : std_logic;
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal ack_int                        : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
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

  -- Process for write requests.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      ctrl_wr_o <= '0';
    elsif rising_edge(clk_i) then
      ctrl_wr_o <= '0';
      if wr_int = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case wb_i.adr(4 downto 3) is
        when "00" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register ctrl
            ctrl_wr_o <= '1';
            ctrl_enable_o <= wb_i.dat(1);
            wr_ack_int <= not wr_ack_done_int;
          when others =>
            wr_ack_int <= not wr_ack_done_int;
          end case;
        when "01" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register seconds
            wr_ack_int <= not wr_ack_done_int;
          when "1" => 
            -- Register seconds
            wr_ack_int <= not wr_ack_done_int;
          when others =>
            wr_ack_int <= not wr_ack_done_int;
          end case;
        when "10" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- Register cycles
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
    elsif rising_edge(clk_i) then
      if rd_int = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        case wb_i.adr(4 downto 3) is
        when "00" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- ctrl
          when others =>
          end case;
        when "01" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- seconds
            reg_rdat_int <= seconds_i(63 downto 32);
          when "1" => 
            -- seconds
            reg_rdat_int <= seconds_i(31 downto 0);
          when others =>
          end case;
        when "10" => 
          case wb_i.adr(2 downto 2) is
          when "0" => 
            -- cycles
            reg_rdat_int <= cycles_i;
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
        -- ctrl
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when "01" => 
      case wb_i.adr(2 downto 2) is
      when "0" => 
        -- seconds
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when "1" => 
        -- seconds
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when "10" => 
      case wb_i.adr(2 downto 2) is
      when "0" => 
        -- cycles
        wb_o.dat <= reg_rdat_int;
        rd_ack_int <= rd_ack1_int;
      when others =>
      end case;
    when others =>
    end case;
  end process;
end syn;
