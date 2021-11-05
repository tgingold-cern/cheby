library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hwInfo is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(4 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- HW serial number
    serialNumber_i       : in    std_logic_vector(63 downto 0);

    -- Firmware Version
    firmwareVersion_major_i : in    std_logic_vector(7 downto 0);
    firmwareVersion_minor_i : in    std_logic_vector(7 downto 0);
    firmwareVersion_patch_i : in    std_logic_vector(7 downto 0);

    -- Memory Map Version
    memMapVersion_major_i : in    std_logic_vector(7 downto 0);
    memMapVersion_minor_i : in    std_logic_vector(7 downto 0);
    memMapVersion_patch_i : in    std_logic_vector(7 downto 0);

    -- Echo register
    -- This version of the standard foresees only 8bits linked to real memory
    echo_echo_o          : out   std_logic_vector(7 downto 0)
  );
end hwInfo;

architecture syn of hwInfo is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal echo_echo_reg                  : std_logic_vector(7 downto 0);
  signal echo_wreq                      : std_logic_vector(1 downto 0);
  signal echo_wack                      : std_logic_vector(1 downto 0);
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(15 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(4 downto 1);
  signal wr_dat_d0                      : std_logic_vector(15 downto 0);
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

  -- Register stdVersion

  -- Register serialNumber

  -- Register firmwareVersion

  -- Register memMapVersion

  -- Register echo
  echo_echo_o <= echo_echo_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        echo_echo_reg <= "00000000";
        echo_wack <= (others => '0');
      else
        if echo_wreq(0) = '1' then
          echo_echo_reg <= wr_dat_d0(7 downto 0);
        end if;
        echo_wack <= echo_wreq;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, echo_wack) begin
    echo_wreq <= (others => '0');
    case wr_adr_d0(4 downto 1) is
    when "0000" =>
      -- Reg stdVersion
      wr_ack_int <= wr_req_d0;
    when "0001" =>
      -- Reg stdVersion
      wr_ack_int <= wr_req_d0;
    when "0010" =>
      -- Reg serialNumber
      wr_ack_int <= wr_req_d0;
    when "0011" =>
      -- Reg serialNumber
      wr_ack_int <= wr_req_d0;
    when "0100" =>
      -- Reg serialNumber
      wr_ack_int <= wr_req_d0;
    when "0101" =>
      -- Reg serialNumber
      wr_ack_int <= wr_req_d0;
    when "0110" =>
      -- Reg firmwareVersion
      wr_ack_int <= wr_req_d0;
    when "0111" =>
      -- Reg firmwareVersion
      wr_ack_int <= wr_req_d0;
    when "1000" =>
      -- Reg memMapVersion
      wr_ack_int <= wr_req_d0;
    when "1001" =>
      -- Reg memMapVersion
      wr_ack_int <= wr_req_d0;
    when "1010" =>
      -- Reg echo
      echo_wreq(1) <= wr_req_d0;
      wr_ack_int <= echo_wack(1);
    when "1011" =>
      -- Reg echo
      echo_wreq(0) <= wr_req_d0;
      wr_ack_int <= echo_wack(0);
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, serialNumber_i, firmwareVersion_major_i, firmwareVersion_patch_i, firmwareVersion_minor_i, memMapVersion_major_i, memMapVersion_patch_i, memMapVersion_minor_i, echo_echo_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case VMEAddr(4 downto 1) is
    when "0000" =>
      -- Reg stdVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= "00000001";
      rd_dat_d0(15 downto 8) <= (others => '0');
    when "0001" =>
      -- Reg stdVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= "00000000";
      rd_dat_d0(15 downto 8) <= "00000000";
    when "0010" =>
      -- Reg serialNumber
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= serialNumber_i(63 downto 48);
    when "0011" =>
      -- Reg serialNumber
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= serialNumber_i(47 downto 32);
    when "0100" =>
      -- Reg serialNumber
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= serialNumber_i(31 downto 16);
    when "0101" =>
      -- Reg serialNumber
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= serialNumber_i(15 downto 0);
    when "0110" =>
      -- Reg firmwareVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= firmwareVersion_major_i;
      rd_dat_d0(15 downto 8) <= (others => '0');
    when "0111" =>
      -- Reg firmwareVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= firmwareVersion_patch_i;
      rd_dat_d0(15 downto 8) <= firmwareVersion_minor_i;
    when "1000" =>
      -- Reg memMapVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= memMapVersion_major_i;
      rd_dat_d0(15 downto 8) <= (others => '0');
    when "1001" =>
      -- Reg memMapVersion
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= memMapVersion_patch_i;
      rd_dat_d0(15 downto 8) <= memMapVersion_minor_i;
    when "1010" =>
      -- Reg echo
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(15 downto 0) <= (others => '0');
    when "1011" =>
      -- Reg echo
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(7 downto 0) <= echo_echo_reg;
      rd_dat_d0(15 downto 8) <= (others => '0');
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
