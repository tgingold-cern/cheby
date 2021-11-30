library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity sramro is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- SRAM bus mymem
    mymem_addr_o         : out   std_logic_vector(7 downto 2);
    mymem_data_i         : in    std_logic_vector(31 downto 0)
  );
end sramro;

architecture syn of sramro is
  signal adr_int                        : std_logic_vector(7 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal mymem_rack                     : std_logic;
  signal mymem_re                       : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
begin

  -- WB decode signals
  adr_int <= wb_i.adr(7 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
      end if;
    end if;
  end process;

  -- Interface mymem
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        mymem_rack <= '0';
      else
        mymem_rack <= mymem_re and not mymem_rack;
      end if;
    end if;
  end process;
  mymem_addr_o <= adr_int(7 downto 2);

  -- Process for write requests.
  process (wr_req_d0) begin
    -- Memory mymem
    wr_ack_int <= wr_req_d0;
  end process;

  -- Process for read requests.
  process (mymem_data_i, mymem_rack, rd_req_int) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    mymem_re <= '0';
    -- Memory mymem
    rd_dat_d0 <= mymem_data_i;
    rd_ack_d0 <= mymem_rack;
    mymem_re <= rd_req_int;
  end process;
end syn;
