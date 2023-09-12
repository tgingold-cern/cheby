library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;
use work.cheby_pkg.all;

entity all1_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

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
    sub3_cernbe_VMEWrDone_i : in    std_logic;

    -- An AVALON bus
    sub4_avalon_address_o : out   std_logic_vector(11 downto 2);
    sub4_avalon_readdata_i : in    std_logic_vector(31 downto 0);
    sub4_avalon_writedata_o : out   std_logic_vector(31 downto 0);
    sub4_avalon_byteenable_o : out   std_logic_vector(3 downto 0);
    sub4_avalon_read_o   : out   std_logic;
    sub4_avalon_write_o  : out   std_logic;
    sub4_avalon_readdatavalid_i : in    std_logic;
    sub4_avalon_waitrequest_i : in    std_logic;
    sub5_apb_paddr_o     : out   std_logic_vector(11 downto 2);
    sub5_apb_psel_o      : out   std_logic;
    sub5_apb_pwrite_o    : out   std_logic;
    sub5_apb_penable_o   : out   std_logic;
    sub5_apb_pready_i    : in    std_logic;
    sub5_apb_pwdata_o    : out   std_logic_vector(31 downto 0);
    sub5_apb_pstrb_o     : out   std_logic_vector(3 downto 0);
    sub5_apb_prdata_i    : in    std_logic_vector(31 downto 0);
    sub5_apb_pslverr_i   : in    std_logic
  );
end all1_wb;

