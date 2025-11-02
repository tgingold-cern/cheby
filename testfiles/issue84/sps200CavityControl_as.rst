##################
Memory Map Summary
##################

SIS-8300-KU

Memory Map for SPS TWC200 Cavity Control

For Space bar0
==============

+-------------------+--------+---------------------------------------+---------------------------------------+
| HW address        | Type   | Name                                  | HDL Name                              |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000000-0x00001f | SUBMAP | hwInfo                                | hwInfo                                |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000000          | REG    | hwInfo.stdVersion                     | hwInfo_stdVersion                     |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000008          | REG    | hwInfo.serialNumber                   | hwInfo_serialNumber                   |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000010          | REG    | hwInfo.firmwareVersion                | hwInfo_firmwareVersion                |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000014          | REG    | hwInfo.memMapVersion                  | hwInfo_memMapVersion                  |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x000018          | REG    | hwInfo.echo                           | hwInfo_echo                           |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100000-0x17ffff | SUBMAP | app                                   | app                                   |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100000-0x1003ff | SUBMAP | app.modulation                        | app_modulation                        |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100000-0x10001f | SUBMAP | app.modulation.ipInfo                 | app_modulation_ipInfo                 |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100000          | REG    | app.modulation.ipInfo.stdVersion      | app_modulation_ipInfo_stdVersion      |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100004          | REG    | app.modulation.ipInfo.ident           | app_modulation_ipInfo_ident           |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100008          | REG    | app.modulation.ipInfo.firmwareVersion | app_modulation_ipInfo_firmwareVersion |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x10000c          | REG    | app.modulation.ipInfo.memMapVersion   | app_modulation_ipInfo_memMapVersion   |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100010          | REG    | app.modulation.ipInfo.echo            | app_modulation_ipInfo_echo            |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100020          | REG    | app.modulation.control                | app_modulation_control                |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100030-0x10003f | BLOCK  | app.modulation.testSignal             | app_modulation_testSignal             |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100030          | REG    | app.modulation.testSignal.amplitude   | app_modulation_testSignal_amplitude   |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100038          | REG    | app.modulation.testSignal.ftw         | app_modulation_testSignal_ftw         |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100040-0x10004f | BLOCK  | app.modulation.staticSignal           | app_modulation_staticSignal           |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100040          | REG    | app.modulation.staticSignal.i         | app_modulation_staticSignal_i         |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100044          | REG    | app.modulation.staticSignal.q         | app_modulation_staticSignal_q         |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100050          | REG    | app.modulation.ftwH1main              | app_modulation_ftwH1main              |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100058          | REG    | app.modulation.ftwH1on                | app_modulation_ftwH1on                |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100060          | REG    | app.modulation.dftwH1slip0            | app_modulation_dftwH1slip0            |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100064          | REG    | app.modulation.dftwH1slip1            | app_modulation_dftwH1slip1            |
+-------------------+--------+---------------------------------------+---------------------------------------+
| 0x100068          | REG    | app.modulation.latches                | app_modulation_latches                |
+-------------------+--------+---------------------------------------+---------------------------------------+

For Space bar4
==============

+-----------------------+--------+-----------------------+-----------------------+
| HW address            | Type   | Name                  | HDL Name              |
+-----------------------+--------+-----------------------+-----------------------+
| 0x00000000-0x000fffff | SUBMAP | fgc_ddr               | fgc_ddr               |
+-----------------------+--------+-----------------------+-----------------------+
| 0x00000000-0x000fffff | MEMORY | fgc_ddr.data64        | fgc_ddr_data64        |
+-----------------------+--------+-----------------------+-----------------------+
|  +0x00000000          | REG    | fgc_ddr.data64.data64 | fgc_ddr_data64_data64 |
+-----------------------+--------+-----------------------+-----------------------+
| 0x20000000-0x3fffffff | SUBMAP | acq_ddr               | acq_ddr               |
+-----------------------+--------+-----------------------+-----------------------+
| 0x20000000-0x3fffffff | MEMORY | acq_ddr.data32        | acq_ddr_data32        |
+-----------------------+--------+-----------------------+-----------------------+
|  +0x20000000          | REG    | acq_ddr.data32.data32 | acq_ddr_data32_data32 |
+-----------------------+--------+-----------------------+-----------------------+
| 0x80000000-0x8001ffff | SUBMAP | acq_ram               | acq_ram               |
+-----------------------+--------+-----------------------+-----------------------+
| 0x80000000-0x8001ffff | MEMORY | acq_ram.data32        | acq_ram_data32        |
+-----------------------+--------+-----------------------+-----------------------+
|  +0x80000000          | REG    | acq_ram.data32.data32 | acq_ram_data32_data32 |
+-----------------------+--------+-----------------------+-----------------------+

