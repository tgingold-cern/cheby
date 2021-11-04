#include "include\MemMapDSP_cregs_srff.h"

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
// read-only: test3

//not implemented ctype for test5: bit_encoding = unsigned, el_width = 64
