library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity buserr_mem_sram is
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

    -- SRAM bus lut
    lut_addr_o           : out   std_logic_vector(6 downto 2);
    lut_data_i           : in    std_logic_vector(31 downto 0);
    lut_data_o           : out   std_logic_vector(31 downto 0);
    lut_wr_o             : out   std_logic
  );
end buserr_mem_sram;

architecture syn of buserr_mem_sram is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_err                         : std_logic;
  signal wr_addr                        : std_logic_vector(7 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
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
  signal lut_rack                       : std_logic;
  signal lut_re                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_err_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(7 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal lut_wp                         : std_logic;
  signal lut_we                         : std_logic;
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

  -- Interface lut
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        lut_rack <= '0';
      else
        lut_rack <= lut_re and not lut_rack;
      end if;
    end if;
  end process;
  lut_data_o <= wr_dat_d0;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        lut_wp <= '0';
      else
        lut_wp <= (wr_req_d0 or lut_wp) and rd_req;
      end if;
    end if;
  end process;
  lut_we <= (wr_req_d0 or lut_wp) and not rd_req;
  process (rd_addr, wr_adr_d0, lut_re) begin
    if lut_re = '1' then
      lut_addr_o <= rd_addr(6 downto 2);
    else
      lut_addr_o <= wr_adr_d0(6 downto 2);
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, scratch_wack, lut_we) begin
    scratch_wreq <= '0';
    lut_wr_o <= '0';
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
      lut_wr_o <= lut_we;
      wr_ack <= lut_we;
      wr_err <= '0';
    when others =>
      wr_ack <= wr_req_d0;
      wr_err <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, scratch_reg, lut_data_i, lut_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    lut_re <= '0';
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
      rd_dat_d0 <= lut_data_i;
      rd_ack_d0 <= lut_rack;
      lut_re <= rd_req;
      rd_err_d0 <= '0';
    when others =>
      rd_ack_d0 <= rd_req;
      rd_err_d0 <= rd_req;
    end case;
  end process;
end syn;
