#include "include\MemMapDSP_cregs_resize_nosplit.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
void set_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)test3;
	*preg = val;
}

unsigned int get_test5() {
	unsigned int* preg = (unsigned int*)test5;
	return (unsigned int) *preg;
}
void set_test5(unsigned int val) {
	unsigned int* preg = (unsigned int*)test5;
	*preg = val;
}

