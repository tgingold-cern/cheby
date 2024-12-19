library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone_pkg.all;

entity bran_wb is
  port (
    rst_n_i              : in    std_logic;
    clk_i                : in    std_logic;
    wb_i                 : in    t_wishbone_slave_in;
    wb_o                 : out   t_wishbone_slave_out;

    -- REG Token
    Token_i              : in    std_logic_vector(31 downto 0);

    -- REG Ctrl
    Enable_o             : out   std_logic;
    std_rst_bst_desync   : out   std_logic;
    std_reset_alignment  : out   std_logic;
    DisableADCStream_o   : out   std_logic;
    EnableTurnEmulator_o : out   std_logic;
    -- Bit indicates whether turn emulator shall provide LHC or SPS timing. If this bit is set, the turn emulator will provide turn clock once every 3564 bunch clocks. Otherwise the turn emulator will emulate SPS timing with its 924 bunch slots
    LHC_timing           : out   std_logic;

    -- REG Stat
    FmcLos_i             : in    std_logic;
    FmcLol_i             : in    std_logic;
    SysrefFail_i         : in    std_logic;
    DCDCSyncEnabled_i    : in    std_logic;
    PatternFail_i        : in    std_logic;
    std_fa_in_reset      : in    std_logic;
    GBTPLLLol_i          : in    std_logic;
    std_bst_desynced     : in    std_logic;
    VfmcDisabled_i       : in    std_logic;
    NoTurnDetected_i     : in    std_logic;
    TurnEmulatorError_i  : in    std_logic;
    TurnEmulatorPLLError_i : in    std_logic;
    JesdRXNotReady_i     : in    std_logic_vector(7 downto 0);
    VoltageFail_i        : in    std_logic_vector(7 downto 0);

    -- REG SysrefTicks
    SysrefTicks_i        : in    std_logic_vector(31 downto 0);

    -- REG GWRevision
    GWRevision_i         : in    std_logic_vector(31 downto 0);

    -- REG TurnPeriod
    TurnPeriod_o         : out   std_logic_vector(31 downto 0);
    TurnPeriod_wr_o      : out   std_logic;

    -- REG TurnLength
    TurnLength_o         : out   std_logic_vector(31 downto 0);
    TurnLength_wr_o      : out   std_logic;

    -- REG TurnsIntercepted
    TurnsIntercepted_b32 : in    std_logic_vector(31 downto 0);

    -- REG FmcPower
    FmcPowerEnable_o     : out   std_logic;
    DCDCSyncEnable_o     : out   std_logic;

    -- REG ADCPatternCheckCtrl
    PatternRst_o         : out   std_logic;

    -- REG ADCCtrl
    ADCRst_o             : out   std_logic;
    ADCEnable_o          : out   std_logic;
    ADCManualSync_o      : out   std_logic;
    ADCDisableAutoSync_o : out   std_logic;

    -- REG JesdLink
    JesdXcvrRst_o        : out   std_logic;
    JesdLinkRst_o        : out   std_logic;
    JesdPLLRst_o         : out   std_logic;
    JesdAvsRst_o         : out   std_logic;
    SixxRst_o            : out   std_logic;
    JesdLinkReady_o      : out   std_logic;
    JesdEnableSysref_o   : out   std_logic;

    -- REG AdcSpiWrite
    AdcSpiWrite_o        : out   std_logic_vector(31 downto 0);
    AdcSpiWrite_wr_o     : out   std_logic;

    -- REG AdcSpiRead
    AdcSpiRead_i         : in    std_logic_vector(31 downto 0);

    -- REG SpiStatus
    AdcSpiBusy_i         : in    std_logic;

    -- REG CummulativeTurns
    cummulative_turns_b32 : out   std_logic_vector(31 downto 0);

    -- REG Debug
    OverrideTurnEmulatorTiming : out   std_logic;

    -- SRAM bus RawData0
    RawData0_addr_o      : out   std_logic_vector(17 downto 2);
    RawData0_data_i      : in    std_logic_vector(31 downto 0);

    -- SRAM bus RawData1
    RawData1_addr_o      : out   std_logic_vector(17 downto 2);
    RawData1_data_i      : in    std_logic_vector(31 downto 0);

    -- SRAM bus RawData2
    RawData2_addr_o      : out   std_logic_vector(17 downto 2);
    RawData2_data_i      : in    std_logic_vector(31 downto 0);

    -- SRAM bus RawData3
    RawData3_addr_o      : out   std_logic_vector(17 downto 2);
    RawData3_data_i      : in    std_logic_vector(31 downto 0)
  );
