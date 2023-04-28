#define MEMMAP_VERSION (0x0133A24D) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, rw , unsigned short
//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
#define test3                                              (0x02000005)// register-data, rw , unsigned short
#define test4                                              (0x02000006)// register-data, rw , unsigned int
#define test5                                              (0x02000008)// register-data, w  , unsigned short
//not implemented ctype for test6: bit_encoding = unsigned, el_width = 64
#define test7                                              (0x0200000D)// register-data, rw , unsigned short
#define test8                                              (0x0200000E)// register-data, rw , unsigned int
