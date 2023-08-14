library ieee;
use ieee.std_logic_1164.all;

package apb_tb_pkg is

  constant datalen : natural := 32;

  type t_apb_master_out is record
    paddr   : std_logic_vector(31 downto 0);
    psel    : std_logic;
    pwrite  : std_logic;
    penable : std_logic;
    pwdata  : std_logic_vector(datalen-1 downto 0);
    pstrb   : std_logic_vector(datalen/8-1 downto 0);
  end record;

  subtype t_apb_slave_in is t_apb_master_out;

  type t_apb_master_in is record
    pready  : std_logic;
    prdata  : std_logic_vector(datalen-1 downto 0);
    pslverr : std_logic;
   end record;

  subtype t_apb_slave_out is t_apb_master_in;


  procedure apb_write (
    signal clk_i : in  std_logic;
    signal bus_o : out t_apb_master_out;
    signal bus_i : in  t_apb_master_in;
    addr         : in  std_logic_vector(31 downto 0);
    data         : in  std_logic_vector(datalen - 1 downto 0);
    slverr       : in  std_logic);

  procedure apb_write (
    signal clk_i : in  std_logic;
    signal bus_o : out t_apb_master_out;
    signal bus_i : in  t_apb_master_in;
    addr         : in  std_logic_vector(31 downto 0);
    data         : in  std_logic_vector(datalen - 1 downto 0));

  procedure apb_read (
    signal clk_i : in  std_logic;
    signal bus_o : out t_apb_master_out;
    signal bus_i : in  t_apb_master_in;
    addr         : in  std_logic_vector(31 downto 0);
    data         : out std_logic_vector(datalen - 1 downto 0);
    slverr       : in  std_logic);

  procedure apb_read (
    signal clk_i : in  std_logic;
    signal bus_o : out t_apb_master_out;
    signal bus_i : in  t_apb_master_in;
    addr         : in  std_logic_vector(31 downto 0);
    data         : out std_logic_vector(datalen - 1 downto 0));

  procedure apb_init (
    signal bus_o : out t_apb_master_out);

end apb_tb_pkg;


package body apb_tb_pkg is

  procedure apb_init (signal bus_o : out t_apb_master_out) is
  begin
    bus_o <= (
      paddr   => (others => '0'),
      psel    => '0',
      pwrite  => '0',
      penable => '0',
      pwdata  => (others => '0'),
      pstrb   => (others => '0')
    );
  end apb_init;

  procedure apb_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_apb_master_out;
      signal bus_i : in  t_apb_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(datalen - 1 downto 0);
      slverr       : in  std_logic) is
  begin
    wait until rising_edge(clk_i);

    -- Write request:
    -- Setup Phase
    bus_o <= (
      paddr   => addr,
      psel    => '1',
      pwrite  => '1',
      penable => '0',
      pwdata  => data,
      pstrb   => (others => '1')
    );

    wait until rising_edge(clk_i);

    -- Access Phase
    bus_o.penable <= '1';

    --   Wait for reply
    loop
      exit when bus_i.pready = '1';

      wait until rising_edge(clk_i);
    end loop;

    bus_o.penable <= '0';
    bus_o.psel    <= '0';
    bus_o.pwrite  <= '0';

    --   Check error
    if bus_i.pslverr /= slverr then
      report "Got wrong slverr, expected " & to_string(slverr) & ", got " & to_string(bus_i.pslverr) severity error;
    end if;
  end apb_write;

  procedure apb_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_apb_master_out;
      signal bus_i : in  t_apb_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(datalen - 1 downto 0)) is
  begin
    apb_write(clk_i, bus_o, bus_i, addr, data, '0');
  end apb_write;

  procedure apb_read (
    signal clk_i : in  std_logic;
    signal bus_o : out t_apb_master_out;
    signal bus_i : in  t_apb_master_in;
    addr         : in  std_logic_vector(31 downto 0);
    data         : out std_logic_vector(datalen - 1 downto 0);
    slverr       : in  std_logic) is
  begin
    wait until rising_edge(clk_i);

    -- Read request:
    -- Setup Phase
    bus_o <= (
      paddr   => addr,
      psel    => '1',
      pwrite  => '0',
      penable => '0',
      pwdata  => (others => '0'),
      pstrb   => (others => '0')
    );

    wait until rising_edge(clk_i);

    -- Access Phase
    bus_o.penable <= '1';

    --   Wait for reply
    loop
      exit when bus_i.pready = '1';

      wait until rising_edge(clk_i);
    end loop;

    data          := bus_i.prdata;
    bus_o.penable <= '0';
    bus_o.psel    <= '0';

    --   Check error
    if bus_i.pslverr /= slverr then
      report "Got wrong slverr, expected " & to_string(slverr) & ", got " & to_string(bus_i.pslverr) severity error;
    end if;
  end apb_read;

  procedure apb_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_apb_master_out;
      signal bus_i : in  t_apb_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(datalen - 1 downto 0)) is
  begin
    apb_read(clk_i, bus_o, bus_i, addr, data, '0');
  end apb_read;

end apb_tb_pkg;
