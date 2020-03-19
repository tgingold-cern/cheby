library ieee;
use ieee.std_logic_1164.all;

package axi4_tb_pkg is
  constant datalen : natural := 32;

  type t_axi4lite_read_master_out is record
    -- Read Address channel
    araddr  : std_logic_vector(31 downto 0);
    arprot  : std_logic_vector(2 downto 0);
    arvalid : std_logic;
    -- Read data channel
    rready  : std_logic;
  end record;

  subtype t_axi4lite_read_slave_in is t_axi4lite_read_master_out;

  type t_axi4lite_read_master_in is record
      -- Read Address channel
      arready : std_logic;
      -- Read data channel
      rdata   : std_logic_vector(datalen - 1 downto 0);
      rresp   : std_logic_vector(1 downto 0);
      rvalid  : std_logic;
   end record;

  subtype t_axi4lite_read_slave_out is t_axi4lite_read_master_in;

  type t_axi4lite_write_master_out is record
      -- Write address channel
      awaddr  : std_logic_vector(31 downto 0);
      awprot  : std_logic_vector(2 downto 0);
      awvalid : std_logic;
      -- Write data channel
      wdata   : std_logic_vector(datalen - 1 downto 0);
      wstrb   : std_logic_vector((datalen / 8) - 1 downto 0);
      wvalid  : std_logic;
      -- Write ack channel
      bready  : std_logic;
   end record;

  subtype t_axi4lite_write_slave_in is t_axi4lite_write_master_out;

  type t_axi4lite_write_master_in is record
      -- Write address channel
      awready : std_logic;
      -- Write data channel
      wready  : std_logic;
      -- Write ack channel
      bresp   : std_logic_vector(1 downto 0);
      bvalid  : std_logic;
   end record;

  subtype t_axi4lite_write_slave_out is t_axi4lite_write_master_in;

  --  Resp values
  constant C_AXI4_RESP_OK     : std_logic_vector(1 downto 0) := "00";
  constant C_AXI4_RESP_EXOKAY : std_logic_vector(1 downto 0) := "01";
  constant C_AXI4_RESP_SLVERR : std_logic_vector(1 downto 0) := "10";
  constant C_AXI4_RESP_DECERR : std_logic_vector(1 downto 0) := "11";

  procedure axi4lite_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_axi4lite_write_master_out;
      signal bus_i : in  t_axi4lite_write_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(datalen - 1 downto 0));

  procedure axi4lite_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_axi4lite_read_master_out;
      signal bus_i : in  t_axi4lite_read_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(datalen - 1 downto 0));

  --  Simultaneous read and write (for testing purposes).
  procedure axi4lite_rw (
      signal clk_i : in  std_logic;
      signal rbus_o : out t_axi4lite_read_master_out;
      signal rbus_i : in  t_axi4lite_read_master_in;
      signal wbus_o : out t_axi4lite_write_master_out;
      signal wbus_i : in  t_axi4lite_write_master_in;
      raddr         : in  std_logic_vector(31 downto 0);
      rdata         : out std_logic_vector(datalen - 1 downto 0);
      waddr         : in  std_logic_vector(31 downto 0);
      wdata         : in  std_logic_vector(datalen - 1 downto 0));

  procedure axi4lite_wr_init (signal bus_o : out t_axi4lite_write_master_out);
  procedure axi4lite_rd_init (signal bus_o : out t_axi4lite_read_master_out);
end axi4_tb_pkg;

