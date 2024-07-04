library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bugConstraintFields is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(2 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;

    -- REG r1
    r1_o                 : out   std_logic_vector(31 downto 0);

    -- REG r2
    r2_r2_o              : out   std_logic_vector(10 downto 0)
  );
end bugConstraintFields;

architecture syn of bugConstraintFields is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal r1_reg                         : std_logic_vector(31 downto 0);
  signal r1_wreq                        : std_logic;
  signal r1_wack                        : std_logic;
  signal r2_r2_reg                      : std_logic_vector(10 downto 0);
  signal r2_wreq                        : std_logic;
  signal r2_wack                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
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
        wr_adr_d0 <= "0";
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

  -- Register r1
  r1_o <= r1_reg;
  r1_wack <= r1_wreq;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        r1_reg <= "00000000000000000000000000000000";
      else
        if r1_wreq = '1' then
          r1_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register r2
  r2_r2_o <= r2_r2_reg;
  r2_wack <= r2_wreq;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        r2_r2_reg <= "00000000000";
      else
        if r2_wreq = '1' then
          r2_r2_reg <= wr_dat_d0(10 downto 0);
        end if;
      end if;
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, r1_wack, r2_wack) begin
    r1_wreq <= '0';
    r2_wreq <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg r1
      r1_wreq <= wr_req_d0;
      wr_ack_int <= r1_wack;
    when "1" =>
      -- Reg r2
      r2_wreq <= wr_req_d0;
      wr_ack_int <= r2_wack;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, r1_reg, r2_r2_reg) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    case VMEAddr(2 downto 2) is
    when "0" =>
      -- Reg r1
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= r1_reg;
    when "1" =>
      -- Reg r2
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0(10 downto 0) <= r2_r2_reg;
      rd_dat_d0(31 downto 11) <= (others => '0');
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
