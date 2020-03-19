-- Do not edit.  Generated on Thu Mar 19 17:36:21 2020 by gingold
-- With Cheby 1.4.dev0 and these options:
--  --gen-hdl=all1_axi4.vhdl -i all1_axi4.cheby


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity all1_axi4 is
  port (
    aclk                 : in    std_logic;
    areset_n             : in    std_logic;
    awvalid              : in    std_logic;
    awready              : out   std_logic;
    awaddr               : in    std_logic_vector(13 downto 2);
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
    araddr               : in    std_logic_vector(13 downto 2);
    arprot               : in    std_logic_vector(2 downto 0);
    rvalid               : out   std_logic;
    rready               : in    std_logic;
    rdata                : out   std_logic_vector(31 downto 0);
    rresp                : out   std_logic_vector(1 downto 0);

    -- A register
    reg1_o               : out   std_logic_vector(31 downto 0);

    -- REG reg2
    reg2_o               : out   std_logic_vector(31 downto 0);

    -- RAM port for ram1
    ram1_adr_i           : in    std_logic_vector(2 downto 0);
    ram1_val_rd_i        : in    std_logic;
    ram1_val_dat_o       : out   std_logic_vector(31 downto 0);

    -- RAM port for ram_ro
    ram_ro_adr_i         : in    std_logic_vector(2 downto 0);
    ram_ro_val_we_i      : in    std_logic;
    ram_ro_val_dat_i     : in    std_logic_vector(31 downto 0);

    -- SRAM bus ram2
    ram2_addr_o          : out   std_logic_vector(4 downto 2);
    ram2_data_i          : in    std_logic_vector(31 downto 0);
    ram2_data_o          : out   std_logic_vector(31 downto 0);
    ram2_wr_o            : out   std_logic;

    -- A WB bus
    sub1_wb_cyc_o        : out   std_logic;
    sub1_wb_stb_o        : out   std_logic;
    sub1_wb_adr_o        : out   std_logic_vector(11 downto 2);
    sub1_wb_sel_o        : out   std_logic_vector(3 downto 0);
    sub1_wb_we_o         : out   std_logic;
    sub1_wb_dat_o        : out   std_logic_vector(31 downto 0);
    sub1_wb_ack_i        : in    std_logic;
    sub1_wb_err_i        : in    std_logic;
    sub1_wb_rty_i        : in    std_logic;
    sub1_wb_stall_i      : in    std_logic;
    sub1_wb_dat_i        : in    std_logic_vector(31 downto 0);

    -- An AXI4-Lite bus
    sub2_axi4_awvalid_o  : out   std_logic;
    sub2_axi4_awready_i  : in    std_logic;
    sub2_axi4_awaddr_o   : out   std_logic_vector(11 downto 2);
    sub2_axi4_awprot_o   : out   std_logic_vector(2 downto 0);
    sub2_axi4_wvalid_o   : out   std_logic;
    sub2_axi4_wready_i   : in    std_logic;
    sub2_axi4_wdata_o    : out   std_logic_vector(31 downto 0);
    sub2_axi4_wstrb_o    : out   std_logic_vector(3 downto 0);
    sub2_axi4_bvalid_i   : in    std_logic;
    sub2_axi4_bready_o   : out   std_logic;
    sub2_axi4_bresp_i    : in    std_logic_vector(1 downto 0);
    sub2_axi4_arvalid_o  : out   std_logic;
    sub2_axi4_arready_i  : in    std_logic;
    sub2_axi4_araddr_o   : out   std_logic_vector(11 downto 2);
    sub2_axi4_arprot_o   : out   std_logic_vector(2 downto 0);
    sub2_axi4_rvalid_i   : in    std_logic;
    sub2_axi4_rready_o   : out   std_logic;
    sub2_axi4_rdata_i    : in    std_logic_vector(31 downto 0);
    sub2_axi4_rresp_i    : in    std_logic_vector(1 downto 0);

    -- A CERN-BE bus
    sub3_cernbe_VMEAddr_o : out   std_logic_vector(11 downto 2);
    sub3_cernbe_VMERdData_i : in    std_logic_vector(31 downto 0);
    sub3_cernbe_VMEWrData_o : out   std_logic_vector(31 downto 0);
    sub3_cernbe_VMERdMem_o : out   std_logic;
    sub3_cernbe_VMEWrMem_o : out   std_logic;
    sub3_cernbe_VMERdDone_i : in    std_logic;
    sub3_cernbe_VMEWrDone_i : in    std_logic
  );
