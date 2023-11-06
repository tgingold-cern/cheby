library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s4 is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(2 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG r1
    r1_o                 : out   std_logic_vector(31 downto 0);

    -- WB bus sub
    sub_cyc_o            : out   std_logic;
    sub_stb_o            : out   std_logic;
    sub_sel_o            : out   std_logic_vector(3 downto 0);
    sub_we_o             : out   std_logic;
    sub_dat_o            : out   std_logic_vector(31 downto 0);
    sub_ack_i            : in    std_logic;
    sub_err_i            : in    std_logic;
    sub_rty_i            : in    std_logic;
    sub_stall_i          : in    std_logic;
    sub_dat_i            : in    std_logic_vector(31 downto 0)
  );
end s4;

architecture syn of s4 is
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal r1_reg                         : std_logic_vector(31 downto 0);
  signal r1_wreq                        : std_logic;
  signal r1_wack                        : std_logic;
  signal sub_re                         : std_logic;
  signal sub_we                         : std_logic;
  signal sub_wt                         : std_logic;
  signal sub_rt                         : std_logic;
  signal sub_tr                         : std_logic;
  signal sub_wack                       : std_logic;
  signal sub_rack                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  process (wb_sel_i) begin
    wr_sel(7 downto 0) <= (others => wb_sel_i(0));
    wr_sel(15 downto 8) <= (others => wb_sel_i(1));
    wr_sel(23 downto 16) <= (others => wb_sel_i(2));
    wr_sel(31 downto 24) <= (others => wb_sel_i(3));
  end process;
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
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0";
        wr_dat_d0 <= "00000000000000000000000000000000";
        wr_sel_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Register r1
  r1_o <= r1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        r1_reg <= "00000000000000000000000000000000";
        r1_wack <= '0';
      else
        if r1_wreq = '1' then
          r1_reg <= wr_dat_d0;
        end if;
        r1_wack <= r1_wreq;
      end if;
    end if;
  end process;

  -- Interface sub
  sub_tr <= sub_wt or sub_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub_rt <= '0';
        sub_wt <= '0';
      else
        sub_rt <= (sub_rt or sub_re) and not sub_rack;
        sub_wt <= (sub_wt or sub_we) and not sub_wack;
      end if;
    end if;
  end process;
  sub_cyc_o <= sub_tr;
  sub_stb_o <= sub_tr;
  sub_wack <= sub_ack_i and sub_wt;
  sub_rack <= sub_ack_i and sub_rt;
  process (wr_sel_d0) begin
    sub_sel_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      sub_sel_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      sub_sel_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      sub_sel_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      sub_sel_o(3) <= '1';
    end if;
  end process;
  sub_we_o <= sub_wt;
  sub_dat_o <= wr_dat_d0;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, r1_wack, sub_wack) begin
    r1_wreq <= '0';
    sub_we <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg r1
      r1_wreq <= wr_req_d0;
      wr_ack_int <= r1_wack;
    when "1" =>
      -- Submap sub
      sub_we <= wr_req_d0;
      wr_ack_int <= sub_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, r1_reg, sub_dat_i, sub_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub_re <= '0';
    case wb_adr_i(2 downto 2) is
    when "0" =>
      -- Reg r1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= r1_reg;
    when "1" =>
      -- Submap sub
      sub_re <= rd_req_int;
      rd_dat_d0 <= sub_dat_i;
      rd_ack_d0 <= sub_rack;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
