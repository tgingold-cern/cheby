#define MEMMAP_VERSION (0x0133A24D) // memory map version, format: hex(yyyymmdd)

#define test2                                              (0x02000000)// register-data, r  , unsigned int
#define test2_lo                                           (0x00000001) // bit-field-data
#define test2_loShiftPoz                                   (0) // bit-field-data shift poZzition
#define test2_hi                                           (0x80000000) // bit-field-data
#define test2_hiShiftPoz                                   (31) // bit-field-data shift poZzition
#define test3                                              (0x02000002)// register-data, r  , unsigned int
#define test3_lo                                           (0x00004000) // bit-field-data
#define test3_loShiftPoz                                   (14) // bit-field-data shift poZzition
#define test3_hi                                           (0x80000000) // bit-field-data
#define test3_hiShiftPoz                                   (31) // bit-field-data shift poZzition