package body axi4_tb_pkg is
  procedure axi4lite_wr_init (signal bus_o : out t_axi4lite_write_master_out) is
  begin
    bus_o <= (awaddr  => (others => '0'),
              wdata   => (others => '0'),
              awprot  => (others => '0'),
              wstrb   => (others => '1'),
              awvalid => '0',
              wvalid  => '0',
              bready  => '0');
  end axi4lite_wr_init;

  procedure axi4lite_write (
      signal clk_i : in  std_logic;
      signal bus_o : out t_axi4lite_write_master_out;
      signal bus_i : in  t_axi4lite_write_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : in  std_logic_vector(datalen - 1 downto 0)) is
  begin
    --  Write request
    wait until rising_edge(clk_i);
    bus_o <= (awaddr  => addr,
              wdata   => data,
              awprot  => (others => '0'),
              wstrb   => (others => '1'),
              awvalid => '1',
              wvalid  => '1',
              bready  => '1');

    wait until rising_edge(clk_i);

    -- Wait for reply.
    loop
      -- Clear valid signals when acked.
      if bus_i.awready = '1' then
        bus_o.awvalid <= '0';
      end if;
      if bus_i.wready = '1' then
        bus_o.wvalid <= '0';
      end if;

      exit when bus_i.bvalid = '1';

      wait until rising_edge(clk_i);
    end loop;

    bus_o.bready <= '0';

    --  Check response.
    if bus_i.bresp /= C_AXI4_RESP_OK then
      report "got error reply" severity warning;
    end if;
  end axi4lite_write;

  procedure axi4lite_rd_init (signal bus_o : out t_axi4lite_read_master_out) is
  begin
    bus_o <= (araddr  => (others => '0'),
              arprot  => (others => '0'),
              arvalid => '0',
              rready  => '0');
  end axi4lite_rd_init;

  procedure axi4lite_read (
      signal clk_i : in  std_logic;
      signal bus_o : out t_axi4lite_read_master_out;
      signal bus_i : in  t_axi4lite_read_master_in;
      addr         : in  std_logic_vector(31 downto 0);
      data         : out std_logic_vector(datalen - 1 downto 0))
  is
    variable ardone : boolean := False;
  begin
    -- Read request.
    wait until rising_edge(clk_i);
    bus_o <= (araddr  => addr,
              arprot  => (others => '0'),
              arvalid => '1',
              rready  => '1');

    wait until rising_edge(clk_i);

    -- Wait for a reply
    loop
      -- Clear valid signal when acked
      if bus_i.arready = '1' then
        bus_o.arvalid <= '0';
        ardone := True;
      end if;

      exit when bus_i.rvalid = '1';

      wait until rising_edge(clk_i);
    end loop;
    assert ardone report "missing arready" severity error;
    
    bus_o.rready <= '0';

    -- Done. Check for errors
    if bus_i.rresp /= C_AXI4_RESP_OK then
      report "got error reply" severity warning;
    else
      data := bus_i.rdata;
    end if;
  end axi4lite_read;

  procedure axi4lite_rw (
    signal clk_i : in  std_logic;
    signal rbus_o : out t_axi4lite_read_master_out;
    signal rbus_i : in  t_axi4lite_read_master_in;
    signal wbus_o : out t_axi4lite_write_master_out;
    signal wbus_i : in  t_axi4lite_write_master_in;
    raddr         : in  std_logic_vector(31 downto 0);
    rdata         : out std_logic_vector(datalen - 1 downto 0);
    waddr         : in  std_logic_vector(31 downto 0);
    wdata         : in  std_logic_vector(datalen - 1 downto 0))
  is
    variable rdone : boolean;
    variable wdone : boolean;
  begin
    wait until rising_edge(clk_i);

    -- Read request.
    rbus_o <= (araddr  => raddr,
               arprot  => (others => '0'),
               arvalid => '1',
               rready  => '1');

    --  Write request
    wbus_o <= (awaddr  => waddr,
               wdata   => wdata,
               awprot  => (others => '0'),
               wstrb   => (others => '1'),
               awvalid => '1',
               wvalid  => '1',
               bready  => '1');

    rdone := False;
    wdone := False;

    --  Wait for replies.
    while rdone nand wdone loop
      wait until rising_edge(clk_i);

      -- Clear valid signals when acked.
      if wbus_i.awready = '1' then
        wbus_o.awvalid <= '0';
      end if;
      if wbus_i.wready = '1' then
        wbus_o.wvalid <= '0';
      end if;
      if rbus_i.arready = '1' then
        rbus_o.arvalid <= '0';
      end if;

      if not wdone and wbus_i.bvalid = '1' then
        wdone := True;
        wbus_o.bready <= '0';

        --  Check response.
        assert wbus_i.bresp = C_AXI4_RESP_OK
          report "got error reply" severity warning;
      end if;

      if not rdone and rbus_i.rvalid = '1' then
        rdone := True;
        rbus_o.rready <= '0';

        -- Done. Check for errors
        if rbus_i.rresp /= C_AXI4_RESP_OK then
          report "got error reply" severity warning;
        else
          rdata := rbus_i.rdata;
        end if;
      end if;
    end loop;
  end axi4lite_rw;
end axi4_tb_pkg;
