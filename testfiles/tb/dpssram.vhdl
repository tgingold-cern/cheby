library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cheby_dpssram is

  generic (
    g_data_width : natural := 32;
    g_size       : natural := 1024;
    g_addr_width : natural := 10;
    g_dual_clock : std_logic := '1';
    g_use_bwsel  : std_logic := '1');

  port (
    clk_a_i : in std_logic;
    clk_b_i : in std_logic;

    addr_a_i : in std_logic_vector(g_addr_width-1 downto 0);
    addr_b_i : in std_logic_vector(g_addr_width-1 downto 0);

    data_a_i : in std_logic_vector(g_data_width-1 downto 0);
    data_b_i : in std_logic_vector(g_data_width-1 downto 0);

    data_a_o : out std_logic_vector(g_data_width-1 downto 0);
    data_b_o : out std_logic_vector(g_data_width-1 downto 0);

    bwsel_a_i : in std_logic_vector((g_data_width+7)/8-1 downto 0);
    bwsel_b_i : in std_logic_vector((g_data_width+7)/8-1 downto 0);

    rd_a_i : in std_logic;
    rd_b_i : in std_logic;

    wr_a_i : in std_logic;
    wr_b_i : in std_logic
    );
end cheby_dpssram;


architecture behav of cheby_dpssram is
begin
  process is
    subtype word_t is std_logic_vector(g_data_width - 1 downto 0);
    type ram_t is array (0 to 2**g_addr_width - 1) of word_t;
    variable ram : ram_t;

    variable addr_a : natural;
    variable addr_b : natural;
    variable mask_a : std_logic_vector(g_data_width-1 downto 0);
    variable mask_b : std_logic_vector(g_data_width-1 downto 0);
  begin
    wait until rising_edge(clk_a_i) or rising_edge(clk_b_i);

    for idx in mask_a'range loop
      mask_a(idx) := bwsel_a_i(idx / 8);
      mask_b(idx) := bwsel_b_i(idx / 8);
    end loop ;

    if rising_edge(clk_a_i) then
      if wr_a_i = '1' then
        addr_a := to_integer(unsigned(addr_a_i));
        ram(addr_a) := (ram(addr_a) and not(mask_a)) or (data_a_i and mask_a);
      end if;
      if rd_a_i = '1' then
        addr_a := to_integer(unsigned(addr_a_i));
        data_a_o <= ram(addr_a);
      end if;
    end if;

    if rising_edge(clk_b_i) then
      if wr_b_i = '1' then
        addr_b := to_integer(unsigned(addr_b_i));
        ram(addr_b) := (ram(addr_b) and not(mask_b)) or (data_b_i and mask_b);
      end if;
      if rd_a_i = '1' then
        addr_b := to_integer(unsigned(addr_b_i));
        data_b_o <= ram(addr_b);
      end if;
    end if;
  end process;
end behav;
