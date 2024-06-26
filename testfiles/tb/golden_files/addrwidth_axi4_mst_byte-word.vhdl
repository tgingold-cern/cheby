library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addrwidth_axi4_byte is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(3 downto 0);
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
    araddr               : in    std_logic_vector(3 downto 0);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- A register
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- An AXI4-Lite bus
    sub2_axi4_awvalid_o  : out   std_logic;
    sub2_axi4_awready_i  : in    std_logic;
    sub2_axi4_awaddr_o   : out   std_logic_vector(2 downto 2);
    sub2_axi4_awprot_o   : out   std_logic_vector(2 downto 0);
    sub2_axi4_wvalid_o   : out   std_logic;
    sub2_axi4_wready_i   : in    std_logic;
    sub2_axi4_wdata_o    : out   std_logic_vector(31 downto 0);
    sub2_axi4_wstrb_o    : out   std_logic_vector(3 downto 0);
    sub2_axi4_bvalid_i   : in    std_logic;
    sub2_axi4_bready_o   : out   std_logic;
    sub2_axi4_bresp_i    : in    std_logic_vector(1 downto 0);
    sub2_axi4_arvalid_o  : out   std_logic;
    sub2_axi4_arready_i  : in    std_logic;
    sub2_axi4_araddr_o   : out   std_logic_vector(2 downto 2);
    sub2_axi4_arprot_o   : out   std_logic_vector(2 downto 0);
    sub2_axi4_rvalid_i   : in    std_logic;
    sub2_axi4_rready_o   : out   std_logic;
    sub2_axi4_rdata_i    : in    std_logic_vector(31 downto 0);
    sub2_axi4_rresp_i    : in    std_logic_vector(1 downto 0)
  );
end addrwidth_axi4_byte;

architecture syn of addrwidth_axi4_byte is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(3 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(3 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal sub2_axi4_aw_val               : std_logic;
  signal sub2_axi4_w_val                : std_logic;
  signal sub2_axi4_ar_val               : std_logic;
  signal sub2_axi4_rd                   : std_logic;
  signal sub2_axi4_wr                   : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
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
          wr_addr <= awaddr(3 downto 2);
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
          rd_addr <= araddr(3 downto 2);
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
        wr_adr_d0 <= "00";
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

  -- Register reg1
  reg1_o <= reg1_reg;
  reg1_wack <= reg1_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg1_reg <= "10111011000000000000000000010001";
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Interface sub2_axi4
  sub2_axi4_awvalid_o <= sub2_axi4_aw_val;
  sub2_axi4_awaddr_o <= wr_adr_d0(2 downto 2);
  sub2_axi4_awprot_o <= "000";
  sub2_axi4_wvalid_o <= sub2_axi4_w_val;
  sub2_axi4_wdata_o <= wr_dat_d0;
  process (wr_sel_d0) begin
    sub2_axi4_wstrb_o <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      sub2_axi4_wstrb_o(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      sub2_axi4_wstrb_o(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      sub2_axi4_wstrb_o(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      sub2_axi4_wstrb_o(3) <= '1';
    end if;
  end process;
  sub2_axi4_bready_o <= '1';
  sub2_axi4_arvalid_o <= sub2_axi4_ar_val;
  sub2_axi4_araddr_o <= rd_addr(2 downto 2);
  sub2_axi4_arprot_o <= "000";
  sub2_axi4_rready_o <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub2_axi4_aw_val <= '0';
        sub2_axi4_w_val <= '0';
        sub2_axi4_ar_val <= '0';
      else
        sub2_axi4_aw_val <= sub2_axi4_wr or (sub2_axi4_aw_val and not sub2_axi4_awready_i);
        sub2_axi4_w_val <= sub2_axi4_wr or (sub2_axi4_w_val and not sub2_axi4_wready_i);
        sub2_axi4_ar_val <= sub2_axi4_rd or (sub2_axi4_ar_val and not sub2_axi4_arready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, sub2_axi4_bvalid_i) begin
    reg1_wreq <= '0';
    sub2_axi4_wr <= '0';
    case wr_adr_d0(3 downto 3) is
    when "0" =>
      case wr_adr_d0(2 downto 2) is
      when "0" =>
        -- Reg reg1
        reg1_wreq <= wr_req_d0;
        wr_ack <= reg1_wack;
      when others =>
        wr_ack <= wr_req_d0;
      end case;
    when "1" =>
      -- Submap sub2_axi4
      sub2_axi4_wr <= wr_req_d0;
      wr_ack <= sub2_axi4_bvalid_i;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg1_reg, sub2_axi4_rdata_i, sub2_axi4_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub2_axi4_rd <= '0';
    case rd_addr(3 downto 3) is
    when "0" =>
      case rd_addr(2 downto 2) is
      when "0" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg1_reg;
      when others =>
        rd_ack_d0 <= rd_req;
      end case;
    when "1" =>
      -- Submap sub2_axi4
      sub2_axi4_rd <= rd_req;
      rd_dat_d0 <= sub2_axi4_rdata_i;
      rd_ack_d0 <= sub2_axi4_rvalid_i;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
