library ieee;
use ieee.std_logic_1164.all;

package avalon_tb_pkg is
  type t_avmm_master_out is record
    address : std_logic_vector(31 downto 0);
    byteenable : std_logic_vector(3 downto 0);
    write : std_logic;
    writedata : std_logic_vector(31 downto 0);
    read : std_logic;
  end record;

  type t_avmm_master_in is record
    readdata : std_logic_vector(31 downto 0);
    readdatavalid : std_logic;
    waitrequest : std_logic;
  end record;

  procedure avmm_init(signal clk     : std_logic;
                      signal avmm_in  : t_avmm_master_in;
                      signal avmm_out   : inout t_avmm_master_out);

  procedure avmm_writel (signal clk     : std_logic;
                         signal avmm_in  : t_avmm_master_in;
                         signal avmm_out   : inout t_avmm_master_out;
                         addr : std_logic_vector (31 downto 0);
                         data : std_logic_vector (31 downto 0));

  procedure avmm_readl (signal clk     : std_logic;
                        signal avmm_in  : t_avmm_master_in;
                        signal avmm_out   : inout t_avmm_master_out;
                        addr : std_logic_vector (31 downto 0);
                        data : out std_logic_vector (31 downto 0));
end avalon_tb_pkg;

package body avalon_tb_pkg is
  procedure avmm_init(signal clk     : std_logic;
                      signal avmm_in  : t_avmm_master_in;
                      signal avmm_out   : inout t_avmm_master_out) is
  begin
    avmm_out.read <= '0';
    avmm_out.write <= '0';
  end avmm_init;

  procedure avmm_writel (signal clk     : std_logic;
                         signal avmm_in  : t_avmm_master_in;
                         signal avmm_out   : inout t_avmm_master_out;
                         addr : std_logic_vector (31 downto 0);
                         data : std_logic_vector (31 downto 0))
    is
      variable rdata : std_logic_vector (31 downto 0);
    begin
      --  W transfer
      avmm_out.write <= '1';
      avmm_out.writedata <= data;
      avmm_out.address <= addr;
      avmm_out.byteenable <= "1111";

      loop
        wait until rising_edge(clk);
        exit when avmm_in.waitrequest = '0';
      end loop;

      avmm_out.write <= '0';
      avmm_out.writedata <= (others => 'X');
      avmm_out.address <= (others => 'X');
    end avmm_writel;

    procedure avmm_readl (signal clk     : std_logic;
                        signal avmm_in  : t_avmm_master_in;
                        signal avmm_out   : inout t_avmm_master_out;
                        addr : std_logic_vector (31 downto 0);
                        data : out std_logic_vector (31 downto 0)) is
    begin
      --  R transfer
      avmm_out.read <= '1';
      avmm_out.address <= addr;
      avmm_out.byteenable <= "1111";

      loop
        wait until rising_edge(clk);
        exit when avmm_in.readdatavalid = '1';
      end loop;

      data := avmm_in.readdata;
      avmm_out.read <= '0';
      avmm_out.address <= (others => 'X');
    end avmm_readl;
end avalon_tb_pkg;
