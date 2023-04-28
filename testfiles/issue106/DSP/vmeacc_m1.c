#include "include\MemMapDSP_m1.h"

unsigned int get_m2_r1() {
	unsigned int* preg = (unsigned int*)m2_r1;
	return (unsigned int) *preg;
}
void set_m2_r1(unsigned int val) {
	unsigned int* preg = (unsigned int*)m2_r1;
	*preg = val;
}

unsigned int get_m2_r1_enumeration() {
	unsigned int* preg = (unsigned int*)r1;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & m2_r1_enumeration) >> b_lsb );
	return bval;
}
void set_m2_r1_enumeration(unsigned int bval) {
	unsigned int* preg = (unsigned int*)r1;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 0;
	unsigned int newval = (oldval & ~m2_r1_enumeration) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_m2_r2() {
	unsigned int* preg = (unsigned int*)m2_r2;
	return (unsigned int) *preg;
}
void set_m2_r2(unsigned int val) {
	unsigned int* preg = (unsigned int*)m2_r2;
	*preg = val;
}

unsigned int get_m2_r3() {
	unsigned int* preg = (unsigned int*)m2_r3;
	return (unsigned int) *preg;
}
void set_m2_r3(unsigned int val) {
	unsigned int* preg = (unsigned int*)m2_r3;
	*preg = val;
}

unsigned int get_m2_r4() {
	unsigned int* preg = (unsigned int*)m2_r4;
	return (unsigned int) *preg;
}
void set_m2_r4(unsigned int val) {
	unsigned int* preg = (unsigned int*)m2_r4;
	*preg = val;
}

