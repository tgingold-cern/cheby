library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MemMap_m1.all;

entity RegCtrl_m1 is
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
    r1                   : out   std_logic_vector(31 downto 0)
  );
end RegCtrl_m1;

architecture syn of RegCtrl_m1 is
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
  signal Loc_r1                         : std_logic_vector(31 downto 0);
  signal CtrlReg_r1_0                   : std_logic_vector(15 downto 0);
  signal CtrlReg_r1_1                   : std_logic_vector(15 downto 0);
  signal WrSel_r1_1                     : std_logic;
  signal WrSel_r1_0                     : std_logic;
begin
  Reg_r1_1: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_r1_1 <= C_PSM_m1_r1_1;
      else
        if WrSel_r1_1 = '1' and VMEWrMem = '1' then
          CtrlReg_r1_1 <= (CtrlReg_r1_1 and not VMEWrData(31 downto 16)) or (VMEWrData(15 downto 0) and VMEWrData(31 downto 16));
        else
          CtrlReg_r1_1 <= CtrlReg_r1_1 and not C_ACM_m1_r1_1;
        end if;
      end if;
    end if;
  end process Reg_r1_1;
  Loc_r1(31 downto 16) <= CtrlReg_r1_1;

  Reg_r1_0: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_r1_0 <= C_PSM_m1_r1_0;
      else
        if WrSel_r1_0 = '1' and VMEWrMem = '1' then
          CtrlReg_r1_0 <= (CtrlReg_r1_0 and not VMEWrData(31 downto 16)) or (VMEWrData(15 downto 0) and VMEWrData(31 downto 16));
        else
          CtrlReg_r1_0 <= CtrlReg_r1_0 and not C_ACM_m1_r1_0;
        end if;
      end if;
    end if;
  end process Reg_r1_0;
  Loc_r1(15 downto 0) <= CtrlReg_r1_0;

  r1 <= Loc_r1;

  WrSelDec: process (VMEAddr) begin
    WrSel_r1_1 <= '0';
    WrSel_r1_0 <= '0';
    case VMEAddr(19 downto 2) is
    when C_Reg_m1_r1_1 =>
      WrSel_r1_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_m1_r1_0 =>
      WrSel_r1_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_r1) begin
    case VMEAddr(19 downto 2) is
    when C_Reg_m1_r1_1 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_r1(31 downto 16)), 32));
      Loc_CRegRdOK <= '1';
    when C_Reg_m1_r1_0 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_r1(15 downto 0)), 32));
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

  RegRdError <= Loc_VMERdMem(1) and not RegRdOK;
  RegWrError <= Loc_VMEWrMem(1) and not CRegWrOK;

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

  RdData <= MemRdData;
  RdDone <= MemRdDone;
  WrDone <= MemWrDone;
  RdError <= MemRdError;
  WrError <= MemWrError;

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
