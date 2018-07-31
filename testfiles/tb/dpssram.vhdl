library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wbgen2_dpssram is

  generic (
    g_data_width : natural := 32;
    g_size       : natural := 1024;
    g_addr_width : natural := 10;
    g_dual_clock : boolean := true;
    g_use_bwsel  : boolean := true);

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
end wbgen2_dpssram;


architecture behav of wbgen2_dpssram is
begin
  process is
    subtype word_t is std_logic_vector(g_data_width - 1 downto 0);
    type ram_t is array (0 to 2**g_addr_width - 1) of word_t;
    variable ram : ram_t;

    variable addr_a : natural;
    variable addr_b : natural;
  begin
    wait until rising_edge(clk_a_i) or rising_edge(clk_b_i);

    if rising_edge(clk_a_i) then
      if wr_a_i = '1' then
        --  TODO: handle wbsel.
        addr_a := to_integer(unsigned(addr_a_i));
        ram(addr_a) := data_a_i;
      end if;
      if rd_a_i = '1' then
        addr_a := to_integer(unsigned(addr_a_i));
        data_a_o <= ram(addr_a);
      end if;
    end if;

    if rising_edge(clk_b_i) then
      if wr_b_i = '1' then
        --  TODO: handle wbsel.
        addr_b := to_integer(unsigned(addr_b_i));
        ram(addr_b) := data_b_i;
      end if;
      if rd_a_i = '1' then
        addr_b := to_integer(unsigned(addr_b_i));
        data_b_o <= ram(addr_b);
      end if;
    end if;
  end process;
end behav;
