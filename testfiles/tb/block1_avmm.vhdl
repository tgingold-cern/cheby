library ieee;
use ieee.std_logic_1164.all;

use work.avalon_tb_pkg.all;

-- A 4KB slave.
entity block1_avmm is
  port (
    clk         : in  std_logic;
    rst_n       : in  std_logic;
    av_in  : in  t_avmm_master_out;
    av_out : out t_avmm_master_in);
end block1_avmm;

architecture behav of block1_avmm is
  signal done : std_logic;
begin
    process(clk)
      --  One line of memory.
      variable mem : std_logic_vector(31 downto 0) := x"0000_4000";

      variable pattern : std_logic_vector(31 downto 0);

      variable addr, datain : std_logic_vector(31 downto 0);

      --  Transactions.
      variable wt : boolean;
      variable rt : boolean;

      --  Wait states
      constant max_ws : natural := 3;
      variable cur_ws : natural := 1;
      variable ws : integer := 0;
    begin
      if rising_edge(clk) then
        if rst_n = '0' then
          av_out.waitrequest <= '0';
          av_out.readdatavalid <= '0';
          wt := false;
          rt := false;
        else
          if not rt and not wt then
            if av_in.read = '1' then
              assert av_in.write = '0' severity failure;
              rt := True;
              av_out.waitrequest <= '1';
              addr := av_in.address;
            elsif av_in.write = '1' then
              wt := True;
              av_out.waitrequest <= '1';
              addr := av_in.address;
              datain := av_in.writedata;
            end if;
          end if;

          if rt then
            if ws < cur_ws then
              ws := ws + 1;
            elsif ws = cur_ws then
              --  It's a read.
              if addr(11 downto 2) = (11 downto 2 => '0') then
                av_out.readdata <= mem;
              else
                pattern( 7 downto  0) := addr(9 downto 2);
                pattern(15 downto  8) := not addr(9 downto 2);
                pattern(23 downto 16) := not addr(9 downto 2);
                pattern(31 downto 24) := addr(9 downto 2);
                av_out.readdata <= pattern;
              end if;

              av_out.readdatavalid <= '1';
              ws := ws + 1;
            else
              av_out.readdatavalid <= '0';
              av_out.waitrequest <= '0';
              ws := 0;
              cur_ws := (cur_ws + 1) mod max_ws;
              rt := False;
            end if;
          end if;

          if wt then
            if ws < cur_ws then
              ws := ws + 1;
            elsif ws = cur_ws then
              --  It's a write.
              if addr(11 downto 2) = (11 downto 2 => '0') then
                mem := datain;
              else
                pattern( 7 downto  0) := not addr(9 downto 2);
                pattern(15 downto  8) := addr(9 downto 2);
                pattern(23 downto 16) := addr(9 downto 2);
                pattern(31 downto 24) := not addr(9 downto 2);
                assert datain = pattern
                  report "block1_avmm: write error" severity error;
              end if;
              ws := ws + 1;
            else
              av_out.waitrequest <= '0';
              ws := 0;
              cur_ws := (cur_ws + 1) mod max_ws;
              wt := False;
            end if;
          end if;
        end if;
      end if;
    end process;
end behav;
