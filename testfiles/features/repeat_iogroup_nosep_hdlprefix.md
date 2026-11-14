# repeat_iogroup_nosep_hdlprefix

Doc HDL prefix for non-indexed iogroup repeats

## 1. Memory map summary

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x0-0x7` | REPEAT (adc) | adc |  |
| `0x0-0x3` | BLOCK | adc0 |  |
| `0x0` | REG | adc0.spie_cmd_mem_wdata |  |
| `0x4-0x7` | BLOCK | adc1 |  |
| `0x4` | REG | adc1.spie_cmd_mem_wdata |  |

## 2. Register description

### 2.1. adc0.spie_cmd_mem_wdata

- **HW Prefix**: adc0_spie_cmd_mem_wdata
- **HW Address**: 0x0
- **C Prefix**: adc0.spie_cmd_mem_wdata
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[31:24]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[23:16]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[15:8]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | spie_cmd_mem_wdata |  |

### 2.2. adc1.spie_cmd_mem_wdata

- **HW Prefix**: adc1_spie_cmd_mem_wdata
- **HW Address**: 0x4
- **C Prefix**: adc1.spie_cmd_mem_wdata
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[31:24]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[23:16]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[15:8]</td>
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
    <td colspan="8" align="center">spie_cmd_mem_wdata[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | spie_cmd_mem_wdata |  |

