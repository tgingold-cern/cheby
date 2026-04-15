library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package repeat_indexing1_pkg is
  type t_itf_master_out is record
    ctrl             : std_logic_vector(31 downto 0);
  end record t_itf_master_out;
  subtype t_itf_slave_in is t_itf_master_out;

  type t_itf_slave_out is record
    status           : std_logic_vector(31 downto 0);
  end record t_itf_slave_out;
  subtype t_itf_master_in is t_itf_slave_out;

  type t_itf_master_out_array is array(natural range <>) of
    t_itf_master_out;
  subtype t_itf_slave_in_array is t_itf_master_out_array;

  type t_itf_master_in_array is array(natural range <>) of
    t_itf_master_in;
  subtype t_itf_slave_out_array is t_itf_master_in_array;

end repeat_indexing1_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.repeat_indexing1_pkg.all;

entity repeat_indexing1 is
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

    -- REPEAT chan
    itf_i                : in    t_itf_master_in_array(3 downto 0);
    itf_o                : out   t_itf_master_out_array(3 downto 0)
  );
end repeat_indexing1;

architecture syn of repeat_indexing1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal chan_0_ctrl_reg                : std_logic_vector(31 downto 0);
  signal chan_0_ctrl_wreq               : std_logic;
  signal chan_0_ctrl_wack               : std_logic;
  signal chan_1_ctrl_reg                : std_logic_vector(31 downto 0);
  signal chan_1_ctrl_wreq               : std_logic;
  signal chan_1_ctrl_wack               : std_logic;
  signal chan_2_ctrl_reg                : std_logic_vector(31 downto 0);
  signal chan_2_ctrl_wreq               : std_logic;
  signal chan_2_ctrl_wack               : std_logic;
  signal chan_3_ctrl_reg                : std_logic_vector(31 downto 0);
  signal chan_3_ctrl_wreq               : std_logic;
  signal chan_3_ctrl_wack               : std_logic;
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

  -- Register chan_0_ctrl
  itf_o(0).ctrl <= chan_0_ctrl_reg;
  chan_0_ctrl_wack <= chan_0_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_0_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan_0_ctrl_wreq = '1' then
          chan_0_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan_0_status

  -- Register chan_1_ctrl
  itf_o(1).ctrl <= chan_1_ctrl_reg;
  chan_1_ctrl_wack <= chan_1_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_1_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan_1_ctrl_wreq = '1' then
          chan_1_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan_1_status

  -- Register chan_2_ctrl
  itf_o(2).ctrl <= chan_2_ctrl_reg;
  chan_2_ctrl_wack <= chan_2_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_2_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan_2_ctrl_wreq = '1' then
          chan_2_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan_2_status

  -- Register chan_3_ctrl
  itf_o(3).ctrl <= chan_3_ctrl_reg;
  chan_3_ctrl_wack <= chan_3_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_3_ctrl_reg <= "00000000000000000000000000000000";
      else
        if chan_3_ctrl_wreq = '1' then
          chan_3_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan_3_status

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, chan_0_ctrl_wack, chan_1_ctrl_wack,
           chan_2_ctrl_wack, chan_3_ctrl_wack) begin
    chan_0_ctrl_wreq <= '0';
    chan_1_ctrl_wreq <= '0';
    chan_2_ctrl_wreq <= '0';
    chan_3_ctrl_wreq <= '0';
    case wr_adr_d0(4 downto 2) is
    when "000" =>
      -- Reg chan_0_ctrl
      chan_0_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan_0_ctrl_wack;
    when "001" =>
      -- Reg chan_0_status
      wr_ack_int <= wr_req_d0;
    when "010" =>
      -- Reg chan_1_ctrl
      chan_1_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan_1_ctrl_wack;
    when "011" =>
      -- Reg chan_1_status
      wr_ack_int <= wr_req_d0;
    when "100" =>
      -- Reg chan_2_ctrl
      chan_2_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan_2_ctrl_wack;
    when "101" =>
      -- Reg chan_2_status
      wr_ack_int <= wr_req_d0;
    when "110" =>
      -- Reg chan_3_ctrl
      chan_3_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= chan_3_ctrl_wack;
    when "111" =>
      -- Reg chan_3_status
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, chan_0_ctrl_reg, itf_i(0).status, chan_1_ctrl_reg,
           itf_i(1).status, chan_2_ctrl_reg, itf_i(2).status, chan_3_ctrl_reg,
           itf_i(3).status) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(4 downto 2) is
    when "000" =>
      -- Reg chan_0_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_0_ctrl_reg;
    when "001" =>
      -- Reg chan_0_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= itf_i(0).status;
    when "010" =>
      -- Reg chan_1_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_1_ctrl_reg;
    when "011" =>
      -- Reg chan_1_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= itf_i(1).status;
    when "100" =>
      -- Reg chan_2_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_2_ctrl_reg;
    when "101" =>
      -- Reg chan_2_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= itf_i(2).status;
    when "110" =>
      -- Reg chan_3_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_3_ctrl_reg;
    when "111" =>
      -- Reg chan_3_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= itf_i(3).status;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
