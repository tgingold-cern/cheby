library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_areaMems.all;

entity RegCtrl_areaMems is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(19 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    VMERdError           : out   std_logic;
    VMEWrError           : out   std_logic;
    area_mem1_Sel        : out   std_logic;
    area_mem1_Addr       : out   std_logic_vector(9 downto 2);
    area_mem1_RdData     : in    std_logic_vector(31 downto 0);
    area_mem1_WrData     : out   std_logic_vector(31 downto 0);
    area_mem1_RdMem      : out   std_logic;
    area_mem1_WrMem      : out   std_logic;
    area_mem1_RdDone     : in    std_logic;
    area_mem1_WrDone     : in    std_logic;
    area_mem1_RdError    : in    std_logic := '0';
    area_mem1_WrError    : in    std_logic := '0';
    area_mem2_Sel        : out   std_logic;
    area_mem2_Addr       : out   std_logic_vector(9 downto 2);
    area_mem2_WrData     : out   std_logic_vector(31 downto 0);
    area_mem2_WrMem      : out   std_logic;
    area_mem2_WrDone     : in    std_logic;
    area_mem2_WrError    : in    std_logic := '0';
    area_mem3_Sel        : out   std_logic;
    area_mem3_Addr       : out   std_logic_vector(9 downto 2);
    area_mem3_RdData     : in    std_logic_vector(31 downto 0);
    area_mem3_RdMem      : out   std_logic;
    area_mem3_RdDone     : in    std_logic;
    area_mem3_RdError    : in    std_logic := '0'
  );
end RegCtrl_areaMems;

