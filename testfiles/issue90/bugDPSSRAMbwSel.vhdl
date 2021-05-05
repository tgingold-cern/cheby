library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity bugDPSSRAMbwSel is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(19 downto 2);
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
    araddr               : in    std_logic_vector(19 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- RAM port for mem
    mem_adr_i            : in    std_logic_vector(9 downto 0);
    mem_r1_rd_i          : in    std_logic;
    mem_r1_dat_o         : out   std_logic_vector(7 downto 0)
  );
end bugDPSSRAMbwSel;

architecture syn of bugDPSSRAMbwSel is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(19 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_strb                        : std_logic_vector(3 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(19 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal mem_r1_int_dato                : std_logic_vector(7 downto 0);
  signal mem_r1_ext_dat                 : std_logic_vector(7 downto 0);
  signal mem_r1_rreq                    : std_logic;
  signal mem_r1_rack                    : std_logic;
  signal mem_r1_int_wr                  : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(19 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal mem_wr                         : std_logic;
  signal mem_rr                         : std_logic;
  signal mem_wreq                       : std_logic;
  signal mem_adr_int                    : std_logic_vector(9 downto 0);
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
          wr_strb <= wstrb;
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
        wr_req_d0 <= '0';
      else
        rd_ack <= rd_ack_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
        wr_sel_d0 <= wr_strb;
      end if;
    end if;
  end process;

  -- Memory mem
  process (rd_addr, wr_adr_d0, mem_wr) begin
    if mem_wr = '1' then
      mem_adr_int <= wr_adr_d0(11 downto 2);
    else
      mem_adr_int <= rd_addr(11 downto 2);
    end if;
  end process;
  mem_wreq <= mem_r1_int_wr;
  mem_rr <= mem_r1_rreq and not mem_wreq;
  mem_wr <= mem_wreq;
  mem_r1_raminst: cheby_dpssram
    generic map (
      g_data_width         => 8,
      g_size               => 1024,
      g_addr_width         => 10,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => aclk,
      clk_b_i              => aclk,
      addr_a_i             => mem_adr_int,
      bwsel_a_i            => wr_sel_d0(0 downto 0),
      data_a_i             => wr_dat_d0(7 downto 0),
      data_a_o             => mem_r1_int_dato,
      rd_a_i               => mem_r1_rreq,
      wr_a_i               => mem_r1_int_wr,
      addr_b_i             => mem_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => mem_r1_ext_dat,
      data_b_o             => mem_r1_dat_o,
      rd_b_i               => mem_r1_rd_i,
      wr_b_i               => '0'
    );
  
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        mem_r1_rack <= '0';
      else
        mem_r1_rack <= (mem_r1_rreq and not mem_wreq) and not mem_r1_rack;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0) begin
    mem_r1_int_wr <= '0';
    -- Memory mem
    mem_r1_int_wr <= wr_req_d0;
    wr_ack <= wr_req_d0;
  end process;

  -- Process for read requests.
  process (mem_r1_int_dato, rd_req, mem_wreq, mem_r1_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    mem_r1_rreq <= '0';
    -- Memory mem
    rd_dat_d0 <= "000000000000000000000000" & mem_r1_int_dato;
    mem_r1_rreq <= rd_req and not mem_wreq;
    rd_ack_d0 <= mem_r1_rack;
  end process;
end syn;
