-- Do not edit.  Generated on Thu Mar 19 17:36:06 2020 by gingold
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl=reg3wrw_wb.vhdl -i reg3wrw_wb.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg3wrw_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(4 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG wrw
    wrw_i                : in    std_logic_vector(63 downto 0);
    wrw_o                : out   std_logic_vector(63 downto 0);
    wrw_wr_o             : out   std_logic_vector(1 downto 0);
    wrw_rd_o             : out   std_logic_vector(1 downto 0);
    wrw_wack_i           : in    std_logic_vector(1 downto 0);
    wrw_rack_i           : in    std_logic_vector(1 downto 0);

    -- REG fwrw_ws
    fwrw_ws_f1_i         : in    std_logic_vector(11 downto 0);
    fwrw_ws_f1_o         : out   std_logic_vector(11 downto 0);
    fwrw_ws_f2_i         : in    std_logic_vector(15 downto 0);
    fwrw_ws_f2_o         : out   std_logic_vector(15 downto 0);
    fwrw_ws_f3_i         : in    std_logic_vector(23 downto 0);
    fwrw_ws_f3_o         : out   std_logic_vector(23 downto 0);
    fwrw_ws_wr_o         : out   std_logic_vector(1 downto 0);

    -- REG fwrw_rws
    fwrw_rws_f1_i        : in    std_logic_vector(11 downto 0);
    fwrw_rws_f1_o        : out   std_logic_vector(11 downto 0);
    fwrw_rws_f2_i        : in    std_logic_vector(15 downto 0);
    fwrw_rws_f2_o        : out   std_logic_vector(15 downto 0);
    fwrw_rws_f3_i        : in    std_logic_vector(23 downto 0);
    fwrw_rws_f3_o        : out   std_logic_vector(23 downto 0);
    fwrw_rws_wr_o        : out   std_logic_vector(1 downto 0);
    fwrw_rws_rd_o        : out   std_logic_vector(1 downto 0);

    -- REG fwrw_rws_rwa
    fwrw_rws_rwa_f1_i    : in    std_logic_vector(11 downto 0);
    fwrw_rws_rwa_f1_o    : out   std_logic_vector(11 downto 0);
    fwrw_rws_rwa_f2_i    : in    std_logic_vector(15 downto 0);
    fwrw_rws_rwa_f2_o    : out   std_logic_vector(15 downto 0);
    fwrw_rws_rwa_f3_i    : in    std_logic_vector(23 downto 0);
    fwrw_rws_rwa_f3_o    : out   std_logic_vector(23 downto 0);
    fwrw_rws_rwa_wr_o    : out   std_logic_vector(1 downto 0);
    fwrw_rws_rwa_rd_o    : out   std_logic_vector(1 downto 0);
    fwrw_rws_rwa_wack_i  : in    std_logic_vector(1 downto 0);
    fwrw_rws_rwa_rack_i  : in    std_logic_vector(1 downto 0)
  );
end reg3wrw_wb;

