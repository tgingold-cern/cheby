#include "include\MemMapDSP_regs_cross_words.h"

unsigned int get_test2() {
	unsigned int* preg = (unsigned int*)test2;
	return (unsigned int) *preg;
}
// read-only: test2

unsigned int get_test2_lo() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test2_lo) >> b_lsb );
	return bval;
}
// read-only: test2_lo

unsigned int get_test2_hi() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test2_hi) >> b_lsb );
	return bval;
}
// read-only: test2_hi

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
// read-only: test3

unsigned int get_test3_lo() {
	unsigned int* preg = (unsigned int*)test3;
	unsigned int b_lsb = 14;
	unsigned int bval = ( (*preg & test3_lo) >> b_lsb );
	return bval;
}
// read-only: test3_lo

unsigned int get_test3_hi() {
	unsigned int* preg = (unsigned int*)test3;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test3_hi) >> b_lsb );
	return bval;
}
// read-only: test3_hi

