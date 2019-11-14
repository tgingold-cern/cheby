library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test8 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- REG r1
    r1_o                 : out   std_logic_vector(7 downto 0)
  );
end test8;

architecture syn of test8 is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal r1_reg                         : std_logic_vector(7 downto 0);
  signal r1_wreq                        : std_logic;
  signal r1_wack                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
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
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Register r1
  r1_o <= r1_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        r1_reg <= "00000000";
        r1_wack <= '0';
      else
        if r1_wreq = '1' then
          r1_reg <= wr_dat_d0(7 downto 0);
        end if;
        r1_wack <= r1_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, r1_wack) begin
    -- Reg r1
    r1_wreq <= wr_req_d0;
    wr_ack_int <= r1_wack;
  end process;

  -- Process for read requests.
  process (VMERdMem, r1_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg r1
    rd_ack_d0 <= VMERdMem;
    rd_dat_d0(23 downto 0) <= (others => '0');
    rd_dat_d0(31 downto 24) <= r1_reg;
  end process;
end syn;
