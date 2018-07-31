library ieee;
use ieee.std_logic_1164.all;

entity generic_dpram is
  generic (
    g_data_width               : natural;
    g_size                     : natural;
    g_with_byte_enable         : boolean;
    g_addr_conflict_resolution : string := "read_first";
    g_init_file                : string := "";
    g_dual_clock               : boolean);
  port (
    rst_n_i : in  std_logic := '1';

    clka_i  : in  std_logic;
    bwea_i  : in  std_logic_vector(g_data_width/8-1 downto 0);
    wea_i   : in  std_logic;
    aa_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    da_i    : in  std_logic_vector(g_data_width-1 downto 0);
    qa_o    : out std_logic_vector(g_data_width-1 downto 0);

    clkb_i  : in  std_logic;
    bweb_i  : in  std_logic_vector(g_data_width/8-1 downto 0);
    web_i   : in  std_logic;
    ab_i    : in  std_logic_vector(f_log2_size(g_size)-1 downto 0);
    db_i    : in  std_logic_vector(g_data_width-1 downto 0);
    qb_o    : out std_logic_vector(g_data_width-1 downto 0));
end generic_dpram;

architecture behav of generic_dpram is
begin
  process
