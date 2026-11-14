# repeatInRepeat

## 1. Memory map summary

| HW address | Type | Name | Description |
| --- | --- | --- | --- |
| `0x00-0x1f` | REPEAT | repA |  |
| `0x00-0x07` | BLOCK | repA.0 |  |
| `0x00-0x07` | BLOCK | repA.0.block1 |  |
| `0x00-0x07` | REPEAT | repA.0.block1.repB |  |
| `0x00-0x03` | BLOCK | repA.0.block1.repB.0 |  |
| `0x00` | REG | repA.0.block1.repB.0.reg1 |  |
| `0x04-0x07` | BLOCK | repA.0.block1.repB.1 |  |
| `0x04` | REG | repA.0.block1.repB.1.reg1 |  |
| `0x08-0x0f` | BLOCK | repA.1 |  |
| `0x08-0x0f` | BLOCK | repA.1.block1 |  |
| `0x08-0x0f` | REPEAT | repA.1.block1.repB |  |
| `0x08-0x0b` | BLOCK | repA.1.block1.repB.0 |  |
| `0x08` | REG | repA.1.block1.repB.0.reg1 |  |
| `0x0c-0x0f` | BLOCK | repA.1.block1.repB.1 |  |
| `0x0c` | REG | repA.1.block1.repB.1.reg1 |  |
| `0x10-0x17` | BLOCK | repA.2 |  |
| `0x10-0x17` | BLOCK | repA.2.block1 |  |
| `0x10-0x17` | REPEAT | repA.2.block1.repB |  |
| `0x10-0x13` | BLOCK | repA.2.block1.repB.0 |  |
| `0x10` | REG | repA.2.block1.repB.0.reg1 |  |
| `0x14-0x17` | BLOCK | repA.2.block1.repB.1 |  |
| `0x14` | REG | repA.2.block1.repB.1.reg1 |  |
| `0x18-0x1f` | BLOCK | repA.3 |  |
| `0x18-0x1f` | BLOCK | repA.3.block1 |  |
| `0x18-0x1f` | REPEAT | repA.3.block1.repB |  |
| `0x18-0x1b` | BLOCK | repA.3.block1.repB.0 |  |
| `0x18` | REG | repA.3.block1.repB.0.reg1 |  |
| `0x1c-0x1f` | BLOCK | repA.3.block1.repB.1 |  |
| `0x1c` | REG | repA.3.block1.repB.1.reg1 |  |

## 2. Register description

### 2.1. repA.0.block1.repB.0.reg1

- **HW Prefix**: repA_0_block1_repB_0_reg1
- **HW Address**: 0x0
- **C Prefix**: repA.0.block1.repB.0.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.2. repA.0.block1.repB.1.reg1

- **HW Prefix**: repA_0_block1_repB_1_reg1
- **HW Address**: 0x4
- **C Prefix**: repA.0.block1.repB.1.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.3. repA.1.block1.repB.0.reg1

- **HW Prefix**: repA_1_block1_repB_0_reg1
- **HW Address**: 0x8
- **C Prefix**: repA.1.block1.repB.0.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.4. repA.1.block1.repB.1.reg1

- **HW Prefix**: repA_1_block1_repB_1_reg1
- **HW Address**: 0xc
- **C Prefix**: repA.1.block1.repB.1.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.5. repA.2.block1.repB.0.reg1

- **HW Prefix**: repA_2_block1_repB_0_reg1
- **HW Address**: 0x10
- **C Prefix**: repA.2.block1.repB.0.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.6. repA.2.block1.repB.1.reg1

- **HW Prefix**: repA_2_block1_repB_1_reg1
- **HW Address**: 0x14
- **C Prefix**: repA.2.block1.repB.1.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.7. repA.3.block1.repB.0.reg1

- **HW Prefix**: repA_3_block1_repB_0_reg1
- **HW Address**: 0x18
- **C Prefix**: repA.3.block1.repB.0.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

### 2.8. repA.3.block1.repB.1.reg1

- **HW Prefix**: repA_3_block1_repB_1_reg1
- **HW Address**: 0x1c
- **C Prefix**: repA.3.block1.repB.1.reg1
- **C Block Offset**: 0x0
- **Access**: read/write

<table>
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
    <td colspan="8" align="center">reg1[7:0]</td>
  </tr>
</table>

| Bits | Name | Description |
|------|------|------------|
| 7:0 | reg1 |  |

