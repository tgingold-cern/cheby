#include "include\MemMapDSP_cregsRegsNoRMW.h"

unsigned short get_test1() {
	unsigned short* preg = (unsigned short*)test1;
	return (unsigned short) *preg;
}
void set_test1(unsigned short val) {
	unsigned short* preg = (unsigned short*)test1;
	*preg = val;
}

//not implemented ctype for test2: bit_encoding = unsigned, el_width = 64
unsigned short get_test3() {
	unsigned short* preg = (unsigned short*)test3;
	return (unsigned short) *preg;
}
void set_test3(unsigned short val) {
	unsigned short* preg = (unsigned short*)test3;
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

unsigned short get_test5() {
	unsigned short* preg = (unsigned short*)test5;
	return (unsigned short) *preg;
}
void set_test5(unsigned short val) {
	unsigned short* preg = (unsigned short*)test5;
	*preg = val;
}

//not implemented ctype for test6: bit_encoding = unsigned, el_width = 64
unsigned short get_test7() {
	unsigned short* preg = (unsigned short*)test7;
	return (unsigned short) *preg;
}
void set_test7(unsigned short val) {
	unsigned short* preg = (unsigned short*)test7;
	*preg = val;
}

unsigned int get_test8() {
	unsigned int* preg = (unsigned int*)test8;
	return (unsigned int) *preg;
}
void set_test8(unsigned int val) {
	unsigned int* preg = (unsigned int*)test8;
	*preg = val;
}

