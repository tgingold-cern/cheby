#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, r  , unsigned int
#define test1_b15                                          (0x00008000) // bit-field-data
#define test1_b15ShiftPoz                                  (15) // bit-field-data shift poZzition
//not implemented ctype for test3: bit_encoding = unsigned, el_width = 64
#define test5                                              (0x02000003)// register-data, rw , unsigned int
#define test7                                              (0x02000004)// register-data, r  , unsigned int
#define test7_b31                                          (0x80000000) // bit-field-data
#define test7_b31ShiftPoz                                  (31) // bit-field-data shift poZzition
