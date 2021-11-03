#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, rmw, unsigned short
#define test2                                              (0x02000001)// register-data, rmw, unsigned int
#define test3                                              (0x02000003)// register-data, rw , unsigned short
#define test4                                              (0x02000004)// register-data, rw , unsigned int
#define test5                                              (0x02000006)// register-data, w  , unsigned short
#define test6                                              (0x02000007)// register-data, w  , unsigned int
#define test7                                              (0x02000009)// register-data, rw , unsigned short
#define test8                                              (0x0200000A)// register-data, rw , unsigned int
#define mem1                                               (0x02000200)// memory-data, rw , unknown type
#define mem2                                               (0x02000400)// memory-data, rw , unknown type
