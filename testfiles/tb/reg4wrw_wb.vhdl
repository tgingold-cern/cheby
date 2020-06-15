library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg4wrw_wb is
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

    -- REG fwrw_rws
    fwrw_rws_f1_i        : in    std_logic_vector(11 downto 0);
    fwrw_rws_f1_o        : out   std_logic_vector(11 downto 0);
    fwrw_rws_f2_o        : out   std_logic_vector(15 downto 0);
    fwrw_rws_f3_i        : in    std_logic_vector(23 downto 0);
    fwrw_rws_f3_o        : out   std_logic_vector(23 downto 0);
    fwrw_rws_wr_o        : out   std_logic_vector(1 downto 0);
    fwrw_rws_rd_o        : out   std_logic_vector(1 downto 0);

    -- REG fwrw_rws_rwa
    fwrw_rws_rwa_f1_i    : in    std_logic_vector(11 downto 0);
    fwrw_rws_rwa_f1_o    : out   std_logic_vector(11 downto 0);
    fwrw_rws_rwa_f2_o    : out   std_logic_vector(15 downto 0);
    fwrw_rws_rwa_f3_i    : in    std_logic_vector(23 downto 0);
    fwrw_rws_rwa_f3_o    : out   std_logic_vector(23 downto 0);
    fwrw_rws_rwa_wr_o    : out   std_logic_vector(1 downto 0);
    fwrw_rws_rwa_rd_o    : out   std_logic_vector(1 downto 0);
    fwrw_rws_rwa_wack_i  : in    std_logic_vector(1 downto 0);
    fwrw_rws_rwa_rack_i  : in    std_logic_vector(1 downto 0)
  );
end reg4wrw_wb;

architecture syn of reg4wrw_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal fwrw_rws_f2_reg                : std_logic_vector(15 downto 0);
  signal fwrw_rws_wreq                  : std_logic_vector(1 downto 0);
  signal fwrw_rws_wack                  : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_f2_reg            : std_logic_vector(15 downto 0);
  signal fwrw_rws_rwa_wreq              : std_logic_vector(1 downto 0);
  signal fwrw_rws_rwa_wack              : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
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

  -- Register fwrw_rws
  fwrw_rws_f1_o <= wr_dat_d0(11 downto 0);
  fwrw_rws_f2_o <= fwrw_rws_f2_reg;
  fwrw_rws_f3_o <= wr_dat_d0(31 downto 8);
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fwrw_rws_f2_reg <= "0000000000000000";
        fwrw_rws_wack <= (others => '0');
      else
        if fwrw_rws_wreq(0) = '1' then
          fwrw_rws_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if fwrw_rws_wreq(1) = '1' then
          fwrw_rws_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
        end if;
        fwrw_rws_wack <= fwrw_rws_wreq;
      end if;
    end if;
  end process;
  fwrw_rws_wr_o <= fwrw_rws_wack;

  -- Register fwrw_rws_rwa
  fwrw_rws_rwa_f1_o <= wr_dat_d0(11 downto 0);
  fwrw_rws_rwa_f2_o <= fwrw_rws_rwa_f2_reg;
  fwrw_rws_rwa_f3_o <= wr_dat_d0(31 downto 8);
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        fwrw_rws_rwa_f2_reg <= "0000000000000000";
        fwrw_rws_rwa_wack <= (others => '0');
      else
        if fwrw_rws_rwa_wreq(0) = '1' then
          fwrw_rws_rwa_f2_reg(7 downto 0) <= wr_dat_d0(31 downto 24);
        end if;
        if fwrw_rws_rwa_wreq(1) = '1' then
          fwrw_rws_rwa_f2_reg(15 downto 8) <= wr_dat_d0(7 downto 0);
        end if;
        fwrw_rws_rwa_wack <= fwrw_rws_rwa_wreq;
      end if;
    end if;
  end process;
  fwrw_rws_rwa_wr_o <= fwrw_rws_rwa_wack;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, fwrw_rws_wack, fwrw_rws_rwa_wack_i) begin
    fwrw_rws_wreq <= (others => '0');
    fwrw_rws_rwa_wreq <= (others => '0');
    case wr_adr_d0(3 downto 3) is
    when "0" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg fwrw_rws
        fwrw_rws_wreq(1) <= wr_req_d0;
        wr_ack_int <= fwrw_rws_wack(1);
      when "1" =>
        -- Reg fwrw_rws
        fwrw_rws_wreq(0) <= wr_req_d0;
        wr_ack_int <= fwrw_rws_wack(0);
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "1" =>
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
  process (wb_adr_i, rd_req_int, fwrw_rws_f2_reg, fwrw_rws_f3_i, fwrw_rws_f1_i, fwrw_rws_rwa_rack_i, fwrw_rws_rwa_f2_reg, fwrw_rws_rwa_f3_i, fwrw_rws_rwa_f1_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    fwrw_rws_rd_o <= (others => '0');
    fwrw_rws_rwa_rd_o <= (others => '0');
    case wb_adr_i(3 downto 3) is
    when "0" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg fwrw_rws
        fwrw_rws_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= fwrw_rws_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= fwrw_rws_f3_i;
      when "1" =>
        -- Reg fwrw_rws
        fwrw_rws_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(11 downto 0) <= fwrw_rws_f1_i;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= fwrw_rws_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "1" =>
      case wb_adr_i(2 downto 2) is
      when "0" =>
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_rd_o(1) <= rd_req_int;
        rd_ack_d0 <= fwrw_rws_rwa_rack_i(1);
        rd_dat_d0(7 downto 0) <= fwrw_rws_rwa_f2_reg(15 downto 8);
        rd_dat_d0(31 downto 8) <= fwrw_rws_rwa_f3_i;
      when "1" =>
        -- Reg fwrw_rws_rwa
        fwrw_rws_rwa_rd_o(0) <= rd_req_int;
        rd_ack_d0 <= fwrw_rws_rwa_rack_i(0);
        rd_dat_d0(11 downto 0) <= fwrw_rws_rwa_f1_i;
        rd_dat_d0(23 downto 12) <= (others => '0');
        rd_dat_d0(31 downto 24) <= fwrw_rws_rwa_f2_reg(7 downto 0);
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
