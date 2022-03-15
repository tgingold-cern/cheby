library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sreg is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REG i1Thresholds
    i1Thresholds_o       : out   std_logic_vector(31 downto 0)
  );
end sreg;

architecture syn of sreg is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal i1Thresholds_highThreshold_reg : std_logic_vector(15 downto 0);
  signal i1Thresholds_lowThreshold_reg  : std_logic_vector(15 downto 0);
  signal i1Thresholds_wreq              : std_logic;
  signal i1Thresholds_wack              : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register i1Thresholds
  i1Thresholds_o(31 downto 16) <= i1Thresholds_highThreshold_reg;
  i1Thresholds_o(15 downto 0) <= i1Thresholds_lowThreshold_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        i1Thresholds_highThreshold_reg <= "0000000000000000";
        i1Thresholds_lowThreshold_reg <= "0000000000000000";
        i1Thresholds_wack <= '0';
      else
        if i1Thresholds_wreq = '1' then
          i1Thresholds_highThreshold_reg <= wr_dat_d0(31 downto 16);
          i1Thresholds_lowThreshold_reg <= wr_dat_d0(15 downto 0);
        end if;
        i1Thresholds_wack <= i1Thresholds_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, i1Thresholds_wack) begin
    i1Thresholds_wreq <= '0';
    -- Reg i1Thresholds
    i1Thresholds_wreq <= wr_req_d0;
    wr_ack_int <= i1Thresholds_wack;
  end process;

  -- Process for read requests.
  process (rd_req_int, i1Thresholds_lowThreshold_reg,
           i1Thresholds_highThreshold_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg i1Thresholds
    rd_ack_d0 <= rd_req_int;
    rd_dat_d0(15 downto 0) <= i1Thresholds_lowThreshold_reg;
    rd_dat_d0(31 downto 16) <= i1Thresholds_highThreshold_reg;
  end process;
end syn;
