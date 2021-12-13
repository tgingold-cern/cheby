#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, rmw, unsigned int
#define test2                                              (0x02000004)// register-data, rmw, unsigned int
#define test3                                              (0x02000008)// register-data, rw , unsigned int
#define test4                                              (0x0200000C)// register-data, rw , unsigned int
#define test5                                              (0x02000010)// register-data, w  , unsigned int
#define test6                                              (0x02000014)// register-data, w  , unsigned int
#define test7                                              (0x02000018)// register-data, r  , unsigned int
#define test8                                              (0x0200001C)// register-data, r  , unsigned int
