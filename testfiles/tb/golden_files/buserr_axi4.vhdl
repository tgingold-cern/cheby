library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_axi4 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(4 downto 2);
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
    araddr               : in    std_logic_vector(4 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- REG rw0
    rw0_o                : out   std_logic_vector(31 downto 0);

    -- REG rw1
    rw1_o                : out   std_logic_vector(31 downto 0);

    -- REG rw2
    rw2_o                : out   std_logic_vector(31 downto 0);

    -- REG ro0
    ro0_i                : in    std_logic_vector(31 downto 0);

    -- REG wo0
    wo0_o                : out   std_logic_vector(31 downto 0)
  );
end buserr_axi4;

architecture syn of buserr_axi4 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_err                         : std_logic;
  signal wr_addr                        : std_logic_vector(4 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal axi_werr                       : std_logic_vector(1 downto 0);
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_err                         : std_logic;
  signal rd_addr                        : std_logic_vector(4 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal axi_rerr                       : std_logic_vector(1 downto 0);
  signal rw0_reg                        : std_logic_vector(31 downto 0);
  signal rw0_wreq                       : std_logic;
  signal rw0_wack                       : std_logic;
  signal rw1_reg                        : std_logic_vector(31 downto 0);
  signal rw1_wreq                       : std_logic;
  signal rw1_wack                       : std_logic;
  signal rw2_reg                        : std_logic_vector(31 downto 0);
  signal rw2_wreq                       : std_logic;
  signal rw2_wack                       : std_logic;
  signal wo0_reg                        : std_logic_vector(31 downto 0);
  signal wo0_wreq                       : std_logic;
  signal wo0_wack                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 2);
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

  -- Register rw0
  rw0_o <= rw0_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rw0_reg <= "00010010001101000101011001111000";
        rw0_wack <= '0';
      else
        if rw0_wreq = '1' then
          rw0_reg <= wr_dat_d0;
        end if;
        rw0_wack <= rw0_wreq;
      end if;
    end if;
  end process;

  -- Register rw1
  rw1_o <= rw1_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rw1_reg <= "00100011010001010110011110001001";
        rw1_wack <= '0';
      else
        if rw1_wreq = '1' then
          rw1_reg <= wr_dat_d0;
        end if;
        rw1_wack <= rw1_wreq;
      end if;
    end if;
  end process;

  -- Register rw2
  rw2_o <= rw2_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rw2_reg <= "00110100010101100111100010011010";
        rw2_wack <= '0';
      else
        if rw2_wreq = '1' then
          rw2_reg <= wr_dat_d0;
        end if;
        rw2_wack <= rw2_wreq;
      end if;
    end if;
  end process;

  -- Register ro0

  -- Register wo0
  wo0_o <= wo0_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        wo0_reg <= "01010110011110001001101010111100";
        wo0_wack <= '0';
      else
        if wo0_wreq = '1' then
          wo0_reg <= wr_dat_d0;
        end if;
        wo0_wack <= wo0_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, rw0_wack, rw1_wack, rw2_wack, wo0_wack) begin
    rw0_wreq <= '0';
    rw1_wreq <= '0';
    rw2_wreq <= '0';
    wo0_wreq <= '0';
    case wr_adr_d0(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rw0_wreq <= wr_req_d0;
      wr_ack <= rw0_wack;
      wr_err <= '0';
    when "001" =>
      -- Reg rw1
      rw1_wreq <= wr_req_d0;
      wr_ack <= rw1_wack;
      wr_err <= '0';
    when "010" =>
      -- Reg rw2
      rw2_wreq <= wr_req_d0;
      wr_ack <= rw2_wack;
      wr_err <= '0';
    when "011" =>
      -- Reg ro0
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    when "100" =>
      -- Reg wo0
      wo0_wreq <= wr_req_d0;
      wr_ack <= wo0_wack;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, rw0_reg, rw1_reg, rw2_reg, ro0_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case rd_addr(4 downto 2) is
    when "000" =>
      -- Reg rw0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw0_reg;
    when "001" =>
      -- Reg rw1
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw1_reg;
    when "010" =>
      -- Reg rw2
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= rw2_reg;
    when "011" =>
      -- Reg ro0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= '0';
      rd_dat_d0 <= ro0_i;
    when "100" =>
      -- Reg wo0
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
