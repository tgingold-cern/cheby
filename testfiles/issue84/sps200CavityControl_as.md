# sps200CavityControl

SIS-8300-KU

Memory Map for SPS TWC200 Cavity Control

## 1.1. Memory map summary for address space bar0

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x000000-0x00001f` | SUBMAP | hwInfo |  |
| `0x000000` | REG | [hwInfo.stdVersion](#211-hwinfostdversion) |  |
| `0x000008` | REG | [hwInfo.serialNumber](#212-hwinfoserialnumber) | HW serial number |
| `0x000010` | REG | [hwInfo.firmwareVersion](#213-hwinfofirmwareversion) | Firmware Version |
| `0x000014` | REG | [hwInfo.memMapVersion](#214-hwinfomemmapversion) | Memory Map Version |
| `0x000018` | REG | [hwInfo.echo](#215-hwinfoecho) | Echo register. This version of the standard foresees only 8bits linked to real memory |
| `0x100000-0x17ffff` | SUBMAP | app |  |
| `0x100000-0x1003ff` | SUBMAP | app.modulation |  |
| `0x100000-0x10001f` | SUBMAP | app.modulation.ipInfo |  |
| `0x100000` | REG | [app.modulation.ipInfo.stdVersion](#216-appmodulationipinfostdversion) |  |
| `0x100004` | REG | [app.modulation.ipInfo.ident](#217-appmodulationipinfoident) | IP Ident code |
| `0x100008` | REG | [app.modulation.ipInfo.firmwareVersion](#218-appmodulationipinfofirmwareversion) | Firmware Version |
| `0x10000c` | REG | [app.modulation.ipInfo.memMapVersion](#219-appmodulationipinfomemmapversion) | Memory Map Version |
| `0x100010` | REG | [app.modulation.ipInfo.echo](#2110-appmodulationipinfoecho) | Echo register. This version of the standard foresees only 8bits linked to real memory |
| `0x100020` | REG | [app.modulation.control](#2111-appmodulationcontrol) |  |
| `0x100030-0x10003f` | BLOCK | app.modulation.testSignal |  |
| `0x100030` | REG | [app.modulation.testSignal.amplitude](#2112-appmodulationtestsignalamplitude) | Amplitude for the test signal |
| `0x100038` | REG | [app.modulation.testSignal.ftw](#2113-appmodulationtestsignalftw) | FTW of the test signal (frequency relative to fs) |
| `0x100040-0x10004f` | BLOCK | app.modulation.staticSignal |  |
| `0x100040` | REG | [app.modulation.staticSignal.i](#2114-appmodulationstaticsignali) | Constant to be used as OTF input for channel I |
| `0x100044` | REG | [app.modulation.staticSignal.q](#2115-appmodulationstaticsignalq) | Constant to be used as OTF input for channel Q |
| `0x100050` | REG | [app.modulation.ftwH1main](#2116-appmodulationftwh1main) |  |
| `0x100058` | REG | [app.modulation.ftwH1on](#2117-appmodulationftwh1on) |  |
| `0x100060` | REG | [app.modulation.dftwH1slip0](#2118-appmodulationdftwh1slip0) |  |
| `0x100064` | REG | [app.modulation.dftwH1slip1](#2119-appmodulationdftwh1slip1) |  |
| `0x100068` | REG | [app.modulation.latches](#2120-appmodulationlatches) |  |

## 1.2. Memory map summary for address space bar4

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x00000000-0x000fffff` | SUBMAP | fgc_ddr |  |
| `0x00000000-0x000fffff` | MEMORY | fgc_ddr.data64 | Memory to store function data, access 64bit width |
| ` +0x00000000` | REG | [fgc_ddr.data64.data64](#221-fgc_ddrdata64data64) |  |
| `0x20000000-0x3fffffff` | SUBMAP | acq_ddr |  |
| `0x20000000-0x3fffffff` | MEMORY | acq_ddr.data32 | Memory to store acquisition  data, access 64bit width |
| ` +0x20000000` | REG | [acq_ddr.data32.data32](#222-acq_ddrdata32data32) |  |
| `0x80000000-0x8001ffff` | SUBMAP | acq_ram |  |
| `0x80000000-0x8001ffff` | MEMORY | acq_ram.data32 | Memory to store function data, access 32bit width |
| ` +0x80000000` | REG | [acq_ram.data32.data32](#223-acq_ramdata32data32) |  |

## 2.1 Register description for address space bar0

### 2.1.1. hwInfo.stdVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>hwInfo_stdVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>hwInfo.stdVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">platform[7:0]</td>
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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:24 | platform | Identifying which platform the version belongs to (i.e. pci, lhc_vme, vme64, ...) |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### 2.1.2. hwInfo.serialNumber

<table>
<tr><td><b>HW address:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>hwInfo_serialNumber</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>hwInfo.serialNumber</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">serialNumber[63:56]</td>
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
    <td colspan="8" align="center">serialNumber[55:48]</td>
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
    <td colspan="8" align="center">serialNumber[47:40]</td>
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
    <td colspan="8" align="center">serialNumber[39:32]</td>
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
    <td colspan="8" align="center">serialNumber[31:24]</td>
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
    <td colspan="8" align="center">serialNumber[23:16]</td>
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
    <td colspan="8" align="center">serialNumber[15:8]</td>
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
    <td colspan="8" align="center">serialNumber[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 63:0 | serialNumber | HW serial number |

### 2.1.3. hwInfo.firmwareVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>hwInfo_firmwareVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>hwInfo.firmwareVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### 2.1.4. hwInfo.memMapVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x14</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x14</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>hwInfo_memMapVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>hwInfo.memMapVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 23:16 | major |  |
| 15:8 | minor |  |
| 7:0 | patch |  |

### 2.1.5. hwInfo.echo

<table>
<tr><td><b>HW address:</b></td><td><code>0x18</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x18</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>hwInfo_echo</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>hwInfo.echo</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

Register used solely by software. No interaction with the firmware foreseen.  
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.  
  
Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)  
  
On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.  
  
At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress.   
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).  
  
If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error   
  
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
    <td colspan="8" align="center">echo[31:24]</td>
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
    <td colspan="8" align="center">echo[23:16]</td>
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
    <td colspan="8" align="center">echo[15:8]</td>
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
    <td colspan="8" align="center">echo[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | echo | Register used solely by software. No interaction with the firmware foreseen.<br>The idea is to use this register as "flag" in the hardware to remember your actions from the software side.<br><br>Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)<br><br>On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.<br><br>At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress. <br>This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).<br><br>If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error <br><br>This register is in particular useful if you have several entities interacting with the hardware. In this case several bits could be assigned to this entities (bits 5..0) to signalize that they have done there part successful and a main entity checks all the expected bits.<br><br>Echo register. This version of the standard foresees only 8bits linked to real memory |

### 2.1.6. app.modulation.ipInfo.stdVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x100000</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ipInfo_stdVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ipInfo.stdVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### 2.1.7. app.modulation.ipInfo.ident

<table>
<tr><td><b>HW address:</b></td><td><code>0x100004</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ipInfo_ident</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ipInfo.ident</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">ident[31:24]</td>
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
    <td colspan="8" align="center">ident[23:16]</td>
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
    <td colspan="8" align="center">ident[15:8]</td>
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
    <td colspan="8" align="center">ident[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | ident | IP Ident code |

### 2.1.8. app.modulation.ipInfo.firmwareVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x100008</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ipInfo_firmwareVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ipInfo.firmwareVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### 2.1.9. app.modulation.ipInfo.memMapVersion

<table>
<tr><td><b>HW address:</b></td><td><code>0x10000c</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0xc</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ipInfo_memMapVersion</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ipInfo.memMapVersion</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">major[7:0]</td>
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
    <td colspan="8" align="center">minor[7:0]</td>
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
    <td colspan="8" align="center">patch[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 23:16 | major | Major version indicating incompatible changes |
| 15:8 | minor | Minor version indicating feature enhancements |
| 7:0 | patch | Patch indicating bug fixes |

### 2.1.10. app.modulation.ipInfo.echo

<table>
<tr><td><b>HW address:</b></td><td><code>0x100010</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ipInfo_echo</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ipInfo.echo</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

Register used solely by software. No interaction with the firmware foreseen.  
The idea is to use this register as "flag" in the hardware to remember your actions from the software side.  
  
Reading 0xFF often happens when the board is not even reachable (i.e. bus problems on VME)  
  
On the other hand if the board is reachable the usual state of flipflops are 0x00. Thus this would indicate that no initialization has been attempted yet.  
  
At start of your software (FESA class) you should set the value 0x40 indicating that initialization is in progress.   
This is important for you to later one check if you can read this value back before finally setting it to 0x80 (the value previously used with Cheburashka).  
  
If your initialization failed but you want to continue anyway you should set the register to 0xC0 to indicate this error   
  
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
    <td colspan="8" align="center">echo[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 7:0 | echo | This version of the standard foresees only 8bits linked to real memory |

### 2.1.11. app.modulation.control

<table>
<tr><td><b>HW address:</b></td><td><code>0x100020</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x20</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_control</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.control</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="3" align="center">rate[2:0]</td>
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
| --- | --- | --- |
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

### 2.1.12. app.modulation.testSignal.amplitude

<table>
<tr><td><b>HW address:</b></td><td><code>0x100030</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_testSignal_amplitude</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.testSignal.amplitude</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">amplitude[15:8]</td>
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
    <td colspan="8" align="center">amplitude[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 15:0 | amplitude | Amplitude for the test signal |

### 2.1.13. app.modulation.testSignal.ftw

<table>
<tr><td><b>HW address:</b></td><td><code>0x100038</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_testSignal_ftw</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.testSignal.ftw</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">ftw[63:56]</td>
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
    <td colspan="8" align="center">ftw[55:48]</td>
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
    <td colspan="8" align="center">ftw[47:40]</td>
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
    <td colspan="8" align="center">ftw[39:32]</td>
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
    <td colspan="8" align="center">ftw[31:24]</td>
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
    <td colspan="8" align="center">ftw[23:16]</td>
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
    <td colspan="8" align="center">ftw[15:8]</td>
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
    <td colspan="8" align="center">ftw[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 63:0 | ftw | FTW of the test signal (frequency relative to fs) |

### 2.1.14. app.modulation.staticSignal.i

<table>
<tr><td><b>HW address:</b></td><td><code>0x100040</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_staticSignal_i</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.staticSignal.i</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">i[15:8]</td>
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
    <td colspan="8" align="center">i[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 15:0 | i | Constant to be used as OTF input for channel I |

### 2.1.15. app.modulation.staticSignal.q

<table>
<tr><td><b>HW address:</b></td><td><code>0x100044</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_staticSignal_q</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.staticSignal.q</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">q[15:8]</td>
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
    <td colspan="8" align="center">q[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 15:0 | q | Constant to be used as OTF input for channel Q |

### 2.1.16. app.modulation.ftwH1main

<table>
<tr><td><b>HW address:</b></td><td><code>0x100050</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x50</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ftwH1main</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ftwH1main</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">ftwH1main[63:56]</td>
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
    <td colspan="8" align="center">ftwH1main[55:48]</td>
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
    <td colspan="8" align="center">ftwH1main[47:40]</td>
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
    <td colspan="8" align="center">ftwH1main[39:32]</td>
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
    <td colspan="8" align="center">ftwH1main[31:24]</td>
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
    <td colspan="8" align="center">ftwH1main[23:16]</td>
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
    <td colspan="8" align="center">ftwH1main[15:8]</td>
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
    <td colspan="8" align="center">ftwH1main[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 63:0 | ftwH1main |  |

### 2.1.17. app.modulation.ftwH1on

<table>
<tr><td><b>HW address:</b></td><td><code>0x100058</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x58</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_ftwH1on</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.ftwH1on</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">ftwH1on[63:56]</td>
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
    <td colspan="8" align="center">ftwH1on[55:48]</td>
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
    <td colspan="8" align="center">ftwH1on[47:40]</td>
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
    <td colspan="8" align="center">ftwH1on[39:32]</td>
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
    <td colspan="8" align="center">ftwH1on[31:24]</td>
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
    <td colspan="8" align="center">ftwH1on[23:16]</td>
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
    <td colspan="8" align="center">ftwH1on[15:8]</td>
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
    <td colspan="8" align="center">ftwH1on[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 63:0 | ftwH1on |  |

### 2.1.18. app.modulation.dftwH1slip0

<table>
<tr><td><b>HW address:</b></td><td><code>0x100060</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x60</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_dftwH1slip0</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.dftwH1slip0</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">dftwH1slip0[31:24]</td>
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
    <td colspan="8" align="center">dftwH1slip0[23:16]</td>
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
    <td colspan="8" align="center">dftwH1slip0[15:8]</td>
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
    <td colspan="8" align="center">dftwH1slip0[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | dftwH1slip0 |  |

### 2.1.19. app.modulation.dftwH1slip1

<table>
<tr><td><b>HW address:</b></td><td><code>0x100064</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x64</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_dftwH1slip1</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.dftwH1slip1</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">dftwH1slip1[31:24]</td>
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
    <td colspan="8" align="center">dftwH1slip1[23:16]</td>
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
    <td colspan="8" align="center">dftwH1slip1[15:8]</td>
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
    <td colspan="8" align="center">dftwH1slip1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | dftwH1slip1 |  |

### 2.1.20. app.modulation.latches

<table>
<tr><td><b>HW address:</b></td><td><code>0x100068</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x68</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>app_modulation_latches</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>app.modulation.latches</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">backplane[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 7:0 | backplane |  |

## 2.2 Register description for address space bar4

### 2.2.1. fgc_ddr.data64.data64

<table>
<tr><td><b>HW address:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>fgc_ddr_data64_data64</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>fgc_ddr.data64.data64</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">upper[31:24]</td>
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
    <td colspan="8" align="center">upper[23:16]</td>
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
    <td colspan="8" align="center">upper[15:8]</td>
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
    <td colspan="8" align="center">upper[7:0]</td>
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
    <td colspan="8" align="center">lower[31:24]</td>
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
    <td colspan="8" align="center">lower[23:16]</td>
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
    <td colspan="8" align="center">lower[15:8]</td>
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
    <td colspan="8" align="center">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 63:32 | upper |  |
| 31:0 | lower |  |

### 2.2.2. acq_ddr.data32.data32

<table>
<tr><td><b>HW address:</b></td><td><code>0x20000000</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>acq_ddr_data32_data32</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>acq_ddr.data32.data32</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">upper[15:8]</td>
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
    <td colspan="8" align="center">upper[7:0]</td>
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
    <td colspan="8" align="center">lower[15:8]</td>
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
    <td colspan="8" align="center">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:16 | upper |  |
| 15:0 | lower |  |

### 2.2.3. acq_ram.data32.data32

<table>
<tr><td><b>HW address:</b></td><td><code>0x80000000</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>acq_ram_data32_data32</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>acq_ram.data32.data32</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">upper[15:8]</td>
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
    <td colspan="8" align="center">upper[7:0]</td>
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
    <td colspan="8" align="center">lower[15:8]</td>
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
    <td colspan="8" align="center">lower[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:16 | upper |  |
| 15:0 | lower |  |

