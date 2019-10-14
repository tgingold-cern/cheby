library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mainMap2 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(14 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    VMERdError           : out   std_logic;
    VMEWrError           : out   std_logic;

    -- CERN-BE bus subMap1
    subMap1_VMEAddr_o    : out   std_logic_vector(12 downto 2);
    subMap1_VMERdData_i  : in    std_logic_vector(31 downto 0);
    subMap1_VMEWrData_o  : out   std_logic_vector(31 downto 0);
    subMap1_VMERdMem_o   : out   std_logic;
    subMap1_VMEWrMem_o   : out   std_logic;
    subMap1_VMERdDone_i  : in    std_logic;
    subMap1_VMEWrDone_i  : in    std_logic;
    subMap1_VMERdError_i : in    std_logic;
    subMap1_VMEWrError_i : in    std_logic;

    -- CERN-BE bus subMap2
    subMap2_VMEAddr_o    : out   std_logic_vector(12 downto 2);
    subMap2_VMERdData_i  : in    std_logic_vector(31 downto 0);
    subMap2_VMEWrData_o  : out   std_logic_vector(31 downto 0);
    subMap2_VMERdMem_o   : out   std_logic;
    subMap2_VMEWrMem_o   : out   std_logic;
    subMap2_VMERdDone_i  : in    std_logic;
    subMap2_VMEWrDone_i  : in    std_logic;
    subMap2_VMERdError_i : in    std_logic;
    subMap2_VMEWrError_i : in    std_logic
  );
end mainMap2;

architecture syn of mainMap2 is
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(14 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
  signal subMap1_ws                     : std_logic;
  signal subMap1_wt                     : std_logic;
  signal subMap2_ws                     : std_logic;
  signal subMap2_wt                     : std_logic;
begin
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- pipelining for wr-in+rd-out
  process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '0' then
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

  -- Assignments for interface subMap1
  subMap1_VMEWrData_o <= wr_dat_d0;
  subMap1_ws <= wr_req_d0 or (subMap1_wt and not VMERdMem);
  process (VMEAddr, wr_adr_d0, subMap1_wt, subMap1_ws) begin
    if (subMap1_ws or subMap1_wt) = '1' then
      subMap1_VMEAddr_o <= wr_adr_d0(12 downto 2);
    else
      subMap1_VMEAddr_o <= VMEAddr(12 downto 2);
    end if;
  end process;

  -- Assignments for interface subMap2
  subMap2_VMEWrData_o <= wr_dat_d0;
  subMap2_ws <= wr_req_d0 or (subMap2_wt and not VMERdMem);
  process (VMEAddr, wr_adr_d0, subMap2_wt, subMap2_ws) begin
    if (subMap2_ws or subMap2_wt) = '1' then
      subMap2_VMEAddr_o <= wr_adr_d0(12 downto 2);
    else
      subMap2_VMEAddr_o <= VMEAddr(12 downto 2);
    end if;
  end process;

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, subMap1_VMEWrDone_i, subMap2_VMEWrDone_i) begin
    subMap1_VMEWrMem_o <= '0';
    subMap2_VMEWrMem_o <= '0';
    case wr_adr_d0(14 downto 13) is
    when "00" => 
      -- Submap subMap1
      subMap1_VMEWrMem_o <= wr_req_d0;
      wr_ack_int <= subMap1_VMEWrDone_i;
    when "01" => 
      -- Submap subMap2
      subMap2_VMEWrMem_o <= wr_req_d0;
      wr_ack_int <= subMap2_VMEWrDone_i;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, subMap1_VMERdData_i, subMap1_VMERdDone_i, subMap2_VMERdData_i, subMap2_VMERdDone_i) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    subMap1_VMERdMem_o <= '0';
    subMap2_VMERdMem_o <= '0';
    case VMEAddr(14 downto 13) is
    when "00" => 
      -- Submap subMap1
      subMap1_VMERdMem_o <= VMERdMem;
      rd_dat_d0 <= subMap1_VMERdData_i;
      rd_ack_d0 <= subMap1_VMERdDone_i;
    when "01" => 
      -- Submap subMap2
      subMap2_VMERdMem_o <= VMERdMem;
      rd_dat_d0 <= subMap2_VMERdData_i;
      rd_ack_d0 <= subMap2_VMERdDone_i;
    when others =>
      rd_ack_d0 <= VMERdMem;
    end case;
  end process;
end syn;
