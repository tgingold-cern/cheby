library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MemMap_mainMap.all;
use work.MemMap_ssmap.all;

entity RegCtrl_mainMap is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(9 downto 2);
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    ssmap2_b1_r1         : out   std_logic_vector(31 downto 0)
  );
end RegCtrl_mainMap;

architecture syn of RegCtrl_mainMap is
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
  signal ssmap2_CRegRdData              : std_logic_vector(31 downto 0);
  signal ssmap2_CRegRdOK                : std_logic;
  signal ssmap2_CRegWrOK                : std_logic;
  signal Loc_ssmap2_CRegRdData          : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_CRegRdOK            : std_logic;
  signal Loc_ssmap2_CRegWrOK            : std_logic;
  signal ssmap2_RegRdDone               : std_logic;
  signal ssmap2_RegWrDone               : std_logic;
  signal ssmap2_RegRdData               : std_logic_vector(31 downto 0);
  signal ssmap2_RegRdOK                 : std_logic;
  signal Loc_ssmap2_RegRdData           : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_RegRdOK             : std_logic;
  signal ssmap2_MemRdData               : std_logic_vector(31 downto 0);
  signal ssmap2_MemRdDone               : std_logic;
  signal ssmap2_MemWrDone               : std_logic;
  signal Loc_ssmap2_MemRdData           : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_MemRdDone           : std_logic;
  signal Loc_ssmap2_MemWrDone           : std_logic;
  signal ssmap2_RdData                  : std_logic_vector(31 downto 0);
  signal ssmap2_RdDone                  : std_logic;
  signal ssmap2_WrDone                  : std_logic;
  signal ssmap2_b1_CRegRdData           : std_logic_vector(31 downto 0);
  signal ssmap2_b1_CRegRdOK             : std_logic;
  signal ssmap2_b1_CRegWrOK             : std_logic;
  signal Loc_ssmap2_b1_CRegRdData       : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_b1_CRegRdOK         : std_logic;
  signal Loc_ssmap2_b1_CRegWrOK         : std_logic;
  signal ssmap2_b1_RegRdDone            : std_logic;
  signal ssmap2_b1_RegWrDone            : std_logic;
  signal ssmap2_b1_RegRdData            : std_logic_vector(31 downto 0);
  signal ssmap2_b1_RegRdOK              : std_logic;
  signal Loc_ssmap2_b1_RegRdData        : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_b1_RegRdOK          : std_logic;
  signal ssmap2_b1_MemRdData            : std_logic_vector(31 downto 0);
  signal ssmap2_b1_MemRdDone            : std_logic;
  signal ssmap2_b1_MemWrDone            : std_logic;
  signal Loc_ssmap2_b1_MemRdData        : std_logic_vector(31 downto 0);
  signal Loc_ssmap2_b1_MemRdDone        : std_logic;
  signal Loc_ssmap2_b1_MemWrDone        : std_logic;
  signal ssmap2_b1_RdData               : std_logic_vector(31 downto 0);
  signal ssmap2_b1_RdDone               : std_logic;
  signal ssmap2_b1_WrDone               : std_logic;
  signal Loc_ssmap2_b1_r1               : std_logic_vector(31 downto 0);
  signal CtrlReg_ssmap2_b1_r1           : std_logic_vector(31 downto 0);
  signal WrSel_ssmap2_b1_r1             : std_logic;
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

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, ssmap2_RdData, ssmap2_RdDone) begin
    if VMEAddr(9 downto 2) = C_Submap_mainMap_ssmap2 then
      RdData <= ssmap2_RdData;
      RdDone <= ssmap2_RdDone;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, ssmap2_WrDone) begin
    if VMEAddr(9 downto 2) = C_Submap_mainMap_ssmap2 then
      WrDone <= ssmap2_WrDone;
    else
      WrDone <= MemWrDone;
    end if;
  end process AreaWrMux;

  Loc_ssmap2_CRegRdData <= (others => '0');
  Loc_ssmap2_CRegRdOK <= '0';
  Loc_ssmap2_CRegWrOK <= '0';

  ssmap2_CRegRdData <= Loc_ssmap2_CRegRdData;
  ssmap2_CRegRdOK <= Loc_ssmap2_CRegRdOK;
  ssmap2_CRegWrOK <= Loc_ssmap2_CRegWrOK;

  Loc_ssmap2_RegRdData <= ssmap2_CRegRdData;
  Loc_ssmap2_RegRdOK <= ssmap2_CRegRdOK;

  ssmap2_RegRdData <= Loc_ssmap2_RegRdData;
  ssmap2_RegRdOK <= Loc_ssmap2_RegRdOK;

  ssmap2_RegRdDone <= Loc_VMERdMem(0) and ssmap2_RegRdOK;
  ssmap2_RegWrDone <= Loc_VMEWrMem(0) and ssmap2_CRegWrOK;

  Loc_ssmap2_MemRdData <= ssmap2_RegRdData;
  Loc_ssmap2_MemRdDone <= ssmap2_RegRdDone;

  ssmap2_MemRdData <= Loc_ssmap2_MemRdData;
  ssmap2_MemRdDone <= Loc_ssmap2_MemRdDone;

  Loc_ssmap2_MemWrDone <= ssmap2_RegWrDone;

  ssmap2_MemWrDone <= Loc_ssmap2_MemWrDone;

  ssmap2_AreaRdMux: process (VMEAddr, ssmap2_MemRdData, ssmap2_MemRdDone, ssmap2_b1_RdData, ssmap2_b1_RdDone) begin
    if VMEAddr(1 downto 2) = C_Area_ssmap_b1 then
      ssmap2_RdData <= ssmap2_b1_RdData;
      ssmap2_RdDone <= ssmap2_b1_RdDone;
    else
      ssmap2_RdData <= ssmap2_MemRdData;
      ssmap2_RdDone <= ssmap2_MemRdDone;
    end if;
  end process ssmap2_AreaRdMux;

  ssmap2_AreaWrMux: process (VMEAddr, ssmap2_MemWrDone, ssmap2_b1_WrDone) begin
    if VMEAddr(1 downto 2) = C_Area_ssmap_b1 then
      ssmap2_WrDone <= ssmap2_b1_WrDone;
    else
      ssmap2_WrDone <= ssmap2_MemWrDone;
    end if;
  end process ssmap2_AreaWrMux;

  Reg_ssmap2_b1_r1: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_ssmap2_b1_r1 <= C_PSM_ssmap_b1_r1;
      else
        if WrSel_ssmap2_b1_r1 = '1' and VMEWrMem = '1' then
          CtrlReg_ssmap2_b1_r1 <= VMEWrData(31 downto 0);
        else
          CtrlReg_ssmap2_b1_r1 <= CtrlReg_ssmap2_b1_r1 and not C_ACM_ssmap_b1_r1;
        end if;
      end if;
    end if;
  end process Reg_ssmap2_b1_r1;
  Loc_ssmap2_b1_r1(31 downto 0) <= CtrlReg_ssmap2_b1_r1;

  ssmap2_b1_r1 <= Loc_ssmap2_b1_r1;

  ssmap2_b1_WrSelDec: process (VMEAddr) begin
    WrSel_ssmap2_b1_r1 <= '0';
    if VMEAddr(1 downto 2) = C_Area_ssmap_b1 then
      case VMEAddr(1 downto 2) is
      when C_Reg_ssmap_b1_r1 =>
        WrSel_ssmap2_b1_r1 <= '1';
        Loc_ssmap2_b1_CRegWrOK <= '1';
      when others =>
        Loc_ssmap2_b1_CRegWrOK <= '0';
      end case;
    else
      Loc_ssmap2_b1_CRegWrOK <= '0';
    end if;
  end process ssmap2_b1_WrSelDec;

  ssmap2_b1_CRegRdMux: process (VMEAddr, Loc_ssmap2_b1_r1) begin
    if VMEAddr(1 downto 2) = C_Area_ssmap_b1 then
      case VMEAddr(1 downto 2) is
      when C_Reg_ssmap_b1_r1 =>
        Loc_ssmap2_b1_CRegRdData <= Loc_ssmap2_b1_r1(31 downto 0);
        Loc_ssmap2_b1_CRegRdOK <= '1';
      when others =>
        Loc_ssmap2_b1_CRegRdData <= (others => '0');
        Loc_ssmap2_b1_CRegRdOK <= '0';
      end case;
    else
      Loc_ssmap2_b1_CRegRdData <= (others => '0');
      Loc_ssmap2_b1_CRegRdOK <= '0';
    end if;
  end process ssmap2_b1_CRegRdMux;

  ssmap2_b1_CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      ssmap2_b1_CRegRdData <= Loc_ssmap2_b1_CRegRdData;
      ssmap2_b1_CRegRdOK <= Loc_ssmap2_b1_CRegRdOK;
      ssmap2_b1_CRegWrOK <= Loc_ssmap2_b1_CRegWrOK;
    end if;
  end process ssmap2_b1_CRegRdMux_DFF;

  Loc_ssmap2_b1_RegRdData <= ssmap2_b1_CRegRdData;
  Loc_ssmap2_b1_RegRdOK <= ssmap2_b1_CRegRdOK;

  ssmap2_b1_RegRdData <= Loc_ssmap2_b1_RegRdData;
  ssmap2_b1_RegRdOK <= Loc_ssmap2_b1_RegRdOK;

  ssmap2_b1_RegRdDone <= Loc_VMERdMem(1) and ssmap2_b1_RegRdOK;
  ssmap2_b1_RegWrDone <= Loc_VMEWrMem(1) and ssmap2_b1_CRegWrOK;

  Loc_ssmap2_b1_MemRdData <= ssmap2_b1_RegRdData;
  Loc_ssmap2_b1_MemRdDone <= ssmap2_b1_RegRdDone;

  ssmap2_b1_MemRdData <= Loc_ssmap2_b1_MemRdData;
  ssmap2_b1_MemRdDone <= Loc_ssmap2_b1_MemRdDone;

  Loc_ssmap2_b1_MemWrDone <= ssmap2_b1_RegWrDone;

  ssmap2_b1_MemWrDone <= Loc_ssmap2_b1_MemWrDone;

  ssmap2_b1_RdData <= ssmap2_b1_MemRdData;
  ssmap2_b1_RdDone <= ssmap2_b1_MemRdDone;
  ssmap2_b1_WrDone <= ssmap2_b1_MemWrDone;

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
