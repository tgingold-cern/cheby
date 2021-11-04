#include "include\MemMapDSP_cregs_busout.h"

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

//not implemented ctype for test3: bit_encoding = unsigned, el_width = 64
unsigned int get_test3_b31() {
	unsigned int* preg = (unsigned int*)test3;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test3_b31) >> b_lsb );
	return bval;
}
// read-only: test3_b31

unsigned int get_test5() {
	unsigned int* preg = (unsigned int*)test5;
	return (unsigned int) *preg;
}
// read-only: test5

unsigned int get_test5_b31() {
	unsigned int* preg = (unsigned int*)test5;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test5_b31) >> b_lsb );
	return bval;
}
// read-only: test5_b31

unsigned int get_test7() {
	unsigned int* preg = (unsigned int*)test7;
	return (unsigned int) *preg;
}
// read-only: test7

unsigned int get_test7_b31() {
	unsigned int* preg = (unsigned int*)test7;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test7_b31) >> b_lsb );
	return bval;
}
// read-only: test7_b31

