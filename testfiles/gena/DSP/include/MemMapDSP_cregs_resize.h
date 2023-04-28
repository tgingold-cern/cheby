#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, r  , unsigned int
//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
#define test3                                              (0x02000003)// register-data, rw , unsigned int
//not implemented ctype for test4: bit_encoding = unsigned, el_width = 64
#define test5                                              (0x02000006)// register-data, w  , unsigned int
//not implemented ctype for test6: bit_encoding = unsigned, el_width = 64
