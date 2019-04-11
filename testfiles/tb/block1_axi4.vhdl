library ieee;
use ieee.std_logic_1164.all;

use work.axi4_tb_pkg.all;

entity block1_axi4 is
  port (
    clk : in std_logic;
    rst_n : in std_logic;
    sub2_wr_in   : in     t_axi4lite_write_slave_in;
    sub2_wr_out  : buffer t_axi4lite_write_slave_out;
    sub2_rd_in   : in     t_axi4lite_read_slave_in;
    sub2_rd_out  : buffer t_axi4lite_read_slave_out);
end block1_axi4;

architecture arch of block1_axi4 is
begin
    process (clk, rst_n)
      variable awaddr : std_logic_vector(11 downto 2);
      variable wdata : std_logic_vector(31 downto 0);
      variable rdata : std_logic_vector(31 downto 0);
      variable awaddr_set : boolean;
      variable wdata_set : boolean;
      variable rdata_set : boolean;

      --  One line of memory.
      variable mem : std_logic_vector(31 downto 0) := x"0000_2000";

      variable pattern : std_logic_vector(31 downto 0);

      --  Wait states
      constant max_ws : natural := 3;
      variable cur_rws : natural := 1;
      variable rws : integer := 0;
      variable cur_wws : natural := 1;
      variable wws : integer := 0;
    begin
      if rising_edge(clk) then
        if rst_n = '0' then
          sub2_wr_out <= (awready => '1',
                          wready => '1',
                          bvalid => '0',
                          bresp => "00");
          sub2_rd_out <= (arready => '1',
                          rvalid => '0',
                          rdata => (others => 'X'),
                          rresp => "00");
          awaddr_set := false;
          wdata_set := false;
          rdata_set := false;
        else
          --  Read part
          if sub2_rd_in.arvalid = '1' then
            --  Start a new TFR
            if sub2_rd_in.araddr(11 downto 2) = "0000000000" then
              rdata := mem;
            else
              pattern( 7 downto  0) := sub2_rd_in.araddr(9 downto 2);
              pattern(15 downto  8) := not sub2_rd_in.araddr(9 downto 2);
              pattern(23 downto 16) := not sub2_rd_in.araddr(9 downto 2);
              pattern(31 downto 24) := sub2_rd_in.araddr(9 downto 2);

              rdata := pattern;
            end if;
            rdata_set := True;
            rws := 0;
            sub2_rd_out.arready <= '0';
          end if;

          if rdata_set then
            if rws < cur_rws then
              rws := rws + 1;
            elsif rws = cur_rws then
              --  Reply
              sub2_rd_out.rvalid <= '1';
              sub2_rd_out.rresp <= C_AXI4_RESP_OK;
              sub2_rd_out.rdata <= rdata;
              rws := rws + 1;
            elsif sub2_rd_in.rready = '1' then
              sub2_rd_out.arready <= '1';
              sub2_rd_out.rvalid <= '0';
              rdata_set := False;
              cur_rws := (cur_rws + 1) mod max_ws;
            end if;
          end if;

          --  Write part
          if sub2_wr_in.awvalid = '1' then
            awaddr := sub2_wr_in.awaddr(11 downto 2);
            awaddr_set := True;
            sub2_wr_out.awready <= '0';
          end if;

          if sub2_wr_in.wvalid = '1' then
            wdata := sub2_wr_in.wdata;
            wdata_set := true;
            sub2_wr_out.wready <= '0';
          end if;

          if wdata_set and awaddr_set then
            if wws < cur_wws then
              wws := wws + 1;
            elsif wws = cur_wws then
              if awaddr = "0000000000" then
                mem := wdata;
              else
                pattern( 7 downto  0) := not awaddr(9 downto 2);
                pattern(15 downto  8) := awaddr(9 downto 2);
                pattern(23 downto 16) := awaddr(9 downto 2);
                pattern(31 downto 24) := not awaddr(9 downto 2);

                assert wdata = pattern
                  report "sub2: write error" severity error;
              end if;

              sub2_wr_out.bvalid <= '1';
              sub2_wr_out.bresp <= C_AXI4_RESP_OK;
              wws := wws + 1;
            elsif sub2_wr_in.bready = '1' then
              wdata_set := False;
              awaddr_set := False;
              sub2_wr_out.bvalid <= '0';
              sub2_wr_out.awready <= '1';
              sub2_wr_out.wready <= '1';
              wws := 0;
              cur_wws := (cur_wws + 1) mod max_ws;
            end if;
          end if;
        end if;
      end if;
    end process;
end arch;
