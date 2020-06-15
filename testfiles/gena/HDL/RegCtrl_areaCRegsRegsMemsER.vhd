library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_areaCRegsRegsMemsER.all;

entity RegCtrl_areaCRegsRegsMemsER is
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
    area_test1           : out   std_logic_vector(15 downto 0);
    area_test2           : out   std_logic_vector(31 downto 0);
    area_test3           : out   std_logic_vector(31 downto 0);
    area_test4           : out   std_logic_vector(63 downto 0);
    area_test5           : out   std_logic_vector(31 downto 0);
    area_test6           : out   std_logic_vector(63 downto 0);
    area_test7           : in    std_logic_vector(63 downto 0);
    area_test8           : in    std_logic_vector(63 downto 0);
    area_mem1_Sel        : out   std_logic;
    area_mem1_Addr       : out   std_logic_vector(9 downto 1);
    area_mem1_RdData     : in    std_logic_vector(15 downto 0);
    area_mem1_WrData     : out   std_logic_vector(15 downto 0);
    area_mem1_RdMem      : out   std_logic;
    area_mem1_WrMem      : out   std_logic;
    area_mem1_RdDone     : in    std_logic;
    area_mem1_WrDone     : in    std_logic;
    area_mem2_Sel        : out   std_logic;
    area_mem2_Addr       : out   std_logic_vector(9 downto 1);
    area_mem2_RdData     : in    std_logic_vector(15 downto 0);
    area_mem2_WrData     : out   std_logic_vector(15 downto 0);
    area_mem2_RdMem      : out   std_logic;
    area_mem2_WrMem      : out   std_logic;
    area_mem2_RdDone     : in    std_logic;
    area_mem2_WrDone     : in    std_logic
  );
end RegCtrl_areaCRegsRegsMemsER;

