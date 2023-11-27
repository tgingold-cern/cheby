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
  signal wr_ack                         : std_logic;
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
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
          axi_awset <= '1';
          wr_req <= axi_wset;
        end if;
        if wvalid = '1' and axi_wset = '0' then
          wr_data <= wdata;
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
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_dat_d0 <= wr_data;
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
    sub_we <= '0';
    sub_VMEWrMem_o <= '0';
    -- Submap sub
    sub_we <= wr_req_d0;
    sub_VMEWrMem_o <= sub_ws;
    wr_ack <= sub_VMEWrDone_i;
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
