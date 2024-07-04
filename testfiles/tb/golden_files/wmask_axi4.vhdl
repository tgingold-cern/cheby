library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity wmask_axi4 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(5 downto 2);
    awprot               : in    std_logic_vector(2 downto 0);
    wvalid               : in    std_logic;
    wready               : out   std_logic;
    wdata                : in    std_logic_vector(31 downto 0);
    wstrb                : in    std_logic_vector(3 downto 0);
    bvalid               : out   std_logic;
    bready               : in    std_logic;
    bresp                : out   std_logic_vector(1 downto 0);
    arvalid              : in    std_logic;
    arready              : out   std_logic;
    araddr               : in    std_logic_vector(5 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- REG reg_rw
    reg_rw_o             : out   std_logic_vector(31 downto 0);

    -- REG reg_ro
    reg_ro_i             : in    std_logic_vector(31 downto 0);

    -- REG reg_wo
    reg_wo_o             : out   std_logic_vector(31 downto 0);

    -- REG wire_rw
    wire_rw_i            : in    std_logic_vector(31 downto 0);
    wire_rw_o            : out   std_logic_vector(31 downto 0);
    wire_rw_wmask_o      : out   std_logic_vector(31 downto 0);

    -- REG wire_ro
    wire_ro_i            : in    std_logic_vector(31 downto 0);

    -- REG wire_wo
    wire_wo_o            : out   std_logic_vector(31 downto 0);
    wire_wo_wmask_o      : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_row1_rd_i       : in    std_logic;
    ram1_row1_dat_o      : out   std_logic_vector(31 downto 0)
  );
end wmask_axi4;

architecture syn of wmask_axi4 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(5 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(5 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
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

  -- AW, W and B channels
  awready <= not axi_awset;
  wready <= not axi_wset;
  bvalid <= axi_wdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wr_req <= '0';
        axi_awset <= '0';
        axi_wset <= '0';
        axi_wdone <= '0';
      else
        wr_req <= '0';
        if awvalid = '1' and axi_awset = '0' then
          wr_addr <= awaddr;
          axi_awset <= '1';
          wr_req <= axi_wset;
        end if;
        if wvalid = '1' and axi_wset = '0' then
          wr_data <= wdata;
          wr_sel(7 downto 0) <= (others => wstrb(0));
          wr_sel(15 downto 8) <= (others => wstrb(1));
          wr_sel(23 downto 16) <= (others => wstrb(2));
          wr_sel(31 downto 24) <= (others => wstrb(3));
          axi_wset <= '1';
          wr_req <= axi_awset or awvalid;
        end if;
        if (axi_wdone and bready) = '1' then
          axi_wset <= '0';
          axi_awset <= '0';
          axi_wdone <= '0';
        end if;
        if wr_ack = '1' then
          axi_wdone <= '1';
        end if;
      end if;
    end if;
  end process;
  bresp <= "00";

  -- AR and R channels
  arready <= not axi_arset;
  rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req <= '0';
        axi_arset <= '0';
        axi_rdone <= '0';
        rdata <= (others => '0');
      else
        rd_req <= '0';
        if arvalid = '1' and axi_arset = '0' then
          rd_addr <= araddr;
          axi_arset <= '1';
          rd_req <= '1';
        end if;
        if (axi_rdone and rready) = '1' then
          axi_arset <= '0';
          axi_rdone <= '0';
        end if;
        if rd_ack = '1' then
          axi_rdone <= '1';
          rdata <= rd_data;
        end if;
      end if;
    end if;
  end process;
  rresp <= "00";

  -- pipelining for wr-in+rd-out
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
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
  reg_rw_wack <= reg_rw_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg_rw_reg <= "00000000000000000000000000000000";
      else
        if reg_rw_wreq = '1' then
          reg_rw_reg <= (reg_rw_reg and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);
        end if;
      end if;
    end if;
  end process;

  -- Register reg_ro

  -- Register reg_wo
  reg_wo_o <= reg_wo_reg;
  reg_wo_wack <= reg_wo_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg_wo_reg <= "00000000000000000000000000000000";
      else
        if reg_wo_wreq = '1' then
          reg_wo_reg <= (reg_wo_reg and not wr_sel_d0) or (wr_dat_d0 and wr_sel_d0);
        end if;
      end if;
    end if;
  end process;

  -- Register wire_rw
  wire_rw_o <= wr_dat_d0;
  wire_rw_wmask_o <= wr_sel_d0;

  -- Register wire_ro

  -- Register wire_wo
  wire_wo_o <= wr_dat_d0;
  wire_wo_wmask_o <= wr_sel_d0;

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
      clk_a_i              => aclk,
      clk_b_i              => aclk,
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
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
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