end bran_wb;

architecture syn of bran_wb is
  signal adr_int                        : std_logic_vector(20 downto 2);
  signal rd_req_int                     : std_logic;
  signal wr_req_int                     : std_logic;
  signal rd_ack_int                     : std_logic;
  signal wr_ack_int                     : std_logic;
  signal wb_en                          : std_logic;
  signal ack_int                        : std_logic;
  signal wb_rip                         : std_logic;
  signal wb_wip                         : std_logic;
  signal Enable_reg                     : std_logic;
  signal RstBstDesync_reg               : std_logic;
  signal FAReset_reg                    : std_logic;
  signal DisableADCStream_reg           : std_logic;
  signal EnableTurnEmulator_reg         : std_logic;
  signal LHCTiming_reg                  : std_logic;
  signal Ctrl_wreq                      : std_logic;
  signal Ctrl_wack                      : std_logic;
  signal TurnPeriod_reg                 : std_logic_vector(31 downto 0) := "00000000000000000000010000000000";
  signal TurnPeriod_wreq                : std_logic;
  signal TurnPeriod_wack                : std_logic;
  signal TurnPeriod_wstrb               : std_logic;
  signal TurnLength_reg                 : std_logic_vector(31 downto 0) := "00000000000000000000000000000011";
  signal TurnLength_wreq                : std_logic;
  signal TurnLength_wack                : std_logic;
  signal TurnLength_wstrb               : std_logic;
  signal FmcPowerEnable_reg             : std_logic;
  signal DCDCSyncEnable_reg             : std_logic;
  signal FmcPower_wreq                  : std_logic;
  signal FmcPower_wack                  : std_logic;
  signal PatternRst_reg                 : std_logic;
  signal ADCPatternCheckCtrl_wreq       : std_logic;
  signal ADCPatternCheckCtrl_wack       : std_logic;
  signal ADCRst_reg                     : std_logic;
  signal ADCEnable_reg                  : std_logic;
  signal ADCManualSync_reg              : std_logic;
  signal ADCDisableAutoSync_reg         : std_logic;
  signal ADCCtrl_wreq                   : std_logic;
  signal ADCCtrl_wack                   : std_logic;
  signal JesdXcvrRst_reg                : std_logic;
  signal JesdLinkRst_reg                : std_logic;
  signal JesdPLLRst_reg                 : std_logic;
  signal JesdAvsRst_reg                 : std_logic;
  signal SixxRst_reg                    : std_logic;
  signal JesdLinkReady_reg              : std_logic;
  signal JesdEnableSysref_reg           : std_logic;
  signal JesdLink_wreq                  : std_logic;
  signal JesdLink_wack                  : std_logic;
  signal AdcSpiWrite_reg                : std_logic_vector(31 downto 0);
  signal AdcSpiWrite_wreq               : std_logic;
  signal AdcSpiWrite_wack               : std_logic;
  signal AdcSpiWrite_wstrb              : std_logic;
  signal CummulativeTurns_reg           : std_logic_vector(31 downto 0);
  signal CummulativeTurns_wreq          : std_logic;
  signal CummulativeTurns_wack          : std_logic;
  signal OverrideTurnEmulatorTiming_reg : std_logic;
  signal Debug_wreq                     : std_logic;
  signal Debug_wack                     : std_logic;
  signal RawData0_rack                  : std_logic;
  signal RawData0_re                    : std_logic;
  signal RawData1_rack                  : std_logic;
  signal RawData1_re                    : std_logic;
  signal RawData2_rack                  : std_logic;
  signal RawData2_re                    : std_logic;
  signal RawData3_rack                  : std_logic;
  signal RawData3_re                    : std_logic;
  signal rd_ack_d0                      : std_logic;
  signal rd_dat_d0                      : std_logic_vector(31 downto 0);
  signal wr_req_d0                      : std_logic;
  signal wr_adr_d0                      : std_logic_vector(20 downto 2);
  signal wr_dat_d0                      : std_logic_vector(31 downto 0);
