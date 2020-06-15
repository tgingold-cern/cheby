library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_muxed.all;

entity RegCtrl_muxed is
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
    muxedRegRO_channel0  : in    std_logic_vector(31 downto 0);
    muxedRegRO_channel1  : in    std_logic_vector(31 downto 0);
    muxedRegRW_channel0  : out   std_logic_vector(31 downto 0);
    muxedRegRW_channel1  : out   std_logic_vector(31 downto 0);
    regSel_channelSelect : out   std_logic_vector(15 downto 8);
    regSel_bufferSelect  : out   std_logic_vector(7 downto 0);
    Mem_Sel              : out   std_logic;
    Mem_Addr             : out   std_logic_vector(18 downto 1);
    Mem_RdData           : in    std_logic_vector(15 downto 0);
    Mem_WrData           : out   std_logic_vector(15 downto 0);
    Mem_RdMem            : out   std_logic;
    Mem_WrMem            : out   std_logic;
    Mem_RdDone           : in    std_logic;
    Mem_WrDone           : in    std_logic
  );
end RegCtrl_muxed;

architecture syn of RegCtrl_muxed is
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
  signal Loc_muxedRegRO                 : std_logic_vector(31 downto 0);
  signal Loc_muxedRegRO_channel0        : std_logic_vector(31 downto 0);
  signal Loc_muxedRegRO_channel1        : std_logic_vector(31 downto 0);
  signal RegOK_muxedRegRO               : std_logic;
  signal Loc_muxedRegRW                 : std_logic_vector(31 downto 0);
  signal Loc_muxedRegRW_channel0        : std_logic_vector(31 downto 0);
  signal Loc_muxedRegRW_channel1        : std_logic_vector(31 downto 0);
  signal RegOK_muxedRegRW               : std_logic;
  signal WrSel_muxedRegRW_1             : std_logic;
  signal WrSel_muxedRegRW_channel0_1    : std_logic;
  signal WrSel_muxedRegRW_channel1_1    : std_logic;
  signal WrSel_muxedRegRW_0             : std_logic;
  signal WrSel_muxedRegRW_channel0_0    : std_logic;
  signal WrSel_muxedRegRW_channel1_0    : std_logic;
  signal Loc_regSel                     : std_logic_vector(15 downto 0);
  signal WrSel_regSel                   : std_logic;
  signal Sel_Mem                        : std_logic;
