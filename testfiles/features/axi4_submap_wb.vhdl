library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi4_submap_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_cyc_i             : in    std_logic;
    wb_stb_i             : in    std_logic;
    wb_adr_i             : in    std_logic_vector(2 downto 2);
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_we_i              : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_ack_o             : out   std_logic;
    wb_err_o             : out   std_logic;
    wb_rty_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    wb_dat_o             : out   std_logic_vector(31 downto 0);

    -- AXI-4 lite bus blk
    blk_awvalid_o        : out   std_logic;
    blk_awready_i        : in    std_logic;
    blk_awaddr_o         : out   std_logic_vector(2 downto 0);
    blk_awprot_o         : out   std_logic_vector(2 downto 0);
    blk_wvalid_o         : out   std_logic;
    blk_wready_i         : in    std_logic;
    blk_wdata_o          : out   std_logic_vector(31 downto 0);
    blk_wstrb_o          : out   std_logic_vector(3 downto 0);
    blk_bvalid_i         : in    std_logic;
    blk_bready_o         : out   std_logic;
    blk_bresp_i          : in    std_logic_vector(1 downto 0);
    blk_arvalid_o        : out   std_logic;
    blk_arready_i        : in    std_logic;
    blk_araddr_o         : out   std_logic_vector(2 downto 0);
    blk_arprot_o         : out   std_logic_vector(2 downto 0);
    blk_rvalid_i         : in    std_logic;
    blk_rready_o         : out   std_logic;
    blk_rdata_i          : in    std_logic_vector(31 downto 0);
    blk_rresp_i          : in    std_logic_vector(1 downto 0)
  );
end axi4_submap_wb;

architecture syn of axi4_submap_wb is
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal blk_aw_val                     : std_logic;
  signal blk_w_val                      : std_logic;
  signal blk_rd                         : std_logic;
  signal blk_wr                         : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_sel_d0                      : std_logic_vector(3 downto 0);
begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_we_i)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_we_i) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_we_i)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_we_i) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= not ack_int and wb_en;
  wb_rty_o <= '0';
  wb_err_o <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_dat_o <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= wb_adr_i;
        wr_dat_d0 <= wb_dat_i;
        wr_sel_d0 <= wb_sel_i;
      end if;
    end if;
  end process;

  -- Interface blk
  blk_awvalid_o <= blk_aw_val;
  blk_awaddr_o <= wr_adr_d0(2 downto 2) & "00";
  blk_awprot_o <= "000";
  blk_wvalid_o <= blk_w_val;
  blk_wdata_o <= wr_dat_d0;
  blk_wstrb_o <= wr_sel_d0;
  blk_bready_o <= '1';
  blk_arvalid_o <= blk_rd;
  blk_araddr_o <= wb_adr_i(2 downto 2) & "00";
  blk_arprot_o <= "000";
  blk_rready_o <= '1';
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        blk_aw_val <= '0';
        blk_w_val <= '0';
      else
        blk_aw_val <= '0';
        blk_aw_val <= blk_wr or (blk_aw_val and not blk_awready_i);
        blk_w_val <= '0';
        blk_w_val <= blk_wr or (blk_w_val and not blk_wready_i);
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, blk_bvalid_i) begin
    blk_wr <= '0';
    -- Submap blk
    blk_wr <= wr_req_d0;
    wr_ack_int <= blk_bvalid_i;
  end process;

  -- Process for read requests.
  process (rd_req_int, blk_rdata_i, blk_rvalid_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    blk_rd <= '0';
    -- Submap blk
    blk_rd <= rd_req_int;
    rd_dat_d0 <= blk_rdata_i;
    rd_ack_d0 <= blk_rvalid_i;
  end process;
end syn;
