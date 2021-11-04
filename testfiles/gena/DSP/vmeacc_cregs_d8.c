#include "include\MemMapDSP_cregs_d8.h"

unsigned int get_test1() {
	unsigned int* preg = (unsigned int*)test1;
	return (unsigned int) *preg;
}
// read-only: test1

unsigned int get_test2() {
	unsigned int* preg = (unsigned int*)test2;
	return (unsigned int) *preg;
}
// read-only: test2

unsigned int get_test3() {
	unsigned int* preg = (unsigned int*)test3;
	return (unsigned int) *preg;
}
void set_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)test3;
	*preg = val;
}

unsigned int get_test4() {
	unsigned int* preg = (unsigned int*)test4;
	return (unsigned int) *preg;
}
void set_test4(unsigned int val) {
	unsigned int* preg = (unsigned int*)test4;
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

unsigned int get_test6() {
	unsigned int* preg = (unsigned int*)test6;
	return (unsigned int) *preg;
}
void set_test6(unsigned int val) {
	unsigned int* preg = (unsigned int*)test6;
	*preg = val;
}

unsigned int get_test7() {
	unsigned int* preg = (unsigned int*)test7;
	return (unsigned int) *preg;
}
// read-only: test7

unsigned int get_test8() {
	unsigned int* preg = (unsigned int*)test8;
	return (unsigned int) *preg;
}
// read-only: test8

