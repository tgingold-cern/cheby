library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mapinfo2 is
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
    VMERdError           : out   std_logic;
    VMEWrError           : out   std_logic;

    -- REG test1
    test1_o              : out   std_logic_vector(31 downto 0)
  );
end mapinfo2;

architecture syn of mapinfo2 is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal test1_reg                      : std_logic_vector(31 downto 0);
  signal test1_wreq                     : std_logic;
  signal test1_wack                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(19 downto 2);
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
        VMERdData <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "000000000000000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
        wr_dat_d0 <= VMEWrData;
      end if;
    end if;
  end process;

  -- Register test1
  test1_o <= test1_reg;
  test1_wack <= test1_wreq;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        test1_reg <= "00000000000000000000000000000000";
      else
        if test1_wreq = '1' then
          test1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register mapver

  -- Register icode

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, test1_wack) begin
    test1_wreq <= '0';
    case wr_adr_d0(19 downto 2) is
    when "000000000000000000" =>
      -- Reg test1
      test1_wreq <= wr_req_d0;
      wr_ack_int <= test1_wack;
    when "000000000000000001" =>
      -- Reg mapver
      wr_ack_int <= wr_req_d0;
    when "000000000000000010" =>
      -- Reg icode
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, test1_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case VMEAddr(19 downto 2) is
    when "000000000000000000" =>
      -- Reg test1
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= test1_reg;
    when "000000000000000001" =>
      -- Reg mapver
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= "00000000000000010000001000000011";
    when "000000000000000010" =>
      -- Reg icode
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= "00000000000000000000000000010001";
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
