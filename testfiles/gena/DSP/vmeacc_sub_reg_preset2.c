#include "include\MemMapDSP_sub_reg_preset2.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

unsigned int get_test1_b15() {
	unsigned int* preg = (unsigned int*)test1;
	unsigned int b_lsb = 15;
	unsigned int bval = ( (*preg & test1_b15) >> b_lsb );
	return bval;
}
// read-only: test1_b15

unsigned int get_test1_w14() {
	unsigned int* preg = (unsigned int*)test1;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test1_w14) >> b_lsb );
	return bval;
}
// read-only: test1_w14