Registers Description for Space bar0

=====================================

Register: hwInfo.stdVersion
---------------------------

* HW Prefix: hwInfo_stdVersion
* HW Address: 0x0
* C Prefix: hwInfo.stdVersion
* C Block Offset: 0x0
* Access: read-only

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|          platform[7:0]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

platform
  Identifying which platform the version belongs to (i.e. pci, lhc_vme, vme64, ...)
major
  Major version indicating incompatible changes
minor
  Minor version indicating feature enhancements
patch
  Patch indicating bug fixes

Register: hwInfo.serialNumber
-----------------------------

* HW Prefix: hwInfo_serialNumber
* HW Address: 0x8
* C Prefix: hwInfo.serialNumber
* C Block Offset: 0x8
* Access: read-only

HW serial number

+---+---+---+---+---+---+---+---+
| 63| 62| 61| 60| 59| 58| 57| 56|
+---+---+---+---+---+---+---+---+
|            serialNumber[63:56]|
+---+---+---+---+---+---+---+---+
| 55| 54| 53| 52| 51| 50| 49| 48|
+---+---+---+---+---+---+---+---+
|            serialNumber[55:48]|
+---+---+---+---+---+---+---+---+
| 47| 46| 45| 44| 43| 42| 41| 40|
+---+---+---+---+---+---+---+---+
|            serialNumber[47:40]|
+---+---+---+---+---+---+---+---+
| 39| 38| 37| 36| 35| 34| 33| 32|
+---+---+---+---+---+---+---+---+
|            serialNumber[39:32]|
+---+---+---+---+---+---+---+---+
| 31| 30| 29| 28| 27| 26| 25| 24|
+---+---+---+---+---+---+---+---+
|            serialNumber[31:24]|
+---+---+---+---+---+---+---+---+
| 23| 22| 21| 20| 19| 18| 17| 16|
+---+---+---+---+---+---+---+---+
|            serialNumber[23:16]|
+---+---+---+---+---+---+---+---+
| 15| 14| 13| 12| 11| 10|  9|  8|
+---+---+---+---+---+---+---+---+
|             serialNumber[15:8]|
+---+---+---+---+---+---+---+---+
|  7|  6|  5|  4|  3|  2|  1|  0|
+---+---+---+---+---+---+---+---+
|              serialNumber[7:0]|
+---+---+---+---+---+---+---+---+

Register: hwInfo.firmwareVersion
--------------------------------

* HW Prefix: hwInfo_firmwareVersion
* HW Address: 0x10
* C Prefix: hwInfo.firmwareVersion
* C Block Offset: 0x10
* Access: read-only

Firmware Version

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

major
  Major version indicating incompatible changes
minor
  Minor version indicating feature enhancements
patch
  Patch indicating bug fixes

Register: hwInfo.memMapVersion
------------------------------

* HW Prefix: hwInfo_memMapVersion
* HW Address: 0x14
* C Prefix: hwInfo.memMapVersion
* C Block Offset: 0x14
* Access: read-only

Memory Map Version

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

major
  (not documented)
minor
  (not documented)
patch
  (not documented)

Register: hwInfo.echo
---------------------

* HW Prefix: hwInfo_echo
* HW Address: 0x18
* C Prefix: hwInfo.echo
* C Block Offset: 0x18
* Access: read/write

Register used solely by software. No interaction with the firmware foreseen.
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.

Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)

On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.

At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. 
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).

If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error 

