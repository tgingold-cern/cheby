library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package nested_iogroup1_pkg is
  type t_regs_master_out is record
    areg             : std_logic_vector(31 downto 0);
    breg1            : std_logic_vector(31 downto 0);
  end record t_regs_master_out;
  subtype t_regs_slave_in is t_regs_master_out;

  type t_regs_slave_out is record
    breg2            : std_logic_vector(31 downto 0);
  end record t_regs_slave_out;
  subtype t_regs_master_in is t_regs_slave_out;

end nested_iogroup1_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.nested_iogroup1_pkg.all;

entity nested_iogroup1 is
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
    regs_i               : in    t_regs_master_in;
    regs_o               : out   t_regs_master_out
  );
end nested_iogroup1;

architecture syn of nested_iogroup1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal areg_reg                       : std_logic_vector(31 downto 0);
  signal areg_wreq                      : std_logic;
  signal areg_wack                      : std_logic;
  signal blk_breg1_reg                  : std_logic_vector(31 downto 0);
  signal blk_breg1_wreq                 : std_logic;
  signal blk_breg1_wack                 : std_logic;
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

  -- Register areg
  regs_o.areg <= areg_reg;
  areg_wack <= areg_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        areg_reg <= "00000000000000000000000000000000";
      else
        if areg_wreq = '1' then
          areg_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_breg1
  regs_o.breg1 <= blk_breg1_reg;
  blk_breg1_wack <= blk_breg1_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_breg1_reg <= "00000000000000000000000000000000";
      else
        if blk_breg1_wreq = '1' then
          blk_breg1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register blk_breg2

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, areg_wack, blk_breg1_wack) begin
    areg_wreq <= '0';
    blk_breg1_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg areg
      areg_wreq <= wr_req_d0;
      wr_ack_int <= areg_wack;
    when "10" =>
      -- Reg blk_breg1
      blk_breg1_wreq <= wr_req_d0;
      wr_ack_int <= blk_breg1_wack;
    when "11" =>
      -- Reg blk_breg2
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, areg_reg, blk_breg1_reg, regs_i.breg2) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg areg
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg_reg;
    when "10" =>
      -- Reg blk_breg1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= blk_breg1_reg;
    when "11" =>
      -- Reg blk_breg2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= regs_i.breg2;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
