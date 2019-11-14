library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bugBlockRegField is
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
    b1_r1_f1_o           : out   std_logic;
    b1_r1_f2_o           : out   std_logic_vector(9 downto 0);
    b1_r1_f3_o           : out   std_logic;
    b1_r1_f4_o           : out   std_logic;
    b1_r1_f5_o           : out   std_logic
  );
end bugBlockRegField;

architecture syn of bugBlockRegField is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal b1_r1_f1_reg                   : std_logic;
  signal b1_r1_f2_reg                   : std_logic_vector(9 downto 0);
  signal b1_r1_f3_reg                   : std_logic;
  signal b1_r1_f4_reg                   : std_logic;
  signal b1_r1_f5_reg                   : std_logic;
  signal b1_r1_wreq                     : std_logic;
  signal b1_r1_wack                     : std_logic;
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

  -- Register b1_r1
  b1_r1_f1_o <= b1_r1_f1_reg;
  b1_r1_f2_o <= b1_r1_f2_reg;
  b1_r1_f3_o <= b1_r1_f3_reg;
  b1_r1_f4_o <= b1_r1_f4_reg;
  b1_r1_f5_o <= b1_r1_f5_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        b1_r1_f1_reg <= '0';
        b1_r1_f2_reg <= "0000000000";
        b1_r1_f3_reg <= '0';
        b1_r1_f4_reg <= '0';
        b1_r1_f5_reg <= '0';
        b1_r1_wack <= '0';
      else
        if b1_r1_wreq = '1' then
          b1_r1_f1_reg <= wr_dat_d0(0);
          b1_r1_f2_reg <= wr_dat_d0(12 downto 3);
          b1_r1_f3_reg <= wr_dat_d0(2);
          b1_r1_f4_reg <= wr_dat_d0(1);
          b1_r1_f5_reg <= wr_dat_d0(13);
        end if;
        b1_r1_wack <= b1_r1_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_req_d0, b1_r1_wack) begin
    b1_r1_wreq <= '0';
    -- Reg b1_r1
    b1_r1_wreq <= wr_req_d0;
    wr_ack_int <= b1_r1_wack;
  end process;

  -- Process for read requests.
  process (VMERdMem, b1_r1_f1_reg, b1_r1_f4_reg, b1_r1_f3_reg, b1_r1_f2_reg, b1_r1_f5_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    -- Reg b1_r1
    rd_ack_d0 <= VMERdMem;
    rd_dat_d0(0) <= b1_r1_f1_reg;
    rd_dat_d0(1) <= b1_r1_f4_reg;
    rd_dat_d0(2) <= b1_r1_f3_reg;
    rd_dat_d0(12 downto 3) <= b1_r1_f2_reg;
    rd_dat_d0(13) <= b1_r1_f5_reg;
    rd_dat_d0(31 downto 14) <= (others => '0');
  end process;
end syn;