This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|            echo[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|            echo[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             echo[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|              echo[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.ipInfo.stdVersion
------------------------------------------

* HW Prefix: app_modulation_ipInfo_stdVersion
* HW Address: 0x100000
* C Prefix: app.modulation.ipInfo.stdVersion
* C Block Offset: 0x0
* Access: read-only

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

major
  Major version indicating incompatible changes
minor
  Minor version indicating feature enhancements
patch
  Patch indicating bug fixes

Register: app.modulation.ipInfo.ident
-------------------------------------

* HW Prefix: app_modulation_ipInfo_ident
* HW Address: 0x100004
* C Prefix: app.modulation.ipInfo.ident
* C Block Offset: 0x4
* Access: read-only

IP Ident code

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|           ident[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|           ident[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|            ident[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             ident[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.ipInfo.firmwareVersion
-----------------------------------------------

* HW Prefix: app_modulation_ipInfo_firmwareVersion
* HW Address: 0x100008
* C Prefix: app.modulation.ipInfo.firmwareVersion
* C Block Offset: 0x8
* Access: read-only

Firmware Version

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

major
  Major version indicating incompatible changes
minor
  Minor version indicating feature enhancements
patch
  Patch indicating bug fixes

Register: app.modulation.ipInfo.memMapVersion
---------------------------------------------

* HW Prefix: app_modulation_ipInfo_memMapVersion
* HW Address: 0x10000c
* C Prefix: app.modulation.ipInfo.memMapVersion
* C Block Offset: 0xc
* Access: read-only

Memory Map Version

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             major[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|             minor[7:0]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             patch[7:0]|
+--+--+--+--+--+--+--+--+

major
  Major version indicating incompatible changes
minor
  Minor version indicating feature enhancements
patch
  Patch indicating bug fixes

Register: app.modulation.ipInfo.echo
------------------------------------

* HW Prefix: app_modulation_ipInfo_echo
* HW Address: 0x100010
* C Prefix: app.modulation.ipInfo.echo
* C Block Offset: 0x10
* Access: read/write

Register used solely by software. No interaction with the firmware foreseen.
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.

Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)

On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.

At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. 
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).

If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error 

This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|              echo[7:0]|
+--+--+--+--+--+--+--+--+

echo
  This version of the standard foresees only 8bits linked to real memory

Register: app.modulation.control
--------------------------------

* HW Prefix: app_modulation_control
* HW Address: 0x100020
* C Prefix: app.modulation.control
* C Block Offset: 0x20
* Access: read/write

+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                31|                30|                29|                28|                27|                26|                25|                24|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                 -|                 -|                 -|                 -|                 -|                 -|                 -|                 -|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                23|                22|                21|                20|                19|                18|                17|                16|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                 -|                 -|                 -|                 -|                 -|                 -|                 -|                 -|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                15|                14|                13|                12|                11|                10|                 9|                 8|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|    clearBPLatches|                                               rate[2:0]|wrInputsValidLatch|       wrRresetFSK|       wrResetSlip|        wrResetNCO|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|                 7|                 6|                 5|                 4|                 3|                 2|                 1|                 0|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+
|     wrInputsValid|         bypassMod|       bypassDemod|                 -|                 -|   useStaticSignal|        useImpulse|     useTestSignal|
+------------------+------------------+------------------+------------------+------------------+------------------+------------------+------------------+

useTestSignal
  Test signal is synthezied with additional internal DDS, test signals frequency given by ftw_RF.

  Use DDS generated test signal instead of ADC input as demodulation input
useImpulse
  Use impulse instead of demodulation output
useStaticSignal
  Use static signal from register instead of demodulation output
bypassDemod
  Bypass demodulator
bypassMod
  Bypass modulator
wrInputsValid
  transmit WR frame
wrInputsValidLatch
  transmit WR no autoclear
wrResetNCO
  activate WR frame control bit
wrResetSlip
  activate WR frame control bit
wrRresetFSK
  activate WR frame control bit
rate
  (not documented)
clearBPLatches
  (not documented)

Register: app.modulation.testSignal.amplitude
---------------------------------------------

* HW Prefix: app_modulation_testSignal_amplitude
* HW Address: 0x100030
* C Prefix: app.modulation.testSignal.amplitude
* C Block Offset: 0x0
* Access: read/write

Amplitude for the test signal

+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|        amplitude[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|         amplitude[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.testSignal.ftw
---------------------------------------

* HW Prefix: app_modulation_testSignal_ftw
* HW Address: 0x100038
* C Prefix: app.modulation.testSignal.ftw
* C Block Offset: 0x8
* Access: read/write

FTW of the test signal (frequency relative to fs)

+--+--+--+--+--+--+--+--+
|63|62|61|60|59|58|57|56|
+--+--+--+--+--+--+--+--+
|             ftw[63:56]|
+--+--+--+--+--+--+--+--+
|55|54|53|52|51|50|49|48|
+--+--+--+--+--+--+--+--+
|             ftw[55:48]|
+--+--+--+--+--+--+--+--+
|47|46|45|44|43|42|41|40|
+--+--+--+--+--+--+--+--+
|             ftw[47:40]|
+--+--+--+--+--+--+--+--+
|39|38|37|36|35|34|33|32|
+--+--+--+--+--+--+--+--+
|             ftw[39:32]|
+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|             ftw[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             ftw[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|              ftw[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|               ftw[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.staticSignal.i
---------------------------------------

* HW Prefix: app_modulation_staticSignal_i
* HW Address: 0x100040
* C Prefix: app.modulation.staticSignal.i
* C Block Offset: 0x0
* Access: read/write

Constant to be used as OTF input for channel I

+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|                i[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|                 i[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.staticSignal.q
---------------------------------------

* HW Prefix: app_modulation_staticSignal_q
* HW Address: 0x100044
* C Prefix: app.modulation.staticSignal.q
* C Block Offset: 0x4
* Access: read/write

Constant to be used as OTF input for channel Q

+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|                q[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|                 q[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.ftwH1main
----------------------------------

* HW Prefix: app_modulation_ftwH1main
* HW Address: 0x100050
* C Prefix: app.modulation.ftwH1main
* C Block Offset: 0x50
* Access: read/write

+--+--+--+--+--+--+--+--+
|63|62|61|60|59|58|57|56|
+--+--+--+--+--+--+--+--+
|       ftwH1main[63:56]|
+--+--+--+--+--+--+--+--+
|55|54|53|52|51|50|49|48|
+--+--+--+--+--+--+--+--+
|       ftwH1main[55:48]|
+--+--+--+--+--+--+--+--+
|47|46|45|44|43|42|41|40|
+--+--+--+--+--+--+--+--+
|       ftwH1main[47:40]|
+--+--+--+--+--+--+--+--+
|39|38|37|36|35|34|33|32|
+--+--+--+--+--+--+--+--+
|       ftwH1main[39:32]|
+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|       ftwH1main[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|       ftwH1main[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|        ftwH1main[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|         ftwH1main[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.ftwH1on
--------------------------------

* HW Prefix: app_modulation_ftwH1on
* HW Address: 0x100058
* C Prefix: app.modulation.ftwH1on
* C Block Offset: 0x58
* Access: read/write

+--+--+--+--+--+--+--+--+
|63|62|61|60|59|58|57|56|
+--+--+--+--+--+--+--+--+
|         ftwH1on[63:56]|
+--+--+--+--+--+--+--+--+
|55|54|53|52|51|50|49|48|
+--+--+--+--+--+--+--+--+
|         ftwH1on[55:48]|
+--+--+--+--+--+--+--+--+
|47|46|45|44|43|42|41|40|
+--+--+--+--+--+--+--+--+
|         ftwH1on[47:40]|
+--+--+--+--+--+--+--+--+
|39|38|37|36|35|34|33|32|
+--+--+--+--+--+--+--+--+
|         ftwH1on[39:32]|
+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|         ftwH1on[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|         ftwH1on[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|          ftwH1on[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|           ftwH1on[7:0]|
+--+--+--+--+--+--+--+--+

Register: app.modulation.dftwH1slip0
------------------------------------

* HW Prefix: app_modulation_dftwH1slip0
* HW Address: 0x100060
* C Prefix: app.modulation.dftwH1slip0
* C Block Offset: 0x60
* Access: read/write

+---+---+---+---+---+---+---+---+
| 31| 30| 29| 28| 27| 26| 25| 24|
+---+---+---+---+---+---+---+---+
|             dftwH1slip0[31:24]|
+---+---+---+---+---+---+---+---+
| 23| 22| 21| 20| 19| 18| 17| 16|
+---+---+---+---+---+---+---+---+
|             dftwH1slip0[23:16]|
+---+---+---+---+---+---+---+---+
| 15| 14| 13| 12| 11| 10|  9|  8|
+---+---+---+---+---+---+---+---+
|              dftwH1slip0[15:8]|
+---+---+---+---+---+---+---+---+
|  7|  6|  5|  4|  3|  2|  1|  0|
+---+---+---+---+---+---+---+---+
|               dftwH1slip0[7:0]|
+---+---+---+---+---+---+---+---+

Register: app.modulation.dftwH1slip1
------------------------------------

* HW Prefix: app_modulation_dftwH1slip1
* HW Address: 0x100064
* C Prefix: app.modulation.dftwH1slip1
* C Block Offset: 0x64
* Access: read/write

+---+---+---+---+---+---+---+---+
| 31| 30| 29| 28| 27| 26| 25| 24|
+---+---+---+---+---+---+---+---+
|             dftwH1slip1[31:24]|
+---+---+---+---+---+---+---+---+
| 23| 22| 21| 20| 19| 18| 17| 16|
+---+---+---+---+---+---+---+---+
|             dftwH1slip1[23:16]|
+---+---+---+---+---+---+---+---+
| 15| 14| 13| 12| 11| 10|  9|  8|
+---+---+---+---+---+---+---+---+
|              dftwH1slip1[15:8]|
+---+---+---+---+---+---+---+---+
|  7|  6|  5|  4|  3|  2|  1|  0|
+---+---+---+---+---+---+---+---+
|               dftwH1slip1[7:0]|
+---+---+---+---+---+---+---+---+

Register: app.modulation.latches
--------------------------------

* HW Prefix: app_modulation_latches
* HW Address: 0x100068
* C Prefix: app.modulation.latches
* C Block Offset: 0x68
* Access: read/write

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
| -| -| -| -| -| -| -| -|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|         backplane[7:0]|
+--+--+--+--+--+--+--+--+

backplane
  (not documented)

Registers Description for Space bar4

=====================================

Register: fgc_ddr.data64.data64
-------------------------------

* HW Prefix: fgc_ddr_data64_data64
* HW Address: 0x0
* C Prefix: fgc_ddr.data64.data64
* C Block Offset: 0x0
* Access: read/write

+--+--+--+--+--+--+--+--+
|63|62|61|60|59|58|57|56|
+--+--+--+--+--+--+--+--+
|           upper[31:24]|
+--+--+--+--+--+--+--+--+
|55|54|53|52|51|50|49|48|
+--+--+--+--+--+--+--+--+
|           upper[23:16]|
+--+--+--+--+--+--+--+--+
|47|46|45|44|43|42|41|40|
+--+--+--+--+--+--+--+--+
|            upper[15:8]|
+--+--+--+--+--+--+--+--+
|39|38|37|36|35|34|33|32|
+--+--+--+--+--+--+--+--+
|             upper[7:0]|
+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|           lower[31:24]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|           lower[23:16]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|            lower[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             lower[7:0]|
+--+--+--+--+--+--+--+--+

upper
  (not documented)
lower
  (not documented)

Register: acq_ddr.data32.data32
-------------------------------

* HW Prefix: acq_ddr_data32_data32
* HW Address: 0x20000000
* C Prefix: acq_ddr.data32.data32
* C Block Offset: 0x0
* Access: read/write

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|            upper[15:8]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             upper[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|            lower[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             lower[7:0]|
+--+--+--+--+--+--+--+--+

upper
  (not documented)
lower
  (not documented)

Register: acq_ram.data32.data32
-------------------------------

* HW Prefix: acq_ram_data32_data32
* HW Address: 0x80000000
* C Prefix: acq_ram.data32.data32
* C Block Offset: 0x0
* Access: read/write

+--+--+--+--+--+--+--+--+
|31|30|29|28|27|26|25|24|
+--+--+--+--+--+--+--+--+
|            upper[15:8]|
+--+--+--+--+--+--+--+--+
|23|22|21|20|19|18|17|16|
+--+--+--+--+--+--+--+--+
|             upper[7:0]|
+--+--+--+--+--+--+--+--+
|15|14|13|12|11|10| 9| 8|
+--+--+--+--+--+--+--+--+
|            lower[15:8]|
+--+--+--+--+--+--+--+--+
| 7| 6| 5| 4| 3| 2| 1| 0|
+--+--+--+--+--+--+--+--+
|             lower[7:0]|
+--+--+--+--+--+--+--+--+

upper
  (not documented)
lower
  (not documented)

