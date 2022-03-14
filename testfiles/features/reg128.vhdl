library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg128 is
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

    -- REG areg
    areg_o               : out   std_logic_vector(127 downto 0)
  );
end reg128;

architecture syn of reg128 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal areg_reg                       : std_logic_vector(127 downto 0);
  signal areg_wreq                      : std_logic_vector(3 downto 0);
  signal areg_wack                      : std_logic_vector(3 downto 0);
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
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
      end if;
    end if;
  end process;

  -- Register areg
  areg_o <= areg_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        areg_reg <= "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        areg_wack <= (others => '0');
      else
        if areg_wreq(0) = '1' then
          areg_reg(31 downto 0) <= wr_dat_d0;
        end if;
        if areg_wreq(1) = '1' then
          areg_reg(63 downto 32) <= wr_dat_d0;
        end if;
        if areg_wreq(2) = '1' then
          areg_reg(95 downto 64) <= wr_dat_d0;
        end if;
        if areg_wreq(3) = '1' then
          areg_reg(127 downto 96) <= wr_dat_d0;
        end if;
        areg_wack <= areg_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, areg_wack) begin
    areg_wreq <= (others => '0');
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg areg
      areg_wreq(3) <= wr_req_d0;
      wr_ack_int <= areg_wack(3);
    when "01" =>
      -- Reg areg
      areg_wreq(2) <= wr_req_d0;
      wr_ack_int <= areg_wack(2);
    when "10" =>
      -- Reg areg
      areg_wreq(1) <= wr_req_d0;
      wr_ack_int <= areg_wack(1);
    when "11" =>
      -- Reg areg
      areg_wreq(0) <= wr_req_d0;
      wr_ack_int <= areg_wack(0);
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, areg_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg areg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg_reg(127 downto 96);
    when "01" =>
      -- Reg areg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg_reg(95 downto 64);
    when "10" =>
      -- Reg areg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg_reg(63 downto 32);
    when "11" =>
      -- Reg areg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg_reg(31 downto 0);
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
