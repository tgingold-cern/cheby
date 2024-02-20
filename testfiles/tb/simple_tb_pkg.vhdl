library ieee;
use ieee.std_logic_1164.all;

package simple_tb_pkg is
  type t_simple_master_out is record
    adr   : std_logic_vector(31 downto 0);
    dati : std_logic_vector(31 downto 0);
    rd  : std_logic;
    wr  : std_logic;
  end record;

  type t_simple_master_in is record
    dato : std_logic_vector(31 downto 0);
    rack : std_logic;
    wack : std_logic;
  end record;

  subtype t_simple_slave_in is t_simple_master_out;
  subtype t_simple_slave_out is t_simple_master_in;

  procedure simple_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_simple_master_out;
      signal bus_i : in  t_simple_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(31 downto 0));

  procedure simple_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_simple_master_out;
      signal bus_i : in  t_simple_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(31 downto 0));

  procedure simple_init (signal bus_o : out t_simple_master_out);
end simple_tb_pkg;

package body simple_tb_pkg is
  procedure simple_init (signal bus_o : out t_simple_master_out) is
  begin
    bus_o <= (adr  => (others => '0'),
              dati => (others => '0'),
              rd   => '0',
              wr   => '0');
  end simple_init;

  procedure simple_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_simple_master_out;
      signal bus_i : in  t_simple_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(31 downto 0)) is
  begin
    --  Write request
    wait until rising_edge(clk_i);
    bus_o <= (adr  => addr,
              dati => data,
              rd  => '0',
              wr  => '1');

    wait until rising_edge(clk_i);

    bus_o.wr <= '0';

    -- Wait for reply.
    loop
      exit when bus_i.wack = '1';

      wait until rising_edge(clk_i);
    end loop;
  end simple_write;

  procedure simple_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_simple_master_out;
      signal bus_i : in  t_simple_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(31 downto 0))
  is
      variable dataTmp : std_logic_vector(31 downto 0);
      variable addrTmp : std_logic_vector(31 downto 0);
   begin
      -- Read request.
      wait until rising_edge(clk_i);
      bus_o <= (adr => addr,
                dati  => (others => '0'),
                rd  => '1',
                wr  => '0');

      wait until rising_edge(clk_i);

      bus_o.rd <= '0';

      -- Wait for a reply
      loop
         exit when bus_i.rack = '1';

         wait until rising_edge(clk_i);
      end loop;

      data := bus_i.dato;
   end simple_read;
end simple_tb_pkg;
