library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity orclrout is
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

    -- REG breg
    breg_i               : in    std_logic_vector(31 downto 0);
    breg_o               : out   std_logic_vector(31 downto 0)
  );
end orclrout;

architecture syn of orclrout is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal breg_reg                       : std_logic_vector(31 downto 0);
  signal breg_wreq                      : std_logic;
  signal breg_wack                      : std_logic;
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
        wb_dat_o <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register breg
  breg_o <= breg_reg;
  breg_wack <= breg_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        breg_reg <= "00000000000000000000000000000000";
      else
        if breg_wreq = '1' then
          breg_reg <= breg_i or (breg_reg and not wr_dat_d0);
        else
          breg_reg <= breg_i or breg_reg;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, breg_wack) begin
    breg_wreq <= '0';
    -- Reg breg
    breg_wreq <= wr_req_d0;
    wr_ack_int <= breg_wack;
  end process;

  -- Process for read requests.
  process (rd_req_int, breg_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg breg
    rd_ack_d0 <= rd_req_int;
    rd_dat_d0 <= breg_reg;
  end process;
end syn;
