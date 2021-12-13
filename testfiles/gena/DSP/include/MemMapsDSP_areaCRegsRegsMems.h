#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, rmw, unsigned int
//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
#define test3                                              (0x02000006)// register-data, rw , unsigned int
//not implemented ctype for test4: bit_encoding = unsigned, el_width = 64
#define test5                                              (0x0200000C)// register-data, w  , unsigned int
//not implemented ctype for test6: bit_encoding = unsigned, el_width = 64
#define test7                                              (0x02000040)// register-data, r  , unsigned int
//not implemented ctype for test8: bit_encoding = unsigned, el_width = 64
#define mem1                                               (0x02000200)// memory-data, rw , unknown type
#define mem2                                               (0x02000400)// memory-data, rw , unknown type
#define area_test1                                         (0x02040000)// register-data, rmw, unsigned int
//not implemented ctype for area_test2: bit_encoding = unsigned, el_width = 64
#define area_test3                                         (0x02040006)// register-data, rw , unsigned int
//not implemented ctype for area_test4: bit_encoding = unsigned, el_width = 64
#define area_test5                                         (0x0204000C)// register-data, w  , unsigned int
//not implemented ctype for area_test6: bit_encoding = unsigned, el_width = 64
//not implemented ctype for area_test7: bit_encoding = unsigned, el_width = 64
//not implemented ctype for area_test8: bit_encoding = unsigned, el_width = 64
#define area_mem1                                          (0x02040200)// memory-data, rw , unknown type
#define area_mem2                                          (0x02040400)// memory-data, rw , unknown type