begin

  -- WB decode signals
  adr_int <= wb_i.adr(20 downto 2);
  wb_en <= wb_i.cyc and wb_i.stb;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_rip <= '0';
      else
        wb_rip <= (wb_rip or (wb_en and not wb_i.we)) and not rd_ack_int;
      end if;
    end if;
  end process;
  rd_req_int <= (wb_en and not wb_i.we) and not wb_rip;

  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        wb_wip <= '0';
      else
        wb_wip <= (wb_wip or (wb_en and wb_i.we)) and not wr_ack_int;
      end if;
    end if;
  end process;
  wr_req_int <= (wb_en and wb_i.we) and not wb_wip;

  ack_int <= rd_ack_int or wr_ack_int;
  wb_o.ack <= ack_int;
  wb_o.stall <= not ack_int and wb_en;
  wb_o.rty <= '0';
  wb_o.err <= '0';

  -- pipelining for wr-in+rd-out
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        rd_ack_int <= '0';
        wb_o.dat <= "00000000000000000000000000000000";
        wr_req_d0 <= '0';
        wr_adr_d0 <= "0000000000000000000";
        wr_dat_d0 <= "00000000000000000000000000000000";
      else
        rd_ack_int <= rd_ack_d0;
        wb_o.dat <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb_i.dat;
      end if;
    end if;
  end process;

  -- Register Token

  -- Register Ctrl
  Enable_o <= Enable_reg;
  std_rst_bst_desync <= RstBstDesync_reg;
  std_reset_alignment <= FAReset_reg;
  DisableADCStream_o <= DisableADCStream_reg;
  EnableTurnEmulator_o <= EnableTurnEmulator_reg;
  LHC_timing <= LHCTiming_reg;
  Ctrl_wack <= Ctrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        Enable_reg <= '0';
        RstBstDesync_reg <= '0';
        FAReset_reg <= '0';
        DisableADCStream_reg <= '0';
        EnableTurnEmulator_reg <= '0';
        LHCTiming_reg <= '0';
      else
        if Ctrl_wreq = '1' then
          Enable_reg <= wr_dat_d0(0);
          RstBstDesync_reg <= wr_dat_d0(1);
          FAReset_reg <= wr_dat_d0(2);
          DisableADCStream_reg <= wr_dat_d0(4);
          EnableTurnEmulator_reg <= wr_dat_d0(6);
          LHCTiming_reg <= wr_dat_d0(10);
        else
          RstBstDesync_reg <= '0';
          FAReset_reg <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Register Stat

  -- Register SysrefTicks

  -- Register GWRevision

  -- Register TurnPeriod
  TurnPeriod_o <= TurnPeriod_reg;
  TurnPeriod_wack <= TurnPeriod_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        TurnPeriod_reg <= "00000000000000000000010000000000";
        TurnPeriod_wstrb <= '0';
      else
        if TurnPeriod_wreq = '1' then
          TurnPeriod_reg <= wr_dat_d0;
        end if;
        TurnPeriod_wstrb <= TurnPeriod_wreq;
      end if;
    end if;
  end process;
  TurnPeriod_wr_o <= TurnPeriod_wstrb;

  -- Register TurnLength
  TurnLength_o <= TurnLength_reg;
  TurnLength_wack <= TurnLength_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        TurnLength_reg <= "00000000000000000000000000000011";
        TurnLength_wstrb <= '0';
      else
        if TurnLength_wreq = '1' then
          TurnLength_reg <= wr_dat_d0;
        end if;
        TurnLength_wstrb <= TurnLength_wreq;
      end if;
    end if;
  end process;
  TurnLength_wr_o <= TurnLength_wstrb;

  -- Register TurnsIntercepted

  -- Register FmcPower
  FmcPowerEnable_o <= FmcPowerEnable_reg;
  DCDCSyncEnable_o <= DCDCSyncEnable_reg;
  FmcPower_wack <= FmcPower_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        FmcPowerEnable_reg <= '0';
        DCDCSyncEnable_reg <= '0';
      else
        if FmcPower_wreq = '1' then
          FmcPowerEnable_reg <= wr_dat_d0(0);
          DCDCSyncEnable_reg <= wr_dat_d0(1);
        end if;
      end if;
    end if;
  end process;

  -- Register ADCPatternCheckCtrl
  PatternRst_o <= PatternRst_reg;
  ADCPatternCheckCtrl_wack <= ADCPatternCheckCtrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        PatternRst_reg <= '0';
      else
        if ADCPatternCheckCtrl_wreq = '1' then
          PatternRst_reg <= wr_dat_d0(0);
        end if;
      end if;
    end if;
  end process;

  -- Register ADCCtrl
  ADCRst_o <= ADCRst_reg;
  ADCEnable_o <= ADCEnable_reg;
  ADCManualSync_o <= ADCManualSync_reg;
  ADCDisableAutoSync_o <= ADCDisableAutoSync_reg;
  ADCCtrl_wack <= ADCCtrl_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        ADCRst_reg <= '0';
        ADCEnable_reg <= '0';
        ADCManualSync_reg <= '0';
        ADCDisableAutoSync_reg <= '0';
      else
        if ADCCtrl_wreq = '1' then
          ADCRst_reg <= wr_dat_d0(0);
          ADCEnable_reg <= wr_dat_d0(1);
          ADCManualSync_reg <= wr_dat_d0(6);
          ADCDisableAutoSync_reg <= wr_dat_d0(7);
        end if;
      end if;
    end if;
  end process;

  -- Register JesdLink
  JesdXcvrRst_o <= JesdXcvrRst_reg;
  JesdLinkRst_o <= JesdLinkRst_reg;
  JesdPLLRst_o <= JesdPLLRst_reg;
  JesdAvsRst_o <= JesdAvsRst_reg;
  SixxRst_o <= SixxRst_reg;
  JesdLinkReady_o <= JesdLinkReady_reg;
  JesdEnableSysref_o <= JesdEnableSysref_reg;
  JesdLink_wack <= JesdLink_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        JesdXcvrRst_reg <= '0';
        JesdLinkRst_reg <= '0';
        JesdPLLRst_reg <= '0';
        JesdAvsRst_reg <= '0';
        SixxRst_reg <= '0';
        JesdLinkReady_reg <= '0';
        JesdEnableSysref_reg <= '0';
      else
        if JesdLink_wreq = '1' then
          JesdXcvrRst_reg <= wr_dat_d0(0);
          JesdLinkRst_reg <= wr_dat_d0(2);
          JesdPLLRst_reg <= wr_dat_d0(4);
          JesdAvsRst_reg <= wr_dat_d0(5);
          SixxRst_reg <= wr_dat_d0(6);
          JesdLinkReady_reg <= wr_dat_d0(8);
          JesdEnableSysref_reg <= wr_dat_d0(9);
        end if;
      end if;
    end if;
  end process;

  -- Register AdcSpiWrite
  AdcSpiWrite_o <= AdcSpiWrite_reg;
  AdcSpiWrite_wack <= AdcSpiWrite_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        AdcSpiWrite_reg <= "00000000000000000000000000000000";
        AdcSpiWrite_wstrb <= '0';
      else
        if AdcSpiWrite_wreq = '1' then
          AdcSpiWrite_reg <= wr_dat_d0;
        end if;
        AdcSpiWrite_wstrb <= AdcSpiWrite_wreq;
      end if;
    end if;
  end process;
  AdcSpiWrite_wr_o <= AdcSpiWrite_wstrb;

  -- Register AdcSpiRead

  -- Register SpiStatus

  -- Register CummulativeTurns
  cummulative_turns_b32 <= CummulativeTurns_reg;
  CummulativeTurns_wack <= CummulativeTurns_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        CummulativeTurns_reg <= "00000000000000000000000000000000";
      else
        if CummulativeTurns_wreq = '1' then
          CummulativeTurns_reg <= wr_dat_d0;
        end if;
      end if;
    end if;
  end process;

  -- Register Debug
  OverrideTurnEmulatorTiming <= OverrideTurnEmulatorTiming_reg;
  Debug_wack <= Debug_wreq;
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        OverrideTurnEmulatorTiming_reg <= '0';
      else
        if Debug_wreq = '1' then
          OverrideTurnEmulatorTiming_reg <= wr_dat_d0(0);
        end if;
      end if;
    end if;
  end process;

  -- Interface RawData0
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        RawData0_rack <= '0';
      else
        RawData0_rack <= RawData0_re and not RawData0_rack;
      end if;
    end if;
  end process;
  RawData0_addr_o <= adr_int(17 downto 2);

  -- Interface RawData1
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        RawData1_rack <= '0';
      else
        RawData1_rack <= RawData1_re and not RawData1_rack;
      end if;
    end if;
  end process;
  RawData1_addr_o <= adr_int(17 downto 2);

  -- Interface RawData2
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        RawData2_rack <= '0';
      else
        RawData2_rack <= RawData2_re and not RawData2_rack;
      end if;
    end if;
  end process;
  RawData2_addr_o <= adr_int(17 downto 2);

  -- Interface RawData3
  process (clk_i) begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        RawData3_rack <= '0';
      else
        RawData3_rack <= RawData3_re and not RawData3_rack;
      end if;
    end if;
  end process;
  RawData3_addr_o <= adr_int(17 downto 2);

  -- Process for write requests.
  process (wr_adr_d0, wr_req_d0, Ctrl_wack, TurnPeriod_wack, TurnLength_wack,
           FmcPower_wack, ADCPatternCheckCtrl_wack, ADCCtrl_wack, JesdLink_wack,
           AdcSpiWrite_wack, CummulativeTurns_wack, Debug_wack) begin
    Ctrl_wreq <= '0';
    TurnPeriod_wreq <= '0';
    TurnLength_wreq <= '0';
    FmcPower_wreq <= '0';
    ADCPatternCheckCtrl_wreq <= '0';
    ADCCtrl_wreq <= '0';
    JesdLink_wreq <= '0';
    AdcSpiWrite_wreq <= '0';
    CummulativeTurns_wreq <= '0';
    Debug_wreq <= '0';
    case wr_adr_d0(20 downto 18) is
    when "000" =>
      case wr_adr_d0(17 downto 2) is
      when "0000000000000000" =>
        -- Reg Token
        wr_ack_int <= wr_req_d0;
      when "0000000000000001" =>
        -- Reg Ctrl
        Ctrl_wreq <= wr_req_d0;
        wr_ack_int <= Ctrl_wack;
      when "0000000000000010" =>
        -- Reg Stat
        wr_ack_int <= wr_req_d0;
      when "0000000000000011" =>
        -- Reg SysrefTicks
        wr_ack_int <= wr_req_d0;
      when "0000000000000100" =>
        -- Reg GWRevision
        wr_ack_int <= wr_req_d0;
      when "0000000000000101" =>
        -- Reg TurnPeriod
        TurnPeriod_wreq <= wr_req_d0;
        wr_ack_int <= TurnPeriod_wack;
      when "0000000000000110" =>
        -- Reg TurnLength
        TurnLength_wreq <= wr_req_d0;
        wr_ack_int <= TurnLength_wack;
      when "0000000000000111" =>
        -- Reg TurnsIntercepted
        wr_ack_int <= wr_req_d0;
      when "0000000000001000" =>
        -- Reg FmcPower
        FmcPower_wreq <= wr_req_d0;
        wr_ack_int <= FmcPower_wack;
      when "0000000000001001" =>
        -- Reg ADCPatternCheckCtrl
        ADCPatternCheckCtrl_wreq <= wr_req_d0;
        wr_ack_int <= ADCPatternCheckCtrl_wack;
      when "0000000000001010" =>
        -- Reg ADCCtrl
        ADCCtrl_wreq <= wr_req_d0;
        wr_ack_int <= ADCCtrl_wack;
      when "0000000000001011" =>
        -- Reg JesdLink
        JesdLink_wreq <= wr_req_d0;
        wr_ack_int <= JesdLink_wack;
      when "0000000000001100" =>
        -- Reg AdcSpiWrite
        AdcSpiWrite_wreq <= wr_req_d0;
        wr_ack_int <= AdcSpiWrite_wack;
      when "0000000000001101" =>
        -- Reg AdcSpiRead
        wr_ack_int <= wr_req_d0;
      when "0000000000001110" =>
        -- Reg SpiStatus
        wr_ack_int <= wr_req_d0;
      when "0000000000001111" =>
        -- Reg CummulativeTurns
        CummulativeTurns_wreq <= wr_req_d0;
        wr_ack_int <= CummulativeTurns_wack;
      when "0000000000010000" =>
        -- Reg Debug
        Debug_wreq <= wr_req_d0;
        wr_ack_int <= Debug_wack;
      when others =>
        wr_ack_int <= wr_req_d0;
      end case;
    when "100" =>
      -- Memory RawData0
      wr_ack_int <= wr_req_d0;
    when "101" =>
      -- Memory RawData1
      wr_ack_int <= wr_req_d0;
    when "110" =>
      -- Memory RawData2
      wr_ack_int <= wr_req_d0;
    when "111" =>
      -- Memory RawData3
      wr_ack_int <= wr_req_d0;
    when others =>
      wr_ack_int <= wr_req_d0;
    end case;
  end process;

  -- Process for read requests.
  process (adr_int, rd_req_int, Token_i, Enable_reg, DisableADCStream_reg,
           EnableTurnEmulator_reg, LHCTiming_reg, VoltageFail_i,
           JesdRXNotReady_i, TurnEmulatorPLLError_i, TurnEmulatorError_i,
           NoTurnDetected_i, VfmcDisabled_i, std_bst_desynced, GBTPLLLol_i,
           std_fa_in_reset, PatternFail_i, DCDCSyncEnabled_i, SysrefFail_i,
           FmcLol_i, FmcLos_i, SysrefTicks_i, GWRevision_i, TurnPeriod_reg,
           TurnLength_reg, TurnsIntercepted_b32, FmcPowerEnable_reg,
           DCDCSyncEnable_reg, PatternRst_reg, ADCRst_reg, ADCEnable_reg,
           ADCManualSync_reg, ADCDisableAutoSync_reg, JesdXcvrRst_reg,
           JesdLinkRst_reg, JesdPLLRst_reg, JesdAvsRst_reg, SixxRst_reg,
           JesdLinkReady_reg, JesdEnableSysref_reg, AdcSpiRead_i, AdcSpiBusy_i,
           CummulativeTurns_reg, OverrideTurnEmulatorTiming_reg,
           RawData0_data_i, RawData0_rack, RawData1_data_i, RawData1_rack,
           RawData2_data_i, RawData2_rack, RawData3_data_i, RawData3_rack) begin
    -- By default ack read requests
    rd_dat_d0 <= (others => 'X');
    RawData0_re <= '0';
    RawData1_re <= '0';
    RawData2_re <= '0';
    RawData3_re <= '0';
    case adr_int(20 downto 18) is
    when "000" =>
      case adr_int(17 downto 2) is
      when "0000000000000000" =>
        -- Reg Token
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= Token_i;
      when "0000000000000001" =>
        -- Reg Ctrl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= Enable_reg;
        rd_dat_d0(1) <= '0';
        rd_dat_d0(2) <= '0';
        rd_dat_d0(3) <= '0';
        rd_dat_d0(4) <= DisableADCStream_reg;
        rd_dat_d0(5) <= '0';
        rd_dat_d0(6) <= EnableTurnEmulator_reg;
        rd_dat_d0(9 downto 7) <= (others => '0');
        rd_dat_d0(10) <= LHCTiming_reg;
        rd_dat_d0(31 downto 11) <= (others => '0');
      when "0000000000000010" =>
        -- Reg Stat
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(7 downto 0) <= VoltageFail_i;
        rd_dat_d0(15 downto 8) <= JesdRXNotReady_i;
        rd_dat_d0(16) <= TurnEmulatorPLLError_i;
        rd_dat_d0(17) <= '0';
        rd_dat_d0(18) <= TurnEmulatorError_i;
        rd_dat_d0(19) <= NoTurnDetected_i;
        rd_dat_d0(21 downto 20) <= (others => '0');
        rd_dat_d0(22) <= VfmcDisabled_i;
        rd_dat_d0(23) <= std_bst_desynced;
        rd_dat_d0(24) <= '0';
        rd_dat_d0(25) <= GBTPLLLol_i;
        rd_dat_d0(26) <= std_fa_in_reset;
        rd_dat_d0(27) <= PatternFail_i;
        rd_dat_d0(28) <= DCDCSyncEnabled_i;
        rd_dat_d0(29) <= SysrefFail_i;
        rd_dat_d0(30) <= FmcLol_i;
        rd_dat_d0(31) <= FmcLos_i;
      when "0000000000000011" =>
        -- Reg SysrefTicks
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= SysrefTicks_i;
      when "0000000000000100" =>
        -- Reg GWRevision
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= GWRevision_i;
      when "0000000000000101" =>
        -- Reg TurnPeriod
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= TurnPeriod_reg;
      when "0000000000000110" =>
        -- Reg TurnLength
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= TurnLength_reg;
      when "0000000000000111" =>
        -- Reg TurnsIntercepted
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= TurnsIntercepted_b32;
      when "0000000000001000" =>
        -- Reg FmcPower
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= FmcPowerEnable_reg;
        rd_dat_d0(1) <= DCDCSyncEnable_reg;
        rd_dat_d0(31 downto 2) <= (others => '0');
      when "0000000000001001" =>
        -- Reg ADCPatternCheckCtrl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= PatternRst_reg;
        rd_dat_d0(31 downto 1) <= (others => '0');
      when "0000000000001010" =>
        -- Reg ADCCtrl
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= ADCRst_reg;
        rd_dat_d0(1) <= ADCEnable_reg;
        rd_dat_d0(5 downto 2) <= (others => '0');
        rd_dat_d0(6) <= ADCManualSync_reg;
        rd_dat_d0(7) <= ADCDisableAutoSync_reg;
        rd_dat_d0(31 downto 8) <= (others => '0');
      when "0000000000001011" =>
        -- Reg JesdLink
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= JesdXcvrRst_reg;
        rd_dat_d0(1) <= '0';
        rd_dat_d0(2) <= JesdLinkRst_reg;
        rd_dat_d0(3) <= '0';
        rd_dat_d0(4) <= JesdPLLRst_reg;
        rd_dat_d0(5) <= JesdAvsRst_reg;
        rd_dat_d0(6) <= SixxRst_reg;
        rd_dat_d0(7) <= '0';
        rd_dat_d0(8) <= JesdLinkReady_reg;
        rd_dat_d0(9) <= JesdEnableSysref_reg;
        rd_dat_d0(31 downto 10) <= (others => '0');
      when "0000000000001100" =>
        -- Reg AdcSpiWrite
        rd_ack_d0 <= rd_req_int;
      when "0000000000001101" =>
        -- Reg AdcSpiRead
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= AdcSpiRead_i;
      when "0000000000001110" =>
        -- Reg SpiStatus
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= AdcSpiBusy_i;
        rd_dat_d0(31 downto 1) <= (others => '0');
      when "0000000000001111" =>
        -- Reg CummulativeTurns
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0 <= CummulativeTurns_reg;
      when "0000000000010000" =>
        -- Reg Debug
        rd_ack_d0 <= rd_req_int;
        rd_dat_d0(0) <= OverrideTurnEmulatorTiming_reg;
        rd_dat_d0(31 downto 1) <= (others => '0');
      when others =>
        rd_ack_d0 <= rd_req_int;
      end case;
    when "100" =>
      -- Memory RawData0
      rd_dat_d0 <= RawData0_data_i;
      rd_ack_d0 <= RawData0_rack;
      RawData0_re <= rd_req_int;
    when "101" =>
      -- Memory RawData1
      rd_dat_d0 <= RawData1_data_i;
      rd_ack_d0 <= RawData1_rack;
      RawData1_re <= rd_req_int;
    when "110" =>
      -- Memory RawData2
      rd_dat_d0 <= RawData2_data_i;
      rd_ack_d0 <= RawData2_rack;
      RawData2_re <= rd_req_int;
    when "111" =>
      -- Memory RawData3
      rd_dat_d0 <= RawData3_data_i;
      rd_ack_d0 <= RawData3_rack;
      RawData3_re <= rd_req_int;
    when others =>
      rd_ack_d0 <= rd_req_int;
    end case;
  end process;
end syn;
