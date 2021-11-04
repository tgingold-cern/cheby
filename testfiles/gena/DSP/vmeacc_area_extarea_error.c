#include "include\MemMapDSP_area_extarea_error.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

unsigned int get_area_test1() {
	unsigned int* preg = (unsigned int*)area_test1;
	return (unsigned int) *preg;
}
// read-only: area_test1

