library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_axi4 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(3 downto 2);
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
    araddr               : in    std_logic_vector(3 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_o               : out   std_logic_vector(31 downto 0);

    -- REG reg3
    reg3_o               : out   std_logic_vector(31 downto 0)
  );
end buserr_axi4;

architecture syn of buserr_axi4 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_err                         : std_logic;
  signal wr_addr                        : std_logic_vector(3 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal axi_werr                       : std_logic_vector(1 downto 0);
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_err                         : std_logic;
  signal rd_addr                        : std_logic_vector(3 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal axi_rerr                       : std_logic_vector(1 downto 0);
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_reg                       : std_logic_vector(31 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal reg3_reg                       : std_logic_vector(31 downto 0);
  signal reg3_wreq                      : std_logic;
  signal reg3_wack                      : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(3 downto 2);
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
        -- During reset, accept all handshakes and return error
        axi_wdone <= '1';
        axi_werr <= "10";
      else
        wr_req <= '0';
        axi_wdone <= '0';
        axi_werr <= "00";
        if awvalid = '1' and axi_awset = '0' then
          wr_addr <= awaddr;
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
  rvalid <= axi_rdone;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req <= '0';
        axi_arset <= '0';
        -- During reset, accept all handshakes and return error
        axi_rdone <= '1';
        axi_rerr <= "10";
        rdata <= (others => '0');
      else
        rd_req <= '0';
        axi_rdone <= '0';
        axi_rerr <= "00";
        if arvalid = '1' and axi_arset = '0' then
          rd_addr <= araddr;
          axi_arset <= '1';
          rd_req <= '1';
        end if;
        if (axi_rdone and rready) = '1' then
          axi_arset <= '0';
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
        wr_req_d0 <= '0';
      else
        rd_ack <= rd_ack_d0;
        rd_err <= rd_err_d0;
        rd_data <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_addr;
        wr_dat_d0 <= wr_data;
      end if;
    end if;
  end process;

  -- Register reg1
  reg1_o <= reg1_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg1_reg <= "00010010001101000101011001111000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_o <= reg2_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg2_reg <= "00010010001101000101011001111000";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wr_dat_d0;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;

  -- Register reg3
  reg3_o <= reg3_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg3_reg <= "00010010001101000101011001111000";
        reg3_wack <= '0';
      else
        if reg3_wreq = '1' then
          reg3_reg <= wr_dat_d0;
        end if;
        reg3_wack <= reg3_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack, reg3_wack) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    reg3_wreq <= '0';
    case wr_adr_d0(3 downto 2) is
    when "00" =>
      -- Reg reg1
      reg1_wreq <= wr_req_d0;
      wr_ack <= reg1_wack;
      wr_err <= '0';
    when "01" =>
      -- Reg reg2
      reg2_wreq <= wr_req_d0;
      wr_ack <= reg2_wack;
      wr_err <= '0';
    when "10" =>
      -- Reg reg3
      reg3_wreq <= wr_req_d0;
      wr_ack <= reg3_wack;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg1_reg, reg2_reg, reg3_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(3 downto 2) is
    when "00" =>
      -- Reg reg1
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg1_reg;
    when "01" =>
      -- Reg reg2
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg2_reg;
    when "10" =>
      -- Reg reg3
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= reg3_reg;
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
