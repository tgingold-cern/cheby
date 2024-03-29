library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library CommonVisual;

use work.MemMap_cregs_srff.all;

entity RegCtrl_cregs_srff is
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
    test3                : in    std_logic_vector(31 downto 0);
    test3_SRFF           : out   std_logic_vector(31 downto 0);
    test3_ClrSRFF        : in    std_logic;
    test5                : in    std_logic_vector(63 downto 0);
    test5_SRFF           : out   std_logic_vector(63 downto 0);
    test5_ClrSRFF        : in    std_logic
  );
end RegCtrl_cregs_srff;

architecture syn of RegCtrl_cregs_srff is
  component SRFFxN
    generic (
      N : positive := 16
    );
    port (
      Clk                  : in    std_logic;
      Rst                  : in    std_logic := '0';
      Set                  : in    std_logic_vector(N-1 downto 0);
      Clr                  : in    std_logic := '0';
      Q                    : out   std_logic_vector(N-1 downto 0)
    );
  end component;

  for all : SRFFxN use entity CommonVisual.SRFFxN(V1);

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
  signal Loc_test3                      : std_logic_vector(31 downto 0);
  signal Loc_test3_SRFF                 : std_logic_vector(31 downto 0);
  signal Loc_test5                      : std_logic_vector(63 downto 0);
  signal Loc_test5_SRFF                 : std_logic_vector(63 downto 0);
begin
  SRFF_test3: SRFFxN
    generic map (
      N                    => 32
    )
    port map (
      Clk                  => Clk,
      Rst                  => Rst,
      Set                  => Loc_test3,
      Clr                  => test3_ClrSRFF,
      Q                    => Loc_test3_SRFF
    );
  
  SRFF_test5: SRFFxN
    generic map (
      N                    => 64
    )
    port map (
      Clk                  => Clk,
      Rst                  => Rst,
      Set                  => Loc_test5,
      Clr                  => test5_ClrSRFF,
      Q                    => Loc_test5_SRFF
    );
  
  test3_SRFF <= Loc_test3_SRFF;
  Loc_test3 <= test3;

  test5_SRFF <= Loc_test5_SRFF;
  Loc_test5 <= test5;

  Loc_CRegRdData <= (others => '0');
  Loc_CRegRdOK <= '0';
  Loc_CRegWrOK <= '0';

  CRegRdData <= Loc_CRegRdData;
  CRegRdOK <= Loc_CRegRdOK;
  CRegWrOK <= Loc_CRegWrOK;

  RegRdMux: process (VMEAddr, CRegRdData, CRegRdOK, Loc_test3_SRFF, Loc_test5_SRFF) begin
    case VMEAddr(19 downto 2) is
    when C_Reg_cregs_srff_test3 =>
      Loc_RegRdData <= Loc_test3_SRFF(31 downto 0);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_srff_test5_1 =>
      Loc_RegRdData <= Loc_test5_SRFF(63 downto 32);
      Loc_RegRdOK <= '1';
    when C_Reg_cregs_srff_test5_0 =>
      Loc_RegRdData <= Loc_test5_SRFF(31 downto 0);
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

  RegRdDone <= Loc_VMERdMem(1) and RegRdOK;
  RegWrDone <= Loc_VMEWrMem(0) and CRegWrOK;

  RegRdError <= Loc_VMERdMem(1) and not RegRdOK;
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
