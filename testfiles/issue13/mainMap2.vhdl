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
    subMap1_VMEAddr_o    : out   std_logic_vector(12 downto 2);
    subMap1_VMERdData_i  : in    std_logic_vector(31 downto 0);
    subMap1_VMEWrData_o  : out   std_logic_vector(31 downto 0);
    subMap1_VMERdMem_o   : out   std_logic;
    subMap1_VMEWrMem_o   : out   std_logic;
    subMap1_VMERdDone_i  : in    std_logic;
    subMap1_VMEWrDone_i  : in    std_logic;
    subMap1_VMERdError_i : in    std_logic;
    subMap1_VMEWrError_i : in    std_logic;
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
  signal wr_ack_done_int                : std_logic;
begin
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- Assign outputs

  -- Assignments for submap subMap1
  subMap1_VMEAddr_o <= VMEAddr(12 downto 2);
  subMap1_VMEWrData_o <= VMEWrData;

  -- Assignments for submap subMap2
  subMap2_VMEAddr_o <= VMEAddr(12 downto 2);
  subMap2_VMEWrData_o <= VMEWrData;

  -- Process for write requests.
  process (Clk, Rst) begin
    if Rst = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
      subMap1_VMEWrMem_o <= '0';
      subMap2_VMEWrMem_o <= '0';
    elsif rising_edge(Clk) then
      subMap1_VMEWrMem_o <= '0';
      subMap2_VMEWrMem_o <= '0';
      if VMEWrMem = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case VMEAddr(14 downto 13) is
        when "00" => 
          -- Submap subMap1
          subMap1_VMEWrMem_o <= '1';
          wr_ack_int <= subMap1_VMEWrDone_i and not wr_ack_done_int;
        when "01" => 
          -- Submap subMap2
          subMap2_VMEWrMem_o <= '1';
          wr_ack_int <= subMap2_VMEWrDone_i and not wr_ack_done_int;
        when others =>
          wr_ack_int <= not wr_ack_done_int;
        end case;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (VMEAddr, VMERdMem, subMap1_VMERdData_i, subMap1_VMERdDone_i, VMERdMem, subMap2_VMERdData_i, subMap2_VMERdDone_i) begin
    -- By default ack read requests
    VMERdData <= (others => '0');
    rd_ack_int <= '1';
    subMap1_VMERdMem_o <= '0';
    subMap2_VMERdMem_o <= '0';
    case VMEAddr(14 downto 13) is
    when "00" => 
      -- Submap subMap1
      subMap1_VMERdMem_o <= VMERdMem;
      VMERdData <= subMap1_VMERdData_i;
      rd_ack_int <= subMap1_VMERdDone_i;
    when "01" => 
      -- Submap subMap2
      subMap2_VMERdMem_o <= VMERdMem;
      VMERdData <= subMap2_VMERdData_i;
      rd_ack_int <= subMap2_VMERdDone_i;
    when others =>
    end case;
  end process;
end syn;
