library ieee;
use ieee.std_logic_1164.all;

use work.apb_tb_pkg.all;

entity block1_apb is
  port (
    clk     : in     std_logic;
    rst_n   : in     std_logic;
    bus_in  : in     t_apb_slave_in;
    bus_out : buffer t_apb_slave_out
  );
end block1_apb;

architecture behavioral of block1_apb is
begin

  process(bus_in)
    -- Preload single memory row with modules address
    variable mem     : std_logic_vector(31 downto 0) := x"0000_5000";
    variable pattern : std_logic_vector(31 downto 0);
  begin
    bus_out.pready  <= '0';
    bus_out.prdata  <= (others => '0');
    bus_out.pslverr <= '1';

    -- Only act combinatorically on access phase
    if bus_in.psel = '1' and bus_in.penable = '1' then
      bus_out.pready  <= '1';
      bus_out.pslverr <= '0';

      -- Write transaction
      if bus_in.pwrite = '1' then
        if bus_in.paddr(11 downto 2) = (11 downto 2 => '0') then
          -- Write to memory
          mem := bus_in.pwdata;
        else
          -- Check pattern
          pattern( 7 downto  0) := not bus_in.paddr(9 downto 2);
          pattern(15 downto  8) := bus_in.paddr(9 downto 2);
          pattern(23 downto 16) := bus_in.paddr(9 downto 2);
          pattern(31 downto 24) := not bus_in.paddr(9 downto 2);

          assert bus_in.pwdata = pattern
            report "block1_apb: write error" severity error;
        end if;

      -- Read transaction
      else
        if bus_in.paddr(11 downto 2) = (11 downto 2 => '0') then
          -- Read from memory
          bus_out.prdata <= mem;
        else
          -- Return pattern
          pattern( 7 downto  0) := bus_in.paddr(9 downto 2);
          pattern(15 downto  8) := not bus_in.paddr(9 downto 2);
          pattern(23 downto 16) := not bus_in.paddr(9 downto 2);
          pattern(31 downto 24) := bus_in.paddr(9 downto 2);

          bus_out.prdata <= pattern;
        end if;
      end if;
    end if;
  end process;

end behavioral;