begin
  Reg_muxedRegRW_channel0_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_muxedRegRW_channel0_1,
      AutoClrMsk           => C_ACM_muxed_muxedRegRW_1,
      Preset               => C_PSM_muxed_muxedRegRW_1,
      CReg                 => Loc_muxedRegRW_channel0(31 downto 16)
    );
  
  Reg_muxedRegRW_channel1_1: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_muxedRegRW_channel1_1,
      AutoClrMsk           => C_ACM_muxed_muxedRegRW_1,
      Preset               => C_PSM_muxed_muxedRegRW_1,
      CReg                 => Loc_muxedRegRW_channel1(31 downto 16)
    );
  
  Reg_muxedRegRW_channel0_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_muxedRegRW_channel0_0,
      AutoClrMsk           => C_ACM_muxed_muxedRegRW_0,
      Preset               => C_PSM_muxed_muxedRegRW_0,
      CReg                 => Loc_muxedRegRW_channel0(15 downto 0)
    );
  
  Reg_muxedRegRW_channel1_0: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_muxedRegRW_channel1_0,
      AutoClrMsk           => C_ACM_muxed_muxedRegRW_0,
      Preset               => C_PSM_muxed_muxedRegRW_0,
      CReg                 => Loc_muxedRegRW_channel1(15 downto 0)
    );
  
  Reg_regSel: CtrlRegN
    generic map (
      N                    => 16
    )
    port map (
      VMEWrData            => VMEWrData(15 downto 0),
      Clk                  => Clk,
      Rst                  => Rst,
      WriteMem             => VMEWrMem,
      CRegSel              => WrSel_regSel,
      AutoClrMsk           => C_ACM_muxed_regSel,
      Preset               => C_PSM_muxed_regSel,
      CReg                 => Loc_regSel(15 downto 0)
    );
  
  Loc_muxedRegRO_channel0 <= muxedRegRO_channel0;
  Loc_muxedRegRO_channel1 <= muxedRegRO_channel1;

  Reg_muxedRegRO_RdMux: process (Loc_regSel, Loc_muxedRegRO_channel0, Loc_muxedRegRO_channel1) begin
    case Loc_regSel(15 downto 8) is
    when "00000000" =>
      Loc_muxedRegRO <= Loc_muxedRegRO_channel0;
      RegOK_muxedRegRO <= '1';
    when "00000001" =>
      Loc_muxedRegRO <= Loc_muxedRegRO_channel1;
      RegOK_muxedRegRO <= '1';
    when others =>
      Loc_muxedRegRO <= (others => '0');
      RegOK_muxedRegRO <= '0';
    end case;
  end process Reg_muxedRegRO_RdMux;

  muxedRegRW_channel0 <= Loc_muxedRegRW_channel0;
  muxedRegRW_channel1 <= Loc_muxedRegRW_channel1;

  Reg_muxedRegRW_WrSelDec: process (Loc_regSel, WrSel_muxedRegRW_1, WrSel_muxedRegRW_0) begin
    WrSel_muxedRegRW_channel0_1 <= '0';
    WrSel_muxedRegRW_channel1_1 <= '0';
    WrSel_muxedRegRW_channel0_0 <= '0';
    WrSel_muxedRegRW_channel1_0 <= '0';
    case Loc_regSel(15 downto 8) is
    when "00000000" =>
      WrSel_muxedRegRW_channel0_1 <= WrSel_muxedRegRW_1;
      WrSel_muxedRegRW_channel0_0 <= WrSel_muxedRegRW_0;
    when "00000001" =>
      WrSel_muxedRegRW_channel1_1 <= WrSel_muxedRegRW_1;
      WrSel_muxedRegRW_channel1_0 <= WrSel_muxedRegRW_0;
    when others =>
    end case;
  end process Reg_muxedRegRW_WrSelDec;

  Reg_muxedRegRW_RdMux: process (Loc_regSel, Loc_muxedRegRW_channel0, Loc_muxedRegRW_channel1) begin
    case Loc_regSel(15 downto 8) is
    when "00000000" =>
      Loc_muxedRegRW <= Loc_muxedRegRW_channel0;
      RegOK_muxedRegRW <= '1';
    when "00000001" =>
      Loc_muxedRegRW <= Loc_muxedRegRW_channel1;
      RegOK_muxedRegRW <= '1';
    when others =>
      Loc_muxedRegRW <= (others => '0');
      RegOK_muxedRegRW <= '0';
    end case;
  end process Reg_muxedRegRW_RdMux;

  regSel_channelSelect <= Loc_regSel(15 downto 8);
  regSel_bufferSelect <= Loc_regSel(7 downto 0);

  WrSelDec: process (VMEAddr, RegOK_muxedRegRW) begin
    WrSel_muxedRegRW_1 <= '0';
    WrSel_muxedRegRW_0 <= '0';
    WrSel_regSel <= '0';
    case VMEAddr(19 downto 1) is
    when C_Reg_muxed_muxedRegRW_1 =>
      WrSel_muxedRegRW_1 <= '1';
      Loc_CRegWrOK <= RegOK_muxedRegRW;
    when C_Reg_muxed_muxedRegRW_0 =>
      WrSel_muxedRegRW_0 <= '1';
      Loc_CRegWrOK <= RegOK_muxedRegRW;
    when C_Reg_muxed_regSel =>
      WrSel_regSel <= '1';
      Loc_CRegWrOK <= '1';
    when others =>
      Loc_CRegWrOK <= '0';
    end case;
  end process WrSelDec;

  CRegRdMux: process (VMEAddr, Loc_muxedRegRW, Loc_regSel, RegOK_muxedRegRW) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_muxed_muxedRegRW_1 =>
      Loc_CRegRdData <= Loc_muxedRegRW(31 downto 16);
      Loc_CRegRdOK <= RegOK_muxedRegRW;
    when C_Reg_muxed_muxedRegRW_0 =>
      Loc_CRegRdData <= Loc_muxedRegRW(15 downto 0);
      Loc_CRegRdOK <= RegOK_muxedRegRW;
    when C_Reg_muxed_regSel =>
      Loc_CRegRdData <= Loc_regSel(15 downto 0);
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

  RegRdMux: process (VMEAddr, CRegRdData, CRegRdOK, Loc_muxedRegRO, RegOK_muxedRegRO) begin
    case VMEAddr(19 downto 1) is
    when C_Reg_muxed_muxedRegRO_1 =>
      Loc_RegRdData <= Loc_muxedRegRO(31 downto 16);
      Loc_RegRdOK <= RegOK_muxedRegRO;
    when C_Reg_muxed_muxedRegRO_0 =>
      Loc_RegRdData <= Loc_muxedRegRO(15 downto 0);
      Loc_RegRdOK <= RegOK_muxedRegRO;
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

  MemRdMux: process (VMEAddr, RegRdData, RegRdDone, Mem_RdData, Mem_RdDone) begin
    Sel_Mem <= '0';
    if VMEAddr(19 downto 1) >= C_Mem_muxed_Mem_Sta and VMEAddr(19 downto 1) <= C_Mem_muxed_Mem_End then
      Sel_Mem <= '1';
      Loc_MemRdData <= Mem_RdData;
      Loc_MemRdDone <= Mem_RdDone;
    else
      Loc_MemRdData <= RegRdData;
      Loc_MemRdDone <= RegRdDone;
    end if;
  end process MemRdMux;

  MemRdMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      MemRdData <= Loc_MemRdData;
      MemRdDone <= Loc_MemRdDone;
    end if;
  end process MemRdMux_DFF;

  MemWrMux: process (VMEAddr, RegWrDone, Mem_WrDone) begin
    if VMEAddr(19 downto 1) >= C_Mem_muxed_Mem_Sta and VMEAddr(19 downto 1) <= C_Mem_muxed_Mem_End then
      Loc_MemWrDone <= Mem_WrDone;
    else
      Loc_MemWrDone <= RegWrDone;
    end if;
  end process MemWrMux;

  MemWrMux_DFF: process (Clk) begin
    if rising_edge(Clk) then
      MemWrDone <= Loc_MemWrDone;
    end if;
  end process MemWrMux_DFF;

  Mem_Addr <= VMEAddr(18 downto 1);
  Mem_Sel <= Sel_Mem;
  Mem_RdMem <= Sel_Mem and VMERdMem;
  Mem_WrMem <= Sel_Mem and VMEWrMem;
  Mem_WrData <= VMEWrData;

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