architecture syn of RegCtrl_areaMems is
  signal Loc_VMERdMem                   : std_logic_vector(2 downto 0);
  signal Loc_VMEWrMem                   : std_logic_vector(1 downto 0);
  signal CRegRdData                     : std_logic_vector(31 downto 0);
  signal CRegRdOK                       : std_logic;
  signal CRegWrOK                       : std_logic;
  signal Loc_CRegRdData                 : std_logic_vector(31 downto 0);
  signal Loc_CRegRdOK                   : std_logic;
  signal Loc_CRegWrOK                   : std_logic;
  signal RegRdDone                      : std_logic;
  signal RegWrDone                      : std_logic;
  signal RegRdData                      : std_logic_vector(31 downto 0);
  signal RegRdOK                        : std_logic;
  signal Loc_RegRdData                  : std_logic_vector(31 downto 0);
  signal Loc_RegRdOK                    : std_logic;
  signal MemRdData                      : std_logic_vector(31 downto 0);
  signal MemRdDone                      : std_logic;
  signal MemWrDone                      : std_logic;
  signal Loc_MemRdData                  : std_logic_vector(31 downto 0);
  signal Loc_MemRdDone                  : std_logic;
  signal Loc_MemWrDone                  : std_logic;
  signal RdData                         : std_logic_vector(31 downto 0);
  signal RdDone                         : std_logic;
  signal WrDone                         : std_logic;
  signal RegRdError                     : std_logic;
  signal RegWrError                     : std_logic;
  signal MemRdError                     : std_logic;
  signal MemWrError                     : std_logic;
  signal Loc_MemRdError                 : std_logic;
  signal Loc_MemWrError                 : std_logic;
  signal RdError                        : std_logic;
  signal WrError                        : std_logic;
  signal area_CRegRdData                : std_logic_vector(31 downto 0);
  signal area_CRegRdOK                  : std_logic;
  signal area_CRegWrOK                  : std_logic;
  signal Loc_area_CRegRdData            : std_logic_vector(31 downto 0);
  signal Loc_area_CRegRdOK              : std_logic;
  signal Loc_area_CRegWrOK              : std_logic;
  signal area_RegRdDone                 : std_logic;
  signal area_RegWrDone                 : std_logic;
  signal area_RegRdData                 : std_logic_vector(31 downto 0);
  signal area_RegRdOK                   : std_logic;
  signal Loc_area_RegRdData             : std_logic_vector(31 downto 0);
  signal Loc_area_RegRdOK               : std_logic;
  signal area_MemRdData                 : std_logic_vector(31 downto 0);
  signal area_MemRdDone                 : std_logic;
  signal area_MemWrDone                 : std_logic;
  signal Loc_area_MemRdData             : std_logic_vector(31 downto 0);
  signal Loc_area_MemRdDone             : std_logic;
  signal Loc_area_MemWrDone             : std_logic;
  signal area_RdData                    : std_logic_vector(31 downto 0);
  signal area_RdDone                    : std_logic;
  signal area_WrDone                    : std_logic;
  signal area_RegRdError                : std_logic;
  signal area_RegWrError                : std_logic;
  signal area_MemRdError                : std_logic;
  signal area_MemWrError                : std_logic;
  signal Loc_area_MemRdError            : std_logic;
  signal Loc_area_MemWrError            : std_logic;
  signal area_RdError                   : std_logic;
  signal area_WrError                   : std_logic;
  signal Sel_area_mem1                  : std_logic;
  signal Sel_area_mem2                  : std_logic;
  signal Sel_area_mem3                  : std_logic;
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

  RegRdError <= Loc_VMERdMem(0) and not RegRdOK;
  RegWrError <= Loc_VMEWrMem(0) and not CRegWrOK;

  Loc_MemRdData <= RegRdData;
  Loc_MemRdDone <= RegRdDone;
  Loc_MemRdError <= RegRdError;

  MemRdData <= Loc_MemRdData;
  MemRdDone <= Loc_MemRdDone;
  MemRdError <= Loc_MemRdError;

  Loc_MemWrDone <= RegWrDone;
  Loc_MemWrError <= RegWrError;

  MemWrDone <= Loc_MemWrDone;
  MemWrError <= Loc_MemWrError;

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, area_RdData, area_RdDone, area_RdError) begin
    if VMEAddr(19 downto 19) = C_Area_areaMems_area then
      RdData <= area_RdData;
      RdDone <= area_RdDone;
      RdError <= area_RdError;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
      RdError <= MemRdError;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, area_WrDone, area_WrError) begin
    if VMEAddr(19 downto 19) = C_Area_areaMems_area then
      WrDone <= area_WrDone;
      WrError <= area_WrError;
    else
      WrDone <= MemWrDone;
      WrError <= MemWrError;
    end if;
  end process AreaWrMux;

  Loc_area_CRegRdData <= (others => '0');
  Loc_area_CRegRdOK <= '0';
  Loc_area_CRegWrOK <= '0';

  area_CRegRdData <= Loc_area_CRegRdData;
  area_CRegRdOK <= Loc_area_CRegRdOK;
  area_CRegWrOK <= Loc_area_CRegWrOK;

  Loc_area_RegRdData <= area_CRegRdData;
  Loc_area_RegRdOK <= area_CRegRdOK;

  area_RegRdData <= Loc_area_RegRdData;
  area_RegRdOK <= Loc_area_RegRdOK;

  area_RegRdDone <= Loc_VMERdMem(0) and area_RegRdOK;
  area_RegWrDone <= Loc_VMEWrMem(0) and area_CRegWrOK;

  area_RegRdError <= Loc_VMERdMem(0) and not area_RegRdOK;
  area_RegWrError <= Loc_VMEWrMem(0) and not area_CRegWrOK;

  area_MemRdMux: process (VMEAddr, area_RegRdData, area_RegRdDone, area_RegRdError, area_mem1_RdData, area_mem1_RdDone, area_mem1_RdError, area_mem3_RdData, area_mem3_RdDone, area_mem3_RdError) begin
    Sel_area_mem1 <= '0';
    Sel_area_mem3 <= '0';
    if VMEAddr(19 downto 19) = C_Area_areaMems_area then
      if VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem1_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem1_End then
        Sel_area_mem1 <= '1';
        Loc_area_MemRdData <= area_mem1_RdData;
        Loc_area_MemRdDone <= area_mem1_RdDone;
        Loc_area_MemRdError <= area_mem1_RdError;
      elsif VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem2_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem2_End then
        Loc_area_MemRdData <= (others => '0');
        Loc_area_MemRdDone <= '0';
        Loc_area_MemRdError <= VMERdMem;
      elsif VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem3_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem3_End then
        Sel_area_mem3 <= '1';
        Loc_area_MemRdData <= area_mem3_RdData;
        Loc_area_MemRdDone <= area_mem3_RdDone;
        Loc_area_MemRdError <= area_mem3_RdError;
      else
        Loc_area_MemRdData <= area_RegRdData;
        Loc_area_MemRdDone <= area_RegRdDone;
        Loc_area_MemRdError <= area_RegRdError;
      end if;
    else
      Loc_area_MemRdData <= area_RegRdData;
      Loc_area_MemRdDone <= area_RegRdDone;
      Loc_area_MemRdError <= area_RegRdError;
    end if;
  end process area_MemRdMux;

  area_MemRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_MemRdData <= Loc_area_MemRdData;
      area_MemRdDone <= Loc_area_MemRdDone;
      area_MemRdError <= Loc_area_MemRdError;
    end if;
  end process area_MemRdMux_DFF;

  area_MemWrMux: process (VMEAddr, area_RegWrDone, area_RegWrError, area_mem1_WrDone, area_mem1_WrError, area_mem2_WrDone, area_mem2_WrError) begin
    Sel_area_mem2 <= '0';
    if VMEAddr(19 downto 19) = C_Area_areaMems_area then
      if VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem1_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem1_End then
        Loc_area_MemWrDone <= area_mem1_WrDone;
        Loc_area_MemWrError <= area_mem1_WrError;
      elsif VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem2_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem2_End then
        Sel_area_mem2 <= '1';
        Loc_area_MemWrDone <= area_mem2_WrDone;
        Loc_area_MemWrError <= area_mem2_WrError;
      elsif VMEAddr(18 downto 2) >= C_Mem_areaMems_area_mem3_Sta and VMEAddr(18 downto 2) <= C_Mem_areaMems_area_mem3_End then
        Loc_area_MemWrDone <= '0';
        Loc_area_MemWrError <= VMEWrMem;
      else
        Loc_area_MemWrDone <= area_RegWrDone;
        Loc_area_MemWrError <= area_RegWrError;
      end if;
    else
      Loc_area_MemWrDone <= area_RegWrDone;
      Loc_area_MemWrError <= area_RegWrError;
    end if;
  end process area_MemWrMux;

  area_MemWrMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_MemWrDone <= Loc_area_MemWrDone;
      area_MemWrError <= Loc_area_MemWrError;
    end if;
  end process area_MemWrMux_DFF;

  area_mem1_Addr <= VMEAddr(9 downto 2);
  area_mem1_Sel <= Sel_area_mem1;
  area_mem1_RdMem <= Sel_area_mem1 and VMERdMem;
  area_mem1_WrMem <= Sel_area_mem1 and VMEWrMem;
  area_mem1_WrData <= VMEWrData;

  area_mem2_Addr <= VMEAddr(9 downto 2);
  area_mem2_Sel <= Sel_area_mem2;
  area_mem2_WrMem <= Sel_area_mem2 and VMEWrMem;
  area_mem2_WrData <= VMEWrData;

  area_mem3_Addr <= VMEAddr(9 downto 2);
  area_mem3_Sel <= Sel_area_mem3;
  area_mem3_RdMem <= Sel_area_mem3 and VMERdMem;

  area_RdData <= area_MemRdData;
  area_RdDone <= area_MemRdDone;
  area_WrDone <= area_MemWrDone;
  area_RdError <= area_MemRdError;
  area_WrError <= area_MemWrError;

  StrobeSeq: process (Clk) begin
    if rising_edge(Clk) then
      Loc_VMERdMem <= Loc_VMERdMem(1 downto 0) & VMERdMem;
      Loc_VMEWrMem <= Loc_VMEWrMem(0) & VMEWrMem;
    end if;
  end process StrobeSeq;

  VMERdData <= RdData;
  VMERdDone <= RdDone;
  VMEWrDone <= WrDone;
  VMERdError <= RdError;
  VMEWrError <= WrError;

end syn;
