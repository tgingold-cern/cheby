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
    i1Thresholds_highThreshold_o : out   std_logic_vector(15 downto 0);
    i1Thresholds_lowThreshold_o : out   std_logic_vector(15 downto 0)
  );
end sreg;

architecture syn of sreg is
  signal wb_en                          : std_logic;
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal ack_int                        : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal i1Thresholds_highThreshold_reg : std_logic_vector(15 downto 0);
  signal i1Thresholds_lowThreshold_reg  : std_logic_vector(15 downto 0);
  signal wr_ack_done_int                : std_logic;
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;
  rd_int <= wb_en and not wb_we_i;
  wr_int <= wb_en and wb_we_i;
  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- Assign outputs
  i1Thresholds_highThreshold_o <= i1Thresholds_highThreshold_reg;
  i1Thresholds_lowThreshold_o <= i1Thresholds_lowThreshold_reg;

  -- Process for write requests.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      i1Thresholds_highThreshold_reg <= "0000000000000000";
      i1Thresholds_lowThreshold_reg <= "0000000000000000";
    elsif rising_edge(clk_i) then
      if wr_int = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        -- Register i1Thresholds
        i1Thresholds_highThreshold_reg <= wb_dat_i(31 downto 16);
        i1Thresholds_lowThreshold_reg <= wb_dat_i(15 downto 0);
        wr_ack_int <= not wr_ack_done_int;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (clk_i, rst_n_i) begin
    if rst_n_i = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
    elsif rising_edge(clk_i) then
      if rd_int = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        reg_rdat_int <= (others => '0');
        -- i1Thresholds
        reg_rdat_int(31 downto 16) <= i1Thresholds_highThreshold_reg;
        reg_rdat_int(15 downto 0) <= i1Thresholds_lowThreshold_reg;
      else
        rd_ack1_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    wb_dat_o <= (others => '0');
    rd_ack_int <= '1';
    -- i1Thresholds
    wb_dat_o <= reg_rdat_int;
    rd_ack_int <= rd_ack1_int;
  end process;
end syn;
