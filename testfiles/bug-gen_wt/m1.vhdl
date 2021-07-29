library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity m1 is
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

    -- CERN-BE bus sm2
    sm2_VMERdData_i      : in    std_logic_vector(31 downto 0);
    sm2_VMEWrData_o      : out   std_logic_vector(31 downto 0);
    sm2_VMERdMem_o       : out   std_logic;
    sm2_VMEWrMem_o       : out   std_logic;
    sm2_VMERdDone_i      : in    std_logic;
    sm2_VMEWrDone_i      : in    std_logic
  );
end m1;

architecture syn of m1 is
  signal rst_n                          : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal r1_reg                         : std_logic_vector(31 downto 0);
  signal r1_wreq                        : std_logic;
  signal r1_wack                        : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(2 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal sm2_ws                         : std_logic;
  signal sm2_wt                         : std_logic;
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

  -- Register r1
  r1_o <= r1_reg;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        r1_reg <= "00000000000000000000000000000000";
        r1_wack <= '0';
      else
        if r1_wreq = '1' then
          r1_reg <= wr_dat_d0;
        end if;
        r1_wack <= r1_wreq;
      end if;
    end if;
  end process;

  -- Interface sm2
  sm2_VMEWrData_o <= wr_dat_d0;
  process (Clk) begin
    if rising_edge(Clk) then
      if rst_n = '0' then
        sm2_wt <= '0';
      else
        sm2_wt <= (sm2_wt or sm2_ws) and not sm2_VMEWrDone_i;
      end if;
    end if;
  end process;
  sm2_ws <= wr_req_d0 or (sm2_wt and not VMERdMem);

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, r1_wack, sm2_VMEWrDone_i) begin
    r1_wreq <= '0';
    sm2_VMEWrMem_o <= '0';
    case wr_adr_d0(2 downto 2) is
    when "0" =>
      -- Reg r1
      r1_wreq <= wr_req_d0;
      wr_ack_int <= r1_wack;
    when "1" =>
      -- Submap sm2
      sm2_VMEWrMem_o <= wr_req_d0;
      wr_ack_int <= sm2_VMEWrDone_i;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, r1_reg, sm2_VMERdData_i, sm2_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    sm2_VMERdMem_o <= '0';
    case VMEAddr(2 downto 2) is
    when "0" =>
      -- Reg r1
      rd_ack_d0 <= VMERdMem;
      rd_dat_d0 <= r1_reg;
    when "1" =>
      -- Submap sm2
      sm2_VMERdMem_o <= VMERdMem;
      rd_dat_d0 <= sm2_VMERdData_i;
      rd_ack_d0 <= sm2_VMERdDone_i;
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
