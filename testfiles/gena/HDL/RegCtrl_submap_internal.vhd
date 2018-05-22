library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_submap_internal.all;
use work.MemMap_incCRegs.all;

entity RegCtrl_submap_internal is
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
    submap1_test1        : out   std_logic_vector(15 downto 0);
    submap1_test2        : out   std_logic_vector(15 downto 0);
    submap1_test3        : out   std_logic_vector(31 downto 0);
    submap1_test4        : out   std_logic_vector(31 downto 0);
    submap1_test5        : out   std_logic_vector(31 downto 0);
    submap1_test6        : out   std_logic_vector(31 downto 0);
    submap1_test7        : in    std_logic_vector(31 downto 0);
    submap1_test8        : in    std_logic_vector(31 downto 0)
  );
end RegCtrl_submap_internal;

architecture syn of RegCtrl_submap_internal is
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
  signal submap1_CRegRdData             : std_logic_vector(31 downto 0);
  signal submap1_CRegRdOK               : std_logic;
  signal submap1_CRegWrOK               : std_logic;
  signal Loc_submap1_CRegRdData         : std_logic_vector(31 downto 0);
  signal Loc_submap1_CRegRdOK           : std_logic;
  signal Loc_submap1_CRegWrOK           : std_logic;
  signal submap1_RegRdDone              : std_logic;
  signal submap1_RegWrDone              : std_logic;
  signal submap1_RegRdData              : std_logic_vector(31 downto 0);
  signal submap1_RegRdOK                : std_logic;
  signal Loc_submap1_RegRdData          : std_logic_vector(31 downto 0);
  signal Loc_submap1_RegRdOK            : std_logic;
  signal submap1_MemRdData              : std_logic_vector(31 downto 0);
  signal submap1_MemRdDone              : std_logic;
  signal submap1_MemWrDone              : std_logic;
  signal Loc_submap1_MemRdData          : std_logic_vector(31 downto 0);
  signal Loc_submap1_MemRdDone          : std_logic;
  signal Loc_submap1_MemWrDone          : std_logic;
  signal submap1_RdData                 : std_logic_vector(31 downto 0);
  signal submap1_RdDone                 : std_logic;
  signal submap1_WrDone                 : std_logic;
  signal submap1_RegRdError             : std_logic;
  signal submap1_RegWrError             : std_logic;
  signal submap1_MemRdError             : std_logic;
  signal submap1_MemWrError             : std_logic;
  signal Loc_submap1_MemRdError         : std_logic;
  signal Loc_submap1_MemWrError         : std_logic;
  signal submap1_RdError                : std_logic;
  signal submap1_WrError                : std_logic;
  signal Loc_submap1_test1              : std_logic_vector(15 downto 0);
  signal WrSel_submap1_test1            : std_logic;
  signal Loc_submap1_test2              : std_logic_vector(15 downto 0);
  signal WrSel_submap1_test2            : std_logic;
  signal Loc_submap1_test3              : std_logic_vector(31 downto 0);
  signal WrSel_submap1_test3            : std_logic;
  signal Loc_submap1_test4              : std_logic_vector(31 downto 0);
  signal WrSel_submap1_test4            : std_logic;
  signal Loc_submap1_test5              : std_logic_vector(31 downto 0);
  signal WrSel_submap1_test5            : std_logic;
  signal Loc_submap1_test6              : std_logic_vector(31 downto 0);
  signal WrSel_submap1_test6            : std_logic;
  signal Loc_submap1_test7              : std_logic_vector(31 downto 0);
  signal Loc_submap1_test8              : std_logic_vector(31 downto 0);

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
  RegRdError <= Loc_VMERdMem(0) and not RegRdOK;
  RegWrError <= Loc_VMEWrMem(0) and not CRegWrOK;
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

  AreaRdMux: process (VMEAddr, MemRdData, MemRdDone, submap1_RdData, submap1_RdDone, submap1_RdError) begin
    if VMEAddr(19 downto 10) = C_Submap_submap_internal_submap1 then
      RdData <= submap1_RdData;
      RdDone <= submap1_RdDone;
      RdError <= submap1_RdError;
    else
      RdData <= MemRdData;
      RdDone <= MemRdDone;
      RdError <= MemRdError;
    end if;
  end process AreaRdMux;

  AreaWrMux: process (VMEAddr, MemWrDone, submap1_WrDone, submap1_WrError) begin
    if VMEAddr(19 downto 10) = C_Submap_submap_internal_submap1 then
      WrDone <= submap1_WrDone;
      WrError <= submap1_WrError;
    else
      WrDone <= MemWrDone;
      WrError <= MemWrError;
    end if;
  end process AreaWrMux;
  Reg_submap1_test1: RMWReg
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test1,
      AutoClrMsk           => C_ACM_incCRegs_test1,
      Preset               => C_PSM_incCRegs_test1,
      CReg                 => Loc_submap1_test1(15 downto 0)
    );
  
  Reg_submap1_test2: RMWReg
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test2,
      AutoClrMsk           => C_ACM_incCRegs_test2,
      Preset               => C_PSM_incCRegs_test2,
      CReg                 => Loc_submap1_test2(15 downto 0)
    );
  
  Reg_submap1_test3: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test3,
      AutoClrMsk           => C_ACM_incCRegs_test3,
      Preset               => C_PSM_incCRegs_test3,
      CReg                 => Loc_submap1_test3(31 downto 0)
    );
  
  Reg_submap1_test4: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test4,
      AutoClrMsk           => C_ACM_incCRegs_test4,
      Preset               => C_PSM_incCRegs_test4,
      CReg                 => Loc_submap1_test4(31 downto 0)
    );
  
  Reg_submap1_test5: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test5,
      AutoClrMsk           => C_ACM_incCRegs_test5,
      Preset               => C_PSM_incCRegs_test5,
      CReg                 => Loc_submap1_test5(31 downto 0)
    );
  
  Reg_submap1_test6: CtrlRegN
    generic map (
      N                    => 32
    )
    port map (
      VMEWrData            => VMEWrData(31 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_submap1_test6,
      AutoClrMsk           => C_ACM_incCRegs_test6,
      Preset               => C_PSM_incCRegs_test6,
      CReg                 => Loc_submap1_test6(31 downto 0)
    );
  
  submap1_test1 <= Loc_submap1_test1;
  submap1_test2 <= Loc_submap1_test2;
  submap1_test3 <= Loc_submap1_test3;
  submap1_test4 <= Loc_submap1_test4;
  submap1_test5 <= Loc_submap1_test5;
  submap1_test6 <= Loc_submap1_test6;
  Loc_submap1_test7 <= submap1_test7;
  Loc_submap1_test8 <= submap1_test8;

  submap1_WrSelDec: process (VMEAddr) begin
    WrSel_submap1_test1 <= '0';
    WrSel_submap1_test2 <= '0';
    WrSel_submap1_test3 <= '0';
    WrSel_submap1_test4 <= '0';
    WrSel_submap1_test5 <= '0';
    WrSel_submap1_test6 <= '0';
    if VMEAddr(19 downto 10) = C_Submap_submap_internal_submap1 then
      case VMEAddr(9 downto 2) is
      when C_Reg_incCRegs_test1 => 
        WrSel_submap1_test1 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when C_Reg_incCRegs_test2 => 
        WrSel_submap1_test2 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when C_Reg_incCRegs_test3 => 
        WrSel_submap1_test3 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when C_Reg_incCRegs_test4 => 
        WrSel_submap1_test4 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when C_Reg_incCRegs_test5 => 
        WrSel_submap1_test5 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when C_Reg_incCRegs_test6 => 
        WrSel_submap1_test6 <= '1';
        Loc_submap1_CRegWrOK <= '1';
      when others =>
        Loc_submap1_CRegWrOK <= '0';
      end case;
    else
      Loc_submap1_CRegWrOK <= '0';
    end if;
  end process submap1_WrSelDec;

  submap1_CRegRdMux: process (VMEAddr, Loc_submap1_test1, Loc_submap1_test2, Loc_submap1_test3, Loc_submap1_test4, Loc_submap1_test5, Loc_submap1_test6) begin
    if VMEAddr(19 downto 10) = C_Submap_submap_internal_submap1 then
      case VMEAddr(9 downto 2) is
      when C_Reg_incCRegs_test1 => 
        Loc_submap1_CRegRdData <= std_logic_vector(resize(unsigned(Loc_submap1_test1(15 downto 0)), 32));
        Loc_submap1_CRegRdOK <= '1';
      when C_Reg_incCRegs_test2 => 
        Loc_submap1_CRegRdData <= std_logic_vector(resize(unsigned(Loc_submap1_test2(15 downto 0)), 32));
        Loc_submap1_CRegRdOK <= '1';
      when C_Reg_incCRegs_test3 => 
        Loc_submap1_CRegRdData <= Loc_submap1_test3(31 downto 0);
        Loc_submap1_CRegRdOK <= '1';
      when C_Reg_incCRegs_test4 => 
        Loc_submap1_CRegRdData <= Loc_submap1_test4(31 downto 0);
        Loc_submap1_CRegRdOK <= '1';
      when C_Reg_incCRegs_test5 => 
        Loc_submap1_CRegRdData <= (others => '0');
        Loc_submap1_CRegRdOK <= '0';
      when C_Reg_incCRegs_test6 => 
        Loc_submap1_CRegRdData <= (others => '0');
        Loc_submap1_CRegRdOK <= '0';
      when others =>
        Loc_submap1_CRegRdData <= (others => '0');
        Loc_submap1_CRegRdOK <= '0';
      end case;
    else
      Loc_submap1_CRegRdData <= (others => '0');
      Loc_submap1_CRegRdOK <= '0';
    end if;
  end process submap1_CRegRdMux;

  submap1_CRegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      submap1_CRegRdData <= Loc_submap1_CRegRdData;
      submap1_CRegRdOK <= Loc_submap1_CRegRdOK;
      submap1_CRegWrOK <= Loc_submap1_CRegWrOK;
    end if;
  end process submap1_CRegRdMux_DFF;

  submap1_RegRdMux: process (VMEAddr, submap1_CRegRdData, submap1_CRegRdOK, Loc_submap1_test7, Loc_submap1_test8) begin
    if VMEAddr(19 downto 10) = C_Submap_submap_internal_submap1 then
      case VMEAddr(9 downto 2) is
      when C_Reg_incCRegs_test7 => 
        Loc_submap1_RegRdData <= Loc_submap1_test7(31 downto 0);
        Loc_submap1_RegRdOK <= '1';
      when C_Reg_incCRegs_test8 => 
        Loc_submap1_RegRdData <= Loc_submap1_test8(31 downto 0);
        Loc_submap1_RegRdOK <= '1';
      when others =>
        Loc_submap1_RegRdData <= submap1_CRegRdData;
        Loc_submap1_RegRdOK <= submap1_CRegRdOK;
      end case;
    else
      Loc_submap1_RegRdData <= submap1_CRegRdData;
      Loc_submap1_RegRdOK <= submap1_CRegRdOK;
    end if;
  end process submap1_RegRdMux;

  submap1_RegRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      submap1_RegRdData <= Loc_submap1_RegRdData;
      submap1_RegRdOK <= Loc_submap1_RegRdOK;
    end if;
  end process submap1_RegRdMux_DFF;
  submap1_RegRdDone <= Loc_VMERdMem(2) and submap1_RegRdOK;
  submap1_RegWrDone <= Loc_VMEWrMem(1) and submap1_CRegWrOK;
  submap1_RegRdError <= Loc_VMERdMem(2) and not submap1_RegRdOK;
  submap1_RegWrError <= Loc_VMEWrMem(1) and not submap1_CRegWrOK;
  Loc_submap1_MemRdData <= submap1_RegRdData;
  Loc_submap1_MemRdDone <= submap1_RegRdDone;
  Loc_submap1_MemRdError <= submap1_RegRdError;
  submap1_MemRdData <= Loc_submap1_MemRdData;
  submap1_MemRdDone <= Loc_submap1_MemRdDone;
  submap1_MemRdError <= Loc_submap1_MemRdError;
  Loc_submap1_MemWrDone <= submap1_RegWrDone;
  Loc_submap1_MemWrError <= submap1_RegWrError;
  submap1_MemWrDone <= Loc_submap1_MemWrDone;
  submap1_MemWrError <= Loc_submap1_MemWrError;
  submap1_RdData <= submap1_MemRdData;
  submap1_RdDone <= submap1_MemRdDone;
  submap1_WrDone <= submap1_MemWrDone;
  submap1_RdError <= submap1_MemRdError;
  submap1_WrError <= submap1_MemWrError;

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
