entity array1_tb is
end array1_tb;

library ieee;
use ieee.std_logic_1164.all;

architecture behav of array1_tb is
  signal rst_n   : std_logic;
  signal clk     : std_logic;
  signal wb_cyc  : std_logic;
  signal wb_stb  : std_logic;
  signal wb_adr  : std_logic_vector(3 downto 0);
  signal wb_sel  : std_logic_vector(3 downto 0);
  signal wb_we   : std_logic;
  signal wb_dato : std_logic_vector(31 downto 0);
  signal wb_ack  : std_logic;
  signal wb_err  : std_logic;
  signal wb_rty  : std_logic;
  signal wb_stall: std_logic;
  signal wb_dati : std_logic_vector(31 downto 0);

  signal end_of_test : boolean := false;
begin
  --  Clock and reset
  process
  begin
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;

    if end_of_test then
      wait;
    end if;
  end process;

  rst_n <= '0' after 0 ns, '1' after 20 ns;

  dut : entity work.array1
    port map (
      rst_n_i    => rst_n,
      clk_i      => clk,
      wb_cyc_i   => wb_cyc,
      wb_stb_i   => wb_stb,
      wb_adr_i   => wb_adr,
      wb_sel_i   => wb_sel,
      wb_we_i    => wb_we,
      wb_dat_i   => wb_dati,
      wb_ack_o   => wb_ack,
      wb_err_o   => wb_err,
      wb_rty_o   => wb_rty,
      wb_stall_o => wb_stall,
      wb_dat_o   => wb_dato,
      areg_adr_i => (others => '0'),
      areg_rd_i  => '0',
      areg_dat_o => open);

  process
    procedure wb_cycle(addr : std_logic_vector (31 downto 0)) is
    begin
      wb_cyc <= '1';
      wb_stb <= '1';
      wb_adr <= addr (wb_adr'range);
      wb_sel <= "1111";

      wait until rising_edge(clk);

      while wb_ack = '0' loop
        wait until rising_edge(clk);
      end loop;

      wb_cyc <= '0';
      wb_stb <= '0';
    end wb_cycle;

    procedure wb_writel (addr : std_logic_vector (31 downto 0);
                         data : std_logic_vector (31 downto 0)) is
    begin
      --  W transfer
      wb_we <= '1';
      wb_dati <= data;

      wb_cycle(addr);
    end wb_writel;

    procedure wb_readl (addr : std_logic_vector (31 downto 0);
                        data : out std_logic_vector (31 downto 0)) is
    begin
      --  R transfer
      wb_we <= '0';
      wb_cycle(addr);
      data := wb_dato;
    end wb_readl;

    variable v : std_logic_vector(31 downto 0);
  begin
    wb_stb <= '0';
    wb_cyc <= '0';

    --  Wait after reset.
    wait until rising_edge(clk) and rst_n = '1';

    wait until rising_edge(clk);
    wb_writel (x"0000_0001", x"abcd_0001");
    wait until rising_edge(clk);
    wb_writel (x"0000_0003", x"abcd_0203");
    wait until rising_edge(clk);

    wb_readl (x"0000_0001", v);
    assert v = x"abcd_0001" severity error;

    wait until rising_edge(clk);
    wb_readl (x"0000_0003", v);
    assert v = x"abcd_0203" severity error;

    wait until rising_edge(clk);

    end_of_test <= true;
    wait;
  end process;
end behav;
