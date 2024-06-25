library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity regprefix1 is
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

    -- REG r1
    f1_o                 : out   std_logic_vector(2 downto 0);
    f2_o                 : out   std_logic;

    -- REG r2
    f3_o                 : out   std_logic_vector(2 downto 0);
    f4_o                 : out   std_logic;

    -- REG r3
    r3_o                 : out   std_logic_vector(31 downto 0)
  );
end regprefix1;

architecture syn of regprefix1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal f1_reg                         : std_logic_vector(2 downto 0);
  signal f2_reg                         : std_logic;
  signal r1_wreq                        : std_logic;
  signal r1_wack                        : std_logic;
  signal f3_reg                         : std_logic_vector(2 downto 0);
  signal f4_reg                         : std_logic;
  signal r2_wreq                        : std_logic;
  signal r2_wack                        : std_logic;
  signal r3_reg                         : std_logic_vector(31 downto 0);
  signal r3_wreq                        : std_logic;
  signal r3_wack                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
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
        wr_adr_d0 <= "00";
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

  -- Register r1
  f1_o <= f1_reg;
  f2_o <= f2_reg;
  r1_wack <= r1_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        f1_reg <= "000";
        f2_reg <= '0';
      else
        if r1_wreq = '1' then
          f1_reg <= wr_dat_d0(2 downto 0);
          f2_reg <= wr_dat_d0(4);
        end if;
      end if;
    end if;
  end process;

  -- Register r2
  f3_o <= f3_reg;
  f4_o <= f4_reg;
  r2_wack <= r2_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        f3_reg <= "000";
        f4_reg <= '0';
      else
        if r2_wreq = '1' then
          f3_reg <= wr_dat_d0(2 downto 0);
          f4_reg <= wr_dat_d0(4);
        end if;
      end if;
    end if;
  end process;

  -- Register r3
  r3_o <= r3_reg;
  r3_wack <= r3_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        r3_reg <= "00000000000000000000000000000000";
      else
        if r3_wreq = '1' then
          r3_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, r1_wack, r2_wack, r3_wack) begin
    r1_wreq <= '0';
    r2_wreq <= '0';
    r3_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg r1
      r1_wreq <= wr_req_d0;
      wr_ack_int <= r1_wack;
    when "01" =>
      -- Reg r2
      r2_wreq <= wr_req_d0;
      wr_ack_int <= r2_wack;
    when "10" =>
      -- Reg r3
      r3_wreq <= wr_req_d0;
      wr_ack_int <= r3_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, f1_reg, f2_reg, f3_reg, f4_reg, r3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg r1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(2 downto 0) <= f1_reg;
      rd_dat_d0(3) <= '0';
      rd_dat_d0(4) <= f2_reg;
      rd_dat_d0(31 downto 5) <= (others => '0');
    when "01" =>
      -- Reg r2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(2 downto 0) <= f3_reg;
      rd_dat_d0(3) <= '0';
      rd_dat_d0(4) <= f4_reg;
      rd_dat_d0(31 downto 5) <= (others => '0');
    when "10" =>
      -- Reg r3
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= r3_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
