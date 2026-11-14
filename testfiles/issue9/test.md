# test

Test AXI4-Lite interface

## 1. Memory map summary

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x00` | REG | [register1](#21-register1) | Test register 1 |
| `0x10-0x1f` | BLOCK | block1 | Test block 1 |
| `0x10` | REG | [block1.register2](#22-block1register2) | Test register 2 |
| `0x14` | REG | [block1.register3](#23-block1register3) | Test register 3 |
| `0x18-0x1b` | BLOCK | block1.block2 | Test block 2 |
| `0x18` | REG | [block1.block2.register4](#24-block1block2register4) | Test register 4 |

## 2. Register description

### 2.1. register1

<table>
<tr><td><b>HW address:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>register1</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>register1</code></td></tr>
<tr><td><b>Access:</b></td><td><code>write-only</code></td></tr>
</table>

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
    <td colspan="8" align="center">register1[31:24]</td>
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
    <td colspan="8" align="center">register1[23:16]</td>
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
    <td colspan="8" align="center">register1[15:8]</td>
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
    <td colspan="8" align="center">register1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | register1 | Test register 1 |

### 2.2. block1.register2

<table>
<tr><td><b>HW address:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>block1_register2</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>block1.register2</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="3" align="center">field2[2:0]</td>
    <td>field1</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 0 | field1 | Test field 1 |
| 3:1 | field2 | Test field 2 |

### 2.3. block1.register3

<table>
<tr><td><b>HW address:</b></td><td><code>0x14</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>block1_register3</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>block1.register3</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read/write</code></td></tr>
</table>

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
    <td colspan="8" align="center">register3[31:24]</td>
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
    <td colspan="8" align="center">register3[23:16]</td>
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
    <td colspan="8" align="center">register3[15:8]</td>
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
    <td colspan="8" align="center">register3[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | register3 | Test register 3 |

### 2.4. block1.block2.register4

<table>
<tr><td><b>HW address:</b></td><td><code>0x18</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>block1_block2_register4</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>block1.block2.register4</code></td></tr>
<tr><td><b>Access:</b></td><td><code>read-only</code></td></tr>
</table>

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
    <td colspan="3" align="center">field4[2:0]</td>
    <td>field3</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 0 | field3 | Test field 3 |
| 3:1 | field4 | Test field 4 |

