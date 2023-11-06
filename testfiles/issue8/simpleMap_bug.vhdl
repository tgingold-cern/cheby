library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exemple is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(19 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- REG smallReg
    smallReg_i           : in    std_logic_vector(15 downto 0);

    -- REG largeReg
    largeReg_i           : in    std_logic_vector(63 downto 0)
  );
end exemple;

architecture syn of exemple is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(15 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(19 downto 1);
begin
  rst_n <= not Rst;
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        rd_ack_int <= '0';
        VMERdData <= "0000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        VMERdData <= rd_dat_d0;
        wr_req_d0 <= VMEWrMem;
        wr_adr_d0 <= VMEAddr;
      end if;
    end if;
  end process;

  -- Register smallReg

  -- Register largeReg

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0) begin
    case wr_adr_d0(19 downto 1) is
    when "0000000000000000000" =>
      -- Reg smallReg
      wr_ack_int <= wr_req_d0;
    when "0000000000000000001" =>
      -- Reg largeReg
      wr_ack_int <= wr_req_d0;
    when "0000000000000000010" =>
      -- Reg largeReg
      wr_ack_int <= wr_req_d0;
    when "0000000000000000011" =>
      -- Reg largeReg
      wr_ack_int <= wr_req_d0;
    when "0000000000000000100" =>
      -- Reg largeReg
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, smallReg_i, largeReg_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case VMEAddr(19 downto 1) is
    when "0000000000000000000" =>
      -- Reg smallReg
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= smallReg_i;
    when "0000000000000000001" =>
      -- Reg largeReg
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= largeReg_i(63 downto 48);
    when "0000000000000000010" =>
      -- Reg largeReg
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= largeReg_i(47 downto 32);
    when "0000000000000000011" =>
      -- Reg largeReg
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= largeReg_i(31 downto 16);
    when "0000000000000000100" =>
      -- Reg largeReg
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= largeReg_i(15 downto 0);
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
