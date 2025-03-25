library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi4lite_pkg.all;

entity all2_axi4 is
  port (
    axi4l_i              : in    t_axi4lite_subordinate_in;
    axi4l_o              : out   t_axi4lite_subordinate_out;
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- AXI-4 lite bus sub2
    sub2_i               : in    t_axi4lite_manager_in;
    sub2_o               : out   t_axi4lite_manager_out
  );
end all2_axi4;

architecture syn of all2_axi4 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(6 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(6 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal sub2_aw_val                    : std_logic;
  signal sub2_w_val                     : std_logic;
  signal sub2_ar_val                    : std_logic;
  signal sub2_rd                        : std_logic;
  signal sub2_wr                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(6 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
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
          wr_addr <= axi4l_i.awaddr(6 downto 2);
          axi_awset <= '1';
          wr_req <= axi_wset;
        end if;
        if axi4l_i.wvalid = '1' and axi_wset = '0' then
          wr_data <= axi4l_i.wdata;
          wr_sel(7 downto 0) <= (others => axi4l_i.wstrb(0));
          wr_sel(15 downto 8) <= (others => axi4l_i.wstrb(1));
          wr_sel(23 downto 16) <= (others => axi4l_i.wstrb(2));
          wr_sel(31 downto 24) <= (others => axi4l_i.wstrb(3));
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
          rd_addr <= axi4l_i.araddr(6 downto 2);
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
        wr_adr_d0 <= "00000";
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
        reg1_reg <= "00010010001101000000000000000000";
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Interface sub2
  sub2_o.awvalid <= sub2_aw_val;
  sub2_o.awaddr <= ((25 downto 0 => '0') & wr_adr_d0(5 downto 2)) & (1 downto 0 => '0');
  sub2_o.awprot <= "000";
  sub2_o.wvalid <= sub2_w_val;
  sub2_o.wdata <= wr_dat_d0;
  process (wr_sel_d0) begin
    sub2_o.wstrb <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      sub2_o.wstrb(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      sub2_o.wstrb(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      sub2_o.wstrb(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      sub2_o.wstrb(3) <= '1';
    end if;
  end process;
  sub2_o.bready <= '1';
  sub2_o.arvalid <= sub2_ar_val;
  sub2_o.araddr <= ((25 downto 0 => '0') & rd_addr(5 downto 2)) & (1 downto 0 => '0');
  sub2_o.arprot <= "000";
  sub2_o.rready <= '1';
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub2_aw_val <= '0';
        sub2_w_val <= '0';
        sub2_ar_val <= '0';
      else
        sub2_aw_val <= sub2_wr or (sub2_aw_val and not sub2_i.awready);
        sub2_w_val <= sub2_wr or (sub2_w_val and not sub2_i.wready);
        sub2_ar_val <= sub2_rd or (sub2_ar_val and not sub2_i.arready);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, sub2_i.bvalid) begin
    reg1_wreq <= '0';
    sub2_wr <= '0';
    case wr_adr_d0(6 downto 6) is
    when "0" =>
      case wr_adr_d0(5 downto 2) is
      when "0000" =>
        -- Reg reg1
        reg1_wreq <= wr_req_d0;
        wr_ack <= reg1_wack;
      when others =>
        wr_ack <= wr_req_d0;
      end case;
    when "1" =>
      -- Submap sub2
      sub2_wr <= wr_req_d0;
      wr_ack <= sub2_i.bvalid;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg1_reg, sub2_i.rdata, sub2_i.rvalid) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sub2_rd <= '0';
    case rd_addr(6 downto 6) is
    when "0" =>
      case rd_addr(5 downto 2) is
      when "0000" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg1_reg;
      when others =>
        rd_ack_d0 <= rd_req;
      end case;
    when "1" =>
      -- Submap sub2
      sub2_rd <= rd_req;
      rd_dat_d0 <= sub2_i.rdata;
      rd_ack_d0 <= sub2_i.rvalid;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
