library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity mem64rodual is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(8 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- RAM port for DdrCapturesIndex
    DdrCapturesIndex_adr_i : in    std_logic_vector(5 downto 0);
    DdrCapturesIndex_clk_i : in    std_logic;
    DdrCapturesIndex_DdrCaptures_we_i : in    std_logic;
    DdrCapturesIndex_DdrCaptures_dat_i : in    std_logic_vector(63 downto 0)
  );
end mem64rodual;

architecture syn of mem64rodual is
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal DdrCapturesIndex_DdrCaptures_int_dato0 : std_logic_vector(31 downto 0);
  signal DdrCapturesIndex_DdrCaptures_int_dato1 : std_logic_vector(31 downto 0);
  signal DdrCapturesIndex_DdrCaptures_ext_dat0 : std_logic_vector(31 downto 0);
  signal DdrCapturesIndex_DdrCaptures_ext_dat1 : std_logic_vector(31 downto 0);
  signal DdrCapturesIndex_DdrCaptures_rreq0 : std_logic;
  signal DdrCapturesIndex_DdrCaptures_rreq1 : std_logic;
  signal DdrCapturesIndex_DdrCaptures_rack0 : std_logic;
  signal DdrCapturesIndex_DdrCaptures_rack1 : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
  signal DdrCapturesIndex_0_sel_int     : std_logic_vector(3 downto 0);
  signal DdrCapturesIndex_1_sel_int     : std_logic_vector(3 downto 0);
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Memory DdrCapturesIndex
  DdrCapturesIndex_DdrCaptures_raminst0: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 64,
      g_addr_width         => 6,
      g_dual_clock         => '1',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => DdrCapturesIndex_clk_i,
      addr_a_i             => wb_adr_i(8 downto 3),
      bwsel_a_i            => DdrCapturesIndex_0_sel_int,
      data_a_i             => (others => 'X'),
      data_a_o             => DdrCapturesIndex_DdrCaptures_int_dato0,
      rd_a_i               => DdrCapturesIndex_DdrCaptures_rreq0,
      wr_a_i               => '0',
      addr_b_i             => DdrCapturesIndex_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => DdrCapturesIndex_DdrCaptures_dat_i(63 downto 32),
      data_b_o             => DdrCapturesIndex_DdrCaptures_ext_dat0,
      rd_b_i               => '0',
      wr_b_i               => DdrCapturesIndex_DdrCaptures_we_i
    );
  
  process (wr_sel_d0) begin
    DdrCapturesIndex_0_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      DdrCapturesIndex_0_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      DdrCapturesIndex_0_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      DdrCapturesIndex_0_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      DdrCapturesIndex_0_sel_int(3) <= '1';
    end if;
  end process;
  DdrCapturesIndex_DdrCaptures_raminst1: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 64,
      g_addr_width         => 6,
      g_dual_clock         => '1',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => DdrCapturesIndex_clk_i,
      addr_a_i             => wb_adr_i(8 downto 3),
      bwsel_a_i            => DdrCapturesIndex_1_sel_int,
      data_a_i             => (others => 'X'),
      data_a_o             => DdrCapturesIndex_DdrCaptures_int_dato1,
      rd_a_i               => DdrCapturesIndex_DdrCaptures_rreq1,
      wr_a_i               => '0',
      addr_b_i             => DdrCapturesIndex_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => DdrCapturesIndex_DdrCaptures_dat_i(31 downto 0),
      data_b_o             => DdrCapturesIndex_DdrCaptures_ext_dat1,
      rd_b_i               => '0',
      wr_b_i               => DdrCapturesIndex_DdrCaptures_we_i
    );
  
  process (wr_sel_d0) begin
    DdrCapturesIndex_1_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      DdrCapturesIndex_1_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      DdrCapturesIndex_1_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      DdrCapturesIndex_1_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      DdrCapturesIndex_1_sel_int(3) <= '1';
    end if;
  end process;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        DdrCapturesIndex_DdrCaptures_rack0 <= '0';
        DdrCapturesIndex_DdrCaptures_rack1 <= '0';
      else
        DdrCapturesIndex_DdrCaptures_rack0 <= DdrCapturesIndex_DdrCaptures_rreq0;
        DdrCapturesIndex_DdrCaptures_rack1 <= DdrCapturesIndex_DdrCaptures_rreq1;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0) begin
    -- Memory DdrCapturesIndex
    wr_ack_int <= wr_req_d0;
  end process;

  -- Process for read requests.
  process (wb_adr_i, DdrCapturesIndex_DdrCaptures_int_dato0, rd_req_int,
           DdrCapturesIndex_DdrCaptures_rack0,
           DdrCapturesIndex_DdrCaptures_int_dato1,
           DdrCapturesIndex_DdrCaptures_rack1) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    DdrCapturesIndex_DdrCaptures_rreq0 <= '0';
    DdrCapturesIndex_DdrCaptures_rreq1 <= '0';
    -- Memory DdrCapturesIndex
    case wb_adr_i(2 downto 2) is
    when "0" =>
      rd_dat_d0 <= DdrCapturesIndex_DdrCaptures_int_dato0;
      DdrCapturesIndex_DdrCaptures_rreq0 <= rd_req_int;
      rd_ack_d0 <= DdrCapturesIndex_DdrCaptures_rack0;
    when "1" =>
      rd_dat_d0 <= DdrCapturesIndex_DdrCaptures_int_dato1;
      DdrCapturesIndex_DdrCaptures_rreq1 <= rd_req_int;
      rd_ack_d0 <= DdrCapturesIndex_DdrCaptures_rack1;
    when others =>
    end case;
  end process;
end syn;
