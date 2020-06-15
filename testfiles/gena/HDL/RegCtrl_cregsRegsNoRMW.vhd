library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregsRegsNoRMW.all;

entity RegCtrl_cregsRegsNoRMW is
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
    test2                : out   std_logic_vector(63 downto 0);
    test3                : out   std_logic_vector(15 downto 0);
    test4                : out   std_logic_vector(31 downto 0);
    test5                : out   std_logic_vector(15 downto 0);
    test6                : out   std_logic_vector(63 downto 0);
    test7                : out   std_logic_vector(15 downto 0);
    test8                : out   std_logic_vector(31 downto 0)
  );
end RegCtrl_cregsRegsNoRMW;

architecture syn of RegCtrl_cregsRegsNoRMW is
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
  signal Loc_test1                      : std_logic_vector(15 downto 0);
  signal WrSel_test1                    : std_logic;
  signal Loc_test2                      : std_logic_vector(63 downto 0);
  signal WrSel_test2_3                  : std_logic;
  signal WrSel_test2_2                  : std_logic;
  signal WrSel_test2_1                  : std_logic;
  signal WrSel_test2_0                  : std_logic;
  signal Loc_test3                      : std_logic_vector(15 downto 0);
  signal WrSel_test3                    : std_logic;
  signal Loc_test4                      : std_logic_vector(31 downto 0);
  signal WrSel_test4_1                  : std_logic;
  signal WrSel_test4_0                  : std_logic;
  signal Loc_test5                      : std_logic_vector(15 downto 0);
  signal WrSel_test5                    : std_logic;
  signal Loc_test6                      : std_logic_vector(63 downto 0);
  signal WrSel_test6_3                  : std_logic;
  signal WrSel_test6_2                  : std_logic;
  signal WrSel_test6_1                  : std_logic;
  signal WrSel_test6_0                  : std_logic;
  signal Loc_test7                      : std_logic_vector(15 downto 0);
  signal WrSel_test7                    : std_logic;
  signal Loc_test8                      : std_logic_vector(31 downto 0);
  signal WrSel_test8_1                  : std_logic;
  signal WrSel_test8_0                  : std_logic;
begin
  Reg_test1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test1,
      Preset               => C_PSM_cregsRegsNoRMW_test1,
      CReg                 => Loc_test1(15 downto 0)
    );
  
  Reg_test2_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_3,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test2_3,
      Preset               => C_PSM_cregsRegsNoRMW_test2_3,
      CReg                 => Loc_test2(63 downto 48)
    );
  
  Reg_test2_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_2,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test2_2,
      Preset               => C_PSM_cregsRegsNoRMW_test2_2,
      CReg                 => Loc_test2(47 downto 32)
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test2_1,
      Preset               => C_PSM_cregsRegsNoRMW_test2_1,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test2_0,
      Preset               => C_PSM_cregsRegsNoRMW_test2_0,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test3,
      Preset               => C_PSM_cregsRegsNoRMW_test3,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test4_1,
      Preset               => C_PSM_cregsRegsNoRMW_test4_1,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test4_0,
      Preset               => C_PSM_cregsRegsNoRMW_test4_0,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test5,
      Preset               => C_PSM_cregsRegsNoRMW_test5,
      CReg                 => Loc_test5(15 downto 0)
    );
  
  Reg_test6_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_3,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test6_3,
      Preset               => C_PSM_cregsRegsNoRMW_test6_3,
      CReg                 => Loc_test6(63 downto 48)
    );
  
  Reg_test6_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_2,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test6_2,
      Preset               => C_PSM_cregsRegsNoRMW_test6_2,
      CReg                 => Loc_test6(47 downto 32)
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test6_1,
      Preset               => C_PSM_cregsRegsNoRMW_test6_1,
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
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test6_0,
      Preset               => C_PSM_cregsRegsNoRMW_test6_0,
      CReg                 => Loc_test6(15 downto 0)
    );
  
  Reg_test7: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test7,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test7,
      Preset               => C_PSM_cregsRegsNoRMW_test7,
      CReg                 => Loc_test7(15 downto 0)
    );
  
  Reg_test8_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test8_1,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test8_1,
      Preset               => C_PSM_cregsRegsNoRMW_test8_1,
      CReg                 => Loc_test8(31 downto 16)
    );
  
  Reg_test8_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test8_0,
      AutoClrMsk           => C_ACM_cregsRegsNoRMW_test8_0,
      Preset               => C_PSM_cregsRegsNoRMW_test8_0,
      CReg                 => Loc_test8(15 downto 0)
    );
  
  test1 <= Loc_test1;

  test2 <= Loc_test2;

  test3 <= Loc_test3;

  test4 <= Loc_test4;

  test5 <= Loc_test5;

  test6 <= Loc_test6;

  test7 <= Loc_test7;

  test8 <= Loc_test8;

  WrSelDec: process (VMEAddr) begin
    WrSel_test1 <= '0';
    WrSel_test2_3 <= '0';
    WrSel_test2_2 <= '0';
    WrSel_test2_1 <= '0';
    WrSel_test2_0 <= '0';
    WrSel_test3 <= '0';
    WrSel_test4_1 <= '0';
    WrSel_test4_0 <= '0';
    WrSel_test5 <= '0';
    WrSel_test6_3 <= '0';
    WrSel_test6_2 <= '0';
    WrSel_test6_1 <= '0';
    WrSel_test6_0 <= '0';
    WrSel_test7 <= '0';
    WrSel_test8_1 <= '0';
    WrSel_test8_0 <= '0';
    case VMEAddr(19 downto 1) is
    when C_Reg_cregsRegsNoRMW_test1 =>
      WrSel_test1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_3 =>
      WrSel_test2_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_2 =>
      WrSel_test2_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_1 =>
      WrSel_test2_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_0 =>
      WrSel_test2_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test3 =>
      WrSel_test3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test4_1 =>
      WrSel_test4_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test4_0 =>
      WrSel_test4_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test5 =>
      WrSel_test5 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test6_3 =>
      WrSel_test6_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test6_2 =>
      WrSel_test6_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test6_1 =>
      WrSel_test6_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test6_0 =>
      WrSel_test6_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test7 =>
      WrSel_test7 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test8_1 =>
      WrSel_test8_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregsRegsNoRMW_test8_0 =>
      WrSel_test8_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test1, Loc_test2, Loc_test3, Loc_test4, Loc_test5, Loc_test6, Loc_test7, Loc_test8) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_cregsRegsNoRMW_test1 =>
      Loc_CRegRdData <= Loc_test1(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_3 =>
      Loc_CRegRdData <= Loc_test2(63 downto 48);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_2 =>
      Loc_CRegRdData <= Loc_test2(47 downto 32);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_1 =>
      Loc_CRegRdData <= Loc_test2(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test2_0 =>
      Loc_CRegRdData <= Loc_test2(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test3 =>
      Loc_CRegRdData <= Loc_test3(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test4_1 =>
      Loc_CRegRdData <= Loc_test4(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test4_0 =>
      Loc_CRegRdData <= Loc_test4(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test5 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegsNoRMW_test6_3 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegsNoRMW_test6_2 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegsNoRMW_test6_1 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegsNoRMW_test6_0 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregsRegsNoRMW_test7 =>
      Loc_CRegRdData <= Loc_test7(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test8_1 =>
      Loc_CRegRdData <= Loc_test8(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregsRegsNoRMW_test8_0 =>
      Loc_CRegRdData <= Loc_test8(15 downto 0);
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
