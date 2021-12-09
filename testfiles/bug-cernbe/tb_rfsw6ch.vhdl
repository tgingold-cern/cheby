library ieee;
use ieee.std_logic_1164.all;

entity tb_rfsw6ch is
end tb_rfsw6ch;

architecture behav of tb_rfsw6ch is
  signal Clk                               : std_logic := '0';
  signal Rst                               : std_logic;
  signal VMEAddr                           : std_logic_vector(18 downto 1);
  signal VMERdData                         : std_logic_vector(15 downto 0);
  signal VMEWrData                         : std_logic_vector(15 downto 0);
  signal VMERdMem                          : std_logic;
  signal VMEWrMem                          : std_logic;
  signal VMERdDone                         : std_logic;
  signal VMEWrDone                         : std_logic;
  signal stdInfo_serialNumber_i            : std_logic_vector(63 downto 0);
  signal stdInfo_ident_jtagRemoteDisable_i : std_logic;
  signal stdInfo_ident_extendedID_i        : std_logic_vector(6 downto 0);
  signal stdInfo_ident_cardID_i            : std_logic_vector(7 downto 0);
  signal stdInfo_firmwareVersion_i         : std_logic_vector(31 downto 0);
  signal stdInfo_memMapVersion_i           : std_logic_vector(31 downto 0);
  signal stdInfo_echo_echo_o               : std_logic_vector(7 downto 0);
  signal control_clearFaults_o             : std_logic;
  signal control_getSerialNumber_o         : std_logic;
  signal control_enableIRQ_o               : std_logic;
  signal control_qClkPLLReset_o            : std_logic;
  signal control_xadcReset_o               : std_logic;
  signal control_faultIRQEna_o             : std_logic;
  signal status_RFSwitchStatus_i           : std_logic_vector(2 downto 0);
  signal status_vmeSNValid_i               : std_logic;
  signal status_noFaults_i                 : std_logic;
  signal status_powerOk_i                  : std_logic;
  signal status_clocksOK_i                 : std_logic;
  signal status_boardTempValid_i           : std_logic;
  signal faults_irqTimeOut_i               : std_logic;
  signal faults_irqOverRun_i               : std_logic;
  signal faults_vmeSNErr_i                 : std_logic;
  signal faults_nvMemCRC_i                 : std_logic;
  signal faults_xadc_i                     : std_logic;
  signal xadcStatus_eoc_i                  : std_logic;
  signal xadcStatus_eos_i                  : std_logic;
  signal xadcStatus_busy_i                 : std_logic;
  signal xadcStatus_jtagLocked_i           : std_logic;
  signal xadcStatus_jtagModified_i         : std_logic;
  signal xadcStatus_jtagBusy_i             : std_logic;
  signal xadcAlarms_vccaux_i               : std_logic;
  signal xadcAlarms_vccint_i               : std_logic;
  signal xadcAlarms_vbram_i                : std_logic;
  signal xadcAlarms_userTemp_i             : std_logic;
  signal xadcAlarms_overTemp_i             : std_logic;
  signal vmeIRQStatID_o                    : std_logic_vector(15 downto 0);
  signal vmeIRQLevel_irqLevel_o            : std_logic_vector(2 downto 0);
  signal vmeIRQLevel_wr_o                  : std_logic;
  signal vmeAddrCtrlStatus_DA_i            : std_logic_vector(3 downto 0);
  signal vmeAddrCtrlStatus_SA_i            : std_logic_vector(3 downto 0);
  signal vmeAddrCtrlStatus_MA_i            : std_logic_vector(3 downto 0);
  signal RFControl_RFSwitchCtrl_o          : std_logic;
  signal RFControl_RFInputSelect_o         : std_logic_vector(2 downto 0);
  signal RFControl_alarmCTRLn_o            : std_logic;
  signal nvMemStatus_i                     : std_logic_vector(15 downto 0);
  signal nvMemControl_o                    : std_logic_vector(15 downto 0);
  signal nvMemGetKey_i                     : std_logic_vector(15 downto 0);
  signal nvMemSetKey_o                     : std_logic_vector(15 downto 0);
  signal nvMemCRCVal_i                     : std_logic_vector(15 downto 0);
  signal sysControl_initialised_o          : std_logic;
  signal testControl_testLED_o             : std_logic;
  signal testControl_vmeInterrupt_o        : std_logic;
  signal testControl_clearTestTrigger_o    : std_logic;
  signal testControl_triggerTestMux_o      : std_logic_vector(3 downto 0);
  signal testStatus_triggerReceived_i      : std_logic;
  signal hardwareVersion_i                 : std_logic_vector(15 downto 0);
  signal designerID_i                      : std_logic_vector(15 downto 0);
  signal boardTemp_i                       : std_logic_vector(15 downto 0);
  signal ispPowrVersion_i                  : std_logic_vector(31 downto 0);
  signal ADCmonitoring_VMEAddr_o           : std_logic_vector(4 downto 1);
  signal ADCmonitoring_VMERdData_i         : std_logic_vector(15 downto 0);
  signal ADCmonitoring_VMEWrData_o         : std_logic_vector(15 downto 0);
  signal ADCmonitoring_VMERdMem_o          : std_logic;
  signal ADCmonitoring_VMEWrMem_o          : std_logic;
  signal ADCmonitoring_VMERdDone_i         : std_logic;
  signal ADCmonitoring_VMEWrDone_i         : std_logic;
  signal xADC_VMEAddr_o                    : std_logic_vector(7 downto 1);
  signal xADC_VMERdData_i                  : std_logic_vector(15 downto 0);
  signal xADC_VMEWrData_o                  : std_logic_vector(15 downto 0);
  signal xADC_VMERdMem_o                   : std_logic;
  signal xADC_VMEWrMem_o                   : std_logic;
  signal xADC_VMERdDone_i                  : std_logic;
  signal xADC_VMEWrDone_i                  : std_logic;
  signal RF1MaskSel_o                      : std_logic_vector(15 downto 0);
  signal RF2MaskSel_o                      : std_logic_vector(15 downto 0);
  signal RF3MaskSel_o                      : std_logic_vector(15 downto 0);
  signal RF4MaskSel_o                      : std_logic_vector(15 downto 0);
  signal RF5MaskSel_o                      : std_logic_vector(15 downto 0);
  signal RF6MaskSel_o                      : std_logic_vector(15 downto 0);
  signal far_far_data_i                    : std_logic_vector(7 downto 0);
  signal far_far_data_o                    : std_logic_vector(7 downto 0);
  signal far_far_xfer_o                    : std_logic;
  signal far_far_ready_i                   : std_logic;
  signal far_far_ready_o                   : std_logic;
  signal far_far_cs_o                      : std_logic;
  signal far_far_wr_o                      : std_logic;
