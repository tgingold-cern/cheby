#define MEMMAP_VERSION (0x0133A24D) // memory map version, format: hex(yyyymmdd)

#define test2                                              (0x02000000)// register-data, r  , unsigned short
#define test3                                              (0x02000001)// register-data, r  , unsigned char
#define test3_lo                                           (0x00000008) // bit-field-data
#define test3_loShiftPoz                                   (3) // bit-field-data shift poZzition
#define test3_hi                                           (0x00000020) // bit-field-data
#define test3_hiShiftPoz                                   (5) // bit-field-data shift poZzition
