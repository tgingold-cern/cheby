#define MEMMAP_VERSION (0x0133EE21) // memory map version, format: hex(yyyymmdd)

#define muxedRegRO                                         (0x02000000)// register-data, r  , unsigned int
#define muxedRegRW                                         (0x02000002)// register-data, rw , unsigned int
#define regSel                                             (0x02000004)// register-data, rw , unsigned short
#define regSel_channelSelect                               (0x0000FF00) // sub-reg
#define regSel_channelSelectShiftPoz                       (8) // sub-reg shift poZzition
#define regSel_bufferSelect                                (0x000000FF) // sub-reg
#define regSel_bufferSelectShiftPoz                        (0) // sub-reg shift poZzition
#define Mem                                                (0x02040000)// memory-data, rw , unknown type
