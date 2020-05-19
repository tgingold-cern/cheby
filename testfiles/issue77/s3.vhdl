library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s3 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
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
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- AXI-4 lite bus sub
    sub_awvalid_o        : out   std_logic;
    sub_awready_i        : in    std_logic;
    sub_awprot_o         : out   std_logic_vector(2 downto 0);
    sub_wvalid_o         : out   std_logic;
    sub_wready_i         : in    std_logic;
    sub_wdata_o          : out   std_logic_vector(31 downto 0);
    sub_wstrb_o          : out   std_logic_vector(3 downto 0);
    sub_bvalid_i         : in    std_logic;
    sub_bready_o         : out   std_logic;
    sub_bresp_i          : in    std_logic_vector(1 downto 0);
    sub_arvalid_o        : out   std_logic;
    sub_arready_i        : in    std_logic;
    sub_arprot_o         : out   std_logic_vector(2 downto 0);
    sub_rvalid_i         : in    std_logic;
    sub_rready_o         : out   std_logic;
    sub_rdata_i          : in    std_logic_vector(31 downto 0);
    sub_rresp_i          : in    std_logic_vector(1 downto 0)
  );
end s3;

architecture syn of s3 is
  signal wr_req                         : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_wdata                       : std_logic_vector(31 downto 0);
  signal wr_wstrb                       : std_logic_vector(3 downto 0);
  signal wr_awaddr                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_awset                      : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal dato                           : std_logic_vector(31 downto 0);
  signal axi_rip                        : std_logic;
  signal axi_rdone                      : std_logic;
  signal sub_aw_val                     : std_logic;
  signal sub_w_val                      : std_logic;
  signal sub_rd                         : std_logic;
  signal sub_wr                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
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
  rd_req <= arvalid and not axi_rip;
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
        wr_dat_d0 <= wr_wdata;
        wr_sel_d0 <= wr_wstrb;
      end if;
    end if;
  end process;

  -- Interface sub
  sub_awvalid_o <= sub_aw_val;
  sub_awprot_o <= "000";
  sub_wvalid_o <= sub_w_val;
  sub_wdata_o <= wr_dat_d0;
  sub_wstrb_o <= wr_sel_d0;
  sub_bready_o <= '1';
  sub_arvalid_o <= sub_rd;
  sub_arprot_o <= "000";
  sub_rready_o <= rready;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub_aw_val <= '0';
        sub_w_val <= '0';
      else
        sub_aw_val <= '0';
        sub_aw_val <= sub_wr or (sub_aw_val and not sub_awready_i);
        sub_w_val <= '0';
        sub_w_val <= sub_wr or (sub_w_val and not sub_wready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, sub_bvalid_i) begin
    sub_wr <= '0';
    -- Submap sub
    sub_wr <= wr_req_d0;
    wr_ack_int <= sub_bvalid_i;
  end process;

  -- Process for read requests.
  process (rd_req, sub_rdata_i, sub_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub_rd <= '0';
    -- Submap sub
    sub_rd <= rd_req;
    rd_dat_d0 <= sub_rdata_i;
    rd_ack_d0 <= sub_rvalid_i;
  end process;
end syn;
