## Memory Map Summary
SIS-8300-KU

Memory Map for SPS TWC200 Cavity Control

## For Space bar0
| HW address | Type | Name | HDL Name |
|------------|------|------|----------|
| 0x000000-0x00001f | SUBMAP | hwInfo | hwInfo |
| 0x000000 | REG | hwInfo.stdVersion | hwInfo_stdVersion |
| 0x000008 | REG | hwInfo.serialNumber | hwInfo_serialNumber |
| 0x000010 | REG | hwInfo.firmwareVersion | hwInfo_firmwareVersion |
| 0x000014 | REG | hwInfo.memMapVersion | hwInfo_memMapVersion |
| 0x000018 | REG | hwInfo.echo | hwInfo_echo |
| 0x100000-0x17ffff | SUBMAP | app | app |
| 0x100000-0x1003ff | SUBMAP | app.modulation | app_modulation |
| 0x100000-0x10001f | SUBMAP | app.modulation.ipInfo | app_modulation_ipInfo |
| 0x100000 | REG | app.modulation.ipInfo.stdVersion | app_modulation_ipInfo_stdVersion |
| 0x100004 | REG | app.modulation.ipInfo.ident | app_modulation_ipInfo_ident |
| 0x100008 | REG | app.modulation.ipInfo.firmwareVersion | app_modulation_ipInfo_firmwareVersion |
| 0x10000c | REG | app.modulation.ipInfo.memMapVersion | app_modulation_ipInfo_memMapVersion |
| 0x100010 | REG | app.modulation.ipInfo.echo | app_modulation_ipInfo_echo |
| 0x100020 | REG | app.modulation.control | app_modulation_control |
| 0x100030-0x10003f | BLOCK | app.modulation.testSignal | app_modulation_testSignal |
| 0x100030 | REG | app.modulation.testSignal.amplitude | app_modulation_testSignal_amplitude |
| 0x100038 | REG | app.modulation.testSignal.ftw | app_modulation_testSignal_ftw |
| 0x100040-0x10004f | BLOCK | app.modulation.staticSignal | app_modulation_staticSignal |
| 0x100040 | REG | app.modulation.staticSignal.i | app_modulation_staticSignal_i |
| 0x100044 | REG | app.modulation.staticSignal.q | app_modulation_staticSignal_q |
| 0x100050 | REG | app.modulation.ftwH1main | app_modulation_ftwH1main |
| 0x100058 | REG | app.modulation.ftwH1on | app_modulation_ftwH1on |
| 0x100060 | REG | app.modulation.dftwH1slip0 | app_modulation_dftwH1slip0 |
| 0x100064 | REG | app.modulation.dftwH1slip1 | app_modulation_dftwH1slip1 |
| 0x100068 | REG | app.modulation.latches | app_modulation_latches |

## For Space bar4
| HW address | Type | Name | HDL Name |
|------------|------|------|----------|
| 0x00000000-0x000fffff | SUBMAP | fgc_ddr | fgc_ddr |
| 0x00000000-0x000fffff | MEMORY | fgc_ddr.data64 | fgc_ddr_data64 |
|  +0x00000000 | REG | fgc_ddr.data64.data64 | fgc_ddr_data64_data64 |
| 0x20000000-0x3fffffff | SUBMAP | acq_ddr | acq_ddr |
| 0x20000000-0x3fffffff | MEMORY | acq_ddr.data32 | acq_ddr_data32 |
|  +0x20000000 | REG | acq_ddr.data32.data32 | acq_ddr_data32_data32 |
| 0x80000000-0x8001ffff | SUBMAP | acq_ram | acq_ram |
| 0x80000000-0x8001ffff | MEMORY | acq_ram.data32 | acq_ram_data32 |
|  +0x80000000 | REG | acq_ram.data32.data32 | acq_ram_data32_data32 |

## Registers Description for Space bar0

### Register: hwInfo.stdVersion

- **HW Prefix**: hwInfo_stdVersion
- **HW Address**: 0x0
- **C Prefix**: hwInfo.stdVersion
- **C Block Offset**: 0x0
- **Access**: read-only

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">platform[7:0]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:24 | platform | Identifying which platform the version belongs to (i.e. pci, lhc_vme, vme64, ...) |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### Register: hwInfo.serialNumber

