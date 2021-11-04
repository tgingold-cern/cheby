#include "include\MemMapDSP_areaCRegs.h"

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
void set_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)test3;
	*preg = val;
}

//not implemented ctype for test4: bit_encoding = unsigned, el_width = 64
unsigned int get_area1_test1() {
	unsigned int* preg = (unsigned int*)area1_test1;
	return (unsigned int) *preg;
}
void set_area1_test1(unsigned int val) {
	unsigned int* preg = (unsigned int*)area1_test1;
	*preg = val;
}

//not implemented ctype for area1_test2: bit_encoding = unsigned, el_width = 64
unsigned int get_area2_test1() {
	unsigned int* preg = (unsigned int*)area2_test1;
	return (unsigned int) *preg;
}
void set_area2_test1(unsigned int val) {
	unsigned int* preg = (unsigned int*)area2_test1;
	*preg = val;
}

//not implemented ctype for area2_test3: bit_encoding = unsigned, el_width = 64
