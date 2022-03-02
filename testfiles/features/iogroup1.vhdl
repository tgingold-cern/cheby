library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package iogroup1_pkg is
  type t_ios_master_out is record
    areg1            : std_logic_vector(31 downto 0);
    areg3            : std_logic_vector(31 downto 0);
    areg3_wr         : std_logic;
    areg4            : std_logic_vector(31 downto 0);
    areg4_wr         : std_logic;
    areg4_rd         : std_logic;
  end record t_ios_master_out;
  subtype t_ios_slave_in is t_ios_master_out;

  type t_ios_slave_out is record
    areg2            : std_logic_vector(31 downto 0);
    areg4            : std_logic_vector(31 downto 0);
    areg4_wack       : std_logic;
    areg4_rack       : std_logic;
  end record t_ios_slave_out;
  subtype t_ios_master_in is t_ios_slave_out;

end iogroup1_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.iogroup1_pkg.all;

entity iogroup1 is
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
    ios_i                : in    t_ios_master_in;
    ios_o                : out   t_ios_master_out
  );
end iogroup1;

architecture syn of iogroup1 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal areg1_reg                      : std_logic_vector(31 downto 0);
  signal areg1_wreq                     : std_logic;
  signal areg1_wack                     : std_logic;
  signal areg3_reg                      : std_logic_vector(31 downto 0);
  signal areg3_wreq                     : std_logic;
  signal areg3_wack                     : std_logic;
  signal areg4_wreq                     : std_logic;
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

  -- Register areg1
  ios_o.areg1 <= areg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        areg1_reg <= "00000000000000000000000000000000";
        areg1_wack <= '0';
      else
        if areg1_wreq = '1' then
          areg1_reg <= wr_dat_d0;
        end if;
        areg1_wack <= areg1_wreq;
      end if;
    end if;
  end process;

  -- Register areg2

  -- Register areg3
  ios_o.areg3 <= areg3_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        areg3_reg <= "00000000000000000000000000000000";
        areg3_wack <= '0';
      else
        if areg3_wreq = '1' then
          areg3_reg <= wr_dat_d0;
        end if;
        areg3_wack <= areg3_wreq;
      end if;
    end if;
  end process;
  ios_o.areg3_wr <= areg3_wack;

  -- Register areg4
  ios_o.areg4 <= wr_dat_d0;
  ios_o.areg4_wr <= areg4_wreq;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, areg1_wack, areg3_wack, ios_i.areg4_wack) begin
    areg1_wreq <= '0';
    areg3_wreq <= '0';
    areg4_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg areg1
      areg1_wreq <= wr_req_d0;
      wr_ack_int <= areg1_wack;
    when "01" =>
      -- Reg areg2
      wr_ack_int <= wr_req_d0;
    when "10" =>
      -- Reg areg3
      areg3_wreq <= wr_req_d0;
      wr_ack_int <= areg3_wack;
    when "11" =>
      -- Reg areg4
      areg4_wreq <= wr_req_d0;
      wr_ack_int <= ios_i.areg4_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, areg1_reg, ios_i.areg2, ios_i.areg4_rack, ios_i.areg4) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ios_o.areg4_rd <= '0';
    case wb_adr_i(3 downto 2) is
    when "00" =>
      -- Reg areg1
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= areg1_reg;
    when "01" =>
      -- Reg areg2
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= ios_i.areg2;
    when "10" =>
      -- Reg areg3
      rd_ack_d0 <= rd_req_int;
    when "11" =>
      -- Reg areg4
      ios_o.areg4_rd <= rd_req_int;
      rd_ack_d0 <= ios_i.areg4_rack;
      rd_dat_d0 <= ios_i.areg4;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
