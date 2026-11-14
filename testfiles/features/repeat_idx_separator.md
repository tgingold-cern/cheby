# repeat_idx_separator

Test repeat index separator behavior

## 1. Memory map summary

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x00-0x07` | REPEAT | rep0 |  |
| `0x00-0x03` | BLOCK | rep0.0 |  |
| `0x00` | REG | [rep0.0.r](#21-rep00r) |  |
| `0x04-0x07` | BLOCK | rep0.1 |  |
| `0x04` | REG | [rep0.1.r](#22-rep01r) |  |
| `0x08-0x0f` | REPEAT | rep1 |  |
| `0x08-0x0b` | BLOCK | rep10 |  |
| `0x08` | REG | [rep10.r](#23-rep10r) |  |
| `0x0c-0x0f` | BLOCK | rep11 |  |
| `0x0c` | REG | [rep11.r](#24-rep11r) |  |
| `0x10-0x17` | REPEAT | rep2 |  |
| `0x10-0x13` | BLOCK | rep2_0 |  |
| `0x10` | REG | [rep2_0.r](#25-rep2_0r) |  |
| `0x14-0x17` | BLOCK | rep2_1 |  |
| `0x14` | REG | [rep2_1.r](#26-rep2_1r) |  |

## 2. Register description

### 2.1. rep0.0.r

<table>
<tr><td><b>HW address:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep0_0_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep0.0.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

### 2.2. rep0.1.r

<table>
<tr><td><b>HW address:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep0_1_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep0.1.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

### 2.3. rep10.r

<table>
<tr><td><b>HW address:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep10_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep10.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

### 2.4. rep11.r

<table>
<tr><td><b>HW address:</b></td><td><code>0xc</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep11_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep11.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

### 2.5. rep2_0.r

<table>
<tr><td><b>HW address:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep2_0_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep2_0.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

### 2.6. rep2_1.r

<table>
<tr><td><b>HW address:</b></td><td><code>0x14</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>rep2_1_r</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>rep2_1.r</code></td></tr>
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
    <td colspan="8" align="center">r[31:24]</td>
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
    <td colspan="8" align="center">r[23:16]</td>
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
    <td colspan="8" align="center">r[15:8]</td>
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
    <td colspan="8" align="center">r[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | r |  |

