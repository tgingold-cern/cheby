library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wbgen2_pkg.all;

entity ramclk is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_adr_i             : in    std_logic_vector(11 downto 0);
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    clk1                 : in    std_logic;
    -- Port for BIT field: 'Enable' in reg: 'Register 1'
    ram1_r1_enable_o     : out   std_logic;
    -- Ports for RAM: Channel 1
    ram1_ch1_addr_i      : in    std_logic_vector(10 downto 0);
    -- Read data output
    ram1_ch1_data_o      : out   std_logic_vector(31 downto 0);
    -- Read strobe input (active high)
    ram1_ch1_rd_i        : in    std_logic;
    -- Write data input
    ram1_ch1_data_i      : in    std_logic_vector(31 downto 0);
    -- Write strobe (active high)
    ram1_ch1_wr_i        : in    std_logic
  );
end ramclk;

architecture syn of ramclk is

  signal ram1_r1_enable_int             : std_logic;
  signal ram1_ch1_rddata_int            : std_logic_vector(31 downto 0);
  signal ram1_ch1_rd_int                : std_logic;
  signal ram1_ch1_wr_int                : std_logic;
  signal ack_sreg                       : std_logic_vector(9 downto 0);
  signal rddata_reg                     : std_logic_vector(31 downto 0);
  signal wrdata_reg                     : std_logic_vector(31 downto 0);
  signal bwsel_reg                      : std_logic_vector(3 downto 0);
  signal rwaddr_reg                     : std_logic_vector(11 downto 0);
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
      ram1_r1_enable_int <= '0';
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
          case rwaddr_reg(11) is
          when '0' => 
            if (wb_we_i = '1') then
              ram1_r1_enable_int <= wrdata_reg(0);
            end if;
            rddata_reg(0) <= ram1_r1_enable_int;
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
            ack_sreg(0) <= '1';
            ack_in_progress <= '1';
          when '1' => 
            if (rd_int = '1') then
              ack_sreg(0) <= '1';
            else
              ack_sreg(0) <= '1';
            end if;
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


  -- Data output multiplexer process
  process (rddata_reg, rwaddr_reg, ram1_ch1_rddata_int, wb_adr_i  )
  begin
    case rwaddr_reg(11) is
    when '1' => 
      wb_dat_o(31 downto 0) <= ram1_ch1_rddata_int;
    when others =>
      wb_dat_o <= rddata_reg;
    end case;
  end process;


  -- Read & write lines decoder for RAMs
  process (wb_adr_i, rd_int, wr_int  )
  begin
    if (wb_adr_i(11) = '1') then
      ram1_ch1_rd_int <= rd_int;
      ram1_ch1_wr_int <= wr_int;
    else
      ram1_ch1_wr_int <= '0';
      ram1_ch1_rd_int <= '0';
    end if;
  end process;


  -- Enable
  ram1_r1_enable_o <= ram1_r1_enable_int;
  -- extra code for reg/fifo/mem: Channel 1
  -- RAM block instantiation for memory: Channel 1
  ram1_ch1_raminst: wbgen2_dpssram
    generic map (
      g_data_width         => 32,
      g_size               => 2048,
      g_addr_width         => 11,
      g_dual_clock         => true,
      g_use_bwsel          => false
    )
    port map (
      clk_a_i              => clk_sys_i,
      clk_b_i              => clk1,
      addr_b_i             => ram1_ch1_addr_i,
      addr_a_i             => rwaddr_reg(10 downto 0),
      data_b_o             => ram1_ch1_data_o,
      rd_b_i               => ram1_ch1_rd_i,
      data_b_i             => ram1_ch1_data_i,
      wr_b_i               => ram1_ch1_wr_i,
      bwsel_b_i            => allones(3 downto 0),
      data_a_o             => ram1_ch1_rddata_int(31 downto 0),
      rd_a_i               => ram1_ch1_rd_int,
      data_a_i             => wrdata_reg(31 downto 0),
      wr_a_i               => ram1_ch1_wr_int,
      bwsel_a_i            => allones(3 downto 0)
    );
  
  rwaddr_reg <= wb_adr_i;
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