architecture syn of RegCtrl_areaCRegsRegsMemsER is
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
  signal area_CRegRdData                : std_logic_vector(15 downto 0);
  signal area_CRegRdOK                  : std_logic;
  signal area_CRegWrOK                  : std_logic;
  signal Loc_area_CRegRdData            : std_logic_vector(15 downto 0);
  signal Loc_area_CRegRdOK              : std_logic;
  signal Loc_area_CRegWrOK              : std_logic;
  signal area_RegRdDone                 : std_logic;
  signal area_RegWrDone                 : std_logic;
  signal area_RegRdData                 : std_logic_vector(15 downto 0);
  signal area_RegRdOK                   : std_logic;
  signal Loc_area_RegRdData             : std_logic_vector(15 downto 0);
  signal Loc_area_RegRdOK               : std_logic;
  signal area_MemRdData                 : std_logic_vector(15 downto 0);
  signal area_MemRdDone                 : std_logic;
  signal area_MemWrDone                 : std_logic;
  signal Loc_area_MemRdData             : std_logic_vector(15 downto 0);
  signal Loc_area_MemRdDone             : std_logic;
  signal Loc_area_MemWrDone             : std_logic;
  signal area_RdData                    : std_logic_vector(15 downto 0);
  signal area_RdDone                    : std_logic;
  signal area_WrDone                    : std_logic;
  signal Loc_area_test1                 : std_logic_vector(15 downto 0);
  signal WrSel_area_test1_1             : std_logic;
  signal WrSel_area_test1_0             : std_logic;
  signal Loc_area_test2                 : std_logic_vector(31 downto 0);
  signal WrSel_area_test2_3             : std_logic;
  signal WrSel_area_test2_2             : std_logic;
  signal WrSel_area_test2_1             : std_logic;
  signal WrSel_area_test2_0             : std_logic;
  signal Loc_area_test3                 : std_logic_vector(31 downto 0);
  signal WrSel_area_test3_1             : std_logic;
  signal WrSel_area_test3_0             : std_logic;
  signal Loc_area_test4                 : std_logic_vector(63 downto 0);
  signal WrSel_area_test4_3             : std_logic;
  signal WrSel_area_test4_2             : std_logic;
  signal WrSel_area_test4_1             : std_logic;
  signal WrSel_area_test4_0             : std_logic;
  signal Loc_area_test5                 : std_logic_vector(31 downto 0);
  signal WrSel_area_test5_1             : std_logic;
  signal WrSel_area_test5_0             : std_logic;
  signal Loc_area_test6                 : std_logic_vector(63 downto 0);
  signal WrSel_area_test6_3             : std_logic;
  signal WrSel_area_test6_2             : std_logic;
  signal WrSel_area_test6_1             : std_logic;
  signal WrSel_area_test6_0             : std_logic;
  signal Loc_area_test7                 : std_logic_vector(63 downto 0);
  signal Loc_area_test8                 : std_logic_vector(63 downto 0);
  signal Sel_area_mem1                  : std_logic;
  signal Sel_area_mem2                  : std_logic;
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

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, area_RdData, area_RdDone) begin
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      RdData <= area_RdData;
      RdDone <= area_RdDone;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, area_WrDone) begin
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      WrDone <= area_WrDone;
    else
      WrDone <= MemWrDone;
    end if;
  end process AreaWrMux;

  Reg_area_test1_1: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test1_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test1_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test1_1,
      CReg                 => Loc_area_test1(15 downto 8)
    );
  
  Reg_area_test1_0: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test1_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test1_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test1_0,
      CReg                 => Loc_area_test1(7 downto 0)
    );
  
  Reg_area_test2_3: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test2_3,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test2_3,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test2_3,
      CReg                 => Loc_area_test2(31 downto 24)
    );
  
  Reg_area_test2_2: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test2_2,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test2_2,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test2_2,
      CReg                 => Loc_area_test2(23 downto 16)
    );
  
  Reg_area_test2_1: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test2_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test2_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test2_1,
      CReg                 => Loc_area_test2(15 downto 8)
    );
  
  Reg_area_test2_0: RMWReg
    generic map (
      N                    => 8
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test2_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test2_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test2_0,
      CReg                 => Loc_area_test2(7 downto 0)
    );
  
  Reg_area_test3_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test3_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test3_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test3_1,
      CReg                 => Loc_area_test3(31 downto 16)
    );
  
  Reg_area_test3_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test3_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test3_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test3_0,
      CReg                 => Loc_area_test3(15 downto 0)
    );
  
  Reg_area_test4_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test4_3,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test4_3,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test4_3,
      CReg                 => Loc_area_test4(63 downto 48)
    );
  
  Reg_area_test4_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test4_2,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test4_2,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test4_2,
      CReg                 => Loc_area_test4(47 downto 32)
    );
  
  Reg_area_test4_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test4_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test4_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test4_1,
      CReg                 => Loc_area_test4(31 downto 16)
    );
  
  Reg_area_test4_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test4_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test4_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test4_0,
      CReg                 => Loc_area_test4(15 downto 0)
    );
  
  Reg_area_test5_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test5_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test5_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test5_1,
      CReg                 => Loc_area_test5(31 downto 16)
    );
  
  Reg_area_test5_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test5_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test5_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test5_0,
      CReg                 => Loc_area_test5(15 downto 0)
    );
  
  Reg_area_test6_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test6_3,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test6_3,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test6_3,
      CReg                 => Loc_area_test6(63 downto 48)
    );
  
  Reg_area_test6_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test6_2,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test6_2,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test6_2,
      CReg                 => Loc_area_test6(47 downto 32)
    );
  
  Reg_area_test6_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test6_1,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test6_1,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test6_1,
      CReg                 => Loc_area_test6(31 downto 16)
    );
  
  Reg_area_test6_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area_test6_0,
      AutoClrMsk           => C_ACM_areaCRegsRegsMemsER_area_test6_0,
      Preset               => C_PSM_areaCRegsRegsMemsER_area_test6_0,
      CReg                 => Loc_area_test6(15 downto 0)
    );
  
  area_test1 <= Loc_area_test1;

  area_test2 <= Loc_area_test2;

  area_test3 <= Loc_area_test3;

  area_test4 <= Loc_area_test4;

  area_test5 <= Loc_area_test5;

  area_test6 <= Loc_area_test6;

  Loc_area_test7 <= area_test7;

  Loc_area_test8 <= area_test8;

  area_WrSelDec: process (VMEAddr) begin
    WrSel_area_test1_1 <= '0';
    WrSel_area_test1_0 <= '0';
    WrSel_area_test2_3 <= '0';
    WrSel_area_test2_2 <= '0';
    WrSel_area_test2_1 <= '0';
    WrSel_area_test2_0 <= '0';
    WrSel_area_test3_1 <= '0';
    WrSel_area_test3_0 <= '0';
    WrSel_area_test4_3 <= '0';
    WrSel_area_test4_2 <= '0';
    WrSel_area_test4_1 <= '0';
    WrSel_area_test4_0 <= '0';
    WrSel_area_test5_1 <= '0';
    WrSel_area_test5_0 <= '0';
    WrSel_area_test6_3 <= '0';
    WrSel_area_test6_2 <= '0';
    WrSel_area_test6_1 <= '0';
    WrSel_area_test6_0 <= '0';
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      case VMEAddr(18 downto 1) is
      when C_Reg_areaCRegsRegsMemsER_area_test1_1 =>
        WrSel_area_test1_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test1_0 =>
        WrSel_area_test1_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_3 =>
        WrSel_area_test2_3 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_2 =>
        WrSel_area_test2_2 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_1 =>
        WrSel_area_test2_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_0 =>
        WrSel_area_test2_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test3_1 =>
        WrSel_area_test3_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test3_0 =>
        WrSel_area_test3_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_3 =>
        WrSel_area_test4_3 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_2 =>
        WrSel_area_test4_2 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_1 =>
        WrSel_area_test4_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_0 =>
        WrSel_area_test4_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test5_1 =>
        WrSel_area_test5_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test5_0 =>
        WrSel_area_test5_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test6_3 =>
        WrSel_area_test6_3 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test6_2 =>
        WrSel_area_test6_2 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test6_1 =>
        WrSel_area_test6_1 <= '1';
        Loc_area_CRegWrOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test6_0 =>
        WrSel_area_test6_0 <= '1';
        Loc_area_CRegWrOK <= '1';
      when others =>
        Loc_area_CRegWrOK <= '0';
      end case;
    else
      Loc_area_CRegWrOK <= '0';
    end if;
  end process area_WrSelDec;

  area_CRegRdMux: process (VMEAddr, Loc_area_test1, Loc_area_test2, Loc_area_test3, Loc_area_test4, Loc_area_test5, Loc_area_test6) begin
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      case VMEAddr(18 downto 1) is
      when C_Reg_areaCRegsRegsMemsER_area_test1_1 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test1(15 downto 8)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test1_0 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test1(7 downto 0)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_3 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test2(31 downto 24)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_2 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test2(23 downto 16)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_1 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test2(15 downto 8)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test2_0 =>
        Loc_area_CRegRdData <= std_logic_vector(resize(unsigned(Loc_area_test2(7 downto 0)), 16));
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test3_1 =>
        Loc_area_CRegRdData <= Loc_area_test3(31 downto 16);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test3_0 =>
        Loc_area_CRegRdData <= Loc_area_test3(15 downto 0);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_3 =>
        Loc_area_CRegRdData <= Loc_area_test4(63 downto 48);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_2 =>
        Loc_area_CRegRdData <= Loc_area_test4(47 downto 32);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_1 =>
        Loc_area_CRegRdData <= Loc_area_test4(31 downto 16);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test4_0 =>
        Loc_area_CRegRdData <= Loc_area_test4(15 downto 0);
        Loc_area_CRegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test5_1 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when C_Reg_areaCRegsRegsMemsER_area_test5_0 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when C_Reg_areaCRegsRegsMemsER_area_test6_3 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when C_Reg_areaCRegsRegsMemsER_area_test6_2 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when C_Reg_areaCRegsRegsMemsER_area_test6_1 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when C_Reg_areaCRegsRegsMemsER_area_test6_0 =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      when others =>
        Loc_area_CRegRdData <= (others => '0');
        Loc_area_CRegRdOK <= '0';
      end case;
    else
      Loc_area_CRegRdData <= (others => '0');
      Loc_area_CRegRdOK <= '0';
    end if;
  end process area_CRegRdMux;

  area_CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_CRegRdData <= Loc_area_CRegRdData;
      area_CRegRdOK <= Loc_area_CRegRdOK;
      area_CRegWrOK <= Loc_area_CRegWrOK;
    end if;
  end process area_CRegRdMux_DFF;

  area_RegRdMux: process (VMEAddr, area_CRegRdData, area_CRegRdOK, Loc_area_test7, Loc_area_test8) begin
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      case VMEAddr(18 downto 1) is
      when C_Reg_areaCRegsRegsMemsER_area_test7_3 =>
        Loc_area_RegRdData <= Loc_area_test7(63 downto 48);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test7_2 =>
        Loc_area_RegRdData <= Loc_area_test7(47 downto 32);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test7_1 =>
        Loc_area_RegRdData <= Loc_area_test7(31 downto 16);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test7_0 =>
        Loc_area_RegRdData <= Loc_area_test7(15 downto 0);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test8_3 =>
        Loc_area_RegRdData <= Loc_area_test8(63 downto 48);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test8_2 =>
        Loc_area_RegRdData <= Loc_area_test8(47 downto 32);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test8_1 =>
        Loc_area_RegRdData <= Loc_area_test8(31 downto 16);
        Loc_area_RegRdOK <= '1';
      when C_Reg_areaCRegsRegsMemsER_area_test8_0 =>
        Loc_area_RegRdData <= Loc_area_test8(15 downto 0);
        Loc_area_RegRdOK <= '1';
      when others =>
        Loc_area_RegRdData <= area_CRegRdData;
        Loc_area_RegRdOK <= area_CRegRdOK;
      end case;
    else
      Loc_area_RegRdData <= area_CRegRdData;
      Loc_area_RegRdOK <= area_CRegRdOK;
    end if;
  end process area_RegRdMux;

  area_RegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_RegRdData <= Loc_area_RegRdData;
      area_RegRdOK <= Loc_area_RegRdOK;
    end if;
  end process area_RegRdMux_DFF;

  area_RegRdDone <= Loc_VMERdMem(2) and area_RegRdOK;
  area_RegWrDone <= Loc_VMEWrMem(1) and area_CRegWrOK;

  area_MemRdMux: process (VMEAddr, area_RegRdData, area_RegRdDone, area_mem1_RdData, area_mem1_RdDone, area_mem2_RdData, area_mem2_RdDone) begin
    Sel_area_mem1 <= '0';
    Sel_area_mem2 <= '0';
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      if VMEAddr(18 downto 1) >= C_Mem_areaCRegsRegsMemsER_area_mem1_Sta and VMEAddr(18 downto 1) <= C_Mem_areaCRegsRegsMemsER_area_mem1_End then
        Sel_area_mem1 <= '1';
        Loc_area_MemRdData <= area_mem1_RdData;
        Loc_area_MemRdDone <= area_mem1_RdDone;
      elsif VMEAddr(18 downto 1) >= C_Mem_areaCRegsRegsMemsER_area_mem2_Sta and VMEAddr(18 downto 1) <= C_Mem_areaCRegsRegsMemsER_area_mem2_End then
        Sel_area_mem2 <= '1';
        Loc_area_MemRdData <= area_mem2_RdData;
        Loc_area_MemRdDone <= area_mem2_RdDone;
      else
        Loc_area_MemRdData <= area_RegRdData;
        Loc_area_MemRdDone <= area_RegRdDone;
      end if;
    else
      Loc_area_MemRdData <= area_RegRdData;
      Loc_area_MemRdDone <= area_RegRdDone;
    end if;
  end process area_MemRdMux;

  area_MemRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_MemRdData <= Loc_area_MemRdData;
      area_MemRdDone <= Loc_area_MemRdDone;
    end if;
  end process area_MemRdMux_DFF;

  area_MemWrMux: process (VMEAddr, area_RegWrDone, area_mem1_WrDone, area_mem2_WrDone) begin
    if VMEAddr(19 downto 19) = C_Area_areaCRegsRegsMemsER_area then
      if VMEAddr(18 downto 1) >= C_Mem_areaCRegsRegsMemsER_area_mem1_Sta and VMEAddr(18 downto 1) <= C_Mem_areaCRegsRegsMemsER_area_mem1_End then
        Loc_area_MemWrDone <= area_mem1_WrDone;
      elsif VMEAddr(18 downto 1) >= C_Mem_areaCRegsRegsMemsER_area_mem2_Sta and VMEAddr(18 downto 1) <= C_Mem_areaCRegsRegsMemsER_area_mem2_End then
        Loc_area_MemWrDone <= area_mem2_WrDone;
      else
        Loc_area_MemWrDone <= area_RegWrDone;
      end if;
    else
      Loc_area_MemWrDone <= area_RegWrDone;
    end if;
  end process area_MemWrMux;

  area_MemWrMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      area_MemWrDone <= Loc_area_MemWrDone;
    end if;
  end process area_MemWrMux_DFF;

  area_mem1_Addr <= VMEAddr(9 downto 1);
  area_mem1_Sel <= Sel_area_mem1;
  area_mem1_RdMem <= Sel_area_mem1 and VMERdMem;
  area_mem1_WrMem <= Sel_area_mem1 and VMEWrMem;
  area_mem1_WrData <= VMEWrData;

  area_mem2_Addr <= VMEAddr(9 downto 1);
  area_mem2_Sel <= Sel_area_mem2;
  area_mem2_RdMem <= Sel_area_mem2 and VMERdMem;
  area_mem2_WrMem <= Sel_area_mem2 and VMEWrMem;
  area_mem2_WrData <= VMEWrData;

  area_RdData <= area_MemRdData;
  area_RdDone <= area_MemRdDone;
  area_WrDone <= area_MemWrDone;

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
