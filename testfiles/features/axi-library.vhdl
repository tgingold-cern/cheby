library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library axi_lib;
use axi_lib.axi4lite_pkg.all;

entity axi_lib_test is
  port (
    axi4l_i              : in    t_axi4lite_subordinate_in;
    axi4l_o              : out   t_axi4lite_subordinate_out;
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;

    -- REG REG_B
    REG_B_o              : out   std_logic_vector(31 downto 0)
  );
end axi_lib_test;

architecture syn of axi_lib_test is
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
  signal REG_B_reg                      : std_logic_vector(31 downto 0);
  signal REG_B_wreq                     : std_logic;
  signal REG_B_wack                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- AW, W and B channels
  axi4l_o.awready <= not axi_awset;
  axi4l_o.wready <= not axi_wset;
  axi4l_o.bvalid <= axi_wdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wr_req <= '0';
        axi_awset <= '0';
        axi_wset <= '0';
        axi_wdone <= '0';
      else
        wr_req <= '0';
        if axi4l_i.awvalid = '1' and axi_awset = '0' then
          axi_awset <= '1';
          wr_req <= axi_wset;
        end if;
        if axi4l_i.wvalid = '1' and axi_wset = '0' then
          wr_data <= axi4l_i.wdata;
          axi_wset <= '1';
          wr_req <= axi_awset or axi4l_i.awvalid;
        end if;
        if (axi_wdone and axi4l_i.bready) = '1' then
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
  axi4l_o.bresp <= "00";

  -- AR and R channels
  axi4l_o.arready <= not axi_arset;
  axi4l_o.rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req <= '0';
        axi_arset <= '0';
        axi_rdone <= '0';
        axi4l_o.rdata <= (others => '0');
      else
        rd_req <= '0';
        if axi4l_i.arvalid = '1' and axi_arset = '0' then
          axi_arset <= '1';
          rd_req <= '1';
        end if;
        if (axi_rdone and axi4l_i.rready) = '1' then
          axi_arset <= '0';
          axi_rdone <= '0';
        end if;
        if rd_ack = '1' then
          axi_rdone <= '1';
          axi4l_o.rdata <= rd_data;
        end if;
      end if;
    end if;
  end process;
  axi4l_o.rresp <= "00";

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

  -- Register REG_B
  REG_B_o <= REG_B_reg;
  REG_B_wack <= REG_B_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        REG_B_reg <= "00000000000000000000000000000000";
      else
        if REG_B_wreq = '1' then
          REG_B_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, REG_B_wack) begin
    REG_B_wreq <= '0';
    -- Reg REG_B
    REG_B_wreq <= wr_req_d0;
    wr_ack <= REG_B_wack;
  end process;

  -- Process for read requests.
  process (rd_req, REG_B_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg REG_B
    rd_ack_d0 <= rd_req;
    rd_dat_d0 <= REG_B_reg;
  end process;
end syn;
