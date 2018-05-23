library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregsRegs.all;

entity RegCtrl_cregsRegs is
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
    test1                : out   std_logic_vector(7 downto 0);
    test2_msBit          : out   std_logic;
    test2_msReg          : out   std_logic_vector(25 downto 22);
    test2_boundryReg     : out   std_logic_vector(17 downto 14);
    test2_isReg          : out   std_logic_vector(9 downto 6);
    test2_lsBit          : out   std_logic;
    test3                : out   std_logic_vector(15 downto 0);
    test4_msBit          : out   std_logic;
    test4_msReg          : out   std_logic_vector(25 downto 22);
    test4_boundryReg     : out   std_logic_vector(17 downto 14);
    test4_isReg          : out   std_logic_vector(9 downto 6);
    test4_lsBit          : out   std_logic;
    test5                : out   std_logic_vector(15 downto 0);
    test6_msBit          : out   std_logic;
    test6_msReg          : out   std_logic_vector(25 downto 22);
    test6_boundryReg     : out   std_logic_vector(17 downto 14);
    test6_isReg          : out   std_logic_vector(9 downto 6);
    test6_lsBit          : out   std_logic;
    test7                : in    std_logic_vector(15 downto 0);
    test8_msBit          : in    std_logic;
    test8_msReg          : in    std_logic_vector(25 downto 22);
    test8_boundryReg     : in    std_logic_vector(17 downto 14);
    test8_isReg          : in    std_logic_vector(9 downto 6);
    test8_lsBit          : in    std_logic
  );
end RegCtrl_cregsRegs;

architecture syn of RegCtrl_cregsRegs is
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

  component CtrlRegN
    generic (
      N : integer := 16
    );
    port (
      Clk                  : in    std_logic;
      Rst                  : in    std_logic;
      CRegSel              : in    std_logic;
      WriteMem             : in    std_logic;
      VMEWrData            : in    std_logic_vector(N-1 downto 0);
      AutoClrMsk           : in    std_logic_vector(N-1 downto 0);
      CReg                 : out   std_logic_vector(N-1 downto 0);
      Preset               : in    std_logic_vector(N-1 downto 0)
    );
  end component;

  for all : CtrlRegN use entity CommonVisual.CtrlRegN(V1);

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
  signal Loc_test1                      : std_logic_vector(7 downto 0);
  signal WrSel_test1                    : std_logic;
  signal Loc_test2                      : std_logic_vector(31 downto 0);
  signal WrSel_test2_1                  : std_logic;
  signal WrSel_test2_0                  : std_logic;
  signal Loc_test3                      : std_logic_vector(15 downto 0);
  signal WrSel_test3                    : std_logic;
  signal Loc_test4                      : std_logic_vector(31 downto 0);
  signal WrSel_test4_1                  : std_logic;
  signal WrSel_test4_0                  : std_logic;
  signal Loc_test5                      : std_logic_vector(15 downto 0);
  signal WrSel_test5                    : std_logic;
  signal Loc_test6                      : std_logic_vector(31 downto 0);
  signal WrSel_test6_1                  : std_logic;
  signal WrSel_test6_0                  : std_logic;
  signal Loc_test7                      : std_logic_vector(15 downto 0);
  signal Loc_test8                      : std_logic_vector(31 downto 0);
