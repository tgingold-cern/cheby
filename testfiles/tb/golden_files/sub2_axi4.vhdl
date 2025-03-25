library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.axi4lite_pkg.all;
use work.cheby_pkg.all;

entity sub2 is
  port (
    axi4l_i              : in    t_axi4lite_subordinate_in;
    axi4l_o              : out   t_axi4lite_subordinate_out;
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;

    -- REG reg1
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_o               : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_val_rd_i        : in    std_logic;
    ram1_val_dat_o       : out   std_logic_vector(31 downto 0)
  );
end sub2;

architecture syn of sub2 is
  signal wr_req                         : std_logic;
  signal wr_ack                         : std_logic;
  signal wr_addr                        : std_logic_vector(5 downto 2);
  signal wr_data                        : std_logic_vector(31 downto 0);
  signal wr_sel                         : std_logic_vector(31 downto 0);
  signal axi_awset                      : std_logic;
  signal axi_wset                       : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack                         : std_logic;
  signal rd_addr                        : std_logic_vector(5 downto 2);
  signal rd_data                        : std_logic_vector(31 downto 0);
  signal axi_arset                      : std_logic;
  signal axi_rdone                      : std_logic;
  signal reg1_reg                       : std_logic_vector(31 downto 0);
  signal reg1_wreq                      : std_logic;
  signal reg1_wack                      : std_logic;
  signal reg2_reg                       : std_logic_vector(31 downto 0);
  signal reg2_wreq                      : std_logic;
  signal reg2_wack                      : std_logic;
  signal ram1_val_int_dato              : std_logic_vector(31 downto 0);
  signal ram1_val_ext_dat               : std_logic_vector(31 downto 0);
  signal ram1_val_rreq                  : std_logic;
  signal ram1_val_rack                  : std_logic;
  signal ram1_val_int_wr                : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(5 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(31 downto 0);
  signal ram1_wr                        : std_logic;
  signal ram1_wreq                      : std_logic;
  signal ram1_adr_int                   : std_logic_vector(2 downto 0);
  signal ram1_sel_int                   : std_logic_vector(3 downto 0);
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
          wr_addr <= axi4l_i.awaddr(5 downto 2);
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
          rd_addr <= axi4l_i.araddr(5 downto 2);
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
        wr_adr_d0 <= "0000";
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
        reg1_reg <= "00010010001101010000000000000000";
      else
        if reg1_wreq = '1' then
          reg1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_o <= reg2_reg;
  reg2_wack <= reg2_wreq;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg2_reg <= "00010010001101000000000000000010";
      else
        if reg2_wreq = '1' then
          reg2_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Memory ram1
  process (rd_addr, wr_adr_d0, ram1_wr) begin
    if ram1_wr = '1' then
      ram1_adr_int <= wr_adr_d0(4 downto 2);
    else
      ram1_adr_int <= rd_addr(4 downto 2);
    end if;
  end process;
  ram1_wreq <= ram1_val_int_wr;
  ram1_wr <= ram1_wreq;
  ram1_val_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => aclk,
      clk_b_i              => aclk,
      addr_a_i             => ram1_adr_int,
      bwsel_a_i            => ram1_sel_int,
      data_a_i             => wr_dat_d0,
      data_a_o             => ram1_val_int_dato,
      rd_a_i               => ram1_val_rreq,
      wr_a_i               => ram1_val_int_wr,
      addr_b_i             => ram1_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram1_val_ext_dat,
      data_b_o             => ram1_val_dat_o,
      rd_b_i               => ram1_val_rd_i,
      wr_b_i               => '0'
    );
  
  process (wr_sel_d0) begin
    ram1_sel_int <= (others => '0');
    if not (wr_sel_d0(7 downto 0) = (7 downto 0 => '0')) then
      ram1_sel_int(0) <= '1';
    end if;
    if not (wr_sel_d0(15 downto 8) = (7 downto 0 => '0')) then
      ram1_sel_int(1) <= '1';
    end if;
    if not (wr_sel_d0(23 downto 16) = (7 downto 0 => '0')) then
      ram1_sel_int(2) <= '1';
    end if;
    if not (wr_sel_d0(31 downto 24) = (7 downto 0 => '0')) then
      ram1_sel_int(3) <= '1';
    end if;
  end process;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        ram1_val_rack <= '0';
      else
        ram1_val_rack <= (ram1_val_rreq and not ram1_wreq) and not ram1_val_rack;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    ram1_val_int_wr <= '0';
    case wr_adr_d0(5 downto 5) is
    when "0" =>
      case wr_adr_d0(4 downto 2) is
      when "000" =>
        -- Reg reg1
        reg1_wreq <= wr_req_d0;
        wr_ack <= reg1_wack;
      when "001" =>
        -- Reg reg2
        reg2_wreq <= wr_req_d0;
        wr_ack <= reg2_wack;
      when others =>
        wr_ack <= wr_req_d0;
      end case;
    when "1" =>
      -- Memory ram1
      ram1_val_int_wr <= wr_req_d0;
      wr_ack <= wr_req_d0;
    when others =>
      wr_ack <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_addr, rd_req, reg1_reg, reg2_reg, ram1_val_int_dato, ram1_wreq,
           ram1_val_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ram1_val_rreq <= '0';
    case rd_addr(5 downto 5) is
    when "0" =>
      case rd_addr(4 downto 2) is
      when "000" =>
        -- Reg reg1
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg1_reg;
      when "001" =>
        -- Reg reg2
        rd_ack_d0 <= rd_req;
        rd_dat_d0 <= reg2_reg;
      when others =>
        rd_ack_d0 <= rd_req;
      end case;
    when "1" =>
      -- Memory ram1
      rd_dat_d0 <= ram1_val_int_dato;
      ram1_val_rreq <= rd_req and not ram1_wreq;
      rd_ack_d0 <= ram1_val_rack;
    when others =>
      rd_ack_d0 <= rd_req;
    end case;
  end process;
end syn;
