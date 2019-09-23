library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MemMap_memmap.all;

entity RegCtrl_memmap is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(1 downto 1);
    VMERdData            : out   std_logic_vector(15 downto 0);
    VMEWrData            : in    std_logic_vector(15 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    reg1                 : out   std_logic_vector(31 downto 0)
  );
end RegCtrl_memmap;

architecture syn of RegCtrl_memmap is
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
  signal Loc_reg1                       : std_logic_vector(31 downto 0);
  signal CtrlReg_reg1_0                 : std_logic_vector(15 downto 0);
  signal CtrlReg_reg1_1                 : std_logic_vector(15 downto 0);
  signal WrSel_reg1_1                   : std_logic;
  signal WrSel_reg1_0                   : std_logic;
begin
  Reg_reg1_1: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_reg1_1 <= C_PSM_memmap_reg1_1;
      else
        if WrSel_reg1_1 = '1' and VMEWrMem = '1' then
          CtrlReg_reg1_1 <= VMEWrData(15 downto 0);
        else
          CtrlReg_reg1_1 <= CtrlReg_reg1_1 and not C_ACM_memmap_reg1_1;
        end if;
      end if;
    end if;
  end process Reg_reg1_1;
  Loc_reg1(31 downto 16) <= CtrlReg_reg1_1;

  Reg_reg1_0: process (Clk) begin
    if rising_edge(Clk) then
      if Rst = '1' then
        CtrlReg_reg1_0 <= C_PSM_memmap_reg1_0;
      else
        if WrSel_reg1_0 = '1' and VMEWrMem = '1' then
          CtrlReg_reg1_0 <= VMEWrData(15 downto 0);
        else
          CtrlReg_reg1_0 <= CtrlReg_reg1_0 and not C_ACM_memmap_reg1_0;
        end if;
      end if;
    end if;
  end process Reg_reg1_0;
  Loc_reg1(15 downto 0) <= CtrlReg_reg1_0;

  reg1 <= Loc_reg1;

  WrSelDec: process (VMEAddr) begin
    WrSel_reg1_1 <= '0';
    WrSel_reg1_0 <= '0';
    case VMEAddr(1 downto 1) is
    when C_Reg_memmap_reg1_1 => 
      WrSel_reg1_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_memmap_reg1_0 => 
      WrSel_reg1_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_reg1) begin
    case VMEAddr(1 downto 1) is
    when C_Reg_memmap_reg1_1 => 
      Loc_CRegRdData <= Loc_reg1(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_memmap_reg1_0 => 
      Loc_CRegRdData <= Loc_reg1(15 downto 0);
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
