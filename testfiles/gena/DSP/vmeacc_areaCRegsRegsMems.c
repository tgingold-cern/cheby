#include "include\MemMapDSP_areaCRegsRegsMems.h"

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
unsigned int get_test7() {
	unsigned int* preg = (unsigned int*)test7;
	return (unsigned int) *preg;
}
// read-only: test7

//not implemented ctype for test8: bit_encoding = unsigned, el_width = 64
//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
unsigned int get_area_test1() {
	unsigned int* preg = (unsigned int*)area_test1;
	return (unsigned int) *preg;
}
// read-only: area_test1

//not implemented ctype for area_test2: bit_encoding = unsigned, el_width = 64
unsigned int get_area_test3() {
	unsigned int* preg = (unsigned int*)area_test3;
	return (unsigned int) *preg;
}
void set_area_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)area_test3;
	*preg = val;
}

//not implemented ctype for area_test4: bit_encoding = unsigned, el_width = 64
unsigned int get_area_test5() {
	unsigned int* preg = (unsigned int*)area_test5;
	return (unsigned int) *preg;
}
void set_area_test5(unsigned int val) {
	unsigned int* preg = (unsigned int*)area_test5;
	*preg = val;
}

//not implemented ctype for area_test6: bit_encoding = unsigned, el_width = 64
//not implemented ctype for area_test7: bit_encoding = unsigned, el_width = 64
//not implemented ctype for area_test8: bit_encoding = unsigned, el_width = 64
//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
