## Memory Map Summary
Test AXI4-Lite interface

| HW address | Type | Name | HDL Name |
|------------|------|------|----------|
| 0x00 | REG | register1 | register1 |
| 0x10-0x1f | BLOCK | block1 | block1 |
| 0x10 | REG | block1.register2 | block1_register2 |
| 0x14 | REG | block1.register3 | block1_register3 |
| 0x18-0x1b | BLOCK | block1.block2 | block1_block2 |
| 0x18 | REG | block1.block2.register4 | block1_block2_register4 |

## Registers Description
### Register: register1

- **HW Prefix**: register1
- **HW Address**: 0x0
- **C Prefix**: register1
- **C Block Offset**: 0x0
- **Access**: write-only

Test register 1

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
    <td colspan="8" style="text-align: center;">register1[31:24]</td>
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
    <td colspan="8" style="text-align: center;">register1[23:16]</td>
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
    <td colspan="8" style="text-align: center;">register1[15:8]</td>
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
    <td colspan="8" style="text-align: center;">register1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | register1 | Test register 1 |

### Register: block1.register2

- **HW Prefix**: block1_register2
- **HW Address**: 0x10
- **C Prefix**: block1.register2
- **C Block Offset**: 0x0
- **Access**: read-only

Test register 2

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
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td colspan="3" style="text-align: center;">field2[2:0]</td>
    <td>field1</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 0 | field1 | Test field 1 |
| 3:1 | field2 | Test field 2 |

### Register: block1.register3

- **HW Prefix**: block1_register3
- **HW Address**: 0x14
- **C Prefix**: block1.register3
- **C Block Offset**: 0x4
- **Access**: read/write

Test register 3

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
    <td colspan="8" style="text-align: center;">register3[31:24]</td>
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
    <td colspan="8" style="text-align: center;">register3[23:16]</td>
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
    <td colspan="8" style="text-align: center;">register3[15:8]</td>
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
    <td colspan="8" style="text-align: center;">register3[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 31:0 | register3 | Test register 3 |

### Register: block1.block2.register4

- **HW Prefix**: block1_block2_register4
- **HW Address**: 0x18
- **C Prefix**: block1.block2.register4
- **C Block Offset**: 0x0
- **Access**: read-only

Test register 4

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
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td>-</td>
    <td colspan="3" style="text-align: center;">field4[2:0]</td>
    <td>field3</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 0 | field3 | Test field 3 |
| 3:1 | field4 | Test field 4 |

