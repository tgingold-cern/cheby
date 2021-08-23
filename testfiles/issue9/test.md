== Memory map summary
Test AXI4-Lite interface

|===
|HW address | Type | Name | HDL name

|0x00
|REG
|register1
|register1

|0x10-0x1f
|BLOCK
|block1
|block1

|0x10
|REG
|block1.register2
|block1_register2

|0x14
|REG
|block1.register3
|block1_register3

|0x18-0x1b
|BLOCK
|block1.block2
|block1_block2

|0x18
|REG
|block1.block2.register4
|block1_block2_register4
|===

== Registers description
=== register1
[horizontal]
HDL name:: register1
address:: 0x0
block offset:: 0x0
access mode:: wo

Test register 1

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

8+s| register1[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| register1[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| register1[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| register1[7:0]
|===
=== block1.register2
[horizontal]
HDL name:: block1_register2
address:: 0x10
block offset:: 0x0
access mode:: ro

Test register 2

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

| -
| -
| -
| -
3+s| field2[2:0]
s| field1
|===

field1::
Test field 1
field2::
Test field 2

=== block1.register3
[horizontal]
HDL name:: block1_register3
address:: 0x14
block offset:: 0x4
access mode:: rw

Test register 3

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

8+s| register3[31:24]

| 23
| 22
| 21
| 20
| 19
| 18
| 17
| 16

8+s| register3[23:16]

| 15
| 14
| 13
| 12
| 11
| 10
| 9
| 8

8+s| register3[15:8]

| 7
| 6
| 5
| 4
| 3
| 2
| 1
| 0

8+s| register3[7:0]
|===
=== block1.block2.register4
[horizontal]
HDL name:: block1_block2_register4
address:: 0x18
block offset:: 0x0
access mode:: ro

Test register 4

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

| -
| -
| -
| -
3+s| field4[2:0]
s| field3
|===

field3::
Test field 3
field4::
Test field 4

