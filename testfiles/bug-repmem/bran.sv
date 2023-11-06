
module bran_wb
  (
    t_wishbone.slave wb,

    // Block identifier - returns 0xcafebeef
    input   wire [31:0] Token_i,

    // Common controls
    // 1 enables the module
    output  wire Enable_o,
    // 1 clears BST_desync flag in stat
    output  wire std_rst_bst_desync,
    // 1 resets the frame aligner
    output  wire std_reset_alignment,
    // 1 to zeros instead of ADC data
    output  wire DisableADCStream_o,
    // 1 to use internal turn clock emulator
    output  wire EnableTurnEmulator_o,
    // Bit indicates whether turn emulator shall provide LHC or SPS timing. If this bit is set, the turn emulator will provide turn clock once every 3564 bunch clocks. Otherwise the turn emulator will emulate SPS timing with its 924 bunch slots
    output  wire LHC_timing,

    // General status work
    // 1 indicates loss of signal JESD
    input   wire FmcLos_i,
    // 1 indicates loss of lock JESD
    input   wire FmcLol_i,
    // 1 indicates error of sysref
    input   wire SysrefFail_i,
    // 1 indicates DCDC sync is enabled
    input   wire DCDCSyncEnabled_i,
    // 1 indicates ADC pattern check failed
    input   wire PatternFail_i,
    // 1 indicates FA waiting for turn clock
    input   wire std_fa_in_reset,
    // 1 if GBT PLL is not locked
    input   wire GBTPLLLol_i,
    // 1 if BST turn and bunch clock do not  match
    input   wire std_bst_desynced,
    // 1 if FMC is NOT powered
    input   wire VfmcDisabled_i,
    // 1 if no turn mark arrives to capture block
    input   wire NoTurnDetected_i,
    // 1 if turn emulator is wrongly setup
    input   wire TurnEmulatorError_i,
    // 1 if turn emulator PLL is not locked
    input   wire TurnEmulatorPLLError_i,
    // 1 for each line not ready
    input   wire [7:0] JesdRXNotReady_i,
    // 1 indicates fail of DCDC converter
    input   wire [7:0] VoltageFail_i,

    // Number of ticks detected on sysref clock
    input   wire [31:0] SysrefTicks_i,

    // Compilation time of gateware
    input   wire [31:0] GWRevision_i,

    // Turn emulator period in 8ns increments
    output  wire [31:0] TurnPeriod_o,
    output  wire TurnPeriod_wr_o,

    // Turn emulator length in 8ns increments
    output  wire [31:0] TurnLength_o,
    output  wire TurnLength_wr_o,

    // Upcounts when turn HW or emulated detected
    input   wire [31:0] TurnsIntercepted_b32,

    // Power control of the FMC mezzanine
    // Enables/disables power to FMC
    output  wire FmcPowerEnable_o,
    // Enables/disables synchronization of DCDC converters on the IAM
    output  wire DCDCSyncEnable_o,

    // ADC pattern checher module control
    // Resets pattern checking
    output  wire PatternRst_o,

    // ADC specific control register
    // ADC reset control
    output  wire ADCRst_o,
    // Enables ADC conversion
    output  wire ADCEnable_o,
    // Synchronization signal value
    output  wire ADCManualSync_o,
    // 1 = sync comes from ADCManualSync
    output  wire ADCDisableAutoSync_o,

    // JESD204B link interface control
    // JESD PHY and MAC reset
    output  wire JesdXcvrRst_o,
    // JESD Link interface reset
    output  wire JesdLinkRst_o,
    // JESD GBT PLL reset
    output  wire JesdPLLRst_o,
    // MAC wishbone infterface reset
    output  wire JesdAvsRst_o,
    // 0-1-0 to reset the FMC PLL chip
    output  wire SixxRst_o,
    // Set link to ready state
    output  wire JesdLinkReady_o,
    // Enable/disable JESD sysref signal
    output  wire JesdEnableSysref_o,

    // ADC SPI write configuration interface
    output  wire [31:0] AdcSpiWrite_o,
    output  wire AdcSpiWrite_wr_o,

    // ADC SPI read configuration interface
    input   wire [31:0] AdcSpiRead_i,

    // SPI status
    // 1 if SPI sends data to ADC
    input   wire AdcSpiBusy_i,

    // For how many turns to accumulate data
    output  wire [31:0] cummulative_turns_b32,

    // Master-of-universe-tool
    output  wire OverrideTurnEmulatorTiming,

    // SRAM bus RawData0
    output  wire [17:2] RawData0_addr_o,
    input   wire [31:0] RawData0_data_i,

    // SRAM bus RawData1
    output  wire [17:2] RawData1_addr_o,
    input   wire [31:0] RawData1_data_i,

    // SRAM bus RawData2
    output  wire [17:2] RawData2_addr_o,
    input   wire [31:0] RawData2_data_i,

    // SRAM bus RawData3
    output  wire [17:2] RawData3_addr_o,
    input   wire [31:0] RawData3_data_i
  );
  wire [20:2] adr_int;
  wire rd_req_int;
  wire wr_req_int;
  reg rd_ack_int;
  reg wr_ack_int;
  wire wb_en;
  wire ack_int;
  reg wb_rip;
  reg wb_wip;
  reg Enable_reg;
  reg RstBstDesync_reg;
  reg FAReset_reg;
  reg DisableADCStream_reg;
  reg EnableTurnEmulator_reg;
  reg LHCTiming_reg;
  reg Ctrl_wreq;
  reg Ctrl_wack;
  reg [31:0] TurnPeriod_reg;
  reg TurnPeriod_wreq;
  reg TurnPeriod_wack;
  reg [31:0] TurnLength_reg;
  reg TurnLength_wreq;
  reg TurnLength_wack;
  reg FmcPowerEnable_reg;
  reg DCDCSyncEnable_reg;
  reg FmcPower_wreq;
  reg FmcPower_wack;
  reg PatternRst_reg;
  reg ADCPatternCheckCtrl_wreq;
  reg ADCPatternCheckCtrl_wack;
  reg ADCRst_reg;
  reg ADCEnable_reg;
  reg ADCManualSync_reg;
  reg ADCDisableAutoSync_reg;
  reg ADCCtrl_wreq;
  reg ADCCtrl_wack;
  reg JesdXcvrRst_reg;
  reg JesdLinkRst_reg;
  reg JesdPLLRst_reg;
  reg JesdAvsRst_reg;
  reg SixxRst_reg;
  reg JesdLinkReady_reg;
  reg JesdEnableSysref_reg;
  reg JesdLink_wreq;
  reg JesdLink_wack;
  reg [31:0] AdcSpiWrite_reg;
  reg AdcSpiWrite_wreq;
  reg AdcSpiWrite_wack;
  reg [31:0] CummulativeTurns_reg;
  reg CummulativeTurns_wreq;
  reg CummulativeTurns_wack;
  reg OverrideTurnEmulatorTiming_reg;
  reg Debug_wreq;
  reg Debug_wack;
  reg RawData0_rack;
  reg RawData0_re;
  reg RawData1_rack;
  reg RawData1_re;
  reg RawData2_rack;
  reg RawData2_re;
  reg RawData3_rack;
  reg RawData3_re;
  reg rd_ack_d0;
  reg [31:0] rd_dat_d0;
  reg wr_req_d0;
  reg [20:2] wr_adr_d0;
  reg [31:0] wr_dat_d0;

  // WB decode signals
  always @(wb.sel)
      ;
  assign adr_int = wb.adr[20:2];
  assign wb_en = wb.cyc & wb.stb;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_rip <= 1'b0;
    else
      wb_rip <= (wb_rip | (wb_en & ~wb.we)) & ~rd_ack_int;
  end
  assign rd_req_int = (wb_en & ~wb.we) & ~wb_rip;

  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      wb_wip <= 1'b0;
    else
      wb_wip <= (wb_wip | (wb_en & wb.we)) & ~wr_ack_int;
  end
  assign wr_req_int = (wb_en & wb.we) & ~wb_wip;

  assign ack_int = rd_ack_int | wr_ack_int;
  assign wb.ack = ack_int;
  assign wb.stall = ~ack_int & wb_en;
  assign wb.rty = 1'b0;
  assign wb.err = 1'b0;

  // pipelining for wr-in+rd-out
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        rd_ack_int <= 1'b0;
        wr_req_d0 <= 1'b0;
      end
    else
      begin
        rd_ack_int <= rd_ack_d0;
        wb.dati <= rd_dat_d0;
        wr_req_d0 <= wr_req_int;
        wr_adr_d0 <= adr_int;
        wr_dat_d0 <= wb.dato;
      end
  end

  // Register Token

  // Register Ctrl
  assign Enable_o = Enable_reg;
  assign std_rst_bst_desync = RstBstDesync_reg;
  assign std_reset_alignment = FAReset_reg;
  assign DisableADCStream_o = DisableADCStream_reg;
  assign EnableTurnEmulator_o = EnableTurnEmulator_reg;
  assign LHC_timing = LHCTiming_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        Enable_reg <= 1'b0;
        RstBstDesync_reg <= 1'b0;
        FAReset_reg <= 1'b0;
        DisableADCStream_reg <= 1'b0;
        EnableTurnEmulator_reg <= 1'b0;
        LHCTiming_reg <= 1'b0;
        Ctrl_wack <= 1'b0;
      end
    else
      begin
        if (Ctrl_wreq == 1'b1)
          begin
            Enable_reg <= wr_dat_d0[0];
            RstBstDesync_reg <= wr_dat_d0[1];
            FAReset_reg <= wr_dat_d0[2];
            DisableADCStream_reg <= wr_dat_d0[4];
            EnableTurnEmulator_reg <= wr_dat_d0[6];
            LHCTiming_reg <= wr_dat_d0[10];
          end
        else
          begin
            RstBstDesync_reg <= 1'b0;
            FAReset_reg <= 1'b0;
          end
        Ctrl_wack <= Ctrl_wreq;
      end
  end

  // Register Stat

  // Register SysrefTicks

  // Register GWRevision

  // Register TurnPeriod
  assign TurnPeriod_o = TurnPeriod_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        TurnPeriod_reg <= 32'b00000000000000000000010000000000;
        TurnPeriod_wack <= 1'b0;
      end
    else
      begin
        if (TurnPeriod_wreq == 1'b1)
          TurnPeriod_reg <= wr_dat_d0;
        TurnPeriod_wack <= TurnPeriod_wreq;
      end
  end
  assign TurnPeriod_wr_o = TurnPeriod_wack;

  // Register TurnLength
  assign TurnLength_o = TurnLength_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        TurnLength_reg <= 32'b00000000000000000000000000000011;
        TurnLength_wack <= 1'b0;
      end
    else
      begin
        if (TurnLength_wreq == 1'b1)
          TurnLength_reg <= wr_dat_d0;
        TurnLength_wack <= TurnLength_wreq;
      end
  end
  assign TurnLength_wr_o = TurnLength_wack;

  // Register TurnsIntercepted

  // Register FmcPower
  assign FmcPowerEnable_o = FmcPowerEnable_reg;
  assign DCDCSyncEnable_o = DCDCSyncEnable_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        FmcPowerEnable_reg <= 1'b0;
        DCDCSyncEnable_reg <= 1'b0;
        FmcPower_wack <= 1'b0;
      end
    else
      begin
        if (FmcPower_wreq == 1'b1)
          begin
            FmcPowerEnable_reg <= wr_dat_d0[0];
            DCDCSyncEnable_reg <= wr_dat_d0[1];
          end
        FmcPower_wack <= FmcPower_wreq;
      end
  end

  // Register ADCPatternCheckCtrl
  assign PatternRst_o = PatternRst_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        PatternRst_reg <= 1'b0;
        ADCPatternCheckCtrl_wack <= 1'b0;
      end
    else
      begin
        if (ADCPatternCheckCtrl_wreq == 1'b1)
          PatternRst_reg <= wr_dat_d0[0];
        ADCPatternCheckCtrl_wack <= ADCPatternCheckCtrl_wreq;
      end
  end

  // Register ADCCtrl
  assign ADCRst_o = ADCRst_reg;
  assign ADCEnable_o = ADCEnable_reg;
  assign ADCManualSync_o = ADCManualSync_reg;
  assign ADCDisableAutoSync_o = ADCDisableAutoSync_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        ADCRst_reg <= 1'b0;
        ADCEnable_reg <= 1'b0;
        ADCManualSync_reg <= 1'b0;
        ADCDisableAutoSync_reg <= 1'b0;
        ADCCtrl_wack <= 1'b0;
      end
    else
      begin
        if (ADCCtrl_wreq == 1'b1)
          begin
            ADCRst_reg <= wr_dat_d0[0];
            ADCEnable_reg <= wr_dat_d0[1];
            ADCManualSync_reg <= wr_dat_d0[6];
            ADCDisableAutoSync_reg <= wr_dat_d0[7];
          end
        ADCCtrl_wack <= ADCCtrl_wreq;
      end
  end

  // Register JesdLink
  assign JesdXcvrRst_o = JesdXcvrRst_reg;
  assign JesdLinkRst_o = JesdLinkRst_reg;
  assign JesdPLLRst_o = JesdPLLRst_reg;
  assign JesdAvsRst_o = JesdAvsRst_reg;
  assign SixxRst_o = SixxRst_reg;
  assign JesdLinkReady_o = JesdLinkReady_reg;
  assign JesdEnableSysref_o = JesdEnableSysref_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        JesdXcvrRst_reg <= 1'b0;
        JesdLinkRst_reg <= 1'b0;
        JesdPLLRst_reg <= 1'b0;
        JesdAvsRst_reg <= 1'b0;
        SixxRst_reg <= 1'b0;
        JesdLinkReady_reg <= 1'b0;
        JesdEnableSysref_reg <= 1'b0;
        JesdLink_wack <= 1'b0;
      end
    else
      begin
        if (JesdLink_wreq == 1'b1)
          begin
            JesdXcvrRst_reg <= wr_dat_d0[0];
            JesdLinkRst_reg <= wr_dat_d0[2];
            JesdPLLRst_reg <= wr_dat_d0[4];
            JesdAvsRst_reg <= wr_dat_d0[5];
            SixxRst_reg <= wr_dat_d0[6];
            JesdLinkReady_reg <= wr_dat_d0[8];
            JesdEnableSysref_reg <= wr_dat_d0[9];
          end
        JesdLink_wack <= JesdLink_wreq;
      end
  end

  // Register AdcSpiWrite
  assign AdcSpiWrite_o = AdcSpiWrite_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        AdcSpiWrite_reg <= 32'b00000000000000000000000000000000;
        AdcSpiWrite_wack <= 1'b0;
      end
    else
      begin
        if (AdcSpiWrite_wreq == 1'b1)
          AdcSpiWrite_reg <= wr_dat_d0;
        AdcSpiWrite_wack <= AdcSpiWrite_wreq;
      end
  end
  assign AdcSpiWrite_wr_o = AdcSpiWrite_wack;

  // Register AdcSpiRead

  // Register SpiStatus

  // Register CummulativeTurns
  assign cummulative_turns_b32 = CummulativeTurns_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        CummulativeTurns_reg <= 32'b00000000000000000000000000000000;
        CummulativeTurns_wack <= 1'b0;
      end
    else
      begin
        if (CummulativeTurns_wreq == 1'b1)
          CummulativeTurns_reg <= wr_dat_d0;
        CummulativeTurns_wack <= CummulativeTurns_wreq;
      end
  end

  // Register Debug
  assign OverrideTurnEmulatorTiming = OverrideTurnEmulatorTiming_reg;
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      begin
        OverrideTurnEmulatorTiming_reg <= 1'b0;
        Debug_wack <= 1'b0;
      end
    else
      begin
        if (Debug_wreq == 1'b1)
          OverrideTurnEmulatorTiming_reg <= wr_dat_d0[0];
        Debug_wack <= Debug_wreq;
      end
  end

  // Interface RawData0
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      RawData0_rack <= 1'b0;
    else
      RawData0_rack <= RawData0_re & ~RawData0_rack;
  end
  assign RawData0_addr_o = adr_int[17:2];

  // Interface RawData1
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      RawData1_rack <= 1'b0;
    else
      RawData1_rack <= RawData1_re & ~RawData1_rack;
  end
  assign RawData1_addr_o = adr_int[17:2];

  // Interface RawData2
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      RawData2_rack <= 1'b0;
    else
      RawData2_rack <= RawData2_re & ~RawData2_rack;
  end
  assign RawData2_addr_o = adr_int[17:2];

  // Interface RawData3
  always @(posedge(wb.clk) or negedge(wb.rst_n))
  begin
    if (!wb.rst_n)
      RawData3_rack <= 1'b0;
    else
      RawData3_rack <= RawData3_re & ~RawData3_rack;
  end
  assign RawData3_addr_o = adr_int[17:2];

  // Process for write requests.
  always @(wr_adr_d0, wr_req_d0, Ctrl_wack, TurnPeriod_wack, TurnLength_wack, FmcPower_wack, ADCPatternCheckCtrl_wack, ADCCtrl_wack, JesdLink_wack, AdcSpiWrite_wack, CummulativeTurns_wack, Debug_wack)
      begin
        Ctrl_wreq <= 1'b0;
        TurnPeriod_wreq <= 1'b0;
        TurnLength_wreq <= 1'b0;
        FmcPower_wreq <= 1'b0;
        ADCPatternCheckCtrl_wreq <= 1'b0;
        ADCCtrl_wreq <= 1'b0;
        JesdLink_wreq <= 1'b0;
        AdcSpiWrite_wreq <= 1'b0;
        CummulativeTurns_wreq <= 1'b0;
        Debug_wreq <= 1'b0;
        case (wr_adr_d0[20:18])
        3'b000:
          case (wr_adr_d0[17:2])
          16'b0000000000000000:
            // Reg Token
            wr_ack_int <= wr_req_d0;
          16'b0000000000000001:
            begin
              // Reg Ctrl
              Ctrl_wreq <= wr_req_d0;
              wr_ack_int <= Ctrl_wack;
            end
          16'b0000000000000010:
            // Reg Stat
            wr_ack_int <= wr_req_d0;
          16'b0000000000000011:
            // Reg SysrefTicks
            wr_ack_int <= wr_req_d0;
          16'b0000000000000100:
            // Reg GWRevision
            wr_ack_int <= wr_req_d0;
          16'b0000000000000101:
            begin
              // Reg TurnPeriod
              TurnPeriod_wreq <= wr_req_d0;
              wr_ack_int <= TurnPeriod_wack;
            end
          16'b0000000000000110:
            begin
              // Reg TurnLength
              TurnLength_wreq <= wr_req_d0;
              wr_ack_int <= TurnLength_wack;
            end
          16'b0000000000000111:
            // Reg TurnsIntercepted
            wr_ack_int <= wr_req_d0;
          16'b0000000000001000:
            begin
              // Reg FmcPower
              FmcPower_wreq <= wr_req_d0;
              wr_ack_int <= FmcPower_wack;
            end
          16'b0000000000001001:
            begin
              // Reg ADCPatternCheckCtrl
              ADCPatternCheckCtrl_wreq <= wr_req_d0;
              wr_ack_int <= ADCPatternCheckCtrl_wack;
            end
          16'b0000000000001010:
            begin
              // Reg ADCCtrl
              ADCCtrl_wreq <= wr_req_d0;
              wr_ack_int <= ADCCtrl_wack;
            end
          16'b0000000000001011:
            begin
              // Reg JesdLink
              JesdLink_wreq <= wr_req_d0;
              wr_ack_int <= JesdLink_wack;
            end
          16'b0000000000001100:
            begin
              // Reg AdcSpiWrite
              AdcSpiWrite_wreq <= wr_req_d0;
              wr_ack_int <= AdcSpiWrite_wack;
            end
          16'b0000000000001101:
            // Reg AdcSpiRead
            wr_ack_int <= wr_req_d0;
          16'b0000000000001110:
            // Reg SpiStatus
            wr_ack_int <= wr_req_d0;
          16'b0000000000001111:
            begin
              // Reg CummulativeTurns
              CummulativeTurns_wreq <= wr_req_d0;
              wr_ack_int <= CummulativeTurns_wack;
            end
          16'b0000000000010000:
            begin
              // Reg Debug
              Debug_wreq <= wr_req_d0;
              wr_ack_int <= Debug_wack;
            end
          default:
            wr_ack_int <= wr_req_d0;
          endcase
        3'b100:
          // Memory RawData0
          wr_ack_int <= wr_req_d0;
        3'b101:
          // Memory RawData1
          wr_ack_int <= wr_req_d0;
        3'b110:
          // Memory RawData2
          wr_ack_int <= wr_req_d0;
        3'b111:
          // Memory RawData3
          wr_ack_int <= wr_req_d0;
        default:
          wr_ack_int <= wr_req_d0;
        endcase
      end

  // Process for read requests.
  always @(adr_int, rd_req_int, Token_i, Enable_reg, DisableADCStream_reg, EnableTurnEmulator_reg, LHCTiming_reg, VoltageFail_i, JesdRXNotReady_i, TurnEmulatorPLLError_i, TurnEmulatorError_i, NoTurnDetected_i, VfmcDisabled_i, std_bst_desynced, GBTPLLLol_i, std_fa_in_reset, PatternFail_i, DCDCSyncEnabled_i, SysrefFail_i, FmcLol_i, FmcLos_i, SysrefTicks_i, GWRevision_i, TurnPeriod_reg, TurnLength_reg, TurnsIntercepted_b32, FmcPowerEnable_reg, DCDCSyncEnable_reg, PatternRst_reg, ADCRst_reg, ADCEnable_reg, ADCManualSync_reg, ADCDisableAutoSync_reg, JesdXcvrRst_reg, JesdLinkRst_reg, JesdPLLRst_reg, JesdAvsRst_reg, SixxRst_reg, JesdLinkReady_reg, JesdEnableSysref_reg, AdcSpiRead_i, AdcSpiBusy_i, CummulativeTurns_reg, OverrideTurnEmulatorTiming_reg, RawData0_data_i, RawData0_rack, RawData1_data_i, RawData1_rack, RawData2_data_i, RawData2_rack, RawData3_data_i, RawData3_rack)
      begin
        // By default ack read requests
        rd_dat_d0 <= {32{1'bx}};
        RawData0_re <= 1'b0;
        RawData1_re <= 1'b0;
        RawData2_re <= 1'b0;
        RawData3_re <= 1'b0;
        case (adr_int[20:18])
        3'b000:
          case (adr_int[17:2])
          16'b0000000000000000:
            begin
              // Reg Token
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= Token_i;
            end
          16'b0000000000000001:
            begin
              // Reg Ctrl
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= Enable_reg;
              rd_dat_d0[1] <= 1'b0;
              rd_dat_d0[2] <= 1'b0;
              rd_dat_d0[3] <= 1'b0;
              rd_dat_d0[4] <= DisableADCStream_reg;
              rd_dat_d0[5] <= 1'b0;
              rd_dat_d0[6] <= EnableTurnEmulator_reg;
              rd_dat_d0[9:7] <= 3'b0;
              rd_dat_d0[10] <= LHCTiming_reg;
              rd_dat_d0[31:11] <= 21'b0;
            end
          16'b0000000000000010:
            begin
              // Reg Stat
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[7:0] <= VoltageFail_i;
              rd_dat_d0[15:8] <= JesdRXNotReady_i;
              rd_dat_d0[16] <= TurnEmulatorPLLError_i;
              rd_dat_d0[17] <= 1'b0;
              rd_dat_d0[18] <= TurnEmulatorError_i;
              rd_dat_d0[19] <= NoTurnDetected_i;
              rd_dat_d0[21:20] <= 2'b0;
              rd_dat_d0[22] <= VfmcDisabled_i;
              rd_dat_d0[23] <= std_bst_desynced;
              rd_dat_d0[24] <= 1'b0;
              rd_dat_d0[25] <= GBTPLLLol_i;
              rd_dat_d0[26] <= std_fa_in_reset;
              rd_dat_d0[27] <= PatternFail_i;
              rd_dat_d0[28] <= DCDCSyncEnabled_i;
              rd_dat_d0[29] <= SysrefFail_i;
              rd_dat_d0[30] <= FmcLol_i;
              rd_dat_d0[31] <= FmcLos_i;
            end
          16'b0000000000000011:
            begin
              // Reg SysrefTicks
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= SysrefTicks_i;
            end
          16'b0000000000000100:
            begin
              // Reg GWRevision
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= GWRevision_i;
            end
          16'b0000000000000101:
            begin
              // Reg TurnPeriod
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= TurnPeriod_reg;
            end
          16'b0000000000000110:
            begin
              // Reg TurnLength
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= TurnLength_reg;
            end
          16'b0000000000000111:
            begin
              // Reg TurnsIntercepted
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= TurnsIntercepted_b32;
            end
          16'b0000000000001000:
            begin
              // Reg FmcPower
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= FmcPowerEnable_reg;
              rd_dat_d0[1] <= DCDCSyncEnable_reg;
              rd_dat_d0[31:2] <= 30'b0;
            end
          16'b0000000000001001:
            begin
              // Reg ADCPatternCheckCtrl
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= PatternRst_reg;
              rd_dat_d0[31:1] <= 31'b0;
            end
          16'b0000000000001010:
            begin
              // Reg ADCCtrl
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= ADCRst_reg;
              rd_dat_d0[1] <= ADCEnable_reg;
              rd_dat_d0[5:2] <= 4'b0;
              rd_dat_d0[6] <= ADCManualSync_reg;
              rd_dat_d0[7] <= ADCDisableAutoSync_reg;
              rd_dat_d0[31:8] <= 24'b0;
            end
          16'b0000000000001011:
            begin
              // Reg JesdLink
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= JesdXcvrRst_reg;
              rd_dat_d0[1] <= 1'b0;
              rd_dat_d0[2] <= JesdLinkRst_reg;
              rd_dat_d0[3] <= 1'b0;
              rd_dat_d0[4] <= JesdPLLRst_reg;
              rd_dat_d0[5] <= JesdAvsRst_reg;
              rd_dat_d0[6] <= SixxRst_reg;
              rd_dat_d0[7] <= 1'b0;
              rd_dat_d0[8] <= JesdLinkReady_reg;
              rd_dat_d0[9] <= JesdEnableSysref_reg;
              rd_dat_d0[31:10] <= 22'b0;
            end
          16'b0000000000001100:
            // Reg AdcSpiWrite
            rd_ack_d0 <= rd_req_int;
          16'b0000000000001101:
            begin
              // Reg AdcSpiRead
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= AdcSpiRead_i;
            end
          16'b0000000000001110:
            begin
              // Reg SpiStatus
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= AdcSpiBusy_i;
              rd_dat_d0[31:1] <= 31'b0;
            end
          16'b0000000000001111:
            begin
              // Reg CummulativeTurns
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0 <= CummulativeTurns_reg;
            end
          16'b0000000000010000:
            begin
              // Reg Debug
              rd_ack_d0 <= rd_req_int;
              rd_dat_d0[0] <= OverrideTurnEmulatorTiming_reg;
              rd_dat_d0[31:1] <= 31'b0;
            end
          default:
            rd_ack_d0 <= rd_req_int;
          endcase
        3'b100:
          begin
            // Memory RawData0
            rd_dat_d0 <= RawData0_data_i;
            rd_ack_d0 <= RawData0_rack;
            RawData0_re <= rd_req_int;
          end
        3'b101:
          begin
            // Memory RawData1
            rd_dat_d0 <= RawData1_data_i;
            rd_ack_d0 <= RawData1_rack;
            RawData1_re <= rd_req_int;
          end
        3'b110:
          begin
            // Memory RawData2
            rd_dat_d0 <= RawData2_data_i;
            rd_ack_d0 <= RawData2_rack;
            RawData2_re <= rd_req_int;
          end
        3'b111:
          begin
            // Memory RawData3
            rd_dat_d0 <= RawData3_data_i;
            rd_ack_d0 <= RawData3_rack;
            RawData3_re <= rd_req_int;
          end
        default:
          rd_ack_d0 <= rd_req_int;
        endcase
      end
endmodule
