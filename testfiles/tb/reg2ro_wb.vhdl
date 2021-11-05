library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg2ro_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(3 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG wro
    wro_i                : in    std_logic_vector(31 downto 0);

    -- REG wro_st
    wro_st_i             : in    std_logic_vector(31 downto 0);
    wro_st_rd_o          : out   std_logic;

    -- REG wro_sa
    wro_sa_i             : in    std_logic_vector(31 downto 0);
    wro_sa_rd_o          : out   std_logic;
    wro_sa_rack_i        : in    std_logic;

    -- REG wro_sa2
    wro_sa2_i            : in    std_logic_vector(31 downto 0);
    wro_sa2_rd_o         : out   std_logic;
    wro_sa2_rack_i       : in    std_logic
  );
end reg2ro_wb;

architecture syn of reg2ro_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
begin

  -- WB decode signals
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
      end if;
    end if;
  end process;

  -- Register wro

  -- Register wro_st

  -- Register wro_sa

  -- Register wro_sa2

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0) begin
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg wro
      wr_ack_int <= wr_req_d0;
    when "01" =>
      -- Reg wro_st
      wr_ack_int <= wr_req_d0;
    when "10" =>
      -- Reg wro_sa
      wr_ack_int <= wr_req_d0;
    when "11" =>
      -- Reg wro_sa2
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, wro_i, wro_st_i, wro_sa_rack_i, wro_sa_i, wro_sa2_rack_i, wro_sa2_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    wro_st_rd_o <= '0';
    wro_sa_rd_o <= '0';
    wro_sa2_rd_o <= '0';
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg wro
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wro_i;
    when "01" =>
      -- Reg wro_st
      wro_st_rd_o <= rd_req_int;
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= wro_st_i;
    when "10" =>
      -- Reg wro_sa
      wro_sa_rd_o <= rd_req_int;
      rd_ack_d0 <= wro_sa_rack_i;
      rd_dat_d0 <= wro_sa_i;
    when "11" =>
      -- Reg wro_sa2
      wro_sa2_rd_o <= rd_req_int;
      rd_ack_d0 <= wro_sa2_rack_i;
      rd_dat_d0 <= wro_sa2_i;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
