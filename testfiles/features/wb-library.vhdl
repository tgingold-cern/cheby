library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library wb_lib;
use wb_lib.wishbone_pkg.all;

entity WB_lib_test is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- REG REG_B
    REG_B_o              : out   std_logic_vector(31 downto 0)
  );
end WB_lib_test;

architecture syn of WB_lib_test is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal REG_B_reg                      : std_logic_vector(31 downto 0);
  signal REG_B_wreq                     : std_logic;
  signal REG_B_wack                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wb_o.dat <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_dat_d0 <= wb_i.dat;
      end if;
    end if;
  end process;

  -- Register REG_B
  REG_B_o <= REG_B_reg;
  REG_B_wack <= REG_B_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        REG_B_reg <= "00000000000000000000000000000000";
      else
        if REG_B_wreq = '1' then
          REG_B_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, REG_B_wack) begin
    REG_B_wreq <= '0';
    -- Reg REG_B
    REG_B_wreq <= wr_req_d0;
    wr_ack_int <= REG_B_wack;
  end process;

  -- Process for read requests.
  process (rd_req_int, REG_B_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg REG_B
    rd_ack_d0 <= rd_req_int;
    rd_dat_d0 <= REG_B_reg;
  end process;
end syn;
