library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_mems_splitaddr.all;

entity RegCtrl_mems_splitaddr is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMERdAddr            : in    std_logic_vector(19 downto 1);
    VMEWrAddr            : in    std_logic_vector(19 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    mem1_RdSel           : out   std_logic;
    mem1_RdAddr          : out   std_logic_vector(9 downto 1);
    mem1_RdData          : in    std_logic_vector(15 downto 0);
    mem1_WrSel           : out   std_logic;
    mem1_WrAddr          : out   std_logic_vector(9 downto 1);
    mem1_WrData          : out   std_logic_vector(15 downto 0);
    mem1_RdMem           : out   std_logic;
    mem1_WrMem           : out   std_logic;
    mem1_RdDone          : in    std_logic;
    mem1_WrDone          : in    std_logic;
    mem2_RdSel           : out   std_logic;
    mem2_RdAddr          : out   std_logic_vector(9 downto 1);
    mem2_RdData          : in    std_logic_vector(15 downto 0);
    mem2_RdMem           : out   std_logic;
    mem2_RdDone          : in    std_logic;
    mem3_WrSel           : out   std_logic;
    mem3_WrAddr          : out   std_logic_vector(9 downto 1);
    mem3_WrData          : out   std_logic_vector(15 downto 0);
    mem3_WrMem           : out   std_logic;
    mem3_WrDone          : in    std_logic
  );
end RegCtrl_mems_splitaddr;

architecture syn of RegCtrl_mems_splitaddr is
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
  signal RdSel_mem1                     : std_logic;
  signal WrSel_mem1                     : std_logic;
  signal RdSel_mem2                     : std_logic;
  signal WrSel_mem3                     : std_logic;

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

  MemRdMux: process (VMERdAddr, RegRdData, RegRdDone, mem1_RdData, mem1_RdDone, mem2_RdData, mem2_RdDone) begin
    RdSel_mem1 <= '0';
    RdSel_mem2 <= '0';
    if VMERdAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem1_Sta and VMERdAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem1_End then
      RdSel_mem1 <= '1';
      Loc_MemRdData <= mem1_RdData;
      Loc_MemRdDone <= mem1_RdDone;
    elsif VMERdAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem2_Sta and VMERdAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem2_End then
      RdSel_mem2 <= '1';
      Loc_MemRdData <= mem2_RdData;
      Loc_MemRdDone <= mem2_RdDone;
    elsif VMERdAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem3_Sta and VMERdAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem3_End then
      Loc_MemRdData <= (others => '0');
      Loc_MemRdDone <= '0';
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

  MemWrMux: process (VMEWrAddr, RegWrDone, mem1_WrDone, mem3_WrDone) begin
    WrSel_mem1 <= '0';
    WrSel_mem3 <= '0';
    if VMEWrAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem1_Sta and VMEWrAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem1_End then
      WrSel_mem1 <= '1';
      Loc_MemWrDone <= mem1_WrDone;
    elsif VMEWrAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem2_Sta and VMEWrAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem2_End then
      Loc_MemWrDone <= '0';
    elsif VMEWrAddr(19 downto 1) >= C_Mem_mems_splitaddr_mem3_Sta and VMEWrAddr(19 downto 1) <= C_Mem_mems_splitaddr_mem3_End then
      WrSel_mem3 <= '1';
      Loc_MemWrDone <= mem3_WrDone;
    else
      Loc_MemWrDone <= RegWrDone;
    end if;
  end process MemWrMux;

  MemWrMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      MemWrDone <= Loc_MemWrDone;
    end if;
  end process MemWrMux_DFF;
  mem1_RdAddr <= VMERdAddr(9 downto 1);
  mem1_RdSel <= RdSel_mem1;
  mem1_RdMem <= RdSel_mem1 and VMERdMem;
  mem1_WrAddr <= VMEWrAddr(9 downto 1);
  mem1_WrSel <= WrSel_mem1;
  mem1_WrMem <= WrSel_mem1 and VMEWrMem;
  mem1_WrData <= VMEWrData;
  mem2_RdAddr <= VMERdAddr(9 downto 1);
  mem2_RdSel <= RdSel_mem2;
  mem2_RdMem <= RdSel_mem2 and VMERdMem;
  mem3_WrAddr <= VMEWrAddr(9 downto 1);
  mem3_WrSel <= WrSel_mem3;
  mem3_WrMem <= WrSel_mem3 and VMEWrMem;
  mem3_WrData <= VMEWrData;
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
