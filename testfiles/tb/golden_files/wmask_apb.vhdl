library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity wmask_apb is
  port (
    pclk                 : in    std_logic;
    presetn              : in    std_logic;
    paddr                : in    std_logic_vector(5 downto 2);
    psel                 : in    std_logic;
    pwrite               : in    std_logic;
    penable              : in    std_logic;
    pready               : out   std_logic;
    pwdata               : in    std_logic_vector(31 downto 0);
    pstrb                : in    std_logic_vector(3 downto 0);
    prdata               : out   std_logic_vector(31 downto 0);
    pslverr              : out   std_logic;

    -- REG reg_rw
    reg_rw_o             : out   std_logic_vector(31 downto 0);

    -- REG reg_ro
    reg_ro_i             : in    std_logic_vector(31 downto 0);

    -- REG reg_wo
    reg_wo_o             : out   std_logic_vector(31 downto 0);

    -- REG wire_rw
    wire_rw_i            : in    std_logic_vector(31 downto 0);
    wire_rw_o            : out   std_logic_vector(31 downto 0);

    -- REG wire_ro
    wire_ro_i            : in    std_logic_vector(31 downto 0);

    -- REG wire_wo
    wire_wo_o            : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_row1_rd_i       : in    std_logic;
    ram1_row1_dat_o      : out   std_logic_vector(31 downto 0)
  );
end wmask_apb;

architecture syn of wmask_apb is
  signal wr_req                         : std_logic;
  signal wr_addr                        : std_logic_vector(5 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal rd_req                         : std_logic;
  signal rd_addr                        : std_logic_vector(5 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal wr_ack                         : std_logic;
  signal rd_ack                         : std_logic;
  signal reg_rw_reg                     : std_logic_vector(31 downto 0);
  signal reg_rw_wreq                    : std_logic;
  signal reg_rw_wack                    : std_logic;
  signal reg_wo_reg                     : std_logic_vector(31 downto 0);
  signal reg_wo_wreq                    : std_logic;
  signal reg_wo_wack                    : std_logic;
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

  -- Write Channel
  wr_req <= (psel and pwrite) and not penable;
  wr_addr <= paddr;
  wr_data <= pwdata;
  process (pstrb) begin
    wr_sel(7 downto 0) <= (others => pstrb(0));
    wr_sel(15 downto 8) <= (others => pstrb(1));
    wr_sel(23 downto 16) <= (others => pstrb(2));
    wr_sel(31 downto 24) <= (others => pstrb(3));
  end process;

  -- Read Channel
  rd_req <= (psel and not pwrite) and not penable;
  rd_addr <= paddr;
  prdata <= rd_data;
  pready <= wr_ack or rd_ack;
  pslverr <= '0';

  -- pipelining for wr-in+rd-out
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        rd_ack <= '0';
        rd_data <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0000";
        wr_dat_d0 <= "00000000000000000000000000000000";
        wr_sel_d0 <= "00000000000000000000000000000000";
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Register reg_rw
  reg_rw_o <= reg_rw_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg_rw_reg <= "00000000000000000000000000000000";
        reg_rw_wack <= '0';
      else
        if reg_rw_wreq = '1' then
          reg_rw_reg <= (reg_rw_reg and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);
        end if;
        reg_rw_wack <= reg_rw_wreq;
      end if;
    end if;
  end process;

  -- Register reg_ro

  -- Register reg_wo
  reg_wo_o <= reg_wo_reg;
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        reg_wo_reg <= "00000000000000000000000000000000";
        reg_wo_wack <= '0';
      else
        if reg_wo_wreq = '1' then
          reg_wo_reg <= (reg_wo_reg and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);
        end if;
        reg_wo_wack <= reg_wo_wreq;
      end if;
    end if;
  end process;

  -- Register wire_rw
  wire_rw_o <= (wire_rw_i and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);

  -- Register wire_ro

  -- Register wire_wo
  wire_wo_o <= wr_dat_d0;

  -- Memory ram1
  process (rd_addr, wr_adr_d0, ram1_wr) begin
    if ram1_wr = '1' then
      ram1_adr_int <= wr_adr_d0(4 downto 2);
    else
      ram1_adr_int <= rd_addr(4 downto 2);
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
      clk_a_i              => pclk,
      clk_b_i              => pclk,
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
  process (pclk) begin
    if rising_edge(pclk) then
      if presetn = '0' then
        ram1_row1_rack <= '0';
      else
        ram1_row1_rack <= (ram1_row1_rreq and not ram1_wreq) and not ram1_row1_rack;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg_rw_wack, reg_wo_wack) begin
    reg_rw_wreq <= '0';
    reg_wo_wreq <= '0';
    ram1_row1_int_wr <= '0';
    case wr_adr_d0(5 downto 5) is
    when "0" =>
      case wr_adr_d0(4 downto 2) is
      when "000" =>
        -- Reg reg_rw
        reg_rw_wreq <= wr_req_d0;
        wr_ack <= reg_rw_wack;
      when "001" =>
        -- Reg reg_ro
        wr_ack <= wr_req_d0;
      when "010" =>
        -- Reg reg_wo
        reg_wo_wreq <= wr_req_d0;
        wr_ack <= reg_wo_wack;
      when "011" =>
        -- Reg wire_rw
        wr_ack <= wr_req_d0;
      when "100" =>
        -- Reg wire_ro
        wr_ack <= wr_req_d0;
      when "101" =>
        -- Reg wire_wo
        wr_ack <= wr_req_d0;
      when others =>
        wr_ack <= wr_req_d0;
      end case;
    when "1" =>
      -- Memory ram1
      ram1_row1_int_wr <= wr_req_d0;
      wr_ack <= wr_req_d0;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg_rw_reg, reg_ro_i, wire_rw_i, wire_ro_i,
           ram1_row1_int_dato, ram1_wreq, ram1_row1_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ram1_row1_rreq <= '0';
    case rd_addr(5 downto 5) is
    when "0" =>
      case rd_addr(4 downto 2) is
      when "000" =>
        -- Reg reg_rw
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg_rw_reg;
      when "001" =>
        -- Reg reg_ro
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg_ro_i;
      when "010" =>
        -- Reg reg_wo
        rd_ack_d0 <= rd_req;
      when "011" =>
        -- Reg wire_rw
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= wire_rw_i;
      when "100" =>
        -- Reg wire_ro
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= wire_ro_i;
      when "101" =>
        -- Reg wire_wo
        rd_ack_d0 <= rd_req;
      when others =>
        rd_ack_d0 <= rd_req;
      end case;
    when "1" =>
      -- Memory ram1
      rd_dat_d0 <= ram1_row1_int_dato;
      ram1_row1_rreq <= rd_req and not ram1_wreq;
      rd_ack_d0 <= ram1_row1_rack;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
