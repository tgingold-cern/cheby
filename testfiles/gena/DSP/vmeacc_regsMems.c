#include "include\MemMapDSP_regsMems.h"

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

unsigned short get_test3() {
	unsigned short* preg = (unsigned short*)test3;
	return (unsigned short) *preg;
}
// read-only: test3

unsigned int get_test4() {
	unsigned int* preg = (unsigned int*)test4;
	return (unsigned int) *preg;
}
// read-only: test4

unsigned short get_test5() {
	unsigned short* preg = (unsigned short*)test5;
	return (unsigned short) *preg;
}
// read-only: test5

unsigned int get_test6() {
	unsigned int* preg = (unsigned int*)test6;
	return (unsigned int) *preg;
}
// read-only: test6

unsigned short get_test7() {
	unsigned short* preg = (unsigned short*)test7;
	return (unsigned short) *preg;
}
// read-only: test7

unsigned int get_test8() {
	unsigned int* preg = (unsigned int*)test8;
	return (unsigned int) *preg;
}
// read-only: test8

//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
//not_implemented: getter of a memory-data element
//not_implemented: setter of a memory-data element
