library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregs_extacm.all;

entity RegCtrl_cregs_extacm is
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
    test1                : in    std_logic_vector(31 downto 0);
    test2                : in    std_logic_vector(63 downto 0);
    test3                : out   std_logic_vector(31 downto 0);
    test3_ACM            : in    std_logic_vector(31 downto 0);
    test4                : out   std_logic_vector(63 downto 0);
    test4_ACM            : in    std_logic_vector(63 downto 0);
    test5                : out   std_logic_vector(31 downto 0);
    test5_ACM            : in    std_logic_vector(31 downto 0);
    test6                : out   std_logic_vector(63 downto 0);
    test6_ACM            : in    std_logic_vector(63 downto 0)
  );
end RegCtrl_cregs_extacm;

architecture syn of RegCtrl_cregs_extacm is
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
  signal Loc_test1                      : std_logic_vector(31 downto 0);
  signal Loc_test2                      : std_logic_vector(63 downto 0);
  signal Loc_test3                      : std_logic_vector(31 downto 0);
  signal WrSel_test3                    : std_logic;
  signal Loc_test4                      : std_logic_vector(63 downto 0);
  signal WrSel_test4_1                  : std_logic;
  signal WrSel_test4_0                  : std_logic;
  signal Loc_test5                      : std_logic_vector(31 downto 0);
  signal WrSel_test5                    : std_logic;
  signal Loc_test6                      : std_logic_vector(63 downto 0);
  signal WrSel_test6_1                  : std_logic;
  signal WrSel_test6_0                  : std_logic;
begin
  Reg_test3: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3,
      AutoClrMsk           => test3_ACM(31 downto 0),
      Preset               => C_PSM_cregs_extacm_test3,
      CReg                 => Loc_test3(31 downto 0)
    );
  
  Reg_test4_1: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_1,
      AutoClrMsk           => test4_ACM(63 downto 32),
      Preset               => C_PSM_cregs_extacm_test4_1,
      CReg                 => Loc_test4(63 downto 32)
    );
  
  Reg_test4_0: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_0,
      AutoClrMsk           => test4_ACM(31 downto 0),
      Preset               => C_PSM_cregs_extacm_test4_0,
      CReg                 => Loc_test4(31 downto 0)
    );
  
  Reg_test5: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5,
      AutoClrMsk           => test5_ACM(31 downto 0),
      Preset               => C_PSM_cregs_extacm_test5,
      CReg                 => Loc_test5(31 downto 0)
    );
  
  Reg_test6_1: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_1,
      AutoClrMsk           => test6_ACM(63 downto 32),
      Preset               => C_PSM_cregs_extacm_test6_1,
      CReg                 => Loc_test6(63 downto 32)
    );
  
  Reg_test6_0: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_0,
      AutoClrMsk           => test6_ACM(31 downto 0),
      Preset               => C_PSM_cregs_extacm_test6_0,
      CReg                 => Loc_test6(31 downto 0)
    );
  
  Loc_test1 <= test1;

  Loc_test2 <= test2;

  test3 <= Loc_test3;

  test4 <= Loc_test4;

  test5 <= Loc_test5;

  test6 <= Loc_test6;

  WrSelDec: process (VMEAddr) begin
    WrSel_test3 <= '0';
    WrSel_test4_1 <= '0';
    WrSel_test4_0 <= '0';
    WrSel_test5 <= '0';
    WrSel_test6_1 <= '0';
    WrSel_test6_0 <= '0';
    case VMEAddr(19 downto 2) is
    when C_Reg_cregs_extacm_test3 =>
      WrSel_test3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_extacm_test4_1 =>
      WrSel_test4_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_extacm_test4_0 =>
      WrSel_test4_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_extacm_test5 =>
      WrSel_test5 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_extacm_test6_1 =>
      WrSel_test6_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_extacm_test6_0 =>
      WrSel_test6_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test3, Loc_test4, Loc_test5, Loc_test6) begin
    case VMEAddr(19 downto 2) is
    when C_Reg_cregs_extacm_test3 =>
      Loc_CRegRdData <= Loc_test3(31 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_extacm_test4_1 =>
      Loc_CRegRdData <= Loc_test4(63 downto 32);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_extacm_test4_0 =>
      Loc_CRegRdData <= Loc_test4(31 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_extacm_test5 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_extacm_test6_1 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_extacm_test6_0 =>
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

  RegRdMux: process (VMEAddr, CRegRdData, CRegRdOK, Loc_test1, Loc_test2) begin
    case VMEAddr(19 downto 2) is
    when C_Reg_cregs_extacm_test1 =>
      Loc_RegRdData <= Loc_test1(31 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_extacm_test2_1 =>
      Loc_RegRdData <= Loc_test2(63 downto 32);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_extacm_test2_0 =>
      Loc_RegRdData <= Loc_test2(31 downto 0);
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

  RegRdError <= Loc_VMERdMem(2) and not RegRdOK;
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
