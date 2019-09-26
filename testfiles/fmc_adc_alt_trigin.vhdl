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

    -- Control register
    -- Enable trigger, cleared when triggered
    ctrl_enable_i        : in    std_logic;
    ctrl_enable_o        : out   std_logic;
    ctrl_wr_o            : out   std_logic;

    -- Time (seconds) to trigger
    seconds_i            : in    std_logic_vector(63 downto 0);

    -- Time (cycles) to trigger
    cycles_i             : in    std_logic_vector(31 downto 0)
  );
end alt_trigin;

architecture syn of alt_trigin is
  signal adr_int                        : std_logic_vector(4 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal ctrl_wreq                      : std_logic;
  signal ctrl_rint                      : std_logic_vector(31 downto 0);
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

  -- Register ctrl
  ctrl_enable_o <= wr_dat_d0(1);
  ctrl_wr_o <= ctrl_wreq;
  ctrl_rint(0) <= '0';
  ctrl_rint(1) <= ctrl_enable_i;
  ctrl_rint(31 downto 2) <= (others => '0');

  -- Register seconds

  -- Register cycles

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0) begin
    ctrl_wreq <= '0';
    case wr_adr_d0(4 downto 3) is
    when "00" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- ctrl
        ctrl_wreq <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- seconds
        wr_ack_int <= wr_req_d0;
      when "1" => 
        -- seconds
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- cycles
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, ctrl_rint, seconds_i, cycles_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case adr_int(4 downto 3) is
    when "00" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- ctrl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= ctrl_rint;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- seconds
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= seconds_i(63 downto 32);
      when "1" => 
        -- seconds
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= seconds_i(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" => 
      case adr_int(2 downto 2) is
      when "0" => 
        -- cycles
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= cycles_i;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
