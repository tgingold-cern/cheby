#include "include\MemMapDSP_cregs_resize.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
void set_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)test3;
	*preg = val;
}

//not implemented ctype for test4: bit_encoding = unsigned, el_width = 64
unsigned int get_test5() {
	unsigned int* preg = (unsigned int*)test5;
	return (unsigned int) *preg;
}
void set_test5(unsigned int val) {
	unsigned int* preg = (unsigned int*)test5;
	*preg = val;
}

//not implemented ctype for test6: bit_encoding = unsigned, el_width = 64
