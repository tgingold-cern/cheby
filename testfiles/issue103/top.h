#ifndef __CHEBY__TOP__H__
#define __CHEBY__TOP__H__

#include "sub1.h"
#include "sub2.h"
#include "sub3.h"
#define TOP_SIZE 12 /* 0xc */

/* A normal submap */
#define TOP_SUB1 0x0UL
#define ADDR_MASK_TOP_SUB1 0xcUL
#define TOP_SUB1_SIZE 4 /* 0x4 */

/* An included submap */
#define TOP_SUB2 0x4UL
#define ADDR_MASK_TOP_SUB2 0xcUL
#define TOP_SUB2_SIZE 4 /* 0x4 */

/* An included submap */
#define TOP_SUB3 0x8UL
#define ADDR_MASK_TOP_SUB3 0xcUL
#define TOP_SUB3_SIZE 4 /* 0x4 */

struct top {
  /* [0x0]: SUBMAP A normal submap */
  struct sub1 sub1;

  /* [0x4]: SUBMAP An included submap */
  struct sub2 sub2;

  /* [0x8]: SUBMAP An included submap */
  struct sub3 sub3;
};

#endif /* __CHEBY__TOP__H__ */
