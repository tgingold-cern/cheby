library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity buserr_mem_int is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(7 downto 2);
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
    araddr               : in    std_logic_vector(7 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- REG scratch
    scratch_o            : out   std_logic_vector(31 downto 0);

    -- RAM port for lut
    lut_adr_i            : in    std_logic_vector(4 downto 0);
    lut_value_rd_i       : in    std_logic;
    lut_value_dat_o      : out   std_logic_vector(31 downto 0)
  );
end buserr_mem_int;

architecture syn of buserr_mem_int is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_err                         : std_logic;
  signal wr_addr                        : std_logic_vector(7 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal axi_werr                       : std_logic_vector(1 downto 0);
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_err                         : std_logic;
  signal rd_addr                        : std_logic_vector(7 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal axi_rerr                       : std_logic_vector(1 downto 0);
  signal scratch_reg                    : std_logic_vector(31 downto 0);
  signal scratch_wreq                   : std_logic;
  signal scratch_wack                   : std_logic;
  signal lut_value_int_dato             : std_logic_vector(31 downto 0);
  signal lut_value_ext_dat              : std_logic_vector(31 downto 0);
  signal lut_value_rreq                 : std_logic;
  signal lut_value_rack                 : std_logic;
  signal lut_value_int_wr               : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(7 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
  signal lut_wr                         : std_logic;
  signal lut_wreq                       : std_logic;
  signal lut_adr_int                    : std_logic_vector(4 downto 0);
  signal lut_sel_int                    : std_logic_vector(3 downto 0);
begin

  -- AW, W and B channels
  awready <= not axi_awset;
  wready <= not axi_wset;
  bvalid <= axi_wdone or not areset_n;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wr_req <= '0';
        axi_awset <= '0';
        axi_wset <= '0';
        -- During reset, return error (BVALID is forced by the reset signal)
        axi_wdone <= '0';
        axi_werr <= "10";
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
          if wr_err = '0' then
            axi_werr <= "00";
          else
            axi_werr <= "10";
          end if;
        end if;
      end if;
    end if;
  end process;
  bresp <= axi_werr;

  -- AR and R channels
  arready <= not axi_arset;
  rvalid <= axi_rdone or not areset_n;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req <= '0';
        axi_arset <= '0';
        -- During reset, return error (RVALID is forced by the reset signal)
        axi_rdone <= '0';
        axi_rerr <= "10";
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
          if rd_err = '0' then
            axi_rerr <= "00";
          else
            axi_rerr <= "10";
          end if;
        end if;
      end if;
    end if;
  end process;
  rresp <= axi_rerr;

  -- pipelining for wr-in+rd-out
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_ack <= '0';
        rd_err <= '0';
        rd_data <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
        wr_sel_d0 <= "00000000000000000000000000000000";
      else
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_sel;
      end if;
    end if;
  end process;

  -- Register scratch
  scratch_o <= scratch_reg;
  scratch_wack <= scratch_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        scratch_reg <= "00000000000000000000000000000000";
      else
        if scratch_wreq = '1' then
          scratch_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Memory lut
  process (rd_addr, wr_adr_d0, lut_wr) begin
    if lut_wr = '1' then
      lut_adr_int <= wr_adr_d0(6 downto 2);
    else
      lut_adr_int <= rd_addr(6 downto 2);
    end if;
  end process;
  lut_wreq <= lut_value_int_wr;
  lut_wr <= lut_wreq;
  lut_value_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 32,
      g_addr_width         => 5,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => aclk,
      clk_b_i              => aclk,
      addr_a_i             => lut_adr_int,
      bwsel_a_i            => lut_sel_int,
      data_a_i             => wr_dat_d0,
      data_a_o             => lut_value_int_dato,
      rd_a_i               => lut_value_rreq,
      wr_a_i               => lut_value_int_wr,
      addr_b_i             => lut_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => lut_value_ext_dat,
      data_b_o             => lut_value_dat_o,
      rd_b_i               => lut_value_rd_i,
      wr_b_i               => '0'
    );
  
  process (wr_sel_d0) begin
    lut_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      lut_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      lut_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      lut_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      lut_sel_int(3) <= '1';
    end if;
  end process;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        lut_value_rack <= '0';
      else
        lut_value_rack <= (lut_value_rreq and not lut_wreq) and not lut_value_rack;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, scratch_wack) begin
    scratch_wreq <= '0';
    lut_value_int_wr <= '0';
    case wr_adr_d0(7 downto 7) is
    when "0" =>
      case wr_adr_d0(6 downto 2) is
      when "00000" =>
        -- Reg scratch
        scratch_wreq <= wr_req_d0;
        wr_ack <= scratch_wack;
        wr_err <= '0';
      when others =>
        wr_ack <= wr_req_d0;
        wr_err <= wr_req_d0;
      end case;
    when "1" =>
      -- Memory lut
      lut_value_int_wr <= wr_req_d0;
      wr_ack <= wr_req_d0;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, scratch_reg, lut_value_int_dato, lut_wreq,
           lut_value_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    lut_value_rreq <= '0';
    case rd_addr(7 downto 7) is
    when "0" =>
      case rd_addr(6 downto 2) is
      when "00000" =>
        -- Reg scratch
        rd_ack_d0 <= rd_req;
        rd_err_d0 <= '0';
        rd_dat_d0 <= scratch_reg;
      when others =>
        rd_ack_d0 <= rd_req;
        rd_err_d0 <= rd_req;
      end case;
    when "1" =>
      -- Memory lut
      rd_dat_d0 <= lut_value_int_dato;
      lut_value_rreq <= rd_req and not lut_wreq;
      rd_ack_d0 <= lut_value_rack;
      rd_err_d0 <= '0';
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
