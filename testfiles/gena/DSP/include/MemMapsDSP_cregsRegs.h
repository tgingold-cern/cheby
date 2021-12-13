#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, rmw, unsigned short
#define test1_hello                                        0 // code-field
#define test1_World                                        1 // code-field
#define test2                                              (0x02000001)// register-data, rw , unsigned int
#define test2_lsBit                                        (0x00000001) // bit-field-data
#define test2_lsBitShiftPoz                                (0) // bit-field-data shift poZzition
#define test2_msBit                                        (0x80000000) // bit-field-data
#define test2_msBitShiftPoz                                (31) // bit-field-data shift poZzition
#define test2_msBit_hello                                  0 // code-field
#define test2_msBit_world                                  1 // code-field
#define test2_boundryReg                                   (0x0003C000) // sub-reg
#define test2_boundryRegShiftPoz                           (14) // sub-reg shift poZzition
#define test2_msReg                                        (0x03C00000) // sub-reg
#define test2_msRegShiftPoz                                (22) // sub-reg shift poZzition
#define test2_msReg_hello                                  0 // code-field
#define test2_msReg_world                                  1 // code-field
#define test2_isReg                                        (0x000003C0) // sub-reg
#define test2_isRegShiftPoz                                (6) // sub-reg shift poZzition
#define test3                                              (0x02000003)// register-data, rw , unsigned short
#define test4                                              (0x02000004)// register-data, rw , unsigned int
#define test4_lsBit                                        (0x00000001) // bit-field-data
#define test4_lsBitShiftPoz                                (0) // bit-field-data shift poZzition
#define test4_msBit                                        (0x80000000) // bit-field-data
#define test4_msBitShiftPoz                                (31) // bit-field-data shift poZzition
#define test4_msBit_hello                                  0 // code-field
#define test4_msBit_world                                  1 // code-field
#define test4_boundryReg                                   (0x0003C000) // sub-reg
#define test4_boundryRegShiftPoz                           (14) // sub-reg shift poZzition
#define test4_msReg                                        (0x03C00000) // sub-reg
#define test4_msRegShiftPoz                                (22) // sub-reg shift poZzition
#define test4_msReg_hello                                  0 // code-field
#define test4_msReg_world                                  1 // code-field
#define test4_isReg                                        (0x000003C0) // sub-reg
#define test4_isRegShiftPoz                                (6) // sub-reg shift poZzition
#define test5                                              (0x02000006)// register-data, w  , unsigned short
#define test6                                              (0x02000007)// register-data, w  , unsigned int
#define test6_lsBit                                        (0x00000001) // bit-field-data
#define test6_lsBitShiftPoz                                (0) // bit-field-data shift poZzition
#define test6_msBit                                        (0x80000000) // bit-field-data
#define test6_msBitShiftPoz                                (31) // bit-field-data shift poZzition
#define test6_msBit_hello                                  0 // code-field
#define test6_msBit_world                                  1 // code-field
#define test6_boundryReg                                   (0x0003C000) // sub-reg
#define test6_boundryRegShiftPoz                           (14) // sub-reg shift poZzition
#define test6_msReg                                        (0x03C00000) // sub-reg
#define test6_msRegShiftPoz                                (22) // sub-reg shift poZzition
#define test6_msReg_hello                                  0 // code-field
#define test6_msReg_world                                  1 // code-field
#define test6_isReg                                        (0x000003C0) // sub-reg
#define test6_isRegShiftPoz                                (6) // sub-reg shift poZzition
#define test7                                              (0x02000009)// register-data, r  , unsigned short
#define test8                                              (0x0200000A)// register-data, r  , unsigned int
#define test8_lsBit                                        (0x00000001) // bit-field-data
#define test8_lsBitShiftPoz                                (0) // bit-field-data shift poZzition
#define test8_msBit                                        (0x80000000) // bit-field-data
#define test8_msBitShiftPoz                                (31) // bit-field-data shift poZzition
#define test8_msBit_hello                                  0 // code-field
#define test8_msBit_world                                  1 // code-field
#define test8_boundryReg                                   (0x0003C000) // sub-reg
#define test8_boundryRegShiftPoz                           (14) // sub-reg shift poZzition
#define test8_msReg                                        (0x03C00000) // sub-reg
#define test8_msRegShiftPoz                                (22) // sub-reg shift poZzition
#define test8_msReg_hello                                  0 // code-field
#define test8_msReg_world                                  1 // code-field
#define test8_isReg                                        (0x000003C0) // sub-reg
#define test8_isRegShiftPoz                                (6) // sub-reg shift poZzition
