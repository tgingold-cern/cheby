library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity wmask_wb is
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

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_row1_rd_i       : in    std_logic;
    ram1_row1_dat_o      : out   std_logic_vector(31 downto 0)
  );
end wmask_wb;

architecture syn of wmask_wb is
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal ram1_row1_int_dato             : std_logic_vector(31 downto 0);
  signal ram1_row1_ext_dat              : std_logic_vector(31 downto 0);
  signal ram1_row1_rreq                 : std_logic;
  signal ram1_row1_rack                 : std_logic;
  signal ram1_row1_int_wr               : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
  signal ram1_wr                        : std_logic;
  signal ram1_wreq                      : std_logic;
  signal ram1_adr_int                   : std_logic_vector(2 downto 0);
  signal ram1_sel_int                   : std_logic_vector(3 downto 0);
begin

  -- WB decode signals
  process (wb_sel_i) begin
    wr_sel(7 downto 0) <= (others => wb_sel_i(0));
    wr_sel(15 downto 8) <= (others => wb_sel_i(1));
    wr_sel(23 downto 16) <= (others => wb_sel_i(2));
    wr_sel(31 downto 24) <= (others => wb_sel_i(3));
  end process;
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
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Register reg1
  reg1_o <= reg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg1_reg <= "00000000000000000000000000000000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= (reg1_reg and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Memory ram1
  process (wb_adr_i, wr_adr_d0, ram1_wr) begin
    if ram1_wr = '1' then
      ram1_adr_int <= wr_adr_d0(4 downto 2);
    else
      ram1_adr_int <= wb_adr_i(4 downto 2);
    end if;
  end process;
  ram1_wreq <= ram1_row1_int_wr;
  ram1_wr <= ram1_wreq;
  ram1_row1_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => ram1_adr_int,
      bwsel_a_i            => ram1_sel_int,
      data_a_i             => wr_dat_d0,
      data_a_o             => ram1_row1_int_dato,
      rd_a_i               => ram1_row1_rreq,
      wr_a_i               => ram1_row1_int_wr,
      addr_b_i             => ram1_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram1_row1_ext_dat,
      data_b_o             => ram1_row1_dat_o,
      rd_b_i               => ram1_row1_rd_i,
      wr_b_i               => '0'
    );
  
  process (wr_sel_d0) begin
    ram1_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      ram1_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      ram1_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      ram1_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      ram1_sel_int(3) <= '1';
    end if;
  end process;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram1_row1_rack <= '0';
      else
        ram1_row1_rack <= ram1_row1_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack) begin
    reg1_wreq <= '0';
    ram1_row1_int_wr <= '0';
    case wr_adr_d0(5 downto 5) is
    when "0" =>
      case wr_adr_d0(4 downto 2) is
      when "000" =>
        -- Reg reg1
        reg1_wreq <= wr_req_d0;
        wr_ack_int <= reg1_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "1" =>
      -- Memory ram1
      ram1_row1_int_wr <= wr_req_d0;
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (wb_adr_i, rd_req_int, reg1_reg, ram1_row1_int_dato, ram1_row1_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ram1_row1_rreq <= '0';
    case wb_adr_i(5 downto 5) is
    when "0" =>
      case wb_adr_i(4 downto 2) is
      when "000" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= reg1_reg;
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "1" =>
      -- Memory ram1
      rd_dat_d0 <= ram1_row1_int_dato;
      ram1_row1_rreq <= rd_req_int;
      rd_ack_d0 <= ram1_row1_rack;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
