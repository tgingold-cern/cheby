== Memory map summary
Memory Map for SPS TWC200 Cavity Control

== For space bar0
|===
|HW address | Type | Name | HDL name

|0x000000-0x00001f
|SUBMAP
|hwInfo
|hwInfo

|0x000000
|REG
|hwInfo.stdVersion
|hwInfo_stdVersion

|0x000008
|REG
|hwInfo.serialNumber
|hwInfo_serialNumber

|0x000010
|REG
|hwInfo.firmwareVersion
|hwInfo_firmwareVersion

|0x000014
|REG
|hwInfo.memMapVersion
|hwInfo_memMapVersion

|0x000018
|REG
|hwInfo.echo
|hwInfo_echo

|0x100000-0x17ffff
|SUBMAP
|app
|app

|0x100000-0x1003ff
|SUBMAP
|app.modulation
|app_modulation

|0x100000-0x10001f
|SUBMAP
|app.modulation.ipInfo
|app_modulation_ipInfo

|0x100000
|REG
|app.modulation.ipInfo.stdVersion
|app_modulation_ipInfo_stdVersion

|0x100004
|REG
|app.modulation.ipInfo.ident
|app_modulation_ipInfo_ident

|0x100008
|REG
|app.modulation.ipInfo.firmwareVersion
|app_modulation_ipInfo_firmwareVersion

|0x10000c
|REG
|app.modulation.ipInfo.memMapVersion
|app_modulation_ipInfo_memMapVersion

|0x100010
|REG
|app.modulation.ipInfo.echo
|app_modulation_ipInfo_echo

|0x100020
|REG
|app.modulation.control
|app_modulation_control

|0x100030-0x10003f
|BLOCK
|app.modulation.testSignal
|app_modulation_testSignal

|0x100030
|REG
|app.modulation.testSignal.amplitude
|app_modulation_testSignal_amplitude

|0x100038
|REG
|app.modulation.testSignal.ftw
|app_modulation_testSignal_ftw

|0x100040-0x10004f
|BLOCK
|app.modulation.staticSignal
|app_modulation_staticSignal

|0x100040
|REG
|app.modulation.staticSignal.i
|app_modulation_staticSignal_i

|0x100044
|REG
|app.modulation.staticSignal.q
|app_modulation_staticSignal_q

|0x100050
|REG
|app.modulation.ftwH1main
|app_modulation_ftwH1main

|0x100058
|REG
|app.modulation.ftwH1on
|app_modulation_ftwH1on

|0x100060
|REG
|app.modulation.dftwH1slip0
|app_modulation_dftwH1slip0

|0x100064
|REG
|app.modulation.dftwH1slip1
|app_modulation_dftwH1slip1

|0x100068
|REG
|app.modulation.latches
|app_modulation_latches
|===

== For space bar4
|===
|HW address | Type | Name | HDL name

|0x00000000-0x000fffff
|SUBMAP
|fgc_ddr
|fgc_ddr

|0x00000000-0x000fffff
|MEMORY
|fgc_ddr.data64
|fgc_ddr_data64

| +0x00000000
|REG
|fgc_ddr.data64.data64
|fgc_ddr_data64_data64

|0x20000000-0x3fffffff
|SUBMAP
|acq_ddr
|acq_ddr

|0x20000000-0x3fffffff
|MEMORY
|acq_ddr.data32
|acq_ddr_data32

| +0x20000000
|REG
|acq_ddr.data32.data32
|acq_ddr_data32_data32

|0x80000000-0x8001ffff
|SUBMAP
|acq_ram
|acq_ram

|0x80000000-0x8001ffff
|MEMORY
|acq_ram.data32
|acq_ram_data32

| +0x80000000
|REG
|acq_ram.data32.data32
|acq_ram_data32_data32
|===

== Registers description for space bar0

=== hwInfo.stdVersion
[horizontal]
HDL name:: hwInfo_stdVersion
address:: 0x0
block offset:: 0x0
access mode:: ro

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| platform[7:0]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

platform::
Identifying which platform the version belongs to (i.e. pci, lhc_vme, vme64, ...)
major::
Major version indicating incompatible changes
minor::
Minor version indicating feature enhancements
patch::
Patch indicating bug fixes

=== hwInfo.serialNumber
[horizontal]
HDL name:: hwInfo_serialNumber
address:: 0x8
block offset:: 0x8
access mode:: ro

HW serial number

[cols="8*^"]
|===

| 63
| 62
| 61
| 60
| 59
| 58
| 57
| 56

8+s| serialNumber[63:56]

| 55
| 54
| 53
| 52
| 51
| 50
| 49
| 48

8+s| serialNumber[55:48]

| 47
| 46
| 45
| 44
| 43
| 42
| 41
| 40

8+s| serialNumber[47:40]

| 39
| 38
| 37
| 36
| 35
| 34
| 33
| 32

