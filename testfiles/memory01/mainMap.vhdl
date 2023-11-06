library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.cheby_pkg.all;

entity mainMap is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(19 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- RAM port for acqVP
    acqVP_adr_i          : in    std_logic_vector(8 downto 0);
    acqVP_value_we_i     : in    std_logic;
    acqVP_value_dat_i    : in    std_logic_vector(15 downto 0)
  );
end mainMap;

architecture syn of mainMap is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal acqVP_value_int_dato           : std_logic_vector(15 downto 0);
  signal acqVP_value_ext_dat            : std_logic_vector(15 downto 0);
  signal acqVP_value_rreq               : std_logic;
  signal acqVP_value_rack               : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        VMERdData <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
      end if;
    end if;
  end process;

  -- Memory acqVP
  acqVP_value_raminst: cheby_dpssram
    generic map (
      g_data_width         => 16,
      g_size               => 512,
      g_addr_width         => 9,
      g_dual_clock         => '0',
      g_use_bwsel          => '0'
    )
    port map (
      clk_a_i              => Clk,
      clk_b_i              => Clk,
      addr_a_i             => VMEAddr(10 downto 2),
      bwsel_a_i            => (others => '1'),
      data_a_i             => (others => 'X'),
      data_a_o             => acqVP_value_int_dato,
      rd_a_i               => acqVP_value_rreq,
      wr_a_i               => '0',
      addr_b_i             => acqVP_adr_i,
      bwsel_b_i            => (others => '1'),
      data_b_i             => acqVP_value_dat_i,
      data_b_o             => acqVP_value_ext_dat,
      rd_b_i               => '0',
      wr_b_i               => acqVP_value_we_i
    );
  
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        acqVP_value_rack <= '0';
      else
        acqVP_value_rack <= acqVP_value_rreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0) begin
    -- Memory acqVP
    wr_ack_int <= wr_req_d0;
  end process;

  -- Process for read requests.
  process (acqVP_value_int_dato, VMERdMem, acqVP_value_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    acqVP_value_rreq <= '0';
    -- Memory acqVP
    rd_dat_d0 <= "0000000000000000" & acqVP_value_int_dato;
    acqVP_value_rreq <= VMERdMem;
    rd_ack_d0 <= acqVP_value_rack;
  end process;
end syn;
