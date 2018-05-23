library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_mems_ro.all;

entity RegCtrl_mems_ro is
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
    mem1_Sel             : out   std_logic;
    mem1_Addr            : out   std_logic_vector(9 downto 1);
    mem1_RdData          : in    std_logic_vector(15 downto 0);
    mem1_RdMem           : out   std_logic;
    mem1_RdDone          : in    std_logic
  );
end RegCtrl_mems_ro;

architecture syn of RegCtrl_mems_ro is
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
  signal Sel_mem1                       : std_logic;
begin
  Loc_CRegRdData <= (others => '0');
  Loc_CRegRdOK <= '0';
  Loc_CRegWrOK <= '0';

  CRegRdData <= Loc_CRegRdData;
  CRegRdOK <= Loc_CRegRdOK;
  CRegWrOK <= Loc_CRegWrOK;

  Loc_RegRdData <= CRegRdData;
  Loc_RegRdOK <= CRegRdOK;

  RegRdData <= Loc_RegRdData;
  RegRdOK <= Loc_RegRdOK;

  RegRdDone <= Loc_VMERdMem(0) and RegRdOK;
  RegWrDone <= Loc_VMEWrMem(0) and CRegWrOK;

  MemRdMux: process (VMEAddr, RegRdData, RegRdDone, mem1_RdData, mem1_RdDone) begin
    Sel_mem1 <= '0';
    if VMEAddr(19 downto 1) >= C_Mem_mems_ro_mem1_Sta and VMEAddr(19 downto 1) <= C_Mem_mems_ro_mem1_End then
      Sel_mem1 <= '1';
      Loc_MemRdData <= mem1_RdData;
      Loc_MemRdDone <= mem1_RdDone;
    else
      Loc_MemRdData <= RegRdData;
      Loc_MemRdDone <= RegRdDone;
    end if;
  end process MemRdMux;

  MemRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      MemRdData <= Loc_MemRdData;
      MemRdDone <= Loc_MemRdDone;
    end if;
  end process MemRdMux_DFF;

  Loc_MemWrDone <= RegWrDone;

  MemWrDone <= Loc_MemWrDone;

  mem1_Addr <= VMEAddr(9 downto 1);
  mem1_Sel <= Sel_mem1;
  mem1_RdMem <= Sel_mem1 and VMERdMem;

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
