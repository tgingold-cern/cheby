library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_area_extarea.all;

entity RegCtrl_area_extarea is
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
    test1                : out   std_logic_vector(15 downto 0);
    area_Sel             : out   std_logic;
    area_Addr            : out   std_logic_vector(18 downto 1);
    area_RdData          : in    std_logic_vector(15 downto 0);
    area_WrData          : out   std_logic_vector(15 downto 0);
    area_RdMem           : out   std_logic;
    area_WrMem           : out   std_logic;
    area_RdDone          : in    std_logic;
    area_WrDone          : in    std_logic
  );
end RegCtrl_area_extarea;

architecture syn of RegCtrl_area_extarea is
  component RMWReg
    generic (
      N : natural := 8
    );
    port (
      VMEWrData            : in    std_logic_vector(2*N-1 downto 0);
      Clk                  : in    std_logic;
      AutoClrMsk           : in    std_logic_vector(N-1 downto 0);
      Rst                  : in    std_logic;
      CRegSel              : in    std_logic;
      CReg                 : out   std_logic_vector(N-1 downto 0);
      WriteMem             : in    std_logic;
      Preset               : in    std_logic_vector(N-1 downto 0)
    );
  end component;

  for all : RMWReg use entity CommonVisual.RMWReg(RMWReg);

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
  signal Loc_test1                      : std_logic_vector(15 downto 0);
  signal WrSel_test1_1                  : std_logic;
  signal WrSel_test1_0                  : std_logic;
  signal Sel_area                       : std_logic;
begin
  Reg_test1_1: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_1,
      AutoClrMsk           => C_ACM_area_extarea_test1_1,
      Preset               => C_PSM_area_extarea_test1_1,
      CReg                 => Loc_test1(15 downto 8)
    );
  
  Reg_test1_0: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_0,
      AutoClrMsk           => C_ACM_area_extarea_test1_0,
      Preset               => C_PSM_area_extarea_test1_0,
      CReg                 => Loc_test1(7 downto 0)
    );
  
  test1 <= Loc_test1;

  WrSelDec: process (VMEAddr) begin
    WrSel_test1_1 <= '0';
    WrSel_test1_0 <= '0';
    case VMEAddr(19 downto 1) is
    when C_Reg_area_extarea_test1_1 => 
      WrSel_test1_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_area_extarea_test1_0 => 
      WrSel_test1_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test1) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_area_extarea_test1_1 => 
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(15 downto 8)), 16));
      Loc_CRegRdOK <= '1';
    when C_Reg_area_extarea_test1_0 => 
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(7 downto 0)), 16));
      Loc_CRegRdOK <= '1';
    when others =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    end case;
  end process CRegRdMux;

  CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      CRegRdData <= Loc_CRegRdData;
      CRegRdOK <= Loc_CRegRdOK;
      CRegWrOK <= Loc_CRegWrOK;
    end if;
  end process CRegRdMux_DFF;

  Loc_RegRdData <= CRegRdData;
  Loc_RegRdOK <= CRegRdOK;

  RegRdData <= Loc_RegRdData;
  RegRdOK <= Loc_RegRdOK;

  RegRdDone <= Loc_VMERdMem(1) and RegRdOK;
  RegWrDone <= Loc_VMEWrMem(1) and CRegWrOK;

  Loc_MemRdData <= RegRdData;
  Loc_MemRdDone <= RegRdDone;

  MemRdData <= Loc_MemRdData;
  MemRdDone <= Loc_MemRdDone;

  Loc_MemWrDone <= RegWrDone;

  MemWrDone <= Loc_MemWrDone;

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, area_RdData, area_RdDone) begin
    Sel_area <= '0';
    if VMEAddr(19 downto 19) = C_Area_area_extarea_area then
      RdData <= area_RdData;
      RdDone <= area_RdDone;
      Sel_area <= '1';
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, area_WrDone) begin
    if VMEAddr(19 downto 19) = C_Area_area_extarea_area then
      WrDone <= area_WrDone;
    else
      WrDone <= MemWrDone;
    end if;
  end process AreaWrMux;

  area_Addr <= VMEAddr(18 downto 1);
  area_Sel <= Sel_area;
  area_RdMem <= Sel_area and VMERdMem;
  area_WrMem <= Sel_area and VMEWrMem;
  area_WrData <= VMEWrData;

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
