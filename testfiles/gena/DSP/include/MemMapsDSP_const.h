#define MEMMAP_VERSION (0x0134158F) // memory map version, format: hex(yyyymmdd)

#define firmwareVersion                                    (0x02000000)// register-data, r  , unsigned int
#define memMapVersion                                      (0x02000001)// register-data, r  , unsigned int
#define designerID                                         (0x02000002)// register-data, r  , unsigned int
#define designerID_fwDesigner                              (0x0000FFFF) // sub-reg
#define designerID_fwDesignerShiftPoz                      (0) // sub-reg shift poZzition
#define designerID_hwDesigner                              (0xFFFF0000) // sub-reg
#define designerID_hwDesignerShiftPoz                      (16) // sub-reg shift poZzition
