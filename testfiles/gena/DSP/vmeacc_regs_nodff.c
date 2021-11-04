#include "include\MemMapDSP_regs_nodff.h"

unsigned short get_test1() {
	unsigned short* preg = (unsigned short*)test1;
	return (unsigned short) *preg;
}
// read-only: test1

unsigned int get_test2() {
	unsigned int* preg = (unsigned int*)test2;
	return (unsigned int) *preg;
}
// read-only: test2

