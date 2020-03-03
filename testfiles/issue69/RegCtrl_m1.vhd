library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MemMap_m1.all;

entity RegCtrl_m1 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMERdData            : out   std_logic_vector(31 downto 0);
    VMEWrData            : in    std_logic_vector(31 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    r1_f1                : out   std_logic_vector(16 downto 0)
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
  signal Loc_r1                         : std_logic_vector(31 downto 0);
  signal CtrlReg_r1                     : std_logic_vector(31 downto 0);
  signal WrSel_r1                       : std_logic;
begin
  Reg_r1: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_r1 <= C_PSM_m1_r1;
      else
        if WrSel_r1 = '1' and VMEWrMem = '1' then
          CtrlReg_r1 <= VMEWrData(31 downto 0);
        else
          CtrlReg_r1 <= CtrlReg_r1 and not C_ACM_m1_r1;
        end if;
      end if;
    end if;
  end process Reg_r1;
  Loc_r1(31 downto 0) <= CtrlReg_r1;

  r1_f1 <= Loc_r1(16 downto 0);

  WrSelDec: process () begin
    WrSel_r1 <= '0';
    WrSel_r1 <= '1';
    Loc_CRegWrOK <= '1';
  end process WrSelDec;

  CRegRdMux: process (Loc_r1) begin
    Loc_CRegRdData <= Loc_r1(31 downto 0);
    Loc_CRegRdOK <= '1';
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
