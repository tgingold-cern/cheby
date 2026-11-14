# repeat_indexing1

repeat with array indexing

## 1. Memory map summary

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x00-0x1f` | REPEAT [0..3] (itf) | chan |  |
| `0x00` | REG | [chan.0.ctrl](#21-chan0ctrl) |  |
| `0x04` | REG | [chan.0.status](#22-chan0status) |  |
| `0x08` | REG | [chan.1.ctrl](#23-chan1ctrl) |  |
| `0x0c` | REG | [chan.1.status](#24-chan1status) |  |
| `0x10` | REG | [chan.2.ctrl](#25-chan2ctrl) |  |
| `0x14` | REG | [chan.2.status](#26-chan2status) |  |
| `0x18` | REG | [chan.3.ctrl](#27-chan3ctrl) |  |
| `0x1c` | REG | [chan.3.status](#28-chan3status) |  |

## 2. Register description

### 2.1. chan.0.ctrl

<table>
<tr><td><b>HW address:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(0).ctrl</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.0.ctrl</code></td></tr>
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
    <td colspan="8" align="center">ctrl[31:24]</td>
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
    <td colspan="8" align="center">ctrl[23:16]</td>
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
    <td colspan="8" align="center">ctrl[15:8]</td>
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
    <td colspan="8" align="center">ctrl[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | ctrl |  |

### 2.2. chan.0.status

<table>
<tr><td><b>HW address:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(0).status</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.0.status</code></td></tr>
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
    <td colspan="8" align="center">status[31:24]</td>
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
    <td colspan="8" align="center">status[23:16]</td>
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
    <td colspan="8" align="center">status[15:8]</td>
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
    <td colspan="8" align="center">status[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | status |  |

### 2.3. chan.1.ctrl

<table>
<tr><td><b>HW address:</b></td><td><code>0x8</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(1).ctrl</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.1.ctrl</code></td></tr>
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
    <td colspan="8" align="center">ctrl[31:24]</td>
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
    <td colspan="8" align="center">ctrl[23:16]</td>
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
    <td colspan="8" align="center">ctrl[15:8]</td>
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
    <td colspan="8" align="center">ctrl[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | ctrl |  |

### 2.4. chan.1.status

<table>
<tr><td><b>HW address:</b></td><td><code>0xc</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(1).status</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.1.status</code></td></tr>
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
    <td colspan="8" align="center">status[31:24]</td>
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
    <td colspan="8" align="center">status[23:16]</td>
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
    <td colspan="8" align="center">status[15:8]</td>
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
    <td colspan="8" align="center">status[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | status |  |

### 2.5. chan.2.ctrl

<table>
<tr><td><b>HW address:</b></td><td><code>0x10</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(2).ctrl</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.2.ctrl</code></td></tr>
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
    <td colspan="8" align="center">ctrl[31:24]</td>
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
    <td colspan="8" align="center">ctrl[23:16]</td>
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
    <td colspan="8" align="center">ctrl[15:8]</td>
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
    <td colspan="8" align="center">ctrl[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | ctrl |  |

### 2.6. chan.2.status

<table>
<tr><td><b>HW address:</b></td><td><code>0x14</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(2).status</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.2.status</code></td></tr>
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
    <td colspan="8" align="center">status[31:24]</td>
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
    <td colspan="8" align="center">status[23:16]</td>
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
    <td colspan="8" align="center">status[15:8]</td>
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
    <td colspan="8" align="center">status[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | status |  |

### 2.7. chan.3.ctrl

<table>
<tr><td><b>HW address:</b></td><td><code>0x18</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x0</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(3).ctrl</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.3.ctrl</code></td></tr>
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
    <td colspan="8" align="center">ctrl[31:24]</td>
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
    <td colspan="8" align="center">ctrl[23:16]</td>
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
    <td colspan="8" align="center">ctrl[15:8]</td>
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
    <td colspan="8" align="center">ctrl[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | ctrl |  |

### 2.8. chan.3.status

<table>
<tr><td><b>HW address:</b></td><td><code>0x1c</code></td></tr>
<tr><td><b>Block offset:</b></td><td><code>0x4</code></td></tr>
<tr><td><b>HDL prefix:</b></td><td><code>itf(3).status</code></td></tr>
<tr><td><b>C prefix:</b></td><td><code>chan.3.status</code></td></tr>
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
    <td colspan="8" align="center">status[31:24]</td>
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
    <td colspan="8" align="center">status[23:16]</td>
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
    <td colspan="8" align="center">status[15:8]</td>
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
    <td colspan="8" align="center">status[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
| --- | --- | --- |
| 31:0 | status |  |

