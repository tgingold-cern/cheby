#include "include\MemMapDSP_muxed.h"

unsigned int get_muxedRegRO() {
	unsigned int* preg = (unsigned int*)muxedRegRO;
	return (unsigned int) *preg;
}
// read-only: muxedRegRO

unsigned int get_muxedRegRW() {
	unsigned int* preg = (unsigned int*)muxedRegRW;
	return (unsigned int) *preg;
}
void set_muxedRegRW(unsigned int val) {
	unsigned int* preg = (unsigned int*)muxedRegRW;
	*preg = val;
}

unsigned short get_regSel() {
	unsigned short* preg = (unsigned short*)regSel;
	return (unsigned short) *preg;
}
void set_regSel(unsigned short val) {
	unsigned short* preg = (unsigned short*)regSel;
	*preg = val;
}

unsigned int get_regSel_channelSelect() {
	unsigned int* preg = (unsigned int*)regSel;
	unsigned int b_lsb = 8;
	unsigned int bval = ( (*preg & regSel_channelSelect) >> b_lsb );
	return bval;
}
void set_regSel_channelSelect(unsigned int bval) {
	unsigned int* preg = (unsigned int*)regSel;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 8;
	unsigned int newval = (oldval & ~regSel_channelSelect) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_regSel_bufferSelect() {
	unsigned int* preg = (unsigned int*)regSel;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & regSel_bufferSelect) >> b_lsb );
	return bval;
}
void set_regSel_bufferSelect(unsigned int bval) {
	unsigned int* preg = (unsigned int*)regSel;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 0;
	unsigned int newval = (oldval & ~regSel_bufferSelect) | (bval << b_lsb);
	*preg = newval;
}

//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
