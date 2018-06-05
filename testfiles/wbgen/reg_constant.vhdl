library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rcst is
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
    wb_stall_o           : out   std_logic
  );
end rcst;

architecture syn of rcst is

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
          if (wb_we_i = '1') then
          end if;
          rddata_reg(7 downto 0) <= "00010011";
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
        end if;
      end if;
    end if;
  end process;


  -- Drive the data output bus
  wb_dat_o <= rddata_reg;
  rwaddr_reg <= (others => '0');
  wb_stall_o <= (not ack_sreg(0)) and (wb_stb_i and wb_cyc_i);
  -- ACK signal generation. Just pass the LSB of ACK counter.
  wb_ack_o <= ack_sreg(0);
end syn;
