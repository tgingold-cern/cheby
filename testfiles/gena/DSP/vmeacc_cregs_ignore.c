#include "include\MemMapDSP_cregs_ignore.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
