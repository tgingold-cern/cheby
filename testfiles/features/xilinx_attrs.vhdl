library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity xilinx_attrs is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(2 downto 2);
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
    araddr               : in    std_logic_vector(2 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- AXI-4 lite bus subm
    subm_awvalid_o       : out   std_logic;
    subm_awready_i       : in    std_logic;
    subm_awaddr_o        : out   std_logic_vector(2 downto 2);
    subm_awprot_o        : out   std_logic_vector(2 downto 0);
    subm_wvalid_o        : out   std_logic;
    subm_wready_i        : in    std_logic;
    subm_wdata_o         : out   std_logic_vector(31 downto 0);
    subm_wstrb_o         : out   std_logic_vector(3 downto 0);
    subm_bvalid_i        : in    std_logic;
    subm_bready_o        : out   std_logic;
    subm_bresp_i         : in    std_logic_vector(1 downto 0);
    subm_arvalid_o       : out   std_logic;
    subm_arready_i       : in    std_logic;
    subm_araddr_o        : out   std_logic_vector(2 downto 2);
    subm_arprot_o        : out   std_logic_vector(2 downto 0);
    subm_rvalid_i        : in    std_logic;
    subm_rready_o        : out   std_logic;
    subm_rdata_i         : in    std_logic_vector(31 downto 0);
    subm_rresp_i         : in    std_logic_vector(1 downto 0)
  );
end xilinx_attrs;

architecture syn of xilinx_attrs is
  signal wr_req                         : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_wdata                       : std_logic_vector(31 downto 0);
  signal wr_wstrb                       : std_logic_vector(3 downto 0);
  signal wr_awaddr                      : std_logic_vector(2 downto 2);
  signal axi_wset                       : std_logic;
  signal axi_awset                      : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal dato                           : std_logic_vector(31 downto 0);
  signal axi_rip                        : std_logic;
  signal axi_rdone                      : std_logic;
  signal subm_aw_val                    : std_logic;
  signal subm_w_val                     : std_logic;
  signal subm_ar_val                    : std_logic;
  signal subm_rd                        : std_logic;
  signal subm_wr                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  attribute X_INTERFACE_INFO : string;
  attribute X_INTERFACE_INFO of awvalid : signal is
    "xilinx.com:interface:aximm:1.0 slave AWVALID";
  attribute X_INTERFACE_INFO of awready : signal is
    "xilinx.com:interface:aximm:1.0 slave AWREADY";
  attribute X_INTERFACE_INFO of awaddr : signal is
    "xilinx.com:interface:aximm:1.0 slave AWADDR";
  attribute X_INTERFACE_INFO of awprot : signal is
    "xilinx.com:interface:aximm:1.0 slave AWPROT";
  attribute X_INTERFACE_INFO of wvalid : signal is
    "xilinx.com:interface:aximm:1.0 slave WVALID";
  attribute X_INTERFACE_INFO of wready : signal is
    "xilinx.com:interface:aximm:1.0 slave WREADY";
  attribute X_INTERFACE_INFO of wdata : signal is
    "xilinx.com:interface:aximm:1.0 slave WDATA";
  attribute X_INTERFACE_INFO of wstrb : signal is
    "xilinx.com:interface:aximm:1.0 slave WSTRB";
  attribute X_INTERFACE_INFO of bvalid : signal is
    "xilinx.com:interface:aximm:1.0 slave BVALID";
  attribute X_INTERFACE_INFO of bready : signal is
    "xilinx.com:interface:aximm:1.0 slave BREADY";
  attribute X_INTERFACE_INFO of bresp : signal is
    "xilinx.com:interface:aximm:1.0 slave BRESP";
  attribute X_INTERFACE_INFO of arvalid : signal is
    "xilinx.com:interface:aximm:1.0 slave ARVALID";
  attribute X_INTERFACE_INFO of arready : signal is
    "xilinx.com:interface:aximm:1.0 slave ARREADY";
  attribute X_INTERFACE_INFO of araddr : signal is
    "xilinx.com:interface:aximm:1.0 slave ARADDR";
  attribute X_INTERFACE_INFO of arprot : signal is
    "xilinx.com:interface:aximm:1.0 slave ARPROT";
  attribute X_INTERFACE_INFO of rvalid : signal is
    "xilinx.com:interface:aximm:1.0 slave RVALID";
  attribute X_INTERFACE_INFO of rready : signal is
    "xilinx.com:interface:aximm:1.0 slave RREADY";
  attribute X_INTERFACE_INFO of rdata : signal is
    "xilinx.com:interface:aximm:1.0 slave RDATA";
  attribute X_INTERFACE_INFO of rresp : signal is
    "xilinx.com:interface:aximm:1.0 slave RRESP";
  attribute X_INTERFACE_INFO of subm_awvalid_o : signal is
    "xilinx.com:interface:aximm:1.0 subm AWVALID";
  attribute X_INTERFACE_INFO of subm_awready_i : signal is
    "xilinx.com:interface:aximm:1.0 subm AWREADY";
  attribute X_INTERFACE_INFO of subm_awaddr_o : signal is
    "xilinx.com:interface:aximm:1.0 subm AWADDR";
  attribute X_INTERFACE_INFO of subm_awprot_o : signal is
    "xilinx.com:interface:aximm:1.0 subm AWPROT";
  attribute X_INTERFACE_INFO of subm_wvalid_o : signal is
    "xilinx.com:interface:aximm:1.0 subm WVALID";
  attribute X_INTERFACE_INFO of subm_wready_i : signal is
    "xilinx.com:interface:aximm:1.0 subm WREADY";
  attribute X_INTERFACE_INFO of subm_wdata_o : signal is
    "xilinx.com:interface:aximm:1.0 subm WDATA";
  attribute X_INTERFACE_INFO of subm_wstrb_o : signal is
    "xilinx.com:interface:aximm:1.0 subm WSTRB";
  attribute X_INTERFACE_INFO of subm_bvalid_i : signal is
    "xilinx.com:interface:aximm:1.0 subm BVALID";
  attribute X_INTERFACE_INFO of subm_bready_o : signal is
    "xilinx.com:interface:aximm:1.0 subm BREADY";
  attribute X_INTERFACE_INFO of subm_bresp_i : signal is
    "xilinx.com:interface:aximm:1.0 subm BRESP";
  attribute X_INTERFACE_INFO of subm_arvalid_o : signal is
    "xilinx.com:interface:aximm:1.0 subm ARVALID";
  attribute X_INTERFACE_INFO of subm_arready_i : signal is
    "xilinx.com:interface:aximm:1.0 subm ARREADY";
  attribute X_INTERFACE_INFO of subm_araddr_o : signal is
    "xilinx.com:interface:aximm:1.0 subm ARADDR";
  attribute X_INTERFACE_INFO of subm_arprot_o : signal is
    "xilinx.com:interface:aximm:1.0 subm ARPROT";
  attribute X_INTERFACE_INFO of subm_rvalid_i : signal is
    "xilinx.com:interface:aximm:1.0 subm RVALID";
  attribute X_INTERFACE_INFO of subm_rready_o : signal is
    "xilinx.com:interface:aximm:1.0 subm RREADY";
  attribute X_INTERFACE_INFO of subm_rdata_i : signal is
    "xilinx.com:interface:aximm:1.0 subm RDATA";
  attribute X_INTERFACE_INFO of subm_rresp_i : signal is
    "xilinx.com:interface:aximm:1.0 subm RRESP";
