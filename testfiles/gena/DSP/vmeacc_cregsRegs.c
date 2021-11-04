#include "include\MemMapDSP_cregsRegs.h"

unsigned short get_test1() {
	unsigned short* preg = (unsigned short*)test1;
	return (unsigned short) *preg;
}
// read-only: test1

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test2() {
	unsigned int* preg = (unsigned int*)test2;
	return (unsigned int) *preg;
}
void set_test2(unsigned int val) {
	unsigned int* preg = (unsigned int*)test2;
	*preg = val;
}

unsigned int get_test2_lsBit() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test2_lsBit) >> b_lsb );
	return bval;
}
void set_test2_lsBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 0;
	unsigned int newval = (oldval & ~test2_lsBit) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test2_msBit() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test2_msBit) >> b_lsb );
	return bval;
}
void set_test2_msBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 31;
	unsigned int newval = (oldval & ~test2_msBit) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test2_boundryReg() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 14;
	unsigned int bval = ( (*preg & test2_boundryReg) >> b_lsb );
	return bval;
}
void set_test2_boundryReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 14;
	unsigned int newval = (oldval & ~test2_boundryReg) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test2_msReg() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 22;
	unsigned int bval = ( (*preg & test2_msReg) >> b_lsb );
	return bval;
}
void set_test2_msReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 22;
	unsigned int newval = (oldval & ~test2_msReg) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test2_isReg() {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int b_lsb = 6;
	unsigned int bval = ( (*preg & test2_isReg) >> b_lsb );
	return bval;
}
void set_test2_isReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test2;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 6;
	unsigned int newval = (oldval & ~test2_isReg) | (bval << b_lsb);
	*preg = newval;
}

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

unsigned int get_test4_lsBit() {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test4_lsBit) >> b_lsb );
	return bval;
}
void set_test4_lsBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 0;
	unsigned int newval = (oldval & ~test4_lsBit) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test4_msBit() {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test4_msBit) >> b_lsb );
	return bval;
}
void set_test4_msBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 31;
	unsigned int newval = (oldval & ~test4_msBit) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test4_boundryReg() {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int b_lsb = 14;
	unsigned int bval = ( (*preg & test4_boundryReg) >> b_lsb );
	return bval;
}
void set_test4_boundryReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 14;
	unsigned int newval = (oldval & ~test4_boundryReg) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test4_msReg() {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int b_lsb = 22;
	unsigned int bval = ( (*preg & test4_msReg) >> b_lsb );
	return bval;
}
void set_test4_msReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 22;
	unsigned int newval = (oldval & ~test4_msReg) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test4_isReg() {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int b_lsb = 6;
	unsigned int bval = ( (*preg & test4_isReg) >> b_lsb );
	return bval;
}
void set_test4_isReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test4;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 6;
	unsigned int newval = (oldval & ~test4_isReg) | (bval << b_lsb);
	*preg = newval;
}

unsigned short get_test5() {
	unsigned short* preg = (unsigned short*)test5;
	return (unsigned short) *preg;
}
void set_test5(unsigned short val) {
	unsigned short* preg = (unsigned short*)test5;
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

unsigned int get_test6_lsBit() {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test6_lsBit) >> b_lsb );
	return bval;
}
void set_test6_lsBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 0;
	unsigned int newval = (oldval & ~test6_lsBit) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test6_msBit() {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test6_msBit) >> b_lsb );
	return bval;
}
void set_test6_msBit(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 31;
	unsigned int newval = (oldval & ~test6_msBit) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test6_boundryReg() {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int b_lsb = 14;
	unsigned int bval = ( (*preg & test6_boundryReg) >> b_lsb );
	return bval;
}
void set_test6_boundryReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 14;
	unsigned int newval = (oldval & ~test6_boundryReg) | (bval << b_lsb);
	*preg = newval;
}

unsigned int get_test6_msReg() {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int b_lsb = 22;
	unsigned int bval = ( (*preg & test6_msReg) >> b_lsb );
	return bval;
}
void set_test6_msReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 22;
	unsigned int newval = (oldval & ~test6_msReg) | (bval << b_lsb);
	*preg = newval;
}

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test6_isReg() {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int b_lsb = 6;
	unsigned int bval = ( (*preg & test6_isReg) >> b_lsb );
	return bval;
}
void set_test6_isReg(unsigned int bval) {
	unsigned int* preg = (unsigned int*)test6;
	unsigned int oldval = *preg;
	unsigned int b_lsb = 6;
	unsigned int newval = (oldval & ~test6_isReg) | (bval << b_lsb);
	*preg = newval;
}

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

unsigned int get_test8_lsBit() {
	unsigned int* preg = (unsigned int*)test8;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & test8_lsBit) >> b_lsb );
	return bval;
}
// read-only: test8_lsBit

unsigned int get_test8_msBit() {
	unsigned int* preg = (unsigned int*)test8;
	unsigned int b_lsb = 31;
	unsigned int bval = ( (*preg & test8_msBit) >> b_lsb );
	return bval;
}
// read-only: test8_msBit

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test8_boundryReg() {
	unsigned int* preg = (unsigned int*)test8;
	unsigned int b_lsb = 14;
	unsigned int bval = ( (*preg & test8_boundryReg) >> b_lsb );
	return bval;
}
// read-only: test8_boundryReg

unsigned int get_test8_msReg() {
	unsigned int* preg = (unsigned int*)test8;
	unsigned int b_lsb = 22;
	unsigned int bval = ( (*preg & test8_msReg) >> b_lsb );
	return bval;
}
// read-only: test8_msReg

// Not implemented yet: no code-field getter
// Not implemented yet: no code-field getter
unsigned int get_test8_isReg() {
	unsigned int* preg = (unsigned int*)test8;
	unsigned int b_lsb = 6;
	unsigned int bval = ( (*preg & test8_isReg) >> b_lsb );
	return bval;
}
// read-only: test8_isReg

