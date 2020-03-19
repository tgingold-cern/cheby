-- Do not edit.  Generated on Thu Mar 19 17:36:06 2020 by gingold
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl=reg3rw_wb.vhdl -i reg3rw_wb.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg3rw_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(5 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG rrw
    rrw_o                : out   std_logic_vector(63 downto 0);

    -- REG frrw
    frrw_f1_o            : out   std_logic_vector(11 downto 0);
    frrw_f2_o            : out   std_logic_vector(15 downto 0);
    frrw_f3_o            : out   std_logic_vector(23 downto 0);

    -- REG frrw_ws
    frrw_ws_f1_o         : out   std_logic_vector(11 downto 0);
    frrw_ws_f2_o         : out   std_logic_vector(15 downto 0);
    frrw_ws_f3_o         : out   std_logic_vector(23 downto 0);
    frrw_ws_wr_o         : out   std_logic_vector(1 downto 0);

    -- REG frrw_rws
    frrw_rws_f1_o        : out   std_logic_vector(11 downto 0);
    frrw_rws_f2_o        : out   std_logic_vector(15 downto 0);
    frrw_rws_f3_o        : out   std_logic_vector(23 downto 0);
    frrw_rws_wr_o        : out   std_logic_vector(1 downto 0);
    frrw_rws_rd_o        : out   std_logic_vector(1 downto 0);

    -- REG frrw_rws_rwa
    frrw_rws_rwa_f1_o    : out   std_logic_vector(11 downto 0);
    frrw_rws_rwa_f2_o    : out   std_logic_vector(15 downto 0);
    frrw_rws_rwa_f3_o    : out   std_logic_vector(23 downto 0);
    frrw_rws_rwa_wr_o    : out   std_logic_vector(1 downto 0);
    frrw_rws_rwa_rd_o    : out   std_logic_vector(1 downto 0);
    frrw_rws_rwa_wack_i  : in    std_logic_vector(1 downto 0);
    frrw_rws_rwa_rack_i  : in    std_logic_vector(1 downto 0)
  );
end reg3rw_wb;

