#include "include\MemMapDSP_submap_internal.h"

unsigned int get_submap1_test1() {
	unsigned int* preg = (unsigned int*)submap1_test1;
	return (unsigned int) *preg;
}
// read-only: submap1_test1

unsigned int get_submap1_test2() {
	unsigned int* preg = (unsigned int*)submap1_test2;
	return (unsigned int) *preg;
}
// read-only: submap1_test2

unsigned int get_submap1_test3() {
	unsigned int* preg = (unsigned int*)submap1_test3;
	return (unsigned int) *preg;
}
void set_submap1_test3(unsigned int val) {
	unsigned int* preg = (unsigned int*)submap1_test3;
	*preg = val;
}

unsigned int get_submap1_test4() {
	unsigned int* preg = (unsigned int*)submap1_test4;
	return (unsigned int) *preg;
}
void set_submap1_test4(unsigned int val) {
	unsigned int* preg = (unsigned int*)submap1_test4;
	*preg = val;
}

unsigned int get_submap1_test5() {
	unsigned int* preg = (unsigned int*)submap1_test5;
	return (unsigned int) *preg;
}
void set_submap1_test5(unsigned int val) {
	unsigned int* preg = (unsigned int*)submap1_test5;
	*preg = val;
}

unsigned int get_submap1_test6() {
	unsigned int* preg = (unsigned int*)submap1_test6;
	return (unsigned int) *preg;
}
void set_submap1_test6(unsigned int val) {
	unsigned int* preg = (unsigned int*)submap1_test6;
	*preg = val;
}

unsigned int get_submap1_test7() {
	unsigned int* preg = (unsigned int*)submap1_test7;
	return (unsigned int) *preg;
}
// read-only: submap1_test7

unsigned int get_submap1_test8() {
	unsigned int* preg = (unsigned int*)submap1_test8;
	return (unsigned int) *preg;
}
// read-only: submap1_test8

