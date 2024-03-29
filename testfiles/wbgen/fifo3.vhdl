library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity fifo3 is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_adr_i             : in    std_logic_vector(0 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    -- FIFO write request
    fifo_fifo2_wr_req_i  : in    std_logic;
    -- FIFO full flag
    fifo_fifo2_wr_full_o : out   std_logic;
    -- FIFO empty flag
    fifo_fifo2_wr_empty_o : out   std_logic;
    fifo_fifo2_val_i     : in    std_logic_vector(7 downto 0);
    fifo_fifo2_val2_i    : in    std_logic_vector(6 downto 0)
  );
end fifo3;

architecture syn of fifo3 is

  signal fifo_fifo2_rst_n               : std_logic;
  signal fifo_fifo2_in_int              : std_logic_vector(14 downto 0);
  signal fifo_fifo2_out_int             : std_logic_vector(14 downto 0);
  signal fifo_fifo2_rdreq_int           : std_logic;
  signal fifo_fifo2_rdreq_int_d0        : std_logic;
  signal fifo_fifo2_full_int            : std_logic;
  signal ack_sreg                       : std_logic_vector(9 downto 0);
  signal rddata_reg                     : std_logic_vector(31 downto 0);
  signal wrdata_reg                     : std_logic_vector(31 downto 0);
  signal bwsel_reg                      : std_logic_vector(3 downto 0);
  signal rwaddr_reg                     : std_logic_vector(0 downto 0);
  signal ack_in_progress                : std_logic;
  signal wr_int                         : std_logic;
  signal rd_int                         : std_logic;
  signal allones                        : std_logic_vector(31 downto 0);
  signal allzeros                       : std_logic_vector(31 downto 0);

begin
  -- Some internal signals assignments. For (foreseen) compatibility with other bus standards.
  wrdata_reg <= wb_dat_i;
  bwsel_reg <= wb_sel_i;
  rd_int <= wb_cyc_i and (wb_stb_i and (not wb_we_i));
  wr_int <= wb_cyc_i and (wb_stb_i and wb_we_i);
  allones <= (others => '1');
  allzeros <= (others => '0');
  -- 
  -- Main register bank access process.
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      ack_sreg <= "0000000000";
      ack_in_progress <= '0';
      rddata_reg <= "00000000000000000000000000000000";
      fifo_fifo2_rdreq_int <= '0';
    elsif rising_edge(clk_sys_i) then
      -- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          ack_in_progress <= '0';
        else
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          case rwaddr_reg(0) is
          when '0' =>
            if (wb_we_i = '1') then
            end if;
            if (fifo_fifo2_rdreq_int_d0 = '0') then
              fifo_fifo2_rdreq_int <= not fifo_fifo2_rdreq_int;
            else
              rddata_reg(7 downto 0) <= fifo_fifo2_out_int(7 downto 0);
              rddata_reg(14 downto 8) <= fifo_fifo2_out_int(14 downto 8);
              rddata_reg(15) <= 'X';
              rddata_reg(16) <= 'X';
              rddata_reg(17) <= 'X';
              rddata_reg(18) <= 'X';
              rddata_reg(19) <= 'X';
              rddata_reg(20) <= 'X';
              rddata_reg(21) <= 'X';
              rddata_reg(22) <= 'X';
              rddata_reg(23) <= 'X';
              rddata_reg(24) <= 'X';
              rddata_reg(25) <= 'X';
              rddata_reg(26) <= 'X';
              rddata_reg(27) <= 'X';
              rddata_reg(28) <= 'X';
              rddata_reg(29) <= 'X';
              rddata_reg(30) <= 'X';
              rddata_reg(31) <= 'X';
              ack_in_progress <= '1';
              ack_sreg(0) <= '1';
            end if;
          when '1' =>
            if (wb_we_i = '1') then
            end if;
            rddata_reg(16) <= fifo_fifo2_full_int;
            rddata_reg(0) <= 'X';
            rddata_reg(1) <= 'X';
            rddata_reg(2) <= 'X';
            rddata_reg(3) <= 'X';
            rddata_reg(4) <= 'X';
            rddata_reg(5) <= 'X';
            rddata_reg(6) <= 'X';
            rddata_reg(7) <= 'X';
            rddata_reg(8) <= 'X';
            rddata_reg(9) <= 'X';
            rddata_reg(10) <= 'X';
            rddata_reg(11) <= 'X';
            rddata_reg(12) <= 'X';
            rddata_reg(13) <= 'X';
            rddata_reg(14) <= 'X';
            rddata_reg(15) <= 'X';
            rddata_reg(17) <= 'X';
            rddata_reg(18) <= 'X';
            rddata_reg(19) <= 'X';
            rddata_reg(20) <= 'X';
            rddata_reg(21) <= 'X';
            rddata_reg(22) <= 'X';
            rddata_reg(23) <= 'X';
            rddata_reg(24) <= 'X';
            rddata_reg(25) <= 'X';
            rddata_reg(26) <= 'X';
            rddata_reg(27) <= 'X';
            rddata_reg(28) <= 'X';
            rddata_reg(29) <= 'X';
            rddata_reg(30) <= 'X';
            rddata_reg(31) <= 'X';
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when others =>
            -- prevent the slave from hanging the bus on invalid address
            ack_in_progress <= '1';
            ack_sreg(0) <= '1';
          end case;
        end if;
      end if;
    end if;
  end process;


  -- Drive the data output bus
  wb_dat_o <= rddata_reg;
  -- extra code for reg/fifo/mem: fifo2
  fifo_fifo2_in_int(7 downto 0) <= fifo_fifo2_val_i;
  fifo_fifo2_in_int(14 downto 8) <= fifo_fifo2_val2_i;
  fifo_fifo2_rst_n <= rst_n_i;
  fifo_fifo2_INST: wbgen2_fifo_sync
    generic map (
      g_size               => 128,
      g_width              => 15,
      g_usedw_size         => 7
    )
    port map (
      wr_req_i             => fifo_fifo2_wr_req_i,
      wr_full_o            => fifo_fifo2_wr_full_o,
      wr_empty_o           => fifo_fifo2_wr_empty_o,
      rd_full_o            => fifo_fifo2_full_int,
      rd_req_i             => fifo_fifo2_rdreq_int,
      rst_n_i              => fifo_fifo2_rst_n,
      clk_i                => clk_sys_i,
      wr_data_i            => fifo_fifo2_in_int,
      rd_data_o            => fifo_fifo2_out_int
    );
  
  -- extra code for reg/fifo/mem: FIFO 'fifo2' data output register 0
  process (clk_sys_i, rst_n_i)
  begin
    if (rst_n_i = '0') then
      fifo_fifo2_rdreq_int_d0 <= '0';
    elsif rising_edge(clk_sys_i) then
      fifo_fifo2_rdreq_int_d0 <= fifo_fifo2_rdreq_int;
    end if;
  end process;


  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