8+s| serialNumber[39:32]

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| serialNumber[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| serialNumber[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| serialNumber[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| serialNumber[7:0]
|===
=== hwInfo.firmwareVersion
[horizontal]
HDL name:: hwInfo_firmwareVersion
address:: 0x10
block offset:: 0x10
access mode:: ro

Firmware Version

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

major::
Major version indicating incompatible changes
minor::
Minor version indicating feature enhancements
patch::
Patch indicating bug fixes

=== hwInfo.memMapVersion
[horizontal]
HDL name:: hwInfo_memMapVersion
address:: 0x14
block offset:: 0x14
access mode:: ro

Memory Map Version

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

major::
(not documented)
minor::
(not documented)
patch::
(not documented)

=== hwInfo.echo
[horizontal]
HDL name:: hwInfo_echo
address:: 0x18
block offset:: 0x18
access mode:: rw

Register used solely by software. No interaction with the firmware foreseen.
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.

Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)

On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.

At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. 
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).

If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error 

This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| echo[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| echo[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| echo[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| echo[7:0]
|===
=== app.modulation.ipInfo.stdVersion
[horizontal]
HDL name:: app_modulation_ipInfo_stdVersion
address:: 0x100000
block offset:: 0x0
access mode:: ro

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

major::
Major version indicating incompatible changes
minor::
Minor version indicating feature enhancements
patch::
Patch indicating bug fixes

=== app.modulation.ipInfo.ident
[horizontal]
HDL name:: app_modulation_ipInfo_ident
address:: 0x100004
block offset:: 0x4
access mode:: ro

IP Ident code

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| ident[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| ident[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| ident[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| ident[7:0]
|===
=== app.modulation.ipInfo.firmwareVersion
[horizontal]
HDL name:: app_modulation_ipInfo_firmwareVersion
address:: 0x100008
block offset:: 0x8
access mode:: ro

Firmware Version

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

major::
Major version indicating incompatible changes
minor::
Minor version indicating feature enhancements
patch::
Patch indicating bug fixes

=== app.modulation.ipInfo.memMapVersion
[horizontal]
HDL name:: app_modulation_ipInfo_memMapVersion
address:: 0x10000c
block offset:: 0xc
access mode:: ro

Memory Map Version

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| major[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| minor[7:0]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| patch[7:0]
|===

major::
Major version indicating incompatible changes
minor::
Minor version indicating feature enhancements
patch::
Patch indicating bug fixes

=== app.modulation.ipInfo.echo
[horizontal]
HDL name:: app_modulation_ipInfo_echo
address:: 0x100010
block offset:: 0x10
access mode:: rw

Register used solely by software. No interaction with the firmware foreseen.
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.

Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)

On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.

At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. 
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).

If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error 

This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

| -
| -
| -
| -
| -
| -
| -
| -

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

| -
| -
| -
| -
| -
| -
| -
| -

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| echo[7:0]
|===

echo::
This version of the standard foresees only 8bits linked to real memory

=== app.modulation.control
[horizontal]
HDL name:: app_modulation_control
address:: 0x100020
block offset:: 0x20
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

| -
| -
| -
| -
| -
| -
| -
| -

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

s| clearBPLatches
3+s| rate[2:0]
s| wrInputsValidLatch
s| wrRresetFSK
s| wrResetSlip
s| wrResetNCO

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

s| wrInputsValid
s| bypassMod
s| bypassDemod
| -
| -
s| useStaticSignal
s| useImpulse
s| useTestSignal
|===

useTestSignal::
Test signal is synthezied with additional internal DDS, test signals frequency given by ftw_RF.
+
Use DDS generated test signal instead of ADC input as demodulation input
useImpulse::
Use impulse instead of demodulation output
useStaticSignal::
Use static signal from register instead of demodulation output
bypassDemod::
Bypass demodulator
bypassMod::
Bypass modulator
wrInputsValid::
transmit WR frame
wrInputsValidLatch::
transmit WR no autoclear
wrResetNCO::
activate WR frame control bit
wrResetSlip::
activate WR frame control bit
wrRresetFSK::
activate WR frame control bit
rate::
(not documented)
clearBPLatches::
(not documented)

=== app.modulation.testSignal.amplitude
[horizontal]
HDL name:: app_modulation_testSignal_amplitude
address:: 0x100030
block offset:: 0x0
access mode:: rw

Amplitude for the test signal

[cols="8*^"]
|===

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| amplitude[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| amplitude[7:0]
|===
=== app.modulation.testSignal.ftw
[horizontal]
HDL name:: app_modulation_testSignal_ftw
address:: 0x100038
block offset:: 0x8
access mode:: rw

FTW of the test signal (frequency relative to fs)

[cols="8*^"]
|===

| 63
| 62
| 61
| 60
| 59
| 58
| 57
| 56

8+s| ftw[63:56]

| 55
| 54
| 53
| 52
| 51
| 50
| 49
| 48

8+s| ftw[55:48]

| 47
| 46
| 45
| 44
| 43
| 42
| 41
| 40

8+s| ftw[47:40]

| 39
| 38
| 37
| 36
| 35
| 34
| 33
| 32

8+s| ftw[39:32]

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| ftw[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| ftw[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| ftw[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| ftw[7:0]
|===
=== app.modulation.staticSignal.i
[horizontal]
HDL name:: app_modulation_staticSignal_i
address:: 0x100040
block offset:: 0x0
access mode:: rw

Constant to be used as OTF input for channel I

[cols="8*^"]
|===

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| i[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| i[7:0]
|===
=== app.modulation.staticSignal.q
[horizontal]
HDL name:: app_modulation_staticSignal_q
address:: 0x100044
block offset:: 0x4
access mode:: rw

Constant to be used as OTF input for channel Q

[cols="8*^"]
|===

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| q[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| q[7:0]
|===
=== app.modulation.ftwH1main
[horizontal]
HDL name:: app_modulation_ftwH1main
address:: 0x100050
block offset:: 0x50
access mode:: rw

[cols="8*^"]
|===

| 63
| 62
| 61
| 60
| 59
| 58
| 57
| 56

8+s| ftwH1main[63:56]

| 55
| 54
| 53
| 52
| 51
| 50
| 49
| 48

8+s| ftwH1main[55:48]

| 47
| 46
| 45
| 44
| 43
| 42
| 41
| 40

8+s| ftwH1main[47:40]

| 39
| 38
| 37
| 36
| 35
| 34
| 33
| 32

8+s| ftwH1main[39:32]

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| ftwH1main[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| ftwH1main[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| ftwH1main[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| ftwH1main[7:0]
|===
=== app.modulation.ftwH1on
[horizontal]
HDL name:: app_modulation_ftwH1on
address:: 0x100058
block offset:: 0x58
access mode:: rw

[cols="8*^"]
|===

| 63
| 62
| 61
| 60
| 59
| 58
| 57
| 56

8+s| ftwH1on[63:56]

| 55
| 54
| 53
| 52
| 51
| 50
| 49
| 48

8+s| ftwH1on[55:48]

| 47
| 46
| 45
| 44
| 43
| 42
| 41
| 40

8+s| ftwH1on[47:40]

| 39
| 38
| 37
| 36
| 35
| 34
| 33
| 32

8+s| ftwH1on[39:32]

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| ftwH1on[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| ftwH1on[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| ftwH1on[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| ftwH1on[7:0]
|===
=== app.modulation.dftwH1slip0
[horizontal]
HDL name:: app_modulation_dftwH1slip0
address:: 0x100060
block offset:: 0x60
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| dftwH1slip0[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| dftwH1slip0[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| dftwH1slip0[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| dftwH1slip0[7:0]
|===
=== app.modulation.dftwH1slip1
[horizontal]
HDL name:: app_modulation_dftwH1slip1
address:: 0x100064
block offset:: 0x64
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| dftwH1slip1[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| dftwH1slip1[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| dftwH1slip1[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| dftwH1slip1[7:0]
|===
=== app.modulation.latches
[horizontal]
HDL name:: app_modulation_latches
address:: 0x100068
block offset:: 0x68
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

| -
| -
| -
| -
| -
| -
| -
| -

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

| -
| -
| -
| -
| -
| -
| -
| -

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

| -
| -
| -
| -
| -
| -
| -
| -

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| backplane[7:0]
|===

backplane::
(not documented)

== Registers description for space bar4

=== fgc_ddr.data64.data64
[horizontal]
HDL name:: fgc_ddr_data64_data64
address:: 0x0
block offset:: 0x0
access mode:: rw

[cols="8*^"]
|===

| 63
| 62
| 61
| 60
| 59
| 58
| 57
| 56

8+s| upper[31:24]

| 55
| 54
| 53
| 52
| 51
| 50
| 49
| 48

8+s| upper[23:16]

| 47
| 46
| 45
| 44
| 43
| 42
| 41
| 40

8+s| upper[15:8]

| 39
| 38
| 37
| 36
| 35
| 34
| 33
| 32

8+s| upper[7:0]

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| lower[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| lower[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| lower[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| lower[7:0]
|===

upper::
(not documented)
lower::
(not documented)

=== acq_ddr.data32.data32
[horizontal]
HDL name:: acq_ddr_data32_data32
address:: 0x20000000
block offset:: 0x0
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| upper[15:8]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| upper[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| lower[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| lower[7:0]
|===

upper::
(not documented)
lower::
(not documented)

=== acq_ram.data32.data32
[horizontal]
HDL name:: acq_ram_data32_data32
address:: 0x80000000
block offset:: 0x0
access mode:: rw

[cols="8*^"]
|===

| 31
| 30
| 29
| 28
| 27
| 26
| 25
| 24

8+s| upper[15:8]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| upper[7:0]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| lower[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| lower[7:0]
|===

upper::
(not documented)
lower::
(not documented)