architecture syn of reg3wrw_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal wrw_wreq                       : std_logic_vector(1 downto 0);
  signal fwrw_ws_wreq                   : std_logic_vector(1 downto 0);
  signal fwrw_rws_wreq                  : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_wreq              : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
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
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Register wrw
  wrw_o(31 downto 0) <= wr_dat_d0;
  wrw_o(63 downto 32) <= wr_dat_d0;
  wrw_wr_o <= wrw_wreq;

  -- Register fwrw_ws
  fwrw_ws_f1_o <= wr_dat_d0(11 downto 0);
  fwrw_ws_f2_o(7 downto 0) <= wr_dat_d0(31 downto 24);
  fwrw_ws_f2_o(15 downto 8) <= wr_dat_d0(7 downto 0);
  fwrw_ws_f3_o <= wr_dat_d0(31 downto 8);
  fwrw_ws_wr_o <= fwrw_ws_wreq;

  -- Register fwrw_rws
  fwrw_rws_f1_o <= wr_dat_d0(11 downto 0);
  fwrw_rws_f2_o(7 downto 0) <= wr_dat_d0(31 downto 24);
  fwrw_rws_f2_o(15 downto 8) <= wr_dat_d0(7 downto 0);
  fwrw_rws_f3_o <= wr_dat_d0(31 downto 8);
  fwrw_rws_wr_o <= fwrw_rws_wreq;

  -- Register fwrw_rws_rwa
  fwrw_rws_rwa_f1_o <= wr_dat_d0(11 downto 0);
  fwrw_rws_rwa_f2_o(7 downto 0) <= wr_dat_d0(31 downto 24);
  fwrw_rws_rwa_f2_o(15 downto 8) <= wr_dat_d0(7 downto 0);
  fwrw_rws_rwa_f3_o <= wr_dat_d0(31 downto 8);
  fwrw_rws_rwa_wr_o <= fwrw_rws_rwa_wreq;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, wrw_wack_i, fwrw_rws_rwa_wack_i) begin
    wrw_wreq <= (others => '0');
    fwrw_ws_wreq <= (others => '0');
    fwrw_rws_wreq <= (others => '0');
    fwrw_rws_rwa_wreq <= (others => '0');
    case wr_adr_d0(4 downto 3) is
    when "00" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg wrw
        wrw_wreq(1) <= wr_req_d0;
        wr_ack_int <= wrw_wack_i(1);
      when "1" => 
        -- Reg wrw
        wrw_wreq(0) <= wr_req_d0;
        wr_ack_int <= wrw_wack_i(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "01" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg fwrw_ws
        fwrw_ws_wreq(1) <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      when "1" => 
        -- Reg fwrw_ws
        fwrw_ws_wreq(0) <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "10" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg fwrw_rws
        fwrw_rws_wreq(1) <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      when "1" => 
        -- Reg fwrw_rws
        fwrw_rws_wreq(0) <= wr_req_d0;
        wr_ack_int <= wr_req_d0;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "11" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_wreq(1) <= wr_req_d0;
        wr_ack_int <= fwrw_rws_rwa_wack_i(1);
      when "1" => 
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_wreq(0) <= wr_req_d0;
        wr_ack_int <= fwrw_rws_rwa_wack_i(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, wrw_rack_i, wrw_i, fwrw_ws_f2_i, fwrw_ws_f3_i, fwrw_ws_f1_i, fwrw_rws_f2_i, fwrw_rws_f3_i, fwrw_rws_f1_i, fwrw_rws_rwa_rack_i, fwrw_rws_rwa_f2_i, fwrw_rws_rwa_f3_i, fwrw_rws_rwa_f1_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    wrw_rd_o <= (others => '0');
    fwrw_rws_rd_o <= (others => '0');
    fwrw_rws_rwa_rd_o <= (others => '0');
    case wb_adr_i(4 downto 3) is
    when "00" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg wrw
        wrw_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= wrw_rack_i(1);
        rd_dat_d0 <= wrw_i(63 downto 32);
      when "1" => 
        -- Reg wrw
        wrw_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= wrw_rack_i(0);
        rd_dat_d0 <= wrw_i(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "01" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg fwrw_ws
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= fwrw_ws_f2_i(15 downto 8);
        rd_dat_d0(31 downto 8) <= fwrw_ws_f3_i;
      when "1" => 
        -- Reg fwrw_ws
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= fwrw_ws_f1_i;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= fwrw_ws_f2_i(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "10" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg fwrw_rws
        fwrw_rws_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= fwrw_rws_f2_i(15 downto 8);
        rd_dat_d0(31 downto 8) <= fwrw_rws_f3_i;
      when "1" => 
        -- Reg fwrw_rws
        fwrw_rws_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= fwrw_rws_f1_i;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= fwrw_rws_f2_i(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "11" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= fwrw_rws_rwa_rack_i(1);
        rd_dat_d0(7 downto 0) <= fwrw_rws_rwa_f2_i(15 downto 8);
        rd_dat_d0(31 downto 8) <= fwrw_rws_rwa_f3_i;
      when "1" => 
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= fwrw_rws_rwa_rack_i(0);
        rd_dat_d0(11 downto 0) <= fwrw_rws_rwa_f1_i;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= fwrw_rws_rwa_f2_i(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
