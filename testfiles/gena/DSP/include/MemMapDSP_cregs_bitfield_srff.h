#define MEMMAP_VERSION (0x0133A207) // memory map version, format: hex(yyyymmdd)

#define test1                                              (0x02000000)// register-data, r  , unsigned int
#define test1_b15                                          (0x00008000) // bit-field-data
#define test1_b15ShiftPoz                                  (15) // bit-field-data shift poZzition
#define test1_w14                                          (0x00003FFF) // sub-reg
#define test1_w14ShiftPoz                                  (0) // sub-reg shift poZzition
