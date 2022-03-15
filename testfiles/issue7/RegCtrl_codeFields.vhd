library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MemMap_codeFields.all;

entity RegCtrl_codeFields is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(13 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    area1_myRegister     : out   std_logic_vector(15 downto 0);
    area2_myRegister     : out   std_logic_vector(15 downto 0)
  );
end RegCtrl_codeFields;

architecture syn of RegCtrl_codeFields is
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
  signal area1_CRegRdData               : std_logic_vector(15 downto 0);
  signal area1_CRegRdOK                 : std_logic;
  signal area1_CRegWrOK                 : std_logic;
  signal Loc_area1_CRegRdData           : std_logic_vector(15 downto 0);
  signal Loc_area1_CRegRdOK             : std_logic;
  signal Loc_area1_CRegWrOK             : std_logic;
  signal area1_RegRdDone                : std_logic;
  signal area1_RegWrDone                : std_logic;
  signal area1_RegRdData                : std_logic_vector(15 downto 0);
  signal area1_RegRdOK                  : std_logic;
  signal Loc_area1_RegRdData            : std_logic_vector(15 downto 0);
  signal Loc_area1_RegRdOK              : std_logic;
  signal area1_MemRdData                : std_logic_vector(15 downto 0);
  signal area1_MemRdDone                : std_logic;
  signal area1_MemWrDone                : std_logic;
  signal Loc_area1_MemRdData            : std_logic_vector(15 downto 0);
  signal Loc_area1_MemRdDone            : std_logic;
  signal Loc_area1_MemWrDone            : std_logic;
  signal area1_RdData                   : std_logic_vector(15 downto 0);
  signal area1_RdDone                   : std_logic;
  signal area1_WrDone                   : std_logic;
  signal Loc_area1_myRegister           : std_logic_vector(15 downto 0);
  signal CtrlReg_area1_myRegister       : std_logic_vector(15 downto 0);
  signal WrSel_area1_myRegister         : std_logic;
  signal area2_CRegRdData               : std_logic_vector(15 downto 0);
  signal area2_CRegRdOK                 : std_logic;
  signal area2_CRegWrOK                 : std_logic;
  signal Loc_area2_CRegRdData           : std_logic_vector(15 downto 0);
  signal Loc_area2_CRegRdOK             : std_logic;
  signal Loc_area2_CRegWrOK             : std_logic;
  signal area2_RegRdDone                : std_logic;
  signal area2_RegWrDone                : std_logic;
  signal area2_RegRdData                : std_logic_vector(15 downto 0);
  signal area2_RegRdOK                  : std_logic;
  signal Loc_area2_RegRdData            : std_logic_vector(15 downto 0);
  signal Loc_area2_RegRdOK              : std_logic;
  signal area2_MemRdData                : std_logic_vector(15 downto 0);
  signal area2_MemRdDone                : std_logic;
  signal area2_MemWrDone                : std_logic;
  signal Loc_area2_MemRdData            : std_logic_vector(15 downto 0);
  signal Loc_area2_MemRdDone            : std_logic;
  signal Loc_area2_MemWrDone            : std_logic;
  signal area2_RdData                   : std_logic_vector(15 downto 0);
  signal area2_RdDone                   : std_logic;
  signal area2_WrDone                   : std_logic;
  signal Loc_area2_myRegister           : std_logic_vector(15 downto 0);
  signal CtrlReg_area2_myRegister       : std_logic_vector(15 downto 0);
  signal WrSel_area2_myRegister         : std_logic;
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

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, area1_RdData, area1_RdDone, area2_RdData,
           area2_RdDone) begin
    if VMEAddr(13 downto 10) = C_Area_codeFields_area1 then
      RdData <= area1_RdData;
      RdDone <= area1_RdDone;
    elsif VMEAddr(13 downto 10) = C_Area_codeFields_area2 then
      RdData <= area2_RdData;
      RdDone <= area2_RdDone;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, area1_WrDone, area2_WrDone) begin
    if VMEAddr(13 downto 10) = C_Area_codeFields_area1 then
      WrDone <= area1_WrDone;
    elsif VMEAddr(13 downto 10) = C_Area_codeFields_area2 then
      WrDone <= area2_WrDone;
    else
      WrDone <= MemWrDone;
    end if;
  end process AreaWrMux;

  Reg_area2_myRegister: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_area2_myRegister <= C_PSM_codeFields_area2_myRegister;
      else
        if WrSel_area2_myRegister = '1' and VMEWrMem = '1' then
          CtrlReg_area2_myRegister <= VMEWrData(15 downto 0);
        else
          CtrlReg_area2_myRegister <= CtrlReg_area2_myRegister and not C_ACM_codeFields_area2_myRegister;
        end if;
      end if;
    end if;
  end process Reg_area2_myRegister;
  Loc_area2_myRegister(15 downto 0) <= CtrlReg_area2_myRegister;

  area2_myRegister <= Loc_area2_myRegister;

  area2_WrSelDec: process (VMEAddr) begin
    WrSel_area2_myRegister <= '0';
    if VMEAddr(13 downto 10) = C_Area_codeFields_area2 then
      case VMEAddr(9 downto 1) is
      when C_Reg_codeFields_area2_myRegister =>
        WrSel_area2_myRegister <= '1';
        Loc_area2_CRegWrOK <= '1';
      when others =>
        Loc_area2_CRegWrOK <= '0';
      end case;
    else
      Loc_area2_CRegWrOK <= '0';
    end if;
  end process area2_WrSelDec;

  area2_CRegRdMux: process (VMEAddr, Loc_area2_myRegister) begin
    if VMEAddr(13 downto 10) = C_Area_codeFields_area2 then
      case VMEAddr(9 downto 1) is
      when C_Reg_codeFields_area2_myRegister =>
        Loc_area2_CRegRdData <= Loc_area2_myRegister(15 downto 0);
        Loc_area2_CRegRdOK <= '1';
      when others =>
        Loc_area2_CRegRdData <= (others => '0');
        Loc_area2_CRegRdOK <= '0';
      end case;
    else
      Loc_area2_CRegRdData <= (others => '0');
      Loc_area2_CRegRdOK <= '0';
    end if;
  end process area2_CRegRdMux;

  area2_CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area2_CRegRdData <= Loc_area2_CRegRdData;
      area2_CRegRdOK <= Loc_area2_CRegRdOK;
      area2_CRegWrOK <= Loc_area2_CRegWrOK;
    end if;
  end process area2_CRegRdMux_DFF;

  Loc_area2_RegRdData <= area2_CRegRdData;
  Loc_area2_RegRdOK <= area2_CRegRdOK;

  area2_RegRdData <= Loc_area2_RegRdData;
  area2_RegRdOK <= Loc_area2_RegRdOK;

  area2_RegRdDone <= Loc_VMERdMem(1) and area2_RegRdOK;
  area2_RegWrDone <= Loc_VMEWrMem(1) and area2_CRegWrOK;

  Loc_area2_MemRdData <= area2_RegRdData;
  Loc_area2_MemRdDone <= area2_RegRdDone;

  area2_MemRdData <= Loc_area2_MemRdData;
  area2_MemRdDone <= Loc_area2_MemRdDone;

  Loc_area2_MemWrDone <= area2_RegWrDone;

  area2_MemWrDone <= Loc_area2_MemWrDone;

  area2_RdData <= area2_MemRdData;
  area2_RdDone <= area2_MemRdDone;
  area2_WrDone <= area2_MemWrDone;

  Reg_area1_myRegister: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_area1_myRegister <= C_PSM_codeFields_area1_myRegister;
      else
        if WrSel_area1_myRegister = '1' and VMEWrMem = '1' then
          CtrlReg_area1_myRegister <= VMEWrData(15 downto 0);
        else
          CtrlReg_area1_myRegister <= CtrlReg_area1_myRegister and not C_ACM_codeFields_area1_myRegister;
        end if;
      end if;
    end if;
  end process Reg_area1_myRegister;
  Loc_area1_myRegister(15 downto 0) <= CtrlReg_area1_myRegister;

  area1_myRegister <= Loc_area1_myRegister;

  area1_WrSelDec: process (VMEAddr) begin
    WrSel_area1_myRegister <= '0';
    if VMEAddr(13 downto 10) = C_Area_codeFields_area1 then
      case VMEAddr(9 downto 1) is
      when C_Reg_codeFields_area1_myRegister =>
        WrSel_area1_myRegister <= '1';
        Loc_area1_CRegWrOK <= '1';
      when others =>
        Loc_area1_CRegWrOK <= '0';
      end case;
    else
      Loc_area1_CRegWrOK <= '0';
    end if;
  end process area1_WrSelDec;

  area1_CRegRdMux: process (VMEAddr, Loc_area1_myRegister) begin
    if VMEAddr(13 downto 10) = C_Area_codeFields_area1 then
      case VMEAddr(9 downto 1) is
      when C_Reg_codeFields_area1_myRegister =>
        Loc_area1_CRegRdData <= Loc_area1_myRegister(15 downto 0);
        Loc_area1_CRegRdOK <= '1';
      when others =>
        Loc_area1_CRegRdData <= (others => '0');
        Loc_area1_CRegRdOK <= '0';
      end case;
    else
      Loc_area1_CRegRdData <= (others => '0');
      Loc_area1_CRegRdOK <= '0';
    end if;
  end process area1_CRegRdMux;

  area1_CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area1_CRegRdData <= Loc_area1_CRegRdData;
      area1_CRegRdOK <= Loc_area1_CRegRdOK;
      area1_CRegWrOK <= Loc_area1_CRegWrOK;
    end if;
  end process area1_CRegRdMux_DFF;

  Loc_area1_RegRdData <= area1_CRegRdData;
  Loc_area1_RegRdOK <= area1_CRegRdOK;

  area1_RegRdData <= Loc_area1_RegRdData;
  area1_RegRdOK <= Loc_area1_RegRdOK;

  area1_RegRdDone <= Loc_VMERdMem(1) and area1_RegRdOK;
  area1_RegWrDone <= Loc_VMEWrMem(1) and area1_CRegWrOK;

  Loc_area1_MemRdData <= area1_RegRdData;
  Loc_area1_MemRdDone <= area1_RegRdDone;

  area1_MemRdData <= Loc_area1_MemRdData;
  area1_MemRdDone <= Loc_area1_MemRdDone;

  Loc_area1_MemWrDone <= area1_RegWrDone;

  area1_MemWrDone <= Loc_area1_MemWrDone;

  area1_RdData <= area1_MemRdData;
  area1_RdDone <= area1_MemRdDone;
  area1_WrDone <= area1_MemWrDone;

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