begin
  Reg_test1: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1,
      AutoClrMsk           => C_ACM_cregsRegs_test1,
      Preset               => C_PSM_cregsRegs_test1,
      CReg                 => Loc_test1(7 downto 0)
    );
  
  Reg_test2_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_1,
      AutoClrMsk           => C_ACM_cregsRegs_test2_1,
      Preset               => C_PSM_cregsRegs_test2_1,
      CReg                 => Loc_test2(31 downto 16)
    );
  
  Reg_test2_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_0,
      AutoClrMsk           => C_ACM_cregsRegs_test2_0,
      Preset               => C_PSM_cregsRegs_test2_0,
      CReg                 => Loc_test2(15 downto 0)
    );
  
  Reg_test3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3,
      AutoClrMsk           => C_ACM_cregsRegs_test3,
      Preset               => C_PSM_cregsRegs_test3,
      CReg                 => Loc_test3(15 downto 0)
    );
  
  Reg_test4_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_1,
      AutoClrMsk           => C_ACM_cregsRegs_test4_1,
      Preset               => C_PSM_cregsRegs_test4_1,
      CReg                 => Loc_test4(31 downto 16)
    );
  
  Reg_test4_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_0,
      AutoClrMsk           => C_ACM_cregsRegs_test4_0,
      Preset               => C_PSM_cregsRegs_test4_0,
      CReg                 => Loc_test4(15 downto 0)
    );
  
  Reg_test5: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5,
      AutoClrMsk           => C_ACM_cregsRegs_test5,
      Preset               => C_PSM_cregsRegs_test5,
      CReg                 => Loc_test5(15 downto 0)
    );
  
  Reg_test6_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_1,
      AutoClrMsk           => C_ACM_cregsRegs_test6_1,
      Preset               => C_PSM_cregsRegs_test6_1,
      CReg                 => Loc_test6(31 downto 16)
    );
  
  Reg_test6_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_0,
      AutoClrMsk           => C_ACM_cregsRegs_test6_0,
      Preset               => C_PSM_cregsRegs_test6_0,
      CReg                 => Loc_test6(15 downto 0)
    );
  
  test1 <= Loc_test1;

  test2_msBit <= Loc_test2(31);
  test2_msReg <= Loc_test2(25 downto 22);
  test2_boundryReg <= Loc_test2(17 downto 14);
  test2_isReg <= Loc_test2(9 downto 6);
  test2_lsBit <= Loc_test2(0);

  test3 <= Loc_test3;

  test4_msBit <= Loc_test4(31);
  test4_msReg <= Loc_test4(25 downto 22);
  test4_boundryReg <= Loc_test4(17 downto 14);
  test4_isReg <= Loc_test4(9 downto 6);
  test4_lsBit <= Loc_test4(0);

  test5 <= Loc_test5;

  test6_msBit <= Loc_test6(31);
  test6_msReg <= Loc_test6(25 downto 22);
  test6_boundryReg <= Loc_test6(17 downto 14);
  test6_isReg <= Loc_test6(9 downto 6);
  test6_lsBit <= Loc_test6(0);

  Loc_test7 <= test7;

  Loc_test8(31) <= test8_msBit;
  Loc_test8(30 downto 26) <= C_PSM_cregsRegs_test8_1(30 downto 26);
  Loc_test8(25 downto 22) <= test8_msReg;
  Loc_test8(21 downto 18) <= C_PSM_cregsRegs_test8_1(21 downto 18);
  Loc_test8(17 downto 14) <= test8_boundryReg;
  Loc_test8(13 downto 10) <= C_PSM_cregsRegs_test8_0(13 downto 10);
  Loc_test8(9 downto 6) <= test8_isReg;
  Loc_test8(5 downto 1) <= C_PSM_cregsRegs_test8_0(5 downto 1);
  Loc_test8(0) <= test8_lsBit;

  WrSelDec: process (VMEAddr) begin
    WrSel_test1 <= '0';
    WrSel_test2_1 <= '0';
    WrSel_test2_0 <= '0';
    WrSel_test3 <= '0';
    WrSel_test4_1 <= '0';
    WrSel_test4_0 <= '0';
    WrSel_test5 <= '0';
    WrSel_test6_1 <= '0';
    WrSel_test6_0 <= '0';
    case VMEAddr(19 downto 1) is
    when C_Reg_cregsRegs_test1 => 
      WrSel_test1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test2_1 => 
      WrSel_test2_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test2_0 => 
      WrSel_test2_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test3 => 
      WrSel_test3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test4_1 => 
      WrSel_test4_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test4_0 => 
      WrSel_test4_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test5 => 
      WrSel_test5 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test6_1 => 
      WrSel_test6_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegs_test6_0 => 
      WrSel_test6_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test1, Loc_test2, Loc_test3, Loc_test4, Loc_test5, Loc_test6) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_cregsRegs_test1 => 
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(7 downto 0)), 16));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test2_1 => 
      Loc_CRegRdData <= Loc_test2(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test2_0 => 
      Loc_CRegRdData <= Loc_test2(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test3 => 
      Loc_CRegRdData <= Loc_test3(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test4_1 => 
      Loc_CRegRdData <= Loc_test4(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test4_0 => 
      Loc_CRegRdData <= Loc_test4(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegs_test5 => 
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegs_test6_1 => 
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegs_test6_0 => 
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
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

  RegRdMux: process (VMEAddr, CRegRdData, CRegRdOK, Loc_test7, Loc_test8) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_cregsRegs_test7 => 
      Loc_RegRdData <= Loc_test7(15 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_cregsRegs_test8_1 => 
      Loc_RegRdData <= Loc_test8(31 downto 16);
      Loc_RegRdOK <= '1';
    when C_Reg_cregsRegs_test8_0 => 
      Loc_RegRdData <= Loc_test8(15 downto 0);
      Loc_RegRdOK <= '1';
    when others =>
      Loc_RegRdData <= CRegRdData;
      Loc_RegRdOK <= CRegRdOK;
    end case;
  end process RegRdMux;

  RegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      RegRdData <= Loc_RegRdData;
      RegRdOK <= Loc_RegRdOK;
    end if;
  end process RegRdMux_DFF;

  RegRdDone <= Loc_VMERdMem(2) and RegRdOK;
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
