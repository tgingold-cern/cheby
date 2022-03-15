library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_areaCRegs.all;

entity RegCtrl_areaCRegs is
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
    VMERdError           : out   std_logic;
    VMEWrError           : out   std_logic;
    test3                : out   std_logic_vector(31 downto 0);
    test4                : out   std_logic_vector(63 downto 0);
    area1_test1          : out   std_logic_vector(31 downto 0);
    area1_test2          : out   std_logic_vector(63 downto 0);
    area2_test1          : out   std_logic_vector(31 downto 0);
    area2_test3          : out   std_logic_vector(63 downto 0)
  );
end RegCtrl_areaCRegs;

architecture syn of RegCtrl_areaCRegs is
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
  signal RegRdError                     : std_logic;
  signal RegWrError                     : std_logic;
  signal MemRdError                     : std_logic;
  signal MemWrError                     : std_logic;
  signal Loc_MemRdError                 : std_logic;
  signal Loc_MemWrError                 : std_logic;
  signal RdError                        : std_logic;
  signal WrError                        : std_logic;
  signal Loc_test3                      : std_logic_vector(31 downto 0);
  signal WrSel_test3_1                  : std_logic;
  signal WrSel_test3_0                  : std_logic;
  signal Loc_test4                      : std_logic_vector(63 downto 0);
  signal WrSel_test4_3                  : std_logic;
  signal WrSel_test4_2                  : std_logic;
  signal WrSel_test4_1                  : std_logic;
  signal WrSel_test4_0                  : std_logic;
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
  signal area1_RegRdError               : std_logic;
  signal area1_RegWrError               : std_logic;
  signal area1_MemRdError               : std_logic;
  signal area1_MemWrError               : std_logic;
  signal Loc_area1_MemRdError           : std_logic;
  signal Loc_area1_MemWrError           : std_logic;
  signal area1_RdError                  : std_logic;
  signal area1_WrError                  : std_logic;
  signal Loc_area1_test1                : std_logic_vector(31 downto 0);
  signal WrSel_area1_test1_1            : std_logic;
  signal WrSel_area1_test1_0            : std_logic;
  signal Loc_area1_test2                : std_logic_vector(63 downto 0);
  signal WrSel_area1_test2_3            : std_logic;
  signal WrSel_area1_test2_2            : std_logic;
  signal WrSel_area1_test2_1            : std_logic;
  signal WrSel_area1_test2_0            : std_logic;
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
  signal area2_RegRdError               : std_logic;
  signal area2_RegWrError               : std_logic;
  signal area2_MemRdError               : std_logic;
  signal area2_MemWrError               : std_logic;
  signal Loc_area2_MemRdError           : std_logic;
  signal Loc_area2_MemWrError           : std_logic;
  signal area2_RdError                  : std_logic;
  signal area2_WrError                  : std_logic;
  signal Loc_area2_test1                : std_logic_vector(31 downto 0);
  signal WrSel_area2_test1_1            : std_logic;
  signal WrSel_area2_test1_0            : std_logic;
  signal Loc_area2_test3                : std_logic_vector(63 downto 0);
  signal WrSel_area2_test3_3            : std_logic;
  signal WrSel_area2_test3_2            : std_logic;
  signal WrSel_area2_test3_1            : std_logic;
  signal WrSel_area2_test3_0            : std_logic;
