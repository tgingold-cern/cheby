#include "include\MemMapDSP_semver.h"

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
void set_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)test3;
	*preg = val;
}

