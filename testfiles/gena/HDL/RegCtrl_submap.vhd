library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_submap.all;

entity RegCtrl_submap is
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
    submap1_Sel          : out   std_logic;
    submap1_Addr         : out   std_logic_vector(9 downto 1);
    submap1_RdData       : in    std_logic_vector(15 downto 0);
    submap1_WrData       : out   std_logic_vector(15 downto 0);
    submap1_RdMem        : out   std_logic;
    submap1_WrMem        : out   std_logic;
    submap1_RdDone       : in    std_logic;
    submap1_WrDone       : in    std_logic
  );
end RegCtrl_submap;

architecture syn of RegCtrl_submap is
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
  signal Sel_submap1                    : std_logic;
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

  Loc_MemRdData <= RegRdData;
  Loc_MemRdDone <= RegRdDone;

  MemRdData <= Loc_MemRdData;
  MemRdDone <= Loc_MemRdDone;

  Loc_MemWrDone <= RegWrDone;

  MemWrDone <= Loc_MemWrDone;

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, submap1_RdData, submap1_RdDone) begin
    Sel_submap1 <= '0';
    if VMEAddr(19 downto 10) = C_Submap_submap_submap1 then
      RdData <= submap1_RdData;
      RdDone <= submap1_RdDone;
      Sel_submap1 <= '1';
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, submap1_WrDone) begin
    if VMEAddr(19 downto 10) = C_Submap_submap_submap1 then
      WrDone <= submap1_WrDone;
    else
      WrDone <= MemWrDone;
    end if;
  end process AreaWrMux;

  submap1_Addr <= VMEAddr(9 downto 1);
  submap1_Sel <= Sel_submap1;
  submap1_RdMem <= Sel_submap1 and VMERdMem;
  submap1_WrMem <= Sel_submap1 and VMEWrMem;
  submap1_WrData <= VMEWrData;

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
