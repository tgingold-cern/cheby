library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package repeat_name_prefix_false_pkg is
  type t_chan_master_out is record
    ctrl             : std_logic_vector(31 downto 0);
  end record t_chan_master_out;
  subtype t_chan_slave_in is t_chan_master_out;

  type t_chan_master_out_array is array(natural range <>) of
    t_chan_master_out;
  subtype t_chan_slave_in_array is t_chan_master_out_array;

end repeat_name_prefix_false_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.repeat_name_prefix_false_pkg.all;

entity repeat_name_prefix_false is
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

    -- REPEAT chan
    chan_o               : out   t_chan_master_out_array(1 downto 0)
  );
end repeat_name_prefix_false;

architecture syn of repeat_name_prefix_false is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal top_blk_chan0_ctrl_reg         : std_logic_vector(31 downto 0);
  signal chan0_ctrl_wreq                : std_logic;
  signal chan0_ctrl_wack                : std_logic;
  signal top_blk_chan1_ctrl_reg         : std_logic_vector(31 downto 0);
  signal chan1_ctrl_wreq                : std_logic;
  signal chan1_ctrl_wack                : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
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
        wr_adr_d0 <= "0";
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

  -- Register chan0_ctrl
  chan_o(0).ctrl <= top_blk_chan0_ctrl_reg;
  chan0_ctrl_wack <= chan0_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        top_blk_chan0_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan0_ctrl_wreq = '1' then
          top_blk_chan0_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan1_ctrl
  chan_o(1).ctrl <= top_blk_chan1_ctrl_reg;
  chan1_ctrl_wack <= chan1_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        top_blk_chan1_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan1_ctrl_wreq = '1' then
          top_blk_chan1_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, chan0_ctrl_wack, chan1_ctrl_wack) begin
    chan0_ctrl_wreq <= '0';
    chan1_ctrl_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg chan0_ctrl
      chan0_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan0_ctrl_wack;
    when "1" =>
      -- Reg chan1_ctrl
      chan1_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan1_ctrl_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, top_blk_chan0_ctrl_reg, top_blk_chan1_ctrl_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(2 downto 2) is
    when "0" =>
      -- Reg chan0_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= top_blk_chan0_ctrl_reg;
    when "1" =>
      -- Reg chan1_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= top_blk_chan1_ctrl_reg;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
