library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package reuse_submap2_pkg is
  type t_leaf_master_out is record
    ctrl_enable      : std_logic;
    ctrl_mode        : std_logic_vector(2 downto 0);
    ctrl_divisor     : std_logic_vector(7 downto 0);
  end record t_leaf_master_out;
  subtype t_leaf_slave_in is t_leaf_master_out;

  type t_leaf_slave_out is record
    status_ready     : std_logic;
    status_count     : std_logic_vector(15 downto 0);
  end record t_leaf_slave_out;
  subtype t_leaf_master_in is t_leaf_slave_out;

  type t_leaf_master_out_array is array(natural range <>) of
    t_leaf_master_out;
  subtype t_leaf_slave_in_array is t_leaf_master_out_array;

  type t_leaf_master_in_array is array(natural range <>) of
    t_leaf_master_in;
  subtype t_leaf_slave_out_array is t_leaf_master_in_array;

  type t_top_master_out is record
    leaf             : t_leaf_master_out_array(1 downto 0);
  end record t_top_master_out;
  subtype t_top_slave_in is t_top_master_out;

  type t_top_slave_out is record
    leaf             : t_leaf_master_in_array(1 downto 0);
  end record t_top_slave_out;
  subtype t_top_master_in is t_top_slave_out;

end reuse_submap2_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.reuse_submap2_pkg.all;

entity reuse_submap2 is
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
    -- Wires and registers
    top_i                : in    t_top_master_in;
    top_o                : out   t_top_master_out
  );
end reuse_submap2;

architecture syn of reuse_submap2 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal leaf_0_leaf_ctrl_enable_reg    : std_logic;
  signal leaf_0_leaf_ctrl_mode_reg      : std_logic_vector(2 downto 0);
  signal leaf_0_leaf_ctrl_divisor_reg   : std_logic_vector(7 downto 0);
  signal leaf_0_ctrl_wreq               : std_logic;
  signal leaf_0_ctrl_wack               : std_logic;
  signal leaf_1_leaf_ctrl_enable_reg    : std_logic;
  signal leaf_1_leaf_ctrl_mode_reg      : std_logic_vector(2 downto 0);
  signal leaf_1_leaf_ctrl_divisor_reg   : std_logic_vector(7 downto 0);
  signal leaf_1_ctrl_wreq               : std_logic;
  signal leaf_1_ctrl_wack               : std_logic;
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

  -- Register leaf_0_ctrl
  top_o.leaf(0).ctrl_enable <= leaf_0_leaf_ctrl_enable_reg;
  top_o.leaf(0).ctrl_mode <= leaf_0_leaf_ctrl_mode_reg;
  top_o.leaf(0).ctrl_divisor <= leaf_0_leaf_ctrl_divisor_reg;
  leaf_0_ctrl_wack <= leaf_0_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        leaf_0_leaf_ctrl_enable_reg <= '0';
        leaf_0_leaf_ctrl_mode_reg <= "000";
        leaf_0_leaf_ctrl_divisor_reg <= "00000000";
      else
        if leaf_0_ctrl_wreq = '1' then
          leaf_0_leaf_ctrl_enable_reg <= wr_dat_d0(0);
          leaf_0_leaf_ctrl_mode_reg <= wr_dat_d0(3 downto 1);
          leaf_0_leaf_ctrl_divisor_reg <= wr_dat_d0(15 downto 8);
        end if;
      end if;
    end if;
  end process;

  -- Register leaf_0_status

  -- Register leaf_1_ctrl
  top_o.leaf(1).ctrl_enable <= leaf_1_leaf_ctrl_enable_reg;
  top_o.leaf(1).ctrl_mode <= leaf_1_leaf_ctrl_mode_reg;
  top_o.leaf(1).ctrl_divisor <= leaf_1_leaf_ctrl_divisor_reg;
  leaf_1_ctrl_wack <= leaf_1_ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        leaf_1_leaf_ctrl_enable_reg <= '0';
        leaf_1_leaf_ctrl_mode_reg <= "000";
        leaf_1_leaf_ctrl_divisor_reg <= "00000000";
      else
        if leaf_1_ctrl_wreq = '1' then
          leaf_1_leaf_ctrl_enable_reg <= wr_dat_d0(0);
          leaf_1_leaf_ctrl_mode_reg <= wr_dat_d0(3 downto 1);
          leaf_1_leaf_ctrl_divisor_reg <= wr_dat_d0(15 downto 8);
        end if;
      end if;
    end if;
  end process;

  -- Register leaf_1_status

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, leaf_0_ctrl_wack, leaf_1_ctrl_wack) begin
    leaf_0_ctrl_wreq <= '0';
    leaf_1_ctrl_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg leaf_0_ctrl
      leaf_0_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= leaf_0_ctrl_wack;
    when "01" =>
      -- Reg leaf_0_status
      wr_ack_int <= wr_req_d0;
    when "10" =>
      -- Reg leaf_1_ctrl
      leaf_1_ctrl_wreq <= wr_req_d0;
      wr_ack_int <= leaf_1_ctrl_wack;
    when "11" =>
      -- Reg leaf_1_status
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, leaf_0_leaf_ctrl_enable_reg,
           leaf_0_leaf_ctrl_mode_reg, leaf_0_leaf_ctrl_divisor_reg,
           top_i.leaf(0).status_ready, top_i.leaf(0).status_count,
           leaf_1_leaf_ctrl_enable_reg, leaf_1_leaf_ctrl_mode_reg,
           leaf_1_leaf_ctrl_divisor_reg, top_i.leaf(1).status_ready,
           top_i.leaf(1).status_count) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg leaf_0_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= leaf_0_leaf_ctrl_enable_reg;
      rd_dat_d0(3 downto 1) <= leaf_0_leaf_ctrl_mode_reg;
      rd_dat_d0(7 downto 4) <= (others => '0');
      rd_dat_d0(15 downto 8) <= leaf_0_leaf_ctrl_divisor_reg;
      rd_dat_d0(31 downto 16) <= (others => '0');
    when "01" =>
      -- Reg leaf_0_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= top_i.leaf(0).status_ready;
      rd_dat_d0(15 downto 1) <= (others => '0');
      rd_dat_d0(31 downto 16) <= top_i.leaf(0).status_count;
    when "10" =>
      -- Reg leaf_1_ctrl
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= leaf_1_leaf_ctrl_enable_reg;
      rd_dat_d0(3 downto 1) <= leaf_1_leaf_ctrl_mode_reg;
      rd_dat_d0(7 downto 4) <= (others => '0');
      rd_dat_d0(15 downto 8) <= leaf_1_leaf_ctrl_divisor_reg;
      rd_dat_d0(31 downto 16) <= (others => '0');
    when "11" =>
      -- Reg leaf_1_status
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= top_i.leaf(1).status_ready;
      rd_dat_d0(15 downto 1) <= (others => '0');
      rd_dat_d0(31 downto 16) <= top_i.leaf(1).status_count;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