end all1_axi4;

architecture syn of all1_axi4 is
  signal wr_req                         : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_wdata                       : std_logic_vector(31 downto 0);
  signal wr_wstrb                       : std_logic_vector(3 downto 0);
  signal wr_awaddr                      : std_logic_vector(13 downto 2);
  signal axi_wset                       : std_logic;
  signal axi_awset                      : std_logic;
  signal axi_wdone                      : std_logic;
  signal rd_req                         : std_logic;
  signal rd_ack_int                     : std_logic;
  signal dato                           : std_logic_vector(31 downto 0);
  signal axi_rip                        : std_logic;
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
  signal ram1_val_ext_wr                : std_logic;
  signal ram_ro_val_int_dati            : std_logic_vector(31 downto 0);
  signal ram_ro_val_int_dato            : std_logic_vector(31 downto 0);
  signal ram_ro_val_ext_dat             : std_logic_vector(31 downto 0);
  signal ram_ro_val_rreq                : std_logic;
  signal ram_ro_val_rack                : std_logic;
  signal ram_ro_val_int_wr              : std_logic;
  signal ram_ro_val_ext_rd              : std_logic;
  signal ram2_rack                      : std_logic;
  signal ram2_re                        : std_logic;
  signal sub1_wb_re                     : std_logic;
  signal sub1_wb_we                     : std_logic;
  signal sub1_wb_wt                     : std_logic;
  signal sub1_wb_rt                     : std_logic;
  signal sub1_wb_tr                     : std_logic;
  signal sub1_wb_wack                   : std_logic;
  signal sub1_wb_rack                   : std_logic;
  signal sub1_wb_wr                     : std_logic;
  signal sub1_wb_rr                     : std_logic;
  signal sub2_axi4_aw_val               : std_logic;
  signal sub2_axi4_w_val                : std_logic;
  signal sub2_axi4_rd                   : std_logic;
  signal sub2_axi4_wr                   : std_logic;
  signal sub3_cernbe_wr                 : std_logic;
  signal sub3_cernbe_rr                 : std_logic;
  signal sub3_cernbe_ws                 : std_logic;
  signal sub3_cernbe_rs                 : std_logic;
  signal sub3_cernbe_re                 : std_logic;
  signal sub3_cernbe_we                 : std_logic;
  signal sub3_cernbe_wt                 : std_logic;
  signal sub3_cernbe_rt                 : std_logic;
  signal rd_req_d0                      : std_logic;
  signal rd_adr_d0                      : std_logic_vector(13 downto 2);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(13 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
  signal wr_ack_d0                      : std_logic;
  signal ram1_wr                        : std_logic;
  signal ram1_rr                        : std_logic;
  signal ram1_wreq                      : std_logic;
  signal ram1_adr_int                   : std_logic_vector(2 downto 0);
  signal ram2_wp                        : std_logic;
  signal ram2_we                        : std_logic;
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
          wr_awaddr <= awaddr;
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

  -- pipelining for rd-in+rd-out+wr-in+wr-out
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        rd_req_d0 <= '0';
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
        wr_ack_int <= '0';
      else
        rd_req_d0 <= rd_req;
        rd_adr_d0 <= araddr;
        rd_ack_int <= rd_ack_d0;
        dato <= rd_dat_d0;
        wr_req_d0 <= wr_req;
        wr_adr_d0 <= wr_awaddr;
        wr_dat_d0 <= wr_wdata;
        wr_sel_d0 <= wr_wstrb;
        wr_ack_int <= wr_ack_d0;
      end if;
    end if;
  end process;

  -- Register reg1
  reg1_o <= reg1_reg;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        reg1_reg <= "00010010001101000000000000000000";
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
        reg2_reg <= "00010010001101000000000000000010";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wr_dat_d0;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;

  -- Memory ram1
  process (rd_adr_d0, wr_adr_d0, ram1_wr) begin
    if ram1_wr = '1' then
      ram1_adr_int <= wr_adr_d0(4 downto 2);
    else
      ram1_adr_int <= rd_adr_d0(4 downto 2);
    end if;
  end process;
  ram1_wreq <= ram1_val_int_wr;
  ram1_rr <= ram1_val_rreq and not ram1_wreq;
  ram1_wr <= ram1_wreq;
  ram1_val_raminst: wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => false,
      g_use_bwsel          => true
    )
    port map (
      clk_a_i              => aclk,
      clk_b_i              => aclk,
      addr_a_i             => ram1_adr_int,
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => wr_dat_d0,
      data_a_o             => ram1_val_int_dato,
      rd_a_i               => ram1_val_rreq,
      wr_a_i               => ram1_val_int_wr,
      addr_b_i             => ram1_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram1_val_ext_dat,
      data_b_o             => ram1_val_dat_o,
      rd_b_i               => ram1_val_rd_i,
      wr_b_i               => ram1_val_ext_wr
    );
  
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        ram1_val_rack <= '0';
      else
        ram1_val_rack <= (ram1_val_rreq and not ram1_wreq) and not ram1_val_rack;
      end if;
    end if;
  end process;
  ram1_val_ext_wr <= '0';

  -- Memory ram_ro
  ram_ro_val_raminst: wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => false,
      g_use_bwsel          => true
    )
    port map (
      clk_a_i              => aclk,
      clk_b_i              => aclk,
      addr_a_i             => rd_adr_d0(4 downto 2),
      bwsel_a_i            => wr_sel_d0,
      data_a_i             => ram_ro_val_int_dati,
      data_a_o             => ram_ro_val_int_dato,
      rd_a_i               => ram_ro_val_rreq,
      wr_a_i               => ram_ro_val_int_wr,
      addr_b_i             => ram_ro_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram_ro_val_dat_i,
      data_b_o             => ram_ro_val_ext_dat,
      rd_b_i               => ram_ro_val_ext_rd,
      wr_b_i               => ram_ro_val_we_i
    );
  
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        ram_ro_val_rack <= '0';
      else
        ram_ro_val_rack <= ram_ro_val_rreq;
      end if;
    end if;
  end process;
  ram_ro_val_int_wr <= '0';
  ram_ro_val_int_dati <= (others => 'X');
  ram_ro_val_ext_rd <= '0';

  -- Interface ram2
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        ram2_rack <= '0';
      else
        ram2_rack <= ram2_re and not ram2_rack;
      end if;
    end if;
  end process;
  ram2_data_o <= wr_dat_d0;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        ram2_wp <= '0';
      else
        ram2_wp <= (wr_req_d0 or ram2_wp) and rd_req_d0;
      end if;
    end if;
  end process;
  ram2_we <= (wr_req_d0 or ram2_wp) and not rd_req_d0;
  process (rd_adr_d0, wr_adr_d0, ram2_re) begin
    if ram2_re = '1' then
      ram2_addr_o <= rd_adr_d0(4 downto 2);
    else
      ram2_addr_o <= wr_adr_d0(4 downto 2);
    end if;
  end process;

  -- Interface sub1_wb
  sub1_wb_tr <= sub1_wb_wt or sub1_wb_rt;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub1_wb_rt <= '0';
        sub1_wb_wt <= '0';
        sub1_wb_wr <= '0';
        sub1_wb_rr <= '0';
      else
        sub1_wb_wr <= (sub1_wb_wr or sub1_wb_we) and not sub1_wb_wack;
        sub1_wb_wt <= (sub1_wb_wt or (sub1_wb_wr and not sub1_wb_tr)) and not sub1_wb_wack;
        sub1_wb_rr <= (sub1_wb_rr or sub1_wb_re) and not sub1_wb_rack;
        sub1_wb_rt <= (sub1_wb_rt or (sub1_wb_rr and not (sub1_wb_wr or sub1_wb_tr))) and not sub1_wb_rack;
      end if;
    end if;
  end process;
  sub1_wb_cyc_o <= sub1_wb_tr;
  sub1_wb_stb_o <= sub1_wb_tr;
  sub1_wb_wack <= sub1_wb_ack_i and sub1_wb_wt;
  sub1_wb_rack <= sub1_wb_ack_i and sub1_wb_rt;
  process (rd_adr_d0, wr_adr_d0, sub1_wb_wt) begin
    if sub1_wb_wt = '1' then
      sub1_wb_adr_o <= wr_adr_d0(11 downto 2);
    else
      sub1_wb_adr_o <= rd_adr_d0(11 downto 2);
    end if;
  end process;
  sub1_wb_sel_o <= wr_sel_d0;
  sub1_wb_we_o <= sub1_wb_wt;
  sub1_wb_dat_o <= wr_dat_d0;

  -- Interface sub2_axi4
  sub2_axi4_awvalid_o <= sub2_axi4_aw_val;
  sub2_axi4_awaddr_o <= wr_adr_d0(11 downto 2);
  sub2_axi4_awprot_o <= "000";
  sub2_axi4_wvalid_o <= sub2_axi4_w_val;
  sub2_axi4_wdata_o <= wr_dat_d0;
  sub2_axi4_wstrb_o <= wr_sel_d0;
  sub2_axi4_bready_o <= '1';
  sub2_axi4_arvalid_o <= sub2_axi4_rd;
  sub2_axi4_araddr_o <= rd_adr_d0(11 downto 2);
  sub2_axi4_arprot_o <= "000";
  sub2_axi4_rready_o <= rready;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub2_axi4_aw_val <= '0';
        sub2_axi4_w_val <= '0';
      else
        sub2_axi4_aw_val <= '0';
        sub2_axi4_aw_val <= sub2_axi4_wr or (sub2_axi4_aw_val and not sub2_axi4_awready_i);
        sub2_axi4_w_val <= '0';
        sub2_axi4_w_val <= sub2_axi4_wr or (sub2_axi4_w_val and not sub2_axi4_wready_i);
      end if;
    end if;
  end process;

  -- Interface sub3_cernbe
  sub3_cernbe_VMEWrData_o <= wr_dat_d0;
  process (aclk) begin
    if rising_edge(aclk) then
      if areset_n = '0' then
        sub3_cernbe_wr <= '0';
        sub3_cernbe_wt <= '0';
        sub3_cernbe_rr <= '0';
        sub3_cernbe_rt <= '0';
      else
        sub3_cernbe_wr <= (sub3_cernbe_wr or sub3_cernbe_we) and not sub3_cernbe_VMEWrDone_i;
        sub3_cernbe_wt <= (sub3_cernbe_wt or sub3_cernbe_ws) and not sub3_cernbe_VMEWrDone_i;
        sub3_cernbe_rr <= (sub3_cernbe_rr or sub3_cernbe_re) and not sub3_cernbe_VMERdDone_i;
        sub3_cernbe_rt <= (sub3_cernbe_rt or sub3_cernbe_rs) and not sub3_cernbe_VMERdDone_i;
      end if;
    end if;
  end process;
  sub3_cernbe_rs <= sub3_cernbe_rr and not (sub3_cernbe_wr or (sub3_cernbe_rt or sub3_cernbe_wt));
  sub3_cernbe_ws <= sub3_cernbe_wr and not (sub3_cernbe_rt or sub3_cernbe_wt);
  process (rd_adr_d0, wr_adr_d0, sub3_cernbe_wt, sub3_cernbe_ws) begin
    if (sub3_cernbe_ws or sub3_cernbe_wt) = '1' then
      sub3_cernbe_VMEAddr_o <= wr_adr_d0(11 downto 2);
    else
      sub3_cernbe_VMEAddr_o <= rd_adr_d0(11 downto 2);
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, reg1_wack, reg2_wack, ram2_we, sub1_wb_wack, sub2_axi4_bvalid_i, sub3_cernbe_ws, sub3_cernbe_VMEWrDone_i) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    ram1_val_int_wr <= '0';
    ram2_wr_o <= '0';
    sub1_wb_we <= '0';
    sub2_axi4_wr <= '0';
    sub3_cernbe_VMEWrMem_o <= '0';
    sub3_cernbe_we <= '0';
    case wr_adr_d0(13 downto 12) is
    when "00" => 
      case wr_adr_d0(11 downto 5) is
      when "0000000" => 
        case wr_adr_d0(4 downto 2) is
        when "000" => 
          -- Reg reg1
          reg1_wreq <= wr_req_d0;
          wr_ack_d0 <= reg1_wack;
        when "001" => 
          -- Reg reg2
          reg2_wreq <= wr_req_d0;
          wr_ack_d0 <= reg2_wack;
        when others =>
          wr_ack_d0 <= wr_req_d0;
        end case;
      when "0000001" => 
        -- Memory ram1
        ram1_val_int_wr <= wr_req_d0;
        wr_ack_d0 <= wr_req_d0;
      when "0000010" => 
        -- Memory ram_ro
      when "0000011" => 
        -- Memory ram2
        ram2_wr_o <= ram2_we;
        wr_ack_d0 <= ram2_we;
      when others =>
        wr_ack_d0 <= wr_req_d0;
      end case;
    when "01" => 
      -- Submap sub1_wb
      sub1_wb_we <= wr_req_d0;
      wr_ack_d0 <= sub1_wb_wack;
    when "10" => 
      -- Submap sub2_axi4
      sub2_axi4_wr <= wr_req_d0;
      wr_ack_d0 <= sub2_axi4_bvalid_i;
    when "11" => 
      -- Submap sub3_cernbe
      sub3_cernbe_we <= wr_req_d0;
      sub3_cernbe_VMEWrMem_o <= sub3_cernbe_ws;
      wr_ack_d0 <= sub3_cernbe_VMEWrDone_i;
    when others =>
      wr_ack_d0 <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (rd_adr_d0, rd_req_d0, reg1_reg, reg2_reg, ram1_val_int_dato, ram1_wreq, ram1_val_rack, ram_ro_val_int_dato, ram_ro_val_rack, ram2_data_i, ram2_rack, sub1_wb_dat_i, sub1_wb_rack, sub2_axi4_rdata_i, sub2_axi4_rvalid_i, sub3_cernbe_rs, sub3_cernbe_VMERdData_i, sub3_cernbe_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    ram1_val_rreq <= '0';
    ram_ro_val_rreq <= '0';
    ram2_re <= '0';
    sub1_wb_re <= '0';
    sub2_axi4_rd <= '0';
    sub3_cernbe_VMERdMem_o <= '0';
    sub3_cernbe_re <= '0';
    case rd_adr_d0(13 downto 12) is
    when "00" => 
      case rd_adr_d0(11 downto 5) is
      when "0000000" => 
        case rd_adr_d0(4 downto 2) is
        when "000" => 
          -- Reg reg1
          rd_ack_d0 <= rd_req_d0;
          rd_dat_d0 <= reg1_reg;
        when "001" => 
          -- Reg reg2
          rd_ack_d0 <= rd_req_d0;
          rd_dat_d0 <= reg2_reg;
        when others =>
          rd_ack_d0 <= rd_req_d0;
        end case;
      when "0000001" => 
        -- Memory ram1
        rd_dat_d0 <= ram1_val_int_dato;
        ram1_val_rreq <= rd_req_d0 and not ram1_wreq;
        rd_ack_d0 <= ram1_val_rack;
      when "0000010" => 
        -- Memory ram_ro
        rd_dat_d0 <= ram_ro_val_int_dato;
        ram_ro_val_rreq <= rd_req_d0;
        rd_ack_d0 <= ram_ro_val_rack;
      when "0000011" => 
        -- Memory ram2
        rd_dat_d0 <= ram2_data_i;
        rd_ack_d0 <= ram2_rack;
        ram2_re <= rd_req_d0;
      when others =>
        rd_ack_d0 <= rd_req_d0;
      end case;
    when "01" => 
      -- Submap sub1_wb
      sub1_wb_re <= rd_req_d0;
      rd_dat_d0 <= sub1_wb_dat_i;
      rd_ack_d0 <= sub1_wb_rack;
    when "10" => 
      -- Submap sub2_axi4
      sub2_axi4_rd <= rd_req_d0;
      rd_dat_d0 <= sub2_axi4_rdata_i;
      rd_ack_d0 <= sub2_axi4_rvalid_i;
    when "11" => 
      -- Submap sub3_cernbe
      sub3_cernbe_re <= rd_req_d0;
      sub3_cernbe_VMERdMem_o <= sub3_cernbe_rs;
      rd_dat_d0 <= sub3_cernbe_VMERdData_i;
      rd_ack_d0 <= sub3_cernbe_VMERdDone_i;
    when others =>
      rd_ack_d0 <= rd_req_d0;
    end case;
  end process;
end syn;
