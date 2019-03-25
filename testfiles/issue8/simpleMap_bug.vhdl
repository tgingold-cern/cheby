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
    smallReg_i           : in    std_logic_vector(15 downto 0);
    largeReg_i           : in    std_logic_vector(63 downto 0)
  );
end exemple;

architecture syn of exemple is
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wr_ack_done_int                : std_logic;
  signal reg_rdat_int                   : std_logic_vector(15 downto 0);
  signal rd_ack1_int                    : std_logic;
begin
  VMERdDone <= rd_ack_int;
  VMEWrDone <= wr_ack_int;

  -- Assign outputs

  -- Process for write requests.
  process (Clk, Rst) begin
    if Rst = '0' then 
      wr_ack_int <= '0';
      wr_ack_done_int <= '0';
    elsif rising_edge(Clk) then
      if VMEWrMem = '1' then
        -- Write in progress
        wr_ack_done_int <= wr_ack_int or wr_ack_done_int;
        case VMEAddr(19 downto 1) is
        when "0000000000000000000" => 
          -- Register smallReg
          wr_ack_int <= not wr_ack_done_int;
        when "0000000000000000001" => 
          -- Register largeReg
          wr_ack_int <= not wr_ack_done_int;
        when "0000000000000000010" => 
          -- Register largeReg
          wr_ack_int <= not wr_ack_done_int;
        when "0000000000000000011" => 
          -- Register largeReg
          wr_ack_int <= not wr_ack_done_int;
        when "0000000000000000100" => 
          -- Register largeReg
          wr_ack_int <= not wr_ack_done_int;
        when others =>
          wr_ack_int <= not wr_ack_done_int;
        end case;
      else
        wr_ack_int <= '0';
        wr_ack_done_int <= '0';
      end if;
    end if;
  end process;

  -- Process for registers read.
  process (Clk, Rst) begin
    if Rst = '0' then 
      rd_ack1_int <= '0';
      reg_rdat_int <= (others => 'X');
    elsif rising_edge(Clk) then
      if VMERdMem = '1' and rd_ack1_int = '0' then
        rd_ack1_int <= '1';
        reg_rdat_int <= (others => '0');
        case VMEAddr(19 downto 1) is
        when "0000000000000000000" => 
          -- smallReg
          reg_rdat_int <= smallReg_i;
        when "0000000000000000001" => 
          -- largeReg
          reg_rdat_int <= largeReg_i(47 downto 32);
        when "0000000000000000010" => 
          -- largeReg
          reg_rdat_int <= largeReg_i(31 downto 16);
        when "0000000000000000011" => 
          -- largeReg
          reg_rdat_int <= largeReg_i(15 downto 0);
        when "0000000000000000100" => 
          -- largeReg
          reg_rdat_int <= largeReg_i(63 downto 48);
        when others =>
        end case;
      else
        rd_ack1_int <= '0';
      end if;
    end if;
  end process;

  -- Process for read requests.
  process (VMEAddr, reg_rdat_int, rd_ack1_int, VMERdMem) begin
    -- By default ack read requests
    VMERdData <= (others => '0');
    rd_ack_int <= '1';
    case VMEAddr(19 downto 1) is
    when "0000000000000000000" => 
      -- smallReg
      VMERdData <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "0000000000000000001" => 
      -- largeReg
      VMERdData <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "0000000000000000010" => 
      -- largeReg
      VMERdData <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "0000000000000000011" => 
      -- largeReg
      VMERdData <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when "0000000000000000100" => 
      -- largeReg
      VMERdData <= reg_rdat_int;
      rd_ack_int <= rd_ack1_int;
    when others =>
    end case;
  end process;
end syn;