begin
  Clk <= not Clk after 5 ns;

  process
  begin
    Rst <= '1';
    VMERdMem <= '0';
    VMEWrMem <= '0';

    VmeAddr <= "00" & x"0044";
    
    wait for 20 ns;
    Rst <= '0';

    if true then
      wait until rising_edge (Clk);
      VmeAddr <= b"00_0000_0000_1000_1000";
      VmeWrMem <= '1';

      wait until rising_edge (Clk);
      VmeWrMem <= '0';

      loop
        wait until rising_edge (Clk);
        exit when VmeWrDone = '1';
      end loop;
    end if;   

    wait until rising_edge (Clk);
    VmeAddr <= "00" & x"0100";
--    VmeWrData <= x"cafe";
    VmeRdMem <= '1';

    wait until rising_edge (Clk);
--    VmeAddr <= b"111";
--    VmeWrData <= x"0000";
    VmeRdMem <= '0';

    loop
      wait until rising_edge (Clk);
      exit when VmeRdDone = '1';
    end loop;

    wait until rising_edge (Clk);
    VmeAddr <= "00" & x"0000";
    
    wait;
  end process;

  RFSW6CH_regs_1: entity work.RFSW6CH_regs
    port map (
      Clk                               => Clk,
      Rst                               => Rst,
      VMEAddr                           => VMEAddr,
      VMERdData                         => VMERdData,
      VMEWrData                         => VMEWrData,
      VMERdMem                          => VMERdMem,
      VMEWrMem                          => VMEWrMem,
      VMERdDone                         => VMERdDone,
      VMEWrDone                         => VMEWrDone,
      stdInfo_serialNumber_i            => stdInfo_serialNumber_i,
      stdInfo_ident_jtagRemoteDisable_i => stdInfo_ident_jtagRemoteDisable_i,
      stdInfo_ident_extendedID_i        => stdInfo_ident_extendedID_i,
      stdInfo_ident_cardID_i            => stdInfo_ident_cardID_i,
      stdInfo_firmwareVersion_i         => stdInfo_firmwareVersion_i,
      stdInfo_memMapVersion_i           => stdInfo_memMapVersion_i,
      stdInfo_echo_echo_o               => stdInfo_echo_echo_o,
      control_clearFaults_o             => control_clearFaults_o,
      control_getSerialNumber_o         => control_getSerialNumber_o,
      control_enableIRQ_o               => control_enableIRQ_o,
      control_qClkPLLReset_o            => control_qClkPLLReset_o,
      control_xadcReset_o               => control_xadcReset_o,
      control_faultIRQEna_o             => control_faultIRQEna_o,
      status_RFSwitchStatus_i           => status_RFSwitchStatus_i,
      status_vmeSNValid_i               => status_vmeSNValid_i,
      status_noFaults_i                 => status_noFaults_i,
      status_powerOk_i                  => status_powerOk_i,
      status_clocksOK_i                 => status_clocksOK_i,
      status_boardTempValid_i           => status_boardTempValid_i,
      faults_irqTimeOut_i               => faults_irqTimeOut_i,
      faults_irqOverRun_i               => faults_irqOverRun_i,
      faults_vmeSNErr_i                 => faults_vmeSNErr_i,
      faults_nvMemCRC_i                 => faults_nvMemCRC_i,
      faults_xadc_i                     => faults_xadc_i,
      xadcStatus_eoc_i                  => xadcStatus_eoc_i,
      xadcStatus_eos_i                  => xadcStatus_eos_i,
      xadcStatus_busy_i                 => xadcStatus_busy_i,
      xadcStatus_jtagLocked_i           => xadcStatus_jtagLocked_i,
      xadcStatus_jtagModified_i         => xadcStatus_jtagModified_i,
      xadcStatus_jtagBusy_i             => xadcStatus_jtagBusy_i,
      xadcAlarms_vccaux_i               => xadcAlarms_vccaux_i,
      xadcAlarms_vccint_i               => xadcAlarms_vccint_i,
      xadcAlarms_vbram_i                => xadcAlarms_vbram_i,
      xadcAlarms_userTemp_i             => xadcAlarms_userTemp_i,
      xadcAlarms_overTemp_i             => xadcAlarms_overTemp_i,
      vmeIRQStatID_o                    => vmeIRQStatID_o,
      vmeIRQLevel_irqLevel_o            => vmeIRQLevel_irqLevel_o,
      vmeIRQLevel_wr_o                  => vmeIRQLevel_wr_o,
      vmeAddrCtrlStatus_DA_i            => vmeAddrCtrlStatus_DA_i,
      vmeAddrCtrlStatus_SA_i            => vmeAddrCtrlStatus_SA_i,
      vmeAddrCtrlStatus_MA_i            => vmeAddrCtrlStatus_MA_i,
      RFControl_RFSwitchCtrl_o          => RFControl_RFSwitchCtrl_o,
      RFControl_RFInputSelect_o         => RFControl_RFInputSelect_o,
      RFControl_alarmCTRLn_o            => RFControl_alarmCTRLn_o,
      nvMemStatus_i                     => nvMemStatus_i,
      nvMemControl_o                    => nvMemControl_o,
      nvMemGetKey_i                     => nvMemGetKey_i,
      nvMemSetKey_o                     => nvMemSetKey_o,
      nvMemCRCVal_i                     => nvMemCRCVal_i,
      sysControl_initialised_o          => sysControl_initialised_o,
      testControl_testLED_o             => testControl_testLED_o,
      testControl_vmeInterrupt_o        => testControl_vmeInterrupt_o,
      testControl_clearTestTrigger_o    => testControl_clearTestTrigger_o,
      testControl_triggerTestMux_o      => testControl_triggerTestMux_o,
      testStatus_triggerReceived_i      => testStatus_triggerReceived_i,
      hardwareVersion_i                 => hardwareVersion_i,
      designerID_i                      => designerID_i,
      boardTemp_i                       => boardTemp_i,
      ispPowrVersion_i                  => ispPowrVersion_i,
      ADCmonitoring_VMEAddr_o           => ADCmonitoring_VMEAddr_o,
      ADCmonitoring_VMERdData_i         => ADCmonitoring_VMERdData_i,
      ADCmonitoring_VMEWrData_o         => ADCmonitoring_VMEWrData_o,
      ADCmonitoring_VMERdMem_o          => ADCmonitoring_VMERdMem_o,
      ADCmonitoring_VMEWrMem_o          => ADCmonitoring_VMEWrMem_o,
      ADCmonitoring_VMERdDone_i         => ADCmonitoring_VMERdDone_i,
      ADCmonitoring_VMEWrDone_i         => ADCmonitoring_VMEWrDone_i,
      xADC_VMEAddr_o                    => xADC_VMEAddr_o,
      xADC_VMERdData_i                  => xADC_VMERdData_i,
      xADC_VMEWrData_o                  => xADC_VMEWrData_o,
      xADC_VMERdMem_o                   => xADC_VMERdMem_o,
      xADC_VMEWrMem_o                   => xADC_VMEWrMem_o,
      xADC_VMERdDone_i                  => xADC_VMERdDone_i,
      xADC_VMEWrDone_i                  => xADC_VMEWrDone_i,
      RF1MaskSel_o                      => RF1MaskSel_o,
      RF2MaskSel_o                      => RF2MaskSel_o,
      RF3MaskSel_o                      => RF3MaskSel_o,
      RF4MaskSel_o                      => RF4MaskSel_o,
      RF5MaskSel_o                      => RF5MaskSel_o,
      RF6MaskSel_o                      => RF6MaskSel_o,
      far_far_data_i                    => far_far_data_i,
      far_far_data_o                    => far_far_data_o,
      far_far_xfer_o                    => far_far_xfer_o,
      far_far_ready_i                   => far_far_ready_i,
      far_far_ready_o                   => far_far_ready_o,
      far_far_cs_o                      => far_far_cs_o,
      far_far_wr_o                      => far_far_wr_o);

  xADC_VMERdData_i <= x"cafe";
  xADC_VMEWrDone_i <= '0';

  process (Clk)
  begin
    if rising_edge (Clk) then
      xADC_VMERdDone_i <=   xADC_VMERdMem_o;
    end if;
  end process;

end behav;