- **HW Prefix**: hwInfo_serialNumber
- **HW Address**: 0x8
- **C Prefix**: hwInfo.serialNumber
- **C Block Offset**: 0x8
- **Access**: read-only

HW serial number

<table>
  <tr>
    <td><b>63</b></td>
    <td><b>62</b></td>
    <td><b>61</b></td>
    <td><b>60</b></td>
    <td><b>59</b></td>
    <td><b>58</b></td>
    <td><b>57</b></td>
    <td><b>56</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[63:56]</td>
  </tr>
  <tr>
    <td><b>55</b></td>
    <td><b>54</b></td>
    <td><b>53</b></td>
    <td><b>52</b></td>
    <td><b>51</b></td>
    <td><b>50</b></td>
    <td><b>49</b></td>
    <td><b>48</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[55:48]</td>
  </tr>
  <tr>
    <td><b>47</b></td>
    <td><b>46</b></td>
    <td><b>45</b></td>
    <td><b>44</b></td>
    <td><b>43</b></td>
    <td><b>42</b></td>
    <td><b>41</b></td>
    <td><b>40</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[47:40]</td>
  </tr>
  <tr>
    <td><b>39</b></td>
    <td><b>38</b></td>
    <td><b>37</b></td>
    <td><b>36</b></td>
    <td><b>35</b></td>
    <td><b>34</b></td>
    <td><b>33</b></td>
    <td><b>32</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[39:32]</td>
  </tr>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">serialNumber[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 63:0 | serialNumber | HW serial number |

### Register: hwInfo.firmwareVersion

- **HW Prefix**: hwInfo_firmwareVersion
- **HW Address**: 0x10
- **C Prefix**: hwInfo.firmwareVersion
- **C Block Offset**: 0x10
- **Access**: read-only

Firmware Version

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### Register: hwInfo.memMapVersion

- **HW Prefix**: hwInfo_memMapVersion
- **HW Address**: 0x14
- **C Prefix**: hwInfo.memMapVersion
- **C Block Offset**: 0x14
- **Access**: read-only

Memory Map Version

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 23:16 | major |  |
| 15:8 | minor |  |
| 7:0 | patch |  |

### Register: hwInfo.echo

- **HW Prefix**: hwInfo_echo
- **HW Address**: 0x18
- **C Prefix**: hwInfo.echo
- **C Block Offset**: 0x18
- **Access**: read/write

Register used solely by software. No interaction with the firmware foreseen. +
The idea is to use this register as "flag" in the hardware to remember your actions from the software side. +
 +
Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME) +
 +
On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet. +
 +
At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress.  +
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka). +
 +
If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error  +
 +
This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">echo[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">echo[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">echo[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">echo[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | echo | Register used solely by software. No interaction with the firmware foreseen.<br>The idea is to use this register as "flag" in the hardware to remember your actions from the software side.<br><br>Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)<br><br>On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.<br><br>At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. <br>This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).<br><br>If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error <br><br>This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.<br><br>Echo register. This version of the standard foresees only 8bits linked to real memory |

### Register: app.modulation.ipInfo.stdVersion

- **HW Prefix**: app_modulation_ipInfo_stdVersion
- **HW Address**: 0x100000
- **C Prefix**: app.modulation.ipInfo.stdVersion
- **C Block Offset**: 0x0
- **Access**: read-only

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### Register: app.modulation.ipInfo.ident

- **HW Prefix**: app_modulation_ipInfo_ident
- **HW Address**: 0x100004
- **C Prefix**: app.modulation.ipInfo.ident
- **C Block Offset**: 0x4
- **Access**: read-only

