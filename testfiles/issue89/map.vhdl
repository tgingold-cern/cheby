library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity map1 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(7 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- RAM port for m1
    m1_adr_i             : in    std_logic_vector(5 downto 0);
    m1_r1_rd_i           : in    std_logic;
    m1_r1_dat_o          : out   std_logic_vector(15 downto 0)
  );
end map1;

architecture syn of map1 is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal m1_r1_int_dato                 : std_logic_vector(15 downto 0);
  signal m1_r1_ext_dat                  : std_logic_vector(15 downto 0);
  signal m1_r1_rreq                     : std_logic;
  signal m1_r1_rack                     : std_logic;
  signal m1_r1_int_wr                   : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(7 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal m1_wr                          : std_logic;
  signal m1_wreq                        : std_logic;
  signal m1_adr_int                     : std_logic_vector(5 downto 0);
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Memory m1
  process (VMEAddr, wr_adr_d0, m1_wr) begin
    if m1_wr = '1' then
      m1_adr_int <= wr_adr_d0(7 downto 2);
    else
      m1_adr_int <= VMEAddr(7 downto 2);
    end if;
  end process;
  m1_wreq <= m1_r1_int_wr;
  m1_wr <= m1_wreq;
  m1_r1_raminst: cheby_dpssram
    generic map (
      g_data_width         => 16,
      g_size               => 64,
      g_addr_width         => 6,
      g_dual_clock         => '0',
      g_use_bwsel          => '0'
    )
    port map (
      clk_a_i              => Clk,
      clk_b_i              => Clk,
      addr_a_i             => m1_adr_int,
      bwsel_a_i            => (others => '1'),
      data_a_i             => wr_dat_d0(15 downto 0),
      data_a_o             => m1_r1_int_dato,
      rd_a_i               => m1_r1_rreq,
      wr_a_i               => m1_r1_int_wr,
      addr_b_i             => m1_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => m1_r1_ext_dat,
      data_b_o             => m1_r1_dat_o,
      rd_b_i               => m1_r1_rd_i,
      wr_b_i               => '0'
    );
  
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        m1_r1_rack <= '0';
      else
        m1_r1_rack <= m1_r1_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0) begin
    m1_r1_int_wr <= '0';
    -- Memory m1
    m1_r1_int_wr <= wr_req_d0;
    wr_ack_int <= wr_req_d0;
  end process;

  -- Process for read requests.
  process (m1_r1_int_dato, VMERdMem, m1_r1_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    m1_r1_rreq <= '0';
    -- Memory m1
    rd_dat_d0 <= "0000000000000000" & m1_r1_int_dato;
    m1_r1_rreq <= VMERdMem;
    rd_ack_d0 <= m1_r1_rack;
  end process;
end syn;
