library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package repeat_iogroup4_pkg is
  type t_itf_master_out is record
    areg             : std_logic_vector(31 downto 0);
  end record t_itf_master_out;
  subtype t_itf_slave_in is t_itf_master_out;

  type t_itf_slave_out is record
    regf_f0          : std_logic;
    regf_f1          : std_logic;
  end record t_itf_slave_out;
  subtype t_itf_master_in is t_itf_slave_out;

  type t_itf_master_out_array is array(natural range <>) of
    t_itf_master_out;
  subtype t_itf_slave_in_array is t_itf_master_out_array;

  type t_itf_master_in_array is array(natural range <>) of
    t_itf_master_in;
  subtype t_itf_slave_out_array is t_itf_master_in_array;

end repeat_iogroup4_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.repeat_iogroup4_pkg.all;

entity repeat_iogroup4 is
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

    -- the array of registers
    itf_i                : in    t_itf_master_in_array(0 downto 0);
    itf_o                : out   t_itf_master_out_array(0 downto 0)
  );
end repeat_iogroup4;

architecture syn of repeat_iogroup4 is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal arr1_0_areg_reg                : std_logic_vector(31 downto 0);
  signal areg0_wreq                     : std_logic;
  signal areg0_wack                     : std_logic;
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

  -- Register areg0
  itf_o(0).areg <= arr1_0_areg_reg;
  areg0_wack <= areg0_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        arr1_0_areg_reg <= "00000000000000000000000000000000";
      else
        if areg0_wreq = '1' then
          arr1_0_areg_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register regf0

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, areg0_wack) begin
    areg0_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg areg0
      areg0_wreq <= wr_req_d0;
      wr_ack_int <= areg0_wack;
    when "1" =>
      -- Reg regf0
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, arr1_0_areg_reg, itf_i(0).regf_f0,
           itf_i(0).regf_f1) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case wb_adr_i(2 downto 2) is
    when "0" =>
      -- Reg areg0
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0 <= arr1_0_areg_reg;
    when "1" =>
      -- Reg regf0
      rd_ack_d0 <= rd_req_int;
      rd_dat_d0(0) <= itf_i(0).regf_f0;
      rd_dat_d0(1) <= itf_i(0).regf_f1;
      rd_dat_d0(31 downto 2) <= (others => '0');
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
