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
  signal reg_rdat_int                   : std_logic_vector(31 downto 0);
  signal rd_ack1_int                    : std_logic;
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
      subMap1_VMEWrMem_o <= '0';
      subMap2_VMEWrMem_o <= '0';
    elsif rising_edge(Clk) then
      wr_ack_int <= '0';
      subMap1_VMEWrMem_o <= '0';
      subMap2_VMEWrMem_o <= '0';
      case VMEAddr(14 downto 13) is
      when "00" => 
        -- Submap subMap1
        subMap1_VMEWrMem_o <= '1';
        wr_ack_int <= subMap1_VMEWrDone_i;
      when "01" => 
        -- Submap subMap2
        subMap2_VMEWrMem_o <= '1';
        wr_ack_int <= subMap2_VMEWrDone_i;
      when others =>
        wr_ack_int <= VMEWrMem;
      end case;
    end if;
  end process;

  -- Process for registers read.
  process (Clk, Rst) begin
    if Rst = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
    elsif rising_edge(Clk) then
      reg_rdat_int <= (others => '0');
      case VMEAddr(14 downto 13) is
      when "00" => 
      when "01" => 
      when others =>
        rd_ack1_int <= VMERdMem;
      end case;
    end if;
  end process;

  -- Process for read requests.
  process (VMEAddr, reg_rdat_int, rd_ack1_int, VMERdMem, VMERdMem, subMap1_VMERdData_i, subMap1_VMERdDone_i, VMERdMem, subMap2_VMERdData_i, subMap2_VMERdDone_i) begin
    -- By default ack read requests
    VMERdData <= (others => '0');
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
      rd_ack_int <= VMERdMem;
    end case;
  end process;
end syn;
