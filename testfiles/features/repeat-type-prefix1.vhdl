library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package repeat_type_prefix1_pkg is
  type t_chan_master_out is record
    cfg              : std_logic_vector(31 downto 0);
  end record t_chan_master_out;
  subtype t_chan_slave_in is t_chan_master_out;

  type t_chan_master_out_array is array(natural range <>) of
    t_chan_master_out;
  subtype t_chan_slave_in_array is t_chan_master_out_array;

  type t_blk_chan_master_out is record
    depth            : std_logic_vector(31 downto 0);
  end record t_blk_chan_master_out;
  subtype t_blk_chan_slave_in is t_blk_chan_master_out;

  type t_blk_chan_slave_out is record
    val              : std_logic_vector(31 downto 0);
  end record t_blk_chan_slave_out;
  subtype t_blk_chan_master_in is t_blk_chan_slave_out;

  type t_blk_chan_master_out_array is array(natural range <>) of
    t_blk_chan_master_out;
  subtype t_blk_chan_slave_in_array is t_blk_chan_master_out_array;

  type t_blk_chan_master_in_array is array(natural range <>) of
    t_blk_chan_master_in;
  subtype t_blk_chan_slave_out_array is t_blk_chan_master_in_array;

  type t_blk_master_out is record
    ctrl             : std_logic_vector(31 downto 0);
    chan             : t_blk_chan_master_out_array(1 downto 0);
  end record t_blk_master_out;
  subtype t_blk_slave_in is t_blk_master_out;

  type t_blk_slave_out is record
    chan             : t_blk_chan_master_in_array(1 downto 0);
  end record t_blk_slave_out;
  subtype t_blk_master_in is t_blk_slave_out;

end repeat_type_prefix1_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.repeat_type_prefix1_pkg.all;

entity repeat_type_prefix1 is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(5 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- REPEAT chan
    chan_o               : out   t_chan_master_out_array(1 downto 0);
    blk_i                : in    t_blk_master_in;
    blk_o                : out   t_blk_master_out
  );
end repeat_type_prefix1;

architecture syn of repeat_type_prefix1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal chan_0_cfg_reg                 : std_logic_vector(31 downto 0);
  signal chan_0_cfg_wreq                : std_logic;
  signal chan_0_cfg_wack                : std_logic;
  signal chan_1_cfg_reg                 : std_logic_vector(31 downto 0);
  signal chan_1_cfg_wreq                : std_logic;
  signal chan_1_cfg_wack                : std_logic;
  signal blk_ctrl_reg                   : std_logic_vector(31 downto 0);
  signal blk_ctrl_wreq                  : std_logic;
  signal blk_ctrl_wack                  : std_logic;
  signal blk_chan_0_depth_reg           : std_logic_vector(31 downto 0);
  signal blk_chan_0_depth_wreq          : std_logic;
  signal blk_chan_0_depth_wack          : std_logic;
  signal blk_chan_1_depth_reg           : std_logic_vector(31 downto 0);
  signal blk_chan_1_depth_wreq          : std_logic;
  signal blk_chan_1_depth_wack          : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
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
        wr_adr_d0 <= "0000";
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

  -- Register chan_0_cfg
  chan_o(0).cfg <= chan_0_cfg_reg;
  chan_0_cfg_wack <= chan_0_cfg_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_0_cfg_reg <= "00000000000000000000000000000000";
      else
        if chan_0_cfg_wreq = '1' then
          chan_0_cfg_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register chan_1_cfg
  chan_o(1).cfg <= chan_1_cfg_reg;
  chan_1_cfg_wack <= chan_1_cfg_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        chan_1_cfg_reg <= "00000000000000000000000000000000";
      else
        if chan_1_cfg_wreq = '1' then
          chan_1_cfg_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_ctrl
  blk_o.ctrl <= blk_ctrl_reg;
  blk_ctrl_wack <= blk_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_ctrl_reg <= "00000000000000000000000000000000";
      else
        if blk_ctrl_wreq = '1' then
          blk_ctrl_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_chan_0_depth
  blk_o.chan(0).depth <= blk_chan_0_depth_reg;
  blk_chan_0_depth_wack <= blk_chan_0_depth_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_chan_0_depth_reg <= "00000000000000000000000000000000";
      else
        if blk_chan_0_depth_wreq = '1' then
          blk_chan_0_depth_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_chan_0_val

  -- Register blk_chan_1_depth
  blk_o.chan(1).depth <= blk_chan_1_depth_reg;
  blk_chan_1_depth_wack <= blk_chan_1_depth_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_chan_1_depth_reg <= "00000000000000000000000000000000";
      else
        if blk_chan_1_depth_wreq = '1' then
          blk_chan_1_depth_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_chan_1_val

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, chan_0_cfg_wack, chan_1_cfg_wack, blk_ctrl_wack,
           blk_chan_0_depth_wack, blk_chan_1_depth_wack) begin
    chan_0_cfg_wreq <= '0';
    chan_1_cfg_wreq <= '0';
    blk_ctrl_wreq <= '0';
    blk_chan_0_depth_wreq <= '0';
    blk_chan_1_depth_wreq <= '0';
    case wr_adr_d0(5 downto 2) is
    when "0000" =>
      -- Reg chan_0_cfg
      chan_0_cfg_wreq <= wr_req_d0;
      wr_ack_int <= chan_0_cfg_wack;
    when "0001" =>
      -- Reg chan_1_cfg
      chan_1_cfg_wreq <= wr_req_d0;
      wr_ack_int <= chan_1_cfg_wack;
    when "1000" =>
      -- Reg blk_ctrl
      blk_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= blk_ctrl_wack;
    when "1100" =>
      -- Reg blk_chan_0_depth
      blk_chan_0_depth_wreq <= wr_req_d0;
      wr_ack_int <= blk_chan_0_depth_wack;
    when "1101" =>
      -- Reg blk_chan_0_val
      wr_ack_int <= wr_req_d0;
    when "1110" =>
      -- Reg blk_chan_1_depth
      blk_chan_1_depth_wreq <= wr_req_d0;
      wr_ack_int <= blk_chan_1_depth_wack;
    when "1111" =>
      -- Reg blk_chan_1_val
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, chan_0_cfg_reg, chan_1_cfg_reg, blk_ctrl_reg,
           blk_chan_0_depth_reg, blk_i.chan(0).val, blk_chan_1_depth_reg,
           blk_i.chan(1).val) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(5 downto 2) is
    when "0000" =>
      -- Reg chan_0_cfg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_0_cfg_reg;
    when "0001" =>
      -- Reg chan_1_cfg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= chan_1_cfg_reg;
    when "1000" =>
      -- Reg blk_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_ctrl_reg;
    when "1100" =>
      -- Reg blk_chan_0_depth
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_chan_0_depth_reg;
    when "1101" =>
      -- Reg blk_chan_0_val
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_i.chan(0).val;
    when "1110" =>
      -- Reg blk_chan_1_depth
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_chan_1_depth_reg;
    when "1111" =>
      -- Reg blk_chan_1_val
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_i.chan(1).val;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
