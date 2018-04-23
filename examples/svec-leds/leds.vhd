library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_demo is
  port (
    rst_n_i                          : in    std_logic;
    clk_i                            : in    std_logic;
    wb_adr_i                         : in    std_logic_vector(4 downto 0);
    wb_dat_i                         : in    std_logic_vector(31 downto 0);
    wb_dat_o                         : out   std_logic_vector(31 downto 0);
    wb_cyc_i                         : in    std_logic;
    wb_sel_i                         : in    std_logic_vector(3 downto 0);
    wb_stb_i                         : in    std_logic;
    wb_we_i                          : in    std_logic;
    wb_ack_o                         : out   std_logic;
    wb_stall_o                       : out   std_logic;
    led_demo_leds_led0_en_o          : out   std_logic;
    led_demo_leds_led1_en_o          : out   std_logic;
    led_demo_leds_led2_en_o          : out   std_logic;
    led_demo_leds_led3_en_o          : out   std_logic;
    led_demo_leds_led4_en_o          : out   std_logic;
    led_demo_leds_led5_en_o          : out   std_logic;
    led_demo_leds_led6_en_o          : out   std_logic;
    led_demo_leds_led7_en_o          : out   std_logic
  );
end led_demo;

architecture syn of led_demo is
  signal wb_en                                    : std_logic;
  signal rd_int                                   : std_logic;
  signal wr_int                                   : std_logic;
  signal ack_int                                  : std_logic;
  signal rd_ack_int                               : std_logic;
  signal wr_ack_int                               : std_logic;
  signal led_demo_leds_led0_en_reg                : std_logic;
  signal led_demo_leds_led1_en_reg                : std_logic;
  signal led_demo_leds_led2_en_reg                : std_logic;
  signal led_demo_leds_led3_en_reg                : std_logic;
  signal led_demo_leds_led4_en_reg                : std_logic;
  signal led_demo_leds_led5_en_reg                : std_logic;
  signal led_demo_leds_led6_en_reg                : std_logic;
  signal led_demo_leds_led7_en_reg                : std_logic;

begin

  -- WB decode signals
  wb_en <= wb_cyc_i and wb_stb_i;
  rd_int <= wb_en and (not wb_we_i);
  wr_int <= wb_en and wb_we_i;
  ack_int <= rd_ack_int or wr_ack_int;
  wb_ack_o <= ack_int;
  wb_stall_o <= (not ack_int) and wb_en;

  -- Assign outputs
  led_demo_leds_led0_en_o <= led_demo_leds_led0_en_reg;
  led_demo_leds_led1_en_o <= led_demo_leds_led1_en_reg;
  led_demo_leds_led2_en_o <= led_demo_leds_led2_en_reg;
  led_demo_leds_led3_en_o <= led_demo_leds_led3_en_reg;
  led_demo_leds_led4_en_o <= led_demo_leds_led4_en_reg;
  led_demo_leds_led5_en_o <= led_demo_leds_led5_en_reg;
  led_demo_leds_led6_en_o <= led_demo_leds_led6_en_reg;
  led_demo_leds_led7_en_o <= led_demo_leds_led7_en_reg;

  -- Process to write registers.
  process (clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then 
      led_demo_leds_led0_en_reg <= '0';
      led_demo_leds_led1_en_reg <= '0';
      led_demo_leds_led2_en_reg <= '0';
      led_demo_leds_led3_en_reg <= '0';
      led_demo_leds_led4_en_reg <= '0';
      led_demo_leds_led5_en_reg <= '0';
      led_demo_leds_led6_en_reg <= '0';
      led_demo_leds_led7_en_reg <= '0';
    elsif rising_edge(clk_i) then
      if (wr_int = '1') and (wr_ack_int = '0') then
        case wb_adr_i(4 downto 2) is
        when "000" => 
          -- led0
          led_demo_leds_led0_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "001" => 
          -- led1
          led_demo_leds_led1_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "010" => 
          -- led2
          led_demo_leds_led2_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "011" => 
          -- led3
          led_demo_leds_led3_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "100" => 
          -- led4
          led_demo_leds_led4_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "101" => 
          -- led5
          led_demo_leds_led5_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "110" => 
          -- led6
          led_demo_leds_led6_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when "111" => 
          -- led7
          led_demo_leds_led7_en_reg <= wb_dat_i(0);
          wr_ack_int <= '1';
        when others =>
          wr_ack_int <= '1';
        end case;
      else
        wr_ack_int <= '0';
      end if;
    end if;
  end process;

  -- Process to read registers.
  process (clk_i, rst_n_i)
  begin
    if rst_n_i = '0' then 
      rd_ack_int <= '0';
      wb_dat_o <= (others => 'X');
    elsif rising_edge(clk_i) then
      wb_dat_o <= (others => 'X');
      if (rd_int = '1') and (rd_ack_int = '0') then
        case wb_adr_i(4 downto 2) is
        when "000" => 
          -- led0
          wb_dat_o(0) <= led_demo_leds_led0_en_reg;
          rd_ack_int <= '1';
        when "001" => 
          -- led1
          wb_dat_o(0) <= led_demo_leds_led1_en_reg;
          rd_ack_int <= '1';
        when "010" => 
          -- led2
          wb_dat_o(0) <= led_demo_leds_led2_en_reg;
          rd_ack_int <= '1';
        when "011" => 
          -- led3
          wb_dat_o(0) <= led_demo_leds_led3_en_reg;
          rd_ack_int <= '1';
        when "100" => 
          -- led4
          wb_dat_o(0) <= led_demo_leds_led4_en_reg;
          rd_ack_int <= '1';
        when "101" => 
          -- led5
          wb_dat_o(0) <= led_demo_leds_led5_en_reg;
          rd_ack_int <= '1';
        when "110" => 
          -- led6
          wb_dat_o(0) <= led_demo_leds_led6_en_reg;
          rd_ack_int <= '1';
        when "111" => 
          -- led7
          wb_dat_o(0) <= led_demo_leds_led7_en_reg;
          rd_ack_int <= '1';
        when others =>
          rd_ack_int <= '1';
        end case;
      else
        rd_ack_int <= '0';
      end if;
    end if;
  end process;
end syn;
