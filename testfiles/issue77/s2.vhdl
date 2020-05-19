library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity s2 is
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

    -- CERN-BE bus sub
    sub_VMERdData_i      : in    std_logic_vector(31 downto 0);
    sub_VMEWrData_o      : out   std_logic_vector(31 downto 0);
    sub_VMERdMem_o       : out   std_logic;
    sub_VMEWrMem_o       : out   std_logic;
    sub_VMERdDone_i      : in    std_logic;
    sub_VMEWrDone_i      : in    std_logic
  );
end s2;

architecture syn of s2 is
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
  signal sub_wr                         : std_logic;
  signal sub_rr                         : std_logic;
  signal sub_ws                         : std_logic;
  signal sub_rs                         : std_logic;
  signal sub_re                         : std_logic;
  signal sub_we                         : std_logic;
  signal sub_wt                         : std_logic;
  signal sub_rt                         : std_logic;
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
  sub_VMEWrData_o <= wr_dat_d0;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub_wr <= '0';
        sub_wt <= '0';
        sub_rr <= '0';
        sub_rt <= '0';
      else
        sub_wr <= (sub_wr or sub_we) and not sub_VMEWrDone_i;
        sub_wt <= (sub_wt or sub_ws) and not sub_VMEWrDone_i;
        sub_rr <= (sub_rr or sub_re) and not sub_VMERdDone_i;
        sub_rt <= (sub_rt or sub_rs) and not sub_VMERdDone_i;
      end if;
    end if;
  end process;
  sub_rs <= sub_rr and not (sub_wr or (sub_rt or sub_wt));
  sub_ws <= sub_wr and not (sub_rt or sub_wt);

  -- Process for write requests.
  process (wr_req_d0, sub_ws, sub_VMEWrDone_i) begin
    sub_VMEWrMem_o <= '0';
    sub_we <= '0';
    -- Submap sub
    sub_we <= wr_req_d0;
    sub_VMEWrMem_o <= sub_ws;
    wr_ack_int <= sub_VMEWrDone_i;
  end process;

  -- Process for read requests.
  process (rd_req, sub_rs, sub_VMERdData_i, sub_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub_VMERdMem_o <= '0';
    sub_re <= '0';
    -- Submap sub
    sub_re <= rd_req;
    sub_VMERdMem_o <= sub_rs;
    rd_dat_d0 <= sub_VMERdData_i;
    rd_ack_d0 <= sub_VMERdDone_i;
  end process;
end syn;
