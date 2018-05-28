library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_regs_cross_words.all;

entity RegCtrl_regs_cross_words is
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
    test2_hi             : in    std_logic;
    test2_lo             : in    std_logic;
    test3_hi             : in    std_logic;
    test3_lo             : in    std_logic
  );
end RegCtrl_regs_cross_words;

architecture syn of RegCtrl_regs_cross_words is
  signal Loc_VMERdMem                   : std_logic_vector(2 downto 0);
  signal Loc_VMEWrMem                   : std_logic_vector(1 downto 0);
  signal CRegRdData                     : std_logic_vector(15 downto 0);
  signal CRegRdOK                       : std_logic;
  signal CRegWrOK                       : std_logic;
  signal Loc_CRegRdData                 : std_logic_vector(15 downto 0);
  signal Loc_CRegRdOK                   : std_logic;
  signal Loc_CRegWrOK                   : std_logic;
  signal RegRdDone                      : std_logic;
  signal RegWrDone                      : std_logic;
  signal RegRdData                      : std_logic_vector(15 downto 0);
  signal RegRdOK                        : std_logic;
  signal Loc_RegRdData                  : std_logic_vector(15 downto 0);
  signal Loc_RegRdOK                    : std_logic;
  signal MemRdData                      : std_logic_vector(15 downto 0);
  signal MemRdDone                      : std_logic;
  signal MemWrDone                      : std_logic;
  signal Loc_MemRdData                  : std_logic_vector(15 downto 0);
  signal Loc_MemRdDone                  : std_logic;
  signal Loc_MemWrDone                  : std_logic;
  signal RdData                         : std_logic_vector(15 downto 0);
  signal RdDone                         : std_logic;
  signal WrDone                         : std_logic;
  signal Loc_test2                      : std_logic_vector(31 downto 0);
  signal Loc_test3                      : std_logic_vector(31 downto 0);
begin
  Loc_test2(31) <= test2_hi;
  Loc_test2(30 downto 16) <= C_PSM_regs_cross_words_test2_1(30 downto 16);
  Loc_test2(15 downto 1) <= C_PSM_regs_cross_words_test2_0(15 downto 1);
  Loc_test2(0) <= test2_lo;

  Loc_test3(31) <= test3_hi;
  Loc_test3(30 downto 16) <= C_PSM_regs_cross_words_test3_1(30 downto 16);
  Loc_test3(15) <= C_PSM_regs_cross_words_test3_0(15);
  Loc_test3(14) <= test3_lo;
  Loc_test3(13 downto 0) <= C_PSM_regs_cross_words_test3_0(13 downto 0);

  Loc_CRegRdData <= (others => '0');
  Loc_CRegRdOK <= '0';
  Loc_CRegWrOK <= '0';

  CRegRdData <= Loc_CRegRdData;
  CRegRdOK <= Loc_CRegRdOK;
  CRegWrOK <= Loc_CRegWrOK;

  RegRdMux: process (VMEAddr, CRegRdData, CRegRdOK, Loc_test2, Loc_test3) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_regs_cross_words_test2_1 => 
      Loc_RegRdData <= Loc_test2(31 downto 16);
      Loc_RegRdOK <= '1';
    when C_Reg_regs_cross_words_test2_0 => 
      Loc_RegRdData <= Loc_test2(15 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_regs_cross_words_test3_1 => 
      Loc_RegRdData <= Loc_test3(31 downto 16);
      Loc_RegRdOK <= '1';
    when C_Reg_regs_cross_words_test3_0 => 
      Loc_RegRdData <= Loc_test3(15 downto 0);
      Loc_RegRdOK <= '1';
    when others =>
      Loc_RegRdData <= CRegRdData;
      Loc_RegRdOK <= CRegRdOK;
    end case;
  end process RegRdMux;

  RegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      RegRdData <= Loc_RegRdData;
      RegRdOK <= Loc_RegRdOK;
    end if;
  end process RegRdMux_DFF;

  RegRdDone <= Loc_VMERdMem(1) and RegRdOK;
  RegWrDone <= Loc_VMEWrMem(0) and CRegWrOK;

  Loc_MemRdData <= RegRdData;
  Loc_MemRdDone <= RegRdDone;

  MemRdData <= Loc_MemRdData;
  MemRdDone <= Loc_MemRdDone;

  Loc_MemWrDone <= RegWrDone;

  MemWrDone <= Loc_MemWrDone;

  RdData <= MemRdData;
  RdDone <= MemRdDone;
  WrDone <= MemWrDone;

  StrobeSeq: process (Clk) begin
    if rising_edge(Clk) then
      Loc_VMERdMem <= Loc_VMERdMem(1 downto 0) & VMERdMem;
      Loc_VMEWrMem <= Loc_VMEWrMem(0) & VMEWrMem;
    end if;
  end process StrobeSeq;

  VMERdData <= RdData;
  VMERdDone <= RdDone;
  VMEWrDone <= WrDone;

end syn;
