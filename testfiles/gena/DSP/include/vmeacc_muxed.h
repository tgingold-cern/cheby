unsigned int get_muxedRegRO(void);
// read-only: muxedRegRO

unsigned int get_muxedRegRW(void);
void set_muxedRegRW(unsigned int val);

unsigned short get_regSel(void);
void set_regSel(unsigned short val);

unsigned int get_regSel_channelSelect(void);
void set_regSel_channelSelect(unsigned int val);

unsigned int get_regSel_bufferSelect(void);
void set_regSel_bufferSelect(unsigned int val);

//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
