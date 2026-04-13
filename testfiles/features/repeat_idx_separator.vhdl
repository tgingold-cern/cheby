library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity repeat_idx_separator is
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

    -- REG r
    rep0_0_r_o           : out   std_logic_vector(31 downto 0);

    -- REG r
    rep0_1_r_o           : out   std_logic_vector(31 downto 0);

    -- REG r
    rep10_r_o            : out   std_logic_vector(31 downto 0);

    -- REG r
    rep11_r_o            : out   std_logic_vector(31 downto 0);

    -- REG r
    rep2_0_r_o           : out   std_logic_vector(31 downto 0);

    -- REG r
    rep2_1_r_o           : out   std_logic_vector(31 downto 0)
  );
end repeat_idx_separator;

architecture syn of repeat_idx_separator is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal rep0_0_r_reg                   : std_logic_vector(31 downto 0);
  signal rep0_0_r_wreq                  : std_logic;
  signal rep0_0_r_wack                  : std_logic;
  signal rep0_1_r_reg                   : std_logic_vector(31 downto 0);
  signal rep0_1_r_wreq                  : std_logic;
  signal rep0_1_r_wack                  : std_logic;
  signal rep10_r_reg                    : std_logic_vector(31 downto 0);
  signal rep10_r_wreq                   : std_logic;
  signal rep10_r_wack                   : std_logic;
  signal rep11_r_reg                    : std_logic_vector(31 downto 0);
  signal rep11_r_wreq                   : std_logic;
  signal rep11_r_wack                   : std_logic;
  signal rep2_0_r_reg                   : std_logic_vector(31 downto 0);
  signal rep2_0_r_wreq                  : std_logic;
  signal rep2_0_r_wack                  : std_logic;
  signal rep2_1_r_reg                   : std_logic_vector(31 downto 0);
  signal rep2_1_r_wreq                  : std_logic;
  signal rep2_1_r_wack                  : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
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
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register rep0_0_r
  rep0_0_r_o <= rep0_0_r_reg;
  rep0_0_r_wack <= rep0_0_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep0_0_r_reg <= "00000000000000000000000000000000";
      else
        if rep0_0_r_wreq = '1' then
          rep0_0_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register rep0_1_r
  rep0_1_r_o <= rep0_1_r_reg;
  rep0_1_r_wack <= rep0_1_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep0_1_r_reg <= "00000000000000000000000000000000";
      else
        if rep0_1_r_wreq = '1' then
          rep0_1_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register rep10_r
  rep10_r_o <= rep10_r_reg;
  rep10_r_wack <= rep10_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep10_r_reg <= "00000000000000000000000000000000";
      else
        if rep10_r_wreq = '1' then
          rep10_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register rep11_r
  rep11_r_o <= rep11_r_reg;
  rep11_r_wack <= rep11_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep11_r_reg <= "00000000000000000000000000000000";
      else
        if rep11_r_wreq = '1' then
          rep11_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register rep2_0_r
  rep2_0_r_o <= rep2_0_r_reg;
  rep2_0_r_wack <= rep2_0_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep2_0_r_reg <= "00000000000000000000000000000000";
      else
        if rep2_0_r_wreq = '1' then
          rep2_0_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register rep2_1_r
  rep2_1_r_o <= rep2_1_r_reg;
  rep2_1_r_wack <= rep2_1_r_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rep2_1_r_reg <= "00000000000000000000000000000000";
      else
        if rep2_1_r_wreq = '1' then
          rep2_1_r_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rep0_0_r_wack, rep0_1_r_wack, rep10_r_wack,
           rep11_r_wack, rep2_0_r_wack, rep2_1_r_wack) begin
    rep0_0_r_wreq <= '0';
    rep0_1_r_wreq <= '0';
    rep10_r_wreq <= '0';
    rep11_r_wreq <= '0';
    rep2_0_r_wreq <= '0';
    rep2_1_r_wreq <= '0';
    case wr_adr_d0(4 downto 2) is
    when "000" =>
      -- Reg rep0_0_r
      rep0_0_r_wreq <= wr_req_d0;
      wr_ack_int <= rep0_0_r_wack;
    when "001" =>
      -- Reg rep0_1_r
      rep0_1_r_wreq <= wr_req_d0;
      wr_ack_int <= rep0_1_r_wack;
    when "010" =>
      -- Reg rep10_r
      rep10_r_wreq <= wr_req_d0;
      wr_ack_int <= rep10_r_wack;
    when "011" =>
      -- Reg rep11_r
      rep11_r_wreq <= wr_req_d0;
      wr_ack_int <= rep11_r_wack;
    when "100" =>
      -- Reg rep2_0_r
      rep2_0_r_wreq <= wr_req_d0;
      wr_ack_int <= rep2_0_r_wack;
    when "101" =>
      -- Reg rep2_1_r
      rep2_1_r_wreq <= wr_req_d0;
      wr_ack_int <= rep2_1_r_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, rep0_0_r_reg, rep0_1_r_reg, rep10_r_reg,
           rep11_r_reg, rep2_0_r_reg, rep2_1_r_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(4 downto 2) is
    when "000" =>
      -- Reg rep0_0_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep0_0_r_reg;
    when "001" =>
      -- Reg rep0_1_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep0_1_r_reg;
    when "010" =>
      -- Reg rep10_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep10_r_reg;
    when "011" =>
      -- Reg rep11_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep11_r_reg;
    when "100" =>
      -- Reg rep2_0_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep2_0_r_reg;
    when "101" =>
      -- Reg rep2_1_r
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= rep2_1_r_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