architecture syn of reg3rw_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rrw_reg                        : std_logic_vector(63 downto 0);
  signal rrw_wreq                       : std_logic_vector(1 downto 0);
  signal rrw_wack                       : std_logic_vector(1 downto 0);
  signal frrw_f1_reg                    : std_logic_vector(11 downto 0);
  signal frrw_f2_reg                    : std_logic_vector(15 downto 0);
  signal frrw_f3_reg                    : std_logic_vector(23 downto 0);
  signal frrw_wreq                      : std_logic_vector(1 downto 0);
  signal frrw_wack                      : std_logic_vector(1 downto 0);
  signal frrw_ws_f1_reg                 : std_logic_vector(11 downto 0);
  signal frrw_ws_f2_reg                 : std_logic_vector(15 downto 0);
  signal frrw_ws_f3_reg                 : std_logic_vector(23 downto 0);
  signal frrw_ws_wreq                   : std_logic_vector(1 downto 0);
  signal frrw_ws_wack                   : std_logic_vector(1 downto 0);
  signal frrw_rws_f1_reg                : std_logic_vector(11 downto 0);
  signal frrw_rws_f2_reg                : std_logic_vector(15 downto 0);
  signal frrw_rws_f3_reg                : std_logic_vector(23 downto 0);
  signal frrw_rws_wreq                  : std_logic_vector(1 downto 0);
  signal frrw_rws_wack                  : std_logic_vector(1 downto 0);
  signal frrw_rws_rwa_f1_reg            : std_logic_vector(11 downto 0);
  signal frrw_rws_rwa_f2_reg            : std_logic_vector(15 downto 0);
  signal frrw_rws_rwa_f3_reg            : std_logic_vector(23 downto 0);
  signal frrw_rws_rwa_wreq              : std_logic_vector(1 downto 0);
  signal frrw_rws_rwa_wack              : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
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

  -- Register rrw
  rrw_o <= rrw_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rrw_reg <= "0000000000000000000000000000000000000000000000000000000000000000";
        rrw_wack <= (others => '0');
      else
        if rrw_wreq(0) = '1' then
          rrw_reg(31 downto 0) <= wr_dat_d0;
        end if;
        if rrw_wreq(1) = '1' then
          rrw_reg(63 downto 32) <= wr_dat_d0;
        end if;
        rrw_wack <= rrw_wreq;
      end if;
    end if;
  end process;

  -- Register frrw
  frrw_f1_o <= frrw_f1_reg;
  frrw_f2_o <= frrw_f2_reg;
  frrw_f3_o <= frrw_f3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        frrw_f1_reg <= "000000000000";
        frrw_f2_reg <= "0000000000000000";
        frrw_f3_reg <= "000000000000000000000000";
        frrw_wack <= (others => '0');
      else
        if frrw_wreq(0) = '1' then
          frrw_f1_reg <= wr_dat_d0(11 downto 0);
          frrw_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if frrw_wreq(1) = '1' then
          frrw_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
          frrw_f3_reg <= wr_dat_d0(31 downto 8);
        end if;
        frrw_wack <= frrw_wreq;
      end if;
    end if;
  end process;

  -- Register frrw_ws
  frrw_ws_f1_o <= frrw_ws_f1_reg;
  frrw_ws_f2_o <= frrw_ws_f2_reg;
  frrw_ws_f3_o <= frrw_ws_f3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        frrw_ws_f1_reg <= "000000000000";
        frrw_ws_f2_reg <= "0000000000000000";
        frrw_ws_f3_reg <= "000000000000000000000000";
        frrw_ws_wack <= (others => '0');
      else
        if frrw_ws_wreq(0) = '1' then
          frrw_ws_f1_reg <= wr_dat_d0(11 downto 0);
          frrw_ws_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if frrw_ws_wreq(1) = '1' then
          frrw_ws_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
          frrw_ws_f3_reg <= wr_dat_d0(31 downto 8);
        end if;
        frrw_ws_wack <= frrw_ws_wreq;
      end if;
    end if;
  end process;
  frrw_ws_wr_o <= frrw_ws_wack;

  -- Register frrw_rws
  frrw_rws_f1_o <= frrw_rws_f1_reg;
  frrw_rws_f2_o <= frrw_rws_f2_reg;
  frrw_rws_f3_o <= frrw_rws_f3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        frrw_rws_f1_reg <= "000000000000";
        frrw_rws_f2_reg <= "0000000000000000";
        frrw_rws_f3_reg <= "000000000000000000000000";
        frrw_rws_wack <= (others => '0');
      else
        if frrw_rws_wreq(0) = '1' then
          frrw_rws_f1_reg <= wr_dat_d0(11 downto 0);
          frrw_rws_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if frrw_rws_wreq(1) = '1' then
          frrw_rws_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
          frrw_rws_f3_reg <= wr_dat_d0(31 downto 8);
        end if;
        frrw_rws_wack <= frrw_rws_wreq;
      end if;
    end if;
  end process;
  frrw_rws_wr_o <= frrw_rws_wack;

  -- Register frrw_rws_rwa
  frrw_rws_rwa_f1_o <= frrw_rws_rwa_f1_reg;
  frrw_rws_rwa_f2_o <= frrw_rws_rwa_f2_reg;
  frrw_rws_rwa_f3_o <= frrw_rws_rwa_f3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        frrw_rws_rwa_f1_reg <= "000000000000";
        frrw_rws_rwa_f2_reg <= "0000000000000000";
        frrw_rws_rwa_f3_reg <= "000000000000000000000000";
        frrw_rws_rwa_wack <= (others => '0');
      else
        if frrw_rws_rwa_wreq(0) = '1' then
          frrw_rws_rwa_f1_reg <= wr_dat_d0(11 downto 0);
          frrw_rws_rwa_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if frrw_rws_rwa_wreq(1) = '1' then
          frrw_rws_rwa_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
          frrw_rws_rwa_f3_reg <= wr_dat_d0(31 downto 8);
        end if;
        frrw_rws_rwa_wack <= frrw_rws_rwa_wreq;
      end if;
    end if;
  end process;
  frrw_rws_rwa_wr_o <= frrw_rws_rwa_wack;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rrw_wack, frrw_wack, frrw_ws_wack, frrw_rws_wack, frrw_rws_rwa_wack_i) begin
    rrw_wreq <= (others => '0');
    frrw_wreq <= (others => '0');
    frrw_ws_wreq <= (others => '0');
    frrw_rws_wreq <= (others => '0');
    frrw_rws_rwa_wreq <= (others => '0');
    case wr_adr_d0(5 downto 3) is
    when "000" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg rrw
        rrw_wreq(1) <= wr_req_d0;
        wr_ack_int <= rrw_wack(1);
      when "1" => 
        -- Reg rrw
        rrw_wreq(0) <= wr_req_d0;
        wr_ack_int <= rrw_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "001" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg frrw
        frrw_wreq(1) <= wr_req_d0;
        wr_ack_int <= frrw_wack(1);
      when "1" => 
        -- Reg frrw
        frrw_wreq(0) <= wr_req_d0;
        wr_ack_int <= frrw_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "010" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg frrw_ws
        frrw_ws_wreq(1) <= wr_req_d0;
        wr_ack_int <= frrw_ws_wack(1);
      when "1" => 
        -- Reg frrw_ws
        frrw_ws_wreq(0) <= wr_req_d0;
        wr_ack_int <= frrw_ws_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "011" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg frrw_rws
        frrw_rws_wreq(1) <= wr_req_d0;
        wr_ack_int <= frrw_rws_wack(1);
      when "1" => 
        -- Reg frrw_rws
        frrw_rws_wreq(0) <= wr_req_d0;
        wr_ack_int <= frrw_rws_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "100" => 
      case wr_adr_d0(2 downto 2) is
      when "0" => 
        -- Reg frrw_rws_rwa
        frrw_rws_rwa_wreq(1) <= wr_req_d0;
        wr_ack_int <= frrw_rws_rwa_wack_i(1);
      when "1" => 
        -- Reg frrw_rws_rwa
        frrw_rws_rwa_wreq(0) <= wr_req_d0;
        wr_ack_int <= frrw_rws_rwa_wack_i(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, rrw_reg, frrw_f2_reg, frrw_f3_reg, frrw_f1_reg, frrw_ws_f2_reg, frrw_ws_f3_reg, frrw_ws_f1_reg, frrw_rws_f2_reg, frrw_rws_f3_reg, frrw_rws_f1_reg, frrw_rws_rwa_rack_i, frrw_rws_rwa_f2_reg, frrw_rws_rwa_f3_reg, frrw_rws_rwa_f1_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    frrw_rws_rd_o <= (others => '0');
    frrw_rws_rwa_rd_o <= (others => '0');
    case wb_adr_i(5 downto 3) is
    when "000" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg rrw
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= rrw_reg(63 downto 32);
      when "1" => 
        -- Reg rrw
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= rrw_reg(31 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "001" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg frrw
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= frrw_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= frrw_f3_reg;
      when "1" => 
        -- Reg frrw
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= frrw_f1_reg;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= frrw_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "010" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg frrw_ws
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= frrw_ws_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= frrw_ws_f3_reg;
      when "1" => 
        -- Reg frrw_ws
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= frrw_ws_f1_reg;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= frrw_ws_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "011" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg frrw_rws
        frrw_rws_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= frrw_rws_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= frrw_rws_f3_reg;
      when "1" => 
        -- Reg frrw_rws
        frrw_rws_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= frrw_rws_f1_reg;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= frrw_rws_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "100" => 
      case wb_adr_i(2 downto 2) is
      when "0" => 
        -- Reg frrw_rws_rwa
        frrw_rws_rwa_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= frrw_rws_rwa_rack_i(1);
        rd_dat_d0(7 downto 0) <= frrw_rws_rwa_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= frrw_rws_rwa_f3_reg;
      when "1" => 
        -- Reg frrw_rws_rwa
        frrw_rws_rwa_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= frrw_rws_rwa_rack_i(0);
        rd_dat_d0(11 downto 0) <= frrw_rws_rwa_f1_reg;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= frrw_rws_rwa_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