begin

  -- AW, W and B channels
  bvalid <= axi_wdone;
  wready <= not axi_wset;
  awready <= not axi_awset;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        axi_wset <= '0';
        axi_awset <= '0';
        wr_req <= '0';
        axi_wdone <= '0';
      else
        wr_req <= '0';
        if wvalid = '1' and axi_wset = '0' then
          wr_wdata <= wdata;
          wr_wstrb <= wstrb;
          axi_wset <= '1';
          wr_req <= axi_awset;
        end if;
        if awvalid = '1' and axi_awset = '0' then
          wr_awaddr <= awaddr;
          axi_awset <= '1';
          wr_req <= axi_wset or wvalid;
        end if;
        if (axi_wdone and bready) = '1' then
          axi_wset <= '0';
          axi_awset <= '0';
          axi_wdone <= '0';
        end if;
        if wr_ack_int = '1' then
          axi_wdone <= '1';
        end if;
      end if;
    end if;
  end process;
  bresp <= "00";

  -- AR and R channels
  rd_req <= arvalid and not (axi_rip or axi_rdone);
  arready <= rd_ack_int;
  rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        axi_rip <= '0';
        axi_rdone <= '0';
        rdata <= (others => '0');
      else
        axi_rip <= arvalid and not axi_rdone;
        if rd_ack_int = '1' then
          rdata <= dato;
        end if;
        axi_rdone <= rd_ack_int or (axi_rdone and not rready);
      end if;
    end if;
  end process;
  rresp <= "00";

  -- pipelining for wr-in+rd-out
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        dato <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_awaddr;
        wr_dat_d0 <= wr_wdata;
        wr_sel_d0 <= wr_wstrb;
      end if;
    end if;
  end process;

  -- Interface subm
  subm_awvalid_o <= subm_aw_val;
  subm_awaddr_o <= wr_adr_d0(2 downto 2);
  subm_awprot_o <= "000";
  subm_wvalid_o <= subm_w_val;
  subm_wdata_o <= wr_dat_d0;
  subm_wstrb_o <= wr_sel_d0;
  subm_bready_o <= '1';
  subm_arvalid_o <= subm_ar_val;
  subm_araddr_o <= araddr(2 downto 2);
  subm_arprot_o <= "000";
  subm_rready_o <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        subm_aw_val <= '0';
        subm_w_val <= '0';
        subm_ar_val <= '0';
      else
        subm_aw_val <= subm_wr or (subm_aw_val and not subm_awready_i);
        subm_w_val <= subm_wr or (subm_w_val and not subm_wready_i);
        subm_ar_val <= subm_rd or (subm_ar_val and not subm_arready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, subm_bvalid_i) begin
    subm_wr <= '0';
    -- Submap subm
    subm_wr <= wr_req_d0;
    wr_ack_int <= subm_bvalid_i;
  end process;

  -- Process for read requests.
  process (rd_req, subm_rdata_i, subm_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    subm_rd <= '0';
    -- Submap subm
    subm_rd <= rd_req;
    rd_dat_d0 <= subm_rdata_i;
    rd_ack_d0 <= subm_rvalid_i;
  end process;
end syn;
