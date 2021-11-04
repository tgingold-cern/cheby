#include "include\MemMapDSP_area_reserved.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
void set_test1(unsigned int val) {
	unsigned int* preg = (unsigned int*)test1;
	*preg = val;
}

unsigned int get_area_test2() {
	unsigned int* preg = (unsigned int*)area_test2;
	return (unsigned int) *preg;
}
// read-only: area_test2

