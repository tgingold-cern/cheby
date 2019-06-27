library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rmonoasync is
  port (
    rst_n_i              : in    std_logic;
    clk_sys_i            : in    std_logic;
    wb_dat_i             : in    std_logic_vector(31 downto 0);
    wb_dat_o             : out   std_logic_vector(31 downto 0);
    wb_cyc_i             : in    std_logic;
    wb_sel_i             : in    std_logic_vector(3 downto 0);
    wb_stb_i             : in    std_logic;
    wb_we_i              : in    std_logic;
    wb_ack_o             : out   std_logic;
    wb_stall_o           : out   std_logic;
    clk1                 : in    std_logic;
    -- Port for asynchronous (clock: clk1) MONOSTABLE field: 'Reset bit' in reg: 'Register 1'
    pt_r1_reset_o        : out   std_logic
  );
end rmonoasync;

architecture syn of rmonoasync is

  signal pt_r1_reset_int                : std_logic;
  signal pt_r1_reset_int_delay          : std_logic;
  signal pt_r1_reset_sync0              : std_logic;
  signal pt_r1_reset_sync1              : std_logic;
  signal pt_r1_reset_sync2              : std_logic;
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
      pt_r1_reset_int <= '0';
      pt_r1_reset_int_delay <= '0';
    elsif rising_edge(clk_sys_i) then
      -- advance the ACK generator shift register
      ack_sreg(8 downto 0) <= ack_sreg(9 downto 1);
      ack_sreg(9) <= '0';
      if (ack_in_progress = '1') then
        if (ack_sreg(0) = '1') then
          ack_in_progress <= '0';
        else
          pt_r1_reset_int <= pt_r1_reset_int_delay;
          pt_r1_reset_int_delay <= '0';
        end if;
      else
        if ((wb_cyc_i = '1') and (wb_stb_i = '1')) then
          if (wb_we_i = '1') then
            pt_r1_reset_int <= wrdata_reg(0);
            pt_r1_reset_int_delay <= wrdata_reg(0);
          end if;
          rddata_reg(0) <= '0';
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
          ack_sreg(4) <= '1';
          ack_in_progress <= '1';
        end if;
      end if;
    end if;
  end process;


  -- Drive the data output bus
  wb_dat_o <= rddata_reg;
  -- Reset bit
  process (clk1, rst_n_i)
  begin
    if (rst_n_i = '0') then
      pt_r1_reset_o <= '0';
      pt_r1_reset_sync0 <= '0';
      pt_r1_reset_sync1 <= '0';
      pt_r1_reset_sync2 <= '0';
    elsif rising_edge(clk1) then
      pt_r1_reset_sync0 <= pt_r1_reset_int;
      pt_r1_reset_sync1 <= pt_r1_reset_sync0;
      pt_r1_reset_sync2 <= pt_r1_reset_sync1;
      pt_r1_reset_o <= pt_r1_reset_sync2 and (not pt_r1_reset_sync1);
    end if;
  end process;


  rwaddr_reg <= (others => '0');
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
