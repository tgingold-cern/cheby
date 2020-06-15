library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregs_d8.all;

entity RegCtrl_cregs_d8 is
  port (
    Clk                  : in    std_logic;
    Rst                  : in    std_logic;
    VMEAddr              : in    std_logic_vector(19 downto 0);
    VMERdData            : out   std_logic_vector(7 downto 0);
    VMEWrData            : in    std_logic_vector(7 downto 0);
    VMERdMem             : in    std_logic;
    VMEWrMem             : in    std_logic;
    VMERdDone            : out   std_logic;
    VMEWrDone            : out   std_logic;
    test1                : out   std_logic_vector(15 downto 0);
    test2                : out   std_logic_vector(15 downto 0);
    test3                : out   std_logic_vector(31 downto 0);
    test4                : out   std_logic_vector(31 downto 0);
    test5                : out   std_logic_vector(31 downto 0);
    test6                : out   std_logic_vector(31 downto 0);
    test7                : in    std_logic_vector(31 downto 0);
    test8                : in    std_logic_vector(31 downto 0)
  );
end RegCtrl_cregs_d8;

architecture syn of RegCtrl_cregs_d8 is
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
  signal CRegRdData                     : std_logic_vector(7 downto 0);
  signal CRegRdOK                       : std_logic;
  signal CRegWrOK                       : std_logic;
  signal Loc_CRegRdData                 : std_logic_vector(7 downto 0);
  signal Loc_CRegRdOK                   : std_logic;
  signal Loc_CRegWrOK                   : std_logic;
  signal RegRdDone                      : std_logic;
  signal RegWrDone                      : std_logic;
  signal RegRdData                      : std_logic_vector(7 downto 0);
  signal RegRdOK                        : std_logic;
  signal Loc_RegRdData                  : std_logic_vector(7 downto 0);
  signal Loc_RegRdOK                    : std_logic;
  signal MemRdData                      : std_logic_vector(7 downto 0);
  signal MemRdDone                      : std_logic;
  signal MemWrDone                      : std_logic;
  signal Loc_MemRdData                  : std_logic_vector(7 downto 0);
  signal Loc_MemRdDone                  : std_logic;
  signal Loc_MemWrDone                  : std_logic;
  signal RdData                         : std_logic_vector(7 downto 0);
  signal RdDone                         : std_logic;
  signal WrDone                         : std_logic;
  signal Loc_test1                      : std_logic_vector(15 downto 0);
  signal WrSel_test1_3                  : std_logic;
  signal WrSel_test1_2                  : std_logic;
  signal WrSel_test1_1                  : std_logic;
  signal WrSel_test1_0                  : std_logic;
  signal Loc_test2                      : std_logic_vector(15 downto 0);
  signal WrSel_test2_3                  : std_logic;
  signal WrSel_test2_2                  : std_logic;
  signal WrSel_test2_1                  : std_logic;
  signal WrSel_test2_0                  : std_logic;
  signal Loc_test3                      : std_logic_vector(31 downto 0);
  signal WrSel_test3_3                  : std_logic;
  signal WrSel_test3_2                  : std_logic;
  signal WrSel_test3_1                  : std_logic;
  signal WrSel_test3_0                  : std_logic;
  signal Loc_test4                      : std_logic_vector(31 downto 0);
  signal WrSel_test4_3                  : std_logic;
  signal WrSel_test4_2                  : std_logic;
  signal WrSel_test4_1                  : std_logic;
  signal WrSel_test4_0                  : std_logic;
  signal Loc_test5                      : std_logic_vector(31 downto 0);
  signal WrSel_test5_3                  : std_logic;
  signal WrSel_test5_2                  : std_logic;
  signal WrSel_test5_1                  : std_logic;
  signal WrSel_test5_0                  : std_logic;
  signal Loc_test6                      : std_logic_vector(31 downto 0);
  signal WrSel_test6_3                  : std_logic;
  signal WrSel_test6_2                  : std_logic;
  signal WrSel_test6_1                  : std_logic;
  signal WrSel_test6_0                  : std_logic;
  signal Loc_test7                      : std_logic_vector(31 downto 0);
  signal Loc_test8                      : std_logic_vector(31 downto 0);