IP Ident code

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ident[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ident[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ident[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ident[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | ident | IP Ident code |

### Register: app.modulation.ipInfo.firmwareVersion

- **HW Prefix**: app_modulation_ipInfo_firmwareVersion
- **HW Address**: 0x100008
- **C Prefix**: app.modulation.ipInfo.firmwareVersion
- **C Block Offset**: 0x8
- **Access**: read-only

Firmware Version

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### Register: app.modulation.ipInfo.memMapVersion

- **HW Prefix**: app_modulation_ipInfo_memMapVersion
- **HW Address**: 0x10000c
- **C Prefix**: app.modulation.ipInfo.memMapVersion
- **C Block Offset**: 0xc
- **Access**: read-only

Memory Map Version

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">major[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">minor[7:0]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### Register: app.modulation.ipInfo.echo

- **HW Prefix**: app_modulation_ipInfo_echo
- **HW Address**: 0x100010
- **C Prefix**: app.modulation.ipInfo.echo
- **C Block Offset**: 0x10
- **Access**: read/write

Register used solely by software. No interaction with the firmware foreseen. +
The idea is to use this register as "flag" in the hardware to remember your actions from the software side. +
 +
Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME) +
 +
On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet. +
 +
At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress.  +
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka). +
 +
If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error  +
 +
This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.

Echo register. This version of the standard foresees only 8bits linked to real memory

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">echo[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | echo | This version of the standard foresees only 8bits linked to real memory |

### Register: app.modulation.control

- **HW Prefix**: app_modulation_control
- **HW Address**: 0x100020
- **C Prefix**: app.modulation.control
- **C Block Offset**: 0x20
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td>clearBPLatches</td>
    <td colspan="3" style="text-align: center;">rate[2:0]</td>
    <td>wrInputsValidLatch</td>
    <td>wrRresetFSK</td>
    <td>wrResetSlip</td>
    <td>wrResetNCO</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td>wrInputsValid</td>
    <td>bypassMod</td>
    <td>bypassDemod</td>
    <td>-</td>
    <td>-</td>
    <td>useStaticSignal</td>
    <td>useImpulse</td>
    <td>useTestSignal</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 0 | useTestSignal | Test signal is synthezied with additional internal DDS, test signals frequency given by ftw_RF.<br><br>Use DDS generated test signal instead of ADC input as demodulation input |
| 1 | useImpulse | Use impulse instead of demodulation output |
| 2 | useStaticSignal | Use static signal from register instead of demodulation output |
| 5 | bypassDemod | Bypass demodulator |
| 6 | bypassMod | Bypass modulator |
| 7 | wrInputsValid | transmit WR frame |
| 11 | wrInputsValidLatch | transmit WR no autoclear |
| 8 | wrResetNCO | activate WR frame control bit |
| 9 | wrResetSlip | activate WR frame control bit |
| 10 | wrRresetFSK | activate WR frame control bit |
| 14:12 | rate |  |
| 15 | clearBPLatches |  |

### Register: app.modulation.testSignal.amplitude

- **HW Prefix**: app_modulation_testSignal_amplitude
- **HW Address**: 0x100030
- **C Prefix**: app.modulation.testSignal.amplitude
- **C Block Offset**: 0x0
- **Access**: read/write

Amplitude for the test signal

<table>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">amplitude[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">amplitude[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 15:0 | amplitude | Amplitude for the test signal |

### Register: app.modulation.testSignal.ftw

- **HW Prefix**: app_modulation_testSignal_ftw
- **HW Address**: 0x100038
- **C Prefix**: app.modulation.testSignal.ftw
- **C Block Offset**: 0x8
- **Access**: read/write

FTW of the test signal (frequency relative to fs)

<table>
  <tr>
    <td><b>63</b></td>
    <td><b>62</b></td>
    <td><b>61</b></td>
    <td><b>60</b></td>
    <td><b>59</b></td>
    <td><b>58</b></td>
    <td><b>57</b></td>
    <td><b>56</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[63:56]</td>
  </tr>
  <tr>
    <td><b>55</b></td>
    <td><b>54</b></td>
    <td><b>53</b></td>
    <td><b>52</b></td>
    <td><b>51</b></td>
    <td><b>50</b></td>
    <td><b>49</b></td>
    <td><b>48</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[55:48]</td>
  </tr>
  <tr>
    <td><b>47</b></td>
    <td><b>46</b></td>
    <td><b>45</b></td>
    <td><b>44</b></td>
    <td><b>43</b></td>
    <td><b>42</b></td>
    <td><b>41</b></td>
    <td><b>40</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[47:40]</td>
  </tr>
  <tr>
    <td><b>39</b></td>
    <td><b>38</b></td>
    <td><b>37</b></td>
    <td><b>36</b></td>
    <td><b>35</b></td>
    <td><b>34</b></td>
    <td><b>33</b></td>
    <td><b>32</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[39:32]</td>
  </tr>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftw[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 63:0 | ftw | FTW of the test signal (frequency relative to fs) |

### Register: app.modulation.staticSignal.i

- **HW Prefix**: app_modulation_staticSignal_i
- **HW Address**: 0x100040
- **C Prefix**: app.modulation.staticSignal.i
- **C Block Offset**: 0x0
- **Access**: read/write

Constant to be used as OTF input for channel I

<table>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">i[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">i[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 15:0 | i | Constant to be used as OTF input for channel I |

### Register: app.modulation.staticSignal.q

- **HW Prefix**: app_modulation_staticSignal_q
- **HW Address**: 0x100044
- **C Prefix**: app.modulation.staticSignal.q
- **C Block Offset**: 0x4
- **Access**: read/write

Constant to be used as OTF input for channel Q

<table>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">q[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">q[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 15:0 | q | Constant to be used as OTF input for channel Q |

### Register: app.modulation.ftwH1main

- **HW Prefix**: app_modulation_ftwH1main
- **HW Address**: 0x100050
- **C Prefix**: app.modulation.ftwH1main
- **C Block Offset**: 0x50
- **Access**: read/write

<table>
  <tr>
    <td><b>63</b></td>
    <td><b>62</b></td>
    <td><b>61</b></td>
    <td><b>60</b></td>
    <td><b>59</b></td>
    <td><b>58</b></td>
    <td><b>57</b></td>
    <td><b>56</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[63:56]</td>
  </tr>
  <tr>
    <td><b>55</b></td>
    <td><b>54</b></td>
    <td><b>53</b></td>
    <td><b>52</b></td>
    <td><b>51</b></td>
    <td><b>50</b></td>
    <td><b>49</b></td>
    <td><b>48</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[55:48]</td>
  </tr>
  <tr>
    <td><b>47</b></td>
    <td><b>46</b></td>
    <td><b>45</b></td>
    <td><b>44</b></td>
    <td><b>43</b></td>
    <td><b>42</b></td>
    <td><b>41</b></td>
    <td><b>40</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[47:40]</td>
  </tr>
  <tr>
    <td><b>39</b></td>
    <td><b>38</b></td>
    <td><b>37</b></td>
    <td><b>36</b></td>
    <td><b>35</b></td>
    <td><b>34</b></td>
    <td><b>33</b></td>
    <td><b>32</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[39:32]</td>
  </tr>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1main[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 63:0 | ftwH1main |  |

### Register: app.modulation.ftwH1on

- **HW Prefix**: app_modulation_ftwH1on
- **HW Address**: 0x100058
- **C Prefix**: app.modulation.ftwH1on
- **C Block Offset**: 0x58
- **Access**: read/write

<table>
  <tr>
    <td><b>63</b></td>
    <td><b>62</b></td>
    <td><b>61</b></td>
    <td><b>60</b></td>
    <td><b>59</b></td>
    <td><b>58</b></td>
    <td><b>57</b></td>
    <td><b>56</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[63:56]</td>
  </tr>
  <tr>
    <td><b>55</b></td>
    <td><b>54</b></td>
    <td><b>53</b></td>
    <td><b>52</b></td>
    <td><b>51</b></td>
    <td><b>50</b></td>
    <td><b>49</b></td>
    <td><b>48</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[55:48]</td>
  </tr>
  <tr>
    <td><b>47</b></td>
    <td><b>46</b></td>
    <td><b>45</b></td>
    <td><b>44</b></td>
    <td><b>43</b></td>
    <td><b>42</b></td>
    <td><b>41</b></td>
    <td><b>40</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[47:40]</td>
  </tr>
  <tr>
    <td><b>39</b></td>
    <td><b>38</b></td>
    <td><b>37</b></td>
    <td><b>36</b></td>
    <td><b>35</b></td>
    <td><b>34</b></td>
    <td><b>33</b></td>
    <td><b>32</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[39:32]</td>
  </tr>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">ftwH1on[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 63:0 | ftwH1on |  |

### Register: app.modulation.dftwH1slip0

- **HW Prefix**: app_modulation_dftwH1slip0
- **HW Address**: 0x100060
- **C Prefix**: app.modulation.dftwH1slip0
- **C Block Offset**: 0x60
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip0[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip0[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip0[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip0[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | dftwH1slip0 |  |

### Register: app.modulation.dftwH1slip1

- **HW Prefix**: app_modulation_dftwH1slip1
- **HW Address**: 0x100064
- **C Prefix**: app.modulation.dftwH1slip1
- **C Block Offset**: 0x64
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip1[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip1[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip1[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">dftwH1slip1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | dftwH1slip1 |  |

### Register: app.modulation.latches

- **HW Prefix**: app_modulation_latches
- **HW Address**: 0x100068
- **C Prefix**: app.modulation.latches
- **C Block Offset**: 0x68
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">backplane[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | backplane |  |

## Registers Description for Space bar4

### Register: fgc_ddr.data64.data64

- **HW Prefix**: fgc_ddr_data64_data64
- **HW Address**: 0x0
- **C Prefix**: fgc_ddr.data64.data64
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
  <tr>
    <td><b>63</b></td>
    <td><b>62</b></td>
    <td><b>61</b></td>
    <td><b>60</b></td>
    <td><b>59</b></td>
    <td><b>58</b></td>
    <td><b>57</b></td>
    <td><b>56</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[31:24]</td>
  </tr>
  <tr>
    <td><b>55</b></td>
    <td><b>54</b></td>
    <td><b>53</b></td>
    <td><b>52</b></td>
    <td><b>51</b></td>
    <td><b>50</b></td>
    <td><b>49</b></td>
    <td><b>48</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[23:16]</td>
  </tr>
  <tr>
    <td><b>47</b></td>
    <td><b>46</b></td>
    <td><b>45</b></td>
    <td><b>44</b></td>
    <td><b>43</b></td>
    <td><b>42</b></td>
    <td><b>41</b></td>
    <td><b>40</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[15:8]</td>
  </tr>
  <tr>
    <td><b>39</b></td>
    <td><b>38</b></td>
    <td><b>37</b></td>
    <td><b>36</b></td>
    <td><b>35</b></td>
    <td><b>34</b></td>
    <td><b>33</b></td>
    <td><b>32</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[7:0]</td>
  </tr>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[31:24]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[23:16]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 63:32 | upper |  |
| 31:0 | lower |  |

### Register: acq_ddr.data32.data32

- **HW Prefix**: acq_ddr_data32_data32
- **HW Address**: 0x20000000
- **C Prefix**: acq_ddr.data32.data32
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[15:8]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:16 | upper |  |
| 15:0 | lower |  |

### Register: acq_ram.data32.data32

- **HW Prefix**: acq_ram_data32_data32
- **HW Address**: 0x80000000
- **C Prefix**: acq_ram.data32.data32
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
  <tr>
    <td><b>31</b></td>
    <td><b>30</b></td>
    <td><b>29</b></td>
    <td><b>28</b></td>
    <td><b>27</b></td>
    <td><b>26</b></td>
    <td><b>25</b></td>
    <td><b>24</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[15:8]</td>
  </tr>
  <tr>
    <td><b>23</b></td>
    <td><b>22</b></td>
    <td><b>21</b></td>
    <td><b>20</b></td>
    <td><b>19</b></td>
    <td><b>18</b></td>
    <td><b>17</b></td>
    <td><b>16</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">upper[7:0]</td>
  </tr>
  <tr>
    <td><b>15</b></td>
    <td><b>14</b></td>
    <td><b>13</b></td>
    <td><b>12</b></td>
    <td><b>11</b></td>
    <td><b>10</b></td>
    <td><b>9</b></td>
    <td><b>8</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[15:8]</td>
  </tr>
  <tr>
    <td><b>7</b></td>
    <td><b>6</b></td>
    <td><b>5</b></td>
    <td><b>4</b></td>
    <td><b>3</b></td>
    <td><b>2</b></td>
    <td><b>1</b></td>
    <td><b>0</b></td>
  </tr>
  <tr>
    <td colspan="8" style="text-align: center;">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:16 | upper |  |
| 15:0 | lower |  |

