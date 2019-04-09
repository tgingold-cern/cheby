library ieee;
use ieee.std_logic_1164.all;

package cernbe_tb_pkg is
  type t_cernbe_master_out is record
    VMEAddr   : std_logic_vector(31 downto 0);
    VMEWrData : std_logic_vector(31 downto 0);
    VMERdMem  : std_logic;
    VMEWrMem  : std_logic;
  end record;

  type t_cernbe_master_in is record
    VMERdData : std_logic_vector(31 downto 0);
    VMERdDone : std_logic;
    VMEWrDone : std_logic;
  end record;

  subtype t_cernbe_slave_in is t_cernbe_master_out;
  subtype t_cernbe_slave_out is t_cernbe_master_in;

  procedure cernbe_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_cernbe_master_out;
      signal bus_i : in  t_cernbe_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(31 downto 0));

  procedure cernbe_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_cernbe_master_out;
      signal bus_i : in  t_cernbe_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(31 downto 0));

  procedure cernbe_init (signal bus_o : out t_cernbe_master_out);
end cernbe_tb_pkg;

package body cernbe_tb_pkg is
  procedure cernbe_init (signal bus_o : out t_cernbe_master_out) is
  begin
    bus_o <= (VMEAddr => (others => '0'),
              VMEWrData   => (others => '0'),
              VMERdMem => '0',
              VMEWrMem  => '0');
  end cernbe_init;

  procedure cernbe_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_cernbe_master_out;
      signal bus_i : in  t_cernbe_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(31 downto 0)) is
  begin
    --  Write request
    wait until rising_edge(clk_i);
    bus_o <= (VMEAddr   => addr,
              VMEWrData => data,
              VMERdMem  => '0',
              VMEWrMem  => '1');

    wait until rising_edge(clk_i);

    bus_o.VMEWrMem <= '0';

    -- Wait for reply.
    loop
      exit when bus_i.VMEWrDone = '1';

      wait until rising_edge(clk_i);
    end loop;
  end cernbe_write;

  procedure cernbe_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_cernbe_master_out;
      signal bus_i : in  t_cernbe_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(31 downto 0))
  is
      variable dataTmp : std_logic_vector(31 downto 0);
      variable addrTmp : std_logic_vector(31 downto 0);
   begin
      -- Read request.
      wait until rising_edge(clk_i);
      bus_o <= (VMEAddr => addr,
                VMEWrData  => (others => '0'),
                VMERdMem  => '1',
                VMEWrMem  => '0');

      wait until rising_edge(clk_i);

      bus_o.VMERdMem <= '0';

      -- Wait for a reply
      loop
         exit when bus_i.VMERdDone = '1';

         wait until rising_edge(clk_i);
      end loop;

      data := bus_i.VMERdData;
   end cernbe_read;
end cernbe_tb_pkg;
