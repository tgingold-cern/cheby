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
    i1Thresholds_i       : in    std_logic_vector(31 downto 0)
  );
end sreg;

architecture syn of sreg is
  signal rd_int                         : std_logic;
  signal wr_int                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
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
  rd_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- Assign outputs

  -- Process for write requests.
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wr_ack_int <= '0';
      else
        wr_ack_int <= '0';
        -- Register i1Thresholds
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack1_int <= '0';
      else
        reg_rdat_int <= (others => '0');
        -- i1Thresholds
        reg_rdat_int(31 downto 16) <= i1Thresholds_i(31 downto 16);
        reg_rdat_int(15 downto 0) <= i1Thresholds_i(15 downto 0);
        rd_ack1_int <= rd_int;
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (reg_rdat_int, rd_ack1_int, rd_int) begin
    -- By default ack read requests
    wb_dat_o <= (others => '0');
    -- i1Thresholds
    wb_dat_o <= reg_rdat_int;
    rd_ack_int <= rd_ack1_int;
  end process;
end syn;
