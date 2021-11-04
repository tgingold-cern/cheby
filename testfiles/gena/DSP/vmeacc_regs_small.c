#include "include\MemMapDSP_regs_small.h"

unsigned short get_test2() {
	unsigned short* preg = (unsigned short*)test2;
	return (unsigned short) *preg;
}
// read-only: test2

unsigned char get_test3() {
	unsigned char* preg = (unsigned char*)test3;
	return (unsigned char) *preg;
}
// read-only: test3

unsigned int get_test3_lo() {
	unsigned int* preg = (unsigned int*)test3;
	unsigned int b_lsb = 3;
	unsigned int bval = ( (*preg & test3_lo) >> b_lsb );
	return bval;
}
// read-only: test3_lo

unsigned int get_test3_hi() {
	unsigned int* preg = (unsigned int*)test3;
	unsigned int b_lsb = 5;
	unsigned int bval = ( (*preg & test3_hi) >> b_lsb );
	return bval;
}
// read-only: test3_hi