begin
  Reg_test1_3: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_3,
      AutoClrMsk           => C_ACM_cregs_d8_test1_3,
      Preset               => C_PSM_cregs_d8_test1_3,
      CReg                 => Loc_test1(15 downto 12)
    );
  
  Reg_test1_2: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_2,
      AutoClrMsk           => C_ACM_cregs_d8_test1_2,
      Preset               => C_PSM_cregs_d8_test1_2,
      CReg                 => Loc_test1(11 downto 8)
    );
  
  Reg_test1_1: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_1,
      AutoClrMsk           => C_ACM_cregs_d8_test1_1,
      Preset               => C_PSM_cregs_d8_test1_1,
      CReg                 => Loc_test1(7 downto 4)
    );
  
  Reg_test1_0: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test1_0,
      AutoClrMsk           => C_ACM_cregs_d8_test1_0,
      Preset               => C_PSM_cregs_d8_test1_0,
      CReg                 => Loc_test1(3 downto 0)
    );
  
  Reg_test2_3: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_3,
      AutoClrMsk           => C_ACM_cregs_d8_test2_3,
      Preset               => C_PSM_cregs_d8_test2_3,
      CReg                 => Loc_test2(15 downto 12)
    );
  
  Reg_test2_2: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_2,
      AutoClrMsk           => C_ACM_cregs_d8_test2_2,
      Preset               => C_PSM_cregs_d8_test2_2,
      CReg                 => Loc_test2(11 downto 8)
    );
  
  Reg_test2_1: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_1,
      AutoClrMsk           => C_ACM_cregs_d8_test2_1,
      Preset               => C_PSM_cregs_d8_test2_1,
      CReg                 => Loc_test2(7 downto 4)
    );
  
  Reg_test2_0: RMWReg
    generic map (
      N                    => 4
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test2_0,
      AutoClrMsk           => C_ACM_cregs_d8_test2_0,
      Preset               => C_PSM_cregs_d8_test2_0,
      CReg                 => Loc_test2(3 downto 0)
    );
  
  Reg_test3_3: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_3,
      AutoClrMsk           => C_ACM_cregs_d8_test3_3,
      Preset               => C_PSM_cregs_d8_test3_3,
      CReg                 => Loc_test3(31 downto 24)
    );
  
  Reg_test3_2: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_2,
      AutoClrMsk           => C_ACM_cregs_d8_test3_2,
      Preset               => C_PSM_cregs_d8_test3_2,
      CReg                 => Loc_test3(23 downto 16)
    );
  
  Reg_test3_1: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_1,
      AutoClrMsk           => C_ACM_cregs_d8_test3_1,
      Preset               => C_PSM_cregs_d8_test3_1,
      CReg                 => Loc_test3(15 downto 8)
    );
  
  Reg_test3_0: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_0,
      AutoClrMsk           => C_ACM_cregs_d8_test3_0,
      Preset               => C_PSM_cregs_d8_test3_0,
      CReg                 => Loc_test3(7 downto 0)
    );
  
  Reg_test4_3: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_3,
      AutoClrMsk           => C_ACM_cregs_d8_test4_3,
      Preset               => C_PSM_cregs_d8_test4_3,
      CReg                 => Loc_test4(31 downto 24)
    );
  
  Reg_test4_2: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_2,
      AutoClrMsk           => C_ACM_cregs_d8_test4_2,
      Preset               => C_PSM_cregs_d8_test4_2,
      CReg                 => Loc_test4(23 downto 16)
    );
  
  Reg_test4_1: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_1,
      AutoClrMsk           => C_ACM_cregs_d8_test4_1,
      Preset               => C_PSM_cregs_d8_test4_1,
      CReg                 => Loc_test4(15 downto 8)
    );
  
  Reg_test4_0: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_0,
      AutoClrMsk           => C_ACM_cregs_d8_test4_0,
      Preset               => C_PSM_cregs_d8_test4_0,
      CReg                 => Loc_test4(7 downto 0)
    );
  
  Reg_test5_3: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5_3,
      AutoClrMsk           => C_ACM_cregs_d8_test5_3,
      Preset               => C_PSM_cregs_d8_test5_3,
      CReg                 => Loc_test5(31 downto 24)
    );
  
  Reg_test5_2: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5_2,
      AutoClrMsk           => C_ACM_cregs_d8_test5_2,
      Preset               => C_PSM_cregs_d8_test5_2,
      CReg                 => Loc_test5(23 downto 16)
    );
  
  Reg_test5_1: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5_1,
      AutoClrMsk           => C_ACM_cregs_d8_test5_1,
      Preset               => C_PSM_cregs_d8_test5_1,
      CReg                 => Loc_test5(15 downto 8)
    );
  
  Reg_test5_0: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test5_0,
      AutoClrMsk           => C_ACM_cregs_d8_test5_0,
      Preset               => C_PSM_cregs_d8_test5_0,
      CReg                 => Loc_test5(7 downto 0)
    );
  
  Reg_test6_3: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_3,
      AutoClrMsk           => C_ACM_cregs_d8_test6_3,
      Preset               => C_PSM_cregs_d8_test6_3,
      CReg                 => Loc_test6(31 downto 24)
    );
  
  Reg_test6_2: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_2,
      AutoClrMsk           => C_ACM_cregs_d8_test6_2,
      Preset               => C_PSM_cregs_d8_test6_2,
      CReg                 => Loc_test6(23 downto 16)
    );
  
  Reg_test6_1: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_1,
      AutoClrMsk           => C_ACM_cregs_d8_test6_1,
      Preset               => C_PSM_cregs_d8_test6_1,
      CReg                 => Loc_test6(15 downto 8)
    );
  
  Reg_test6_0: CtrlRegN
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(7 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test6_0,
      AutoClrMsk           => C_ACM_cregs_d8_test6_0,
      Preset               => C_PSM_cregs_d8_test6_0,
      CReg                 => Loc_test6(7 downto 0)
    );
  
  test1 <= Loc_test1;

  test2 <= Loc_test2;

  test3 <= Loc_test3;

  test4 <= Loc_test4;

  test5 <= Loc_test5;

  test6 <= Loc_test6;

  Loc_test7 <= test7;

  Loc_test8 <= test8;

  WrSelDec: process (VMEAddr) begin
    WrSel_test1_3 <= '0';
    WrSel_test1_2 <= '0';
    WrSel_test1_1 <= '0';
    WrSel_test1_0 <= '0';
    WrSel_test2_3 <= '0';
    WrSel_test2_2 <= '0';
    WrSel_test2_1 <= '0';
    WrSel_test2_0 <= '0';
    WrSel_test3_3 <= '0';
    WrSel_test3_2 <= '0';
    WrSel_test3_1 <= '0';
    WrSel_test3_0 <= '0';
    WrSel_test4_3 <= '0';
    WrSel_test4_2 <= '0';
    WrSel_test4_1 <= '0';
    WrSel_test4_0 <= '0';
    WrSel_test5_3 <= '0';
    WrSel_test5_2 <= '0';
    WrSel_test5_1 <= '0';
    WrSel_test5_0 <= '0';
    WrSel_test6_3 <= '0';
    WrSel_test6_2 <= '0';
    WrSel_test6_1 <= '0';
    WrSel_test6_0 <= '0';
    case VMEAddr(19 downto 0) is
    when C_Reg_cregs_d8_test1_3 =>
      WrSel_test1_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test1_2 =>
      WrSel_test1_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test1_1 =>
      WrSel_test1_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test1_0 =>
      WrSel_test1_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test2_3 =>
      WrSel_test2_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test2_2 =>
      WrSel_test2_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test2_1 =>
      WrSel_test2_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test2_0 =>
      WrSel_test2_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test3_3 =>
      WrSel_test3_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test3_2 =>
      WrSel_test3_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test3_1 =>
      WrSel_test3_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test3_0 =>
      WrSel_test3_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test4_3 =>
      WrSel_test4_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test4_2 =>
      WrSel_test4_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test4_1 =>
      WrSel_test4_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test4_0 =>
      WrSel_test4_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test5_3 =>
      WrSel_test5_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test5_2 =>
      WrSel_test5_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test5_1 =>
      WrSel_test5_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test5_0 =>
      WrSel_test5_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test6_3 =>
      WrSel_test6_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test6_2 =>
      WrSel_test6_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test6_1 =>
      WrSel_test6_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_cregs_d8_test6_0 =>
      WrSel_test6_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test1, Loc_test2, Loc_test3, Loc_test4, Loc_test5, Loc_test6) begin
    case VMEAddr(19 downto 0) is
    when C_Reg_cregs_d8_test1_3 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(15 downto 12)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test1_2 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(11 downto 8)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test1_1 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(7 downto 4)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test1_0 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test1(3 downto 0)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test2_3 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test2(15 downto 12)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test2_2 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test2(11 downto 8)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test2_1 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test2(7 downto 4)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test2_0 =>
      Loc_CRegRdData <= std_logic_vector(resize(unsigned(Loc_test2(3 downto 0)), 8));
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test3_3 =>
      Loc_CRegRdData <= Loc_test3(31 downto 24);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test3_2 =>
      Loc_CRegRdData <= Loc_test3(23 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test3_1 =>
      Loc_CRegRdData <= Loc_test3(15 downto 8);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test3_0 =>
      Loc_CRegRdData <= Loc_test3(7 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test4_3 =>
      Loc_CRegRdData <= Loc_test4(31 downto 24);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test4_2 =>
      Loc_CRegRdData <= Loc_test4(23 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test4_1 =>
      Loc_CRegRdData <= Loc_test4(15 downto 8);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test4_0 =>
      Loc_CRegRdData <= Loc_test4(7 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_cregs_d8_test5_3 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test5_2 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test5_1 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test5_0 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test6_3 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test6_2 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test6_1 =>
      Loc_CRegRdData <= (others => '0');
      Loc_CRegRdOK <= '0';
    when C_Reg_cregs_d8_test6_0 =>
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
    case VMEAddr(19 downto 0) is
    when C_Reg_cregs_d8_test7_3 =>
      Loc_RegRdData <= Loc_test7(31 downto 24);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test7_2 =>
      Loc_RegRdData <= Loc_test7(23 downto 16);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test7_1 =>
      Loc_RegRdData <= Loc_test7(15 downto 8);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test7_0 =>
      Loc_RegRdData <= Loc_test7(7 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test8_3 =>
      Loc_RegRdData <= Loc_test8(31 downto 24);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test8_2 =>
      Loc_RegRdData <= Loc_test8(23 downto 16);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test8_1 =>
      Loc_RegRdData <= Loc_test8(15 downto 8);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_d8_test8_0 =>
      Loc_RegRdData <= Loc_test8(7 downto 0);
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