begin
  Reg_test3_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_1,
      AutoClrMsk           => C_ACM_areaCRegs_test3_1,
      Preset               => C_PSM_areaCRegs_test3_1,
      CReg                 => Loc_test3(31 downto 16)
    );
  
  Reg_test3_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test3_0,
      AutoClrMsk           => C_ACM_areaCRegs_test3_0,
      Preset               => C_PSM_areaCRegs_test3_0,
      CReg                 => Loc_test3(15 downto 0)
    );
  
  Reg_test4_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_3,
      AutoClrMsk           => C_ACM_areaCRegs_test4_3,
      Preset               => C_PSM_areaCRegs_test4_3,
      CReg                 => Loc_test4(63 downto 48)
    );
  
  Reg_test4_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_test4_2,
      AutoClrMsk           => C_ACM_areaCRegs_test4_2,
      Preset               => C_PSM_areaCRegs_test4_2,
      CReg                 => Loc_test4(47 downto 32)
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
      AutoClrMsk           => C_ACM_areaCRegs_test4_1,
      Preset               => C_PSM_areaCRegs_test4_1,
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
      AutoClrMsk           => C_ACM_areaCRegs_test4_0,
      Preset               => C_PSM_areaCRegs_test4_0,
      CReg                 => Loc_test4(15 downto 0)
    );
  
  test3 <= Loc_test3;

  test4 <= Loc_test4;

  WrSelDec: process (VMEAddr) begin
    WrSel_test3_1 <= '0';
    WrSel_test3_0 <= '0';
    WrSel_test4_3 <= '0';
    WrSel_test4_2 <= '0';
    WrSel_test4_1 <= '0';
    WrSel_test4_0 <= '0';
    case VMEAddr(19 downto 1) is
    when C_Reg_areaCRegs_test3_1 =>
      WrSel_test3_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_areaCRegs_test3_0 =>
      WrSel_test3_0 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_areaCRegs_test4_3 =>
      WrSel_test4_3 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_areaCRegs_test4_2 =>
      WrSel_test4_2 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_areaCRegs_test4_1 =>
      WrSel_test4_1 <= '1';
      Loc_CRegWrOK <= '1';
    when C_Reg_areaCRegs_test4_0 =>
      WrSel_test4_0 <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_test3, Loc_test4) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_areaCRegs_test3_1 =>
      Loc_CRegRdData <= Loc_test3(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_areaCRegs_test3_0 =>
      Loc_CRegRdData <= Loc_test3(15 downto 0);
      Loc_CRegRdOK <= '1';
    when C_Reg_areaCRegs_test4_3 =>
      Loc_CRegRdData <= Loc_test4(63 downto 48);
      Loc_CRegRdOK <= '1';
    when C_Reg_areaCRegs_test4_2 =>
      Loc_CRegRdData <= Loc_test4(47 downto 32);
      Loc_CRegRdOK <= '1';
    when C_Reg_areaCRegs_test4_1 =>
      Loc_CRegRdData <= Loc_test4(31 downto 16);
      Loc_CRegRdOK <= '1';
    when C_Reg_areaCRegs_test4_0 =>
      Loc_CRegRdData <= Loc_test4(15 downto 0);
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

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, area1_RdData, area1_RdDone, area1_RdError,
           area2_RdData, area2_RdDone, area2_RdError, MemRdError) begin
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area1 then
      RdData <= area1_RdData;
      RdDone <= area1_RdDone;
      RdError <= area1_RdError;
    elsif VMEAddr(19 downto 10) = C_Area_areaCRegs_area2 then
      RdData <= area2_RdData;
      RdDone <= area2_RdDone;
      RdError <= area2_RdError;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
      RdError <= MemRdError;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, area1_WrDone, area1_WrError, area2_WrDone,
           area2_WrError, MemWrError) begin
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area1 then
      WrDone <= area1_WrDone;
      WrError <= area1_WrError;
    elsif VMEAddr(19 downto 10) = C_Area_areaCRegs_area2 then
      WrDone <= area2_WrDone;
      WrError <= area2_WrError;
    else
      WrDone <= MemWrDone;
      WrError <= MemWrError;
    end if;
  end process AreaWrMux;

  Reg_area2_test1_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test1_1,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test1_1,
      Preset               => C_PSM_areaCRegs_area2_test1_1,
      CReg                 => Loc_area2_test1(31 downto 16)
    );
  
  Reg_area2_test1_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test1_0,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test1_0,
      Preset               => C_PSM_areaCRegs_area2_test1_0,
      CReg                 => Loc_area2_test1(15 downto 0)
    );
  
  Reg_area2_test3_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test3_3,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test3_3,
      Preset               => C_PSM_areaCRegs_area2_test3_3,
      CReg                 => Loc_area2_test3(63 downto 48)
    );
  
  Reg_area2_test3_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test3_2,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test3_2,
      Preset               => C_PSM_areaCRegs_area2_test3_2,
      CReg                 => Loc_area2_test3(47 downto 32)
    );
  
  Reg_area2_test3_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test3_1,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test3_1,
      Preset               => C_PSM_areaCRegs_area2_test3_1,
      CReg                 => Loc_area2_test3(31 downto 16)
    );
  
  Reg_area2_test3_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area2_test3_0,
      AutoClrMsk           => C_ACM_areaCRegs_area2_test3_0,
      Preset               => C_PSM_areaCRegs_area2_test3_0,
      CReg                 => Loc_area2_test3(15 downto 0)
    );
  
  area2_test1 <= Loc_area2_test1;

  area2_test3 <= Loc_area2_test3;

  area2_WrSelDec: process (VMEAddr) begin
    WrSel_area2_test1_1 <= '0';
    WrSel_area2_test1_0 <= '0';
    WrSel_area2_test3_3 <= '0';
    WrSel_area2_test3_2 <= '0';
    WrSel_area2_test3_1 <= '0';
    WrSel_area2_test3_0 <= '0';
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area2 then
      case VMEAddr(9 downto 1) is
      when C_Reg_areaCRegs_area2_test1_1 =>
        WrSel_area2_test1_1 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area2_test1_0 =>
        WrSel_area2_test1_0 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area2_test3_3 =>
        WrSel_area2_test3_3 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area2_test3_2 =>
        WrSel_area2_test3_2 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area2_test3_1 =>
        WrSel_area2_test3_1 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area2_test3_0 =>
        WrSel_area2_test3_0 <= '1';
        Loc_area2_CRegWrOK <= '1';
      when others =>
        Loc_area2_CRegWrOK <= '0';
      end case;
    else
      Loc_area2_CRegWrOK <= '0';
    end if;
  end process area2_WrSelDec;

  area2_CRegRdMux: process (VMEAddr, Loc_area2_test1, Loc_area2_test3) begin
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area2 then
      case VMEAddr(9 downto 1) is
      when C_Reg_areaCRegs_area2_test1_1 =>
        Loc_area2_CRegRdData <= Loc_area2_test1(31 downto 16);
        Loc_area2_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area2_test1_0 =>
        Loc_area2_CRegRdData <= Loc_area2_test1(15 downto 0);
        Loc_area2_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area2_test3_3 =>
        Loc_area2_CRegRdData <= Loc_area2_test3(63 downto 48);
        Loc_area2_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area2_test3_2 =>
        Loc_area2_CRegRdData <= Loc_area2_test3(47 downto 32);
        Loc_area2_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area2_test3_1 =>
        Loc_area2_CRegRdData <= Loc_area2_test3(31 downto 16);
        Loc_area2_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area2_test3_0 =>
        Loc_area2_CRegRdData <= Loc_area2_test3(15 downto 0);
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

  area2_RegRdError <= Loc_VMERdMem(1) and not area2_RegRdOK;
  area2_RegWrError <= Loc_VMEWrMem(1) and not area2_CRegWrOK;

  Loc_area2_MemRdData <= area2_RegRdData;
  Loc_area2_MemRdDone <= area2_RegRdDone;
  Loc_area2_MemRdError <= area2_RegRdError;

  area2_MemRdData <= Loc_area2_MemRdData;
  area2_MemRdDone <= Loc_area2_MemRdDone;
  area2_MemRdError <= Loc_area2_MemRdError;

  Loc_area2_MemWrDone <= area2_RegWrDone;
  Loc_area2_MemWrError <= area2_RegWrError;

  area2_MemWrDone <= Loc_area2_MemWrDone;
  area2_MemWrError <= Loc_area2_MemWrError;

  area2_RdData <= area2_MemRdData;
  area2_RdDone <= area2_MemRdDone;
  area2_WrDone <= area2_MemWrDone;
  area2_RdError <= area2_MemRdError;
  area2_WrError <= area2_MemWrError;

  Reg_area1_test1_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test1_1,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test1_1,
      Preset               => C_PSM_areaCRegs_area1_test1_1,
      CReg                 => Loc_area1_test1(31 downto 16)
    );
  
  Reg_area1_test1_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test1_0,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test1_0,
      Preset               => C_PSM_areaCRegs_area1_test1_0,
      CReg                 => Loc_area1_test1(15 downto 0)
    );
  
  Reg_area1_test2_3: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test2_3,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test2_3,
      Preset               => C_PSM_areaCRegs_area1_test2_3,
      CReg                 => Loc_area1_test2(63 downto 48)
    );
  
  Reg_area1_test2_2: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test2_2,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test2_2,
      Preset               => C_PSM_areaCRegs_area1_test2_2,
      CReg                 => Loc_area1_test2(47 downto 32)
    );
  
  Reg_area1_test2_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test2_1,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test2_1,
      Preset               => C_PSM_areaCRegs_area1_test2_1,
      CReg                 => Loc_area1_test2(31 downto 16)
    );
  
  Reg_area1_test2_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_area1_test2_0,
      AutoClrMsk           => C_ACM_areaCRegs_area1_test2_0,
      Preset               => C_PSM_areaCRegs_area1_test2_0,
      CReg                 => Loc_area1_test2(15 downto 0)
    );
  
  area1_test1 <= Loc_area1_test1;

  area1_test2 <= Loc_area1_test2;

  area1_WrSelDec: process (VMEAddr) begin
    WrSel_area1_test1_1 <= '0';
    WrSel_area1_test1_0 <= '0';
    WrSel_area1_test2_3 <= '0';
    WrSel_area1_test2_2 <= '0';
    WrSel_area1_test2_1 <= '0';
    WrSel_area1_test2_0 <= '0';
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area1 then
      case VMEAddr(9 downto 1) is
      when C_Reg_areaCRegs_area1_test1_1 =>
        WrSel_area1_test1_1 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area1_test1_0 =>
        WrSel_area1_test1_0 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area1_test2_3 =>
        WrSel_area1_test2_3 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area1_test2_2 =>
        WrSel_area1_test2_2 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area1_test2_1 =>
        WrSel_area1_test2_1 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when C_Reg_areaCRegs_area1_test2_0 =>
        WrSel_area1_test2_0 <= '1';
        Loc_area1_CRegWrOK <= '1';
      when others =>
        Loc_area1_CRegWrOK <= '0';
      end case;
    else
      Loc_area1_CRegWrOK <= '0';
    end if;
  end process area1_WrSelDec;

  area1_CRegRdMux: process (VMEAddr, Loc_area1_test1, Loc_area1_test2) begin
    if VMEAddr(19 downto 10) = C_Area_areaCRegs_area1 then
      case VMEAddr(9 downto 1) is
      when C_Reg_areaCRegs_area1_test1_1 =>
        Loc_area1_CRegRdData <= Loc_area1_test1(31 downto 16);
        Loc_area1_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area1_test1_0 =>
        Loc_area1_CRegRdData <= Loc_area1_test1(15 downto 0);
        Loc_area1_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area1_test2_3 =>
        Loc_area1_CRegRdData <= Loc_area1_test2(63 downto 48);
        Loc_area1_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area1_test2_2 =>
        Loc_area1_CRegRdData <= Loc_area1_test2(47 downto 32);
        Loc_area1_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area1_test2_1 =>
        Loc_area1_CRegRdData <= Loc_area1_test2(31 downto 16);
        Loc_area1_CRegRdOK <= '1';
      when C_Reg_areaCRegs_area1_test2_0 =>
        Loc_area1_CRegRdData <= Loc_area1_test2(15 downto 0);
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

  area1_RegRdError <= Loc_VMERdMem(1) and not area1_RegRdOK;
  area1_RegWrError <= Loc_VMEWrMem(1) and not area1_CRegWrOK;

  Loc_area1_MemRdData <= area1_RegRdData;
  Loc_area1_MemRdDone <= area1_RegRdDone;
  Loc_area1_MemRdError <= area1_RegRdError;

  area1_MemRdData <= Loc_area1_MemRdData;
  area1_MemRdDone <= Loc_area1_MemRdDone;
  area1_MemRdError <= Loc_area1_MemRdError;

  Loc_area1_MemWrDone <= area1_RegWrDone;
  Loc_area1_MemWrError <= area1_RegWrError;

  area1_MemWrDone <= Loc_area1_MemWrDone;
  area1_MemWrError <= Loc_area1_MemWrError;

  area1_RdData <= area1_MemRdData;
  area1_RdDone <= area1_MemRdDone;
  area1_WrDone <= area1_MemWrDone;
  area1_RdError <= area1_MemRdError;
  area1_WrError <= area1_MemWrError;

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