architecture syn of all1_wb is
  signal adr_int                        : std_logic_vector(14 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
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
  signal ram_ro_val_int_dato            : std_logic_vector(31 downto 0);
  signal ram_ro_val_ext_dat             : std_logic_vector(31 downto 0);
  signal ram_ro_val_rreq                : std_logic;
  signal ram_ro_val_rack                : std_logic;
  signal ram2_rack                      : std_logic;
  signal ram2_re                        : std_logic;
  signal sub1_wb_re                     : std_logic;
  signal sub1_wb_we                     : std_logic;
  signal sub1_wb_wt                     : std_logic;
  signal sub1_wb_rt                     : std_logic;
  signal sub1_wb_tr                     : std_logic;
  signal sub1_wb_wack                   : std_logic;
  signal sub1_wb_rack                   : std_logic;
  signal sub2_axi4_aw_val               : std_logic;
  signal sub2_axi4_w_val                : std_logic;
  signal sub2_axi4_ar_val               : std_logic;
  signal sub2_axi4_rd                   : std_logic;
  signal sub2_axi4_wr                   : std_logic;
  signal sub4_avalon_re                 : std_logic;
  signal sub4_avalon_we                 : std_logic;
  signal sub4_avalon_rr                 : std_logic;
  signal sub4_avalon_wr                 : std_logic;
  signal sub5_apb_wr_req                : std_logic;
  signal sub5_apb_wr_ack                : std_logic;
  signal sub5_apb_wr                    : std_logic;
  signal sub5_apb_wr_reg                : std_logic;
  signal sub5_apb_rd_req                : std_logic;
  signal sub5_apb_rd_ack                : std_logic;
  signal sub5_apb_rd                    : std_logic;
  signal sub5_apb_rd_reg                : std_logic;
begin

  -- WB decode signals
  adr_int <= wb_i.adr(14 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- Register reg1
  reg1_o <= reg1_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg1_reg <= "00010010001101000000000000000000";
        reg1_wack <= '0';
      else
        if reg1_wreq = '1' then
          reg1_reg <= wb_i.dat;
        end if;
        reg1_wack <= reg1_wreq;
      end if;
    end if;
  end process;

  -- Register reg2
  reg2_o <= reg2_reg;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        reg2_reg <= "00010010001101000000000000000010";
        reg2_wack <= '0';
      else
        if reg2_wreq = '1' then
          reg2_reg <= wb_i.dat;
        end if;
        reg2_wack <= reg2_wreq;
      end if;
    end if;
  end process;

  -- Memory ram1
  ram1_val_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => adr_int(4 downto 2),
      bwsel_a_i            => wb_i.sel,
      data_a_i             => wb_i.dat,
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
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram1_val_rack <= '0';
      else
        ram1_val_rack <= ram1_val_rreq;
      end if;
    end if;
  end process;

  -- Memory ram_ro
  ram_ro_val_raminst: cheby_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 8,
      g_addr_width         => 3,
      g_dual_clock         => '0',
      g_use_bwsel          => '1'
    )
    port map (
      clk_a_i              => clk_i,
      clk_b_i              => clk_i,
      addr_a_i             => adr_int(4 downto 2),
      bwsel_a_i            => wb_i.sel,
      data_a_i             => (others => 'X'),
      data_a_o             => ram_ro_val_int_dato,
      rd_a_i               => ram_ro_val_rreq,
      wr_a_i               => '0',
      addr_b_i             => ram_ro_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => ram_ro_val_dat_i,
      data_b_o             => ram_ro_val_ext_dat,
      rd_b_i               => '0',
      wr_b_i               => ram_ro_val_we_i
    );
  
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram_ro_val_rack <= '0';
      else
        ram_ro_val_rack <= ram_ro_val_rreq;
      end if;
    end if;
  end process;

  -- Interface ram2
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ram2_rack <= '0';
      else
        ram2_rack <= ram2_re and not ram2_rack;
      end if;
    end if;
  end process;
  ram2_data_o <= wb_i.dat;
  ram2_addr_o <= adr_int(4 downto 2);

  -- Interface sub1_wb
  sub1_wb_tr <= sub1_wb_wt or sub1_wb_rt;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub1_wb_rt <= '0';
        sub1_wb_wt <= '0';
      else
        sub1_wb_rt <= (sub1_wb_rt or sub1_wb_re) and not sub1_wb_rack;
        sub1_wb_wt <= (sub1_wb_wt or sub1_wb_we) and not sub1_wb_wack;
      end if;
    end if;
  end process;
  sub1_wb_cyc_o <= sub1_wb_tr;
  sub1_wb_stb_o <= sub1_wb_tr;
  sub1_wb_wack <= sub1_wb_ack_i and sub1_wb_wt;
  sub1_wb_rack <= sub1_wb_ack_i and sub1_wb_rt;
  sub1_wb_adr_o <= adr_int(11 downto 2);
  sub1_wb_sel_o <= wb_i.sel;
  sub1_wb_we_o <= sub1_wb_wt;
  sub1_wb_dat_o <= wb_i.dat;

  -- Interface sub2_axi4
  sub2_axi4_awvalid_o <= sub2_axi4_aw_val;
  sub2_axi4_awaddr_o <= adr_int(11 downto 2);
  sub2_axi4_awprot_o <= "000";
  sub2_axi4_wvalid_o <= sub2_axi4_w_val;
  sub2_axi4_wdata_o <= wb_i.dat;
  sub2_axi4_wstrb_o <= wb_i.sel;
  sub2_axi4_bready_o <= '1';
  sub2_axi4_arvalid_o <= sub2_axi4_ar_val;
  sub2_axi4_araddr_o <= adr_int(11 downto 2);
  sub2_axi4_arprot_o <= "000";
  sub2_axi4_rready_o <= '1';
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub2_axi4_aw_val <= '0';
        sub2_axi4_w_val <= '0';
        sub2_axi4_ar_val <= '0';
      else
        sub2_axi4_aw_val <= sub2_axi4_wr or (sub2_axi4_aw_val and not sub2_axi4_awready_i);
        sub2_axi4_w_val <= sub2_axi4_wr or (sub2_axi4_w_val and not sub2_axi4_wready_i);
        sub2_axi4_ar_val <= sub2_axi4_rd or (sub2_axi4_ar_val and not sub2_axi4_arready_i);
      end if;
    end if;
  end process;

  -- Interface sub3_cernbe
  sub3_cernbe_VMEWrData_o <= wb_i.dat;
  sub3_cernbe_VMEAddr_o <= adr_int(11 downto 2);

  -- Interface sub4_avalon
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub4_avalon_rr <= '0';
        sub4_avalon_wr <= '0';
      else
        sub4_avalon_rr <= (sub4_avalon_rr and sub4_avalon_waitrequest_i) or sub4_avalon_re;
        sub4_avalon_wr <= (sub4_avalon_wr and sub4_avalon_waitrequest_i) or sub4_avalon_we;
      end if;
    end if;
  end process;
  sub4_avalon_address_o <= adr_int(11 downto 2);
  sub4_avalon_byteenable_o <= wb_i.sel;
  sub4_avalon_write_o <= sub4_avalon_wr;
  sub4_avalon_read_o <= sub4_avalon_rr;
  sub4_avalon_writedata_o <= wb_i.dat;

  -- Interface sub5_apb
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sub5_apb_wr_reg <= '0';
        sub5_apb_rd_reg <= '0';
      else
        if sub5_apb_wr_ack = '1' then
          sub5_apb_wr_reg <= '0';
        elsif sub5_apb_wr_req = '1' then
          sub5_apb_wr_reg <= '1';
        end if;
        if sub5_apb_rd_ack = '1' then
          sub5_apb_rd_reg <= '0';
        elsif sub5_apb_rd_req = '1' then
          sub5_apb_rd_reg <= '1';
        end if;
      end if;
    end if;
  end process;
  sub5_apb_wr <= sub5_apb_wr_reg or sub5_apb_wr_req;
  sub5_apb_rd <= sub5_apb_rd_reg or sub5_apb_rd_req;
  sub5_apb_psel_o <= sub5_apb_wr or sub5_apb_rd;
  sub5_apb_penable_o <= (not wr_req_int and sub5_apb_wr) or (not rd_req_int and sub5_apb_rd);
  sub5_apb_pwrite_o <= sub5_apb_wr;
  process (sub5_apb_wr, adr_int, adr_int) begin
    if sub5_apb_wr = '1' then
      sub5_apb_paddr_o <= adr_int(11 downto 2);
    else
      sub5_apb_paddr_o <= adr_int(11 downto 2);
    end if;
  end process;
  sub5_apb_pwdata_o <= wb_i.dat;
  sub5_apb_pstrb_o <= wb_i.sel;

  -- Process for write requests.
  process (adr_int, wr_req_int, reg1_wack, reg2_wack, sub1_wb_wack,
           sub2_axi4_bvalid_i, sub3_cernbe_VMEWrDone_i, sub4_avalon_wr,
           sub4_avalon_waitrequest_i, wr_ack_int, sub5_apb_wr, sub5_apb_pready_i,
           sub5_apb_pslverr_i) begin
    reg1_wreq <= '0';
    reg2_wreq <= '0';
    ram1_val_int_wr <= '0';
    ram2_wr_o <= '0';
    sub1_wb_we <= '0';
    sub2_axi4_wr <= '0';
    sub3_cernbe_VMEWrMem_o <= '0';
    sub4_avalon_we <= '0';
    sub5_apb_wr_req <= '0';
    sub5_apb_wr_ack <= '0';
    case adr_int(14 downto 12) is
    when "000" =>
      case adr_int(11 downto 5) is
      when "0000000" =>
        case adr_int(4 downto 2) is
        when "000" =>
          -- Reg reg1
          reg1_wreq <= wr_req_int;
          wr_ack_int <= reg1_wack;
        when "001" =>
          -- Reg reg2
          reg2_wreq <= wr_req_int;
          wr_ack_int <= reg2_wack;
        when others =>
          wr_ack_int <= wr_req_int;
        end case;
      when "0000001" =>
        -- Memory ram1
        ram1_val_int_wr <= wr_req_int;
        wr_ack_int <= wr_req_int;
      when "0000010" =>
        -- Memory ram_ro
        wr_ack_int <= wr_req_int;
      when "0000011" =>
        -- Memory ram2
        ram2_wr_o <= wr_req_int;
        wr_ack_int <= wr_req_int;
      when others =>
        wr_ack_int <= wr_req_int;
      end case;
    when "001" =>
      -- Submap sub1_wb
      sub1_wb_we <= wr_req_int;
      wr_ack_int <= sub1_wb_wack;
    when "010" =>
      -- Submap sub2_axi4
      sub2_axi4_wr <= wr_req_int;
      wr_ack_int <= sub2_axi4_bvalid_i;
    when "011" =>
      -- Submap sub3_cernbe
      sub3_cernbe_VMEWrMem_o <= wr_req_int;
      wr_ack_int <= sub3_cernbe_VMEWrDone_i;
    when "100" =>
      -- Submap sub4_avalon
      sub4_avalon_we <= wr_req_int;
      wr_ack_int <= sub4_avalon_wr and not sub4_avalon_waitrequest_i;
    when "101" =>
      -- Submap sub5_apb
      sub5_apb_wr_req <= wr_req_int;
      sub5_apb_wr_ack <= wr_ack_int;
      wr_ack_int <= sub5_apb_wr and sub5_apb_pready_i;
    when others =>
      wr_ack_int <= wr_req_int;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, reg1_reg, reg2_reg, ram1_val_int_dato, ram1_val_rack,
           ram_ro_val_int_dato, ram_ro_val_rack, ram2_data_i, ram2_rack,
           sub1_wb_dat_i, sub1_wb_rack, sub2_axi4_rdata_i, sub2_axi4_rvalid_i,
           sub3_cernbe_VMERdData_i, sub3_cernbe_VMERdDone_i,
           sub4_avalon_readdata_i, sub4_avalon_readdatavalid_i, rd_ack_int,
           sub5_apb_prdata_i, sub5_apb_rd, sub5_apb_pready_i, sub5_apb_pslverr_i) begin
    -- By default ack read requests
    wb_o.dat <= (others => 'X');
    ram1_val_rreq <= '0';
    ram_ro_val_rreq <= '0';
    ram2_re <= '0';
    sub1_wb_re <= '0';
    sub2_axi4_rd <= '0';
    sub3_cernbe_VMERdMem_o <= '0';
    sub4_avalon_re <= '0';
    sub5_apb_rd_req <= '0';
    sub5_apb_rd_ack <= '0';
    case adr_int(14 downto 12) is
    when "000" =>
      case adr_int(11 downto 5) is
      when "0000000" =>
        case adr_int(4 downto 2) is
        when "000" =>
          -- Reg reg1
          rd_ack_int <= rd_req_int;
          wb_o.dat <= reg1_reg;
        when "001" =>
          -- Reg reg2
          rd_ack_int <= rd_req_int;
          wb_o.dat <= reg2_reg;
        when others =>
          rd_ack_int <= rd_req_int;
        end case;
      when "0000001" =>
        -- Memory ram1
        wb_o.dat <= ram1_val_int_dato;
        ram1_val_rreq <= rd_req_int;
        rd_ack_int <= ram1_val_rack;
      when "0000010" =>
        -- Memory ram_ro
        wb_o.dat <= ram_ro_val_int_dato;
        ram_ro_val_rreq <= rd_req_int;
        rd_ack_int <= ram_ro_val_rack;
      when "0000011" =>
        -- Memory ram2
        wb_o.dat <= ram2_data_i;
        rd_ack_int <= ram2_rack;
        ram2_re <= rd_req_int;
      when others =>
        rd_ack_int <= rd_req_int;
      end case;
    when "001" =>
      -- Submap sub1_wb
      sub1_wb_re <= rd_req_int;
      wb_o.dat <= sub1_wb_dat_i;
      rd_ack_int <= sub1_wb_rack;
    when "010" =>
      -- Submap sub2_axi4
      sub2_axi4_rd <= rd_req_int;
      wb_o.dat <= sub2_axi4_rdata_i;
      rd_ack_int <= sub2_axi4_rvalid_i;
    when "011" =>
      -- Submap sub3_cernbe
      sub3_cernbe_VMERdMem_o <= rd_req_int;
      wb_o.dat <= sub3_cernbe_VMERdData_i;
      rd_ack_int <= sub3_cernbe_VMERdDone_i;
    when "100" =>
      -- Submap sub4_avalon
      sub4_avalon_re <= rd_req_int;
      wb_o.dat <= sub4_avalon_readdata_i;
      rd_ack_int <= sub4_avalon_readdatavalid_i;
    when "101" =>
      -- Submap sub5_apb
      sub5_apb_rd_req <= rd_req_int;
      sub5_apb_rd_ack <= rd_ack_int;
      wb_o.dat <= sub5_apb_prdata_i;
      rd_ack_int <= sub5_apb_rd and sub5_apb_pready_i;
    when others =>
      rd_ack_int <= rd_req_int;
    end case;
  end process;
end syn;
