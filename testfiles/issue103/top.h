#ifndef __CHEBY__TOP__H__
#define __CHEBY__TOP__H__

#include <stdint.h>


#include "sub1.h"
#include "sub2.h"
#include "sub3.h"
#define TOP_SIZE 12 /* 0xc */

/* REG sub1 */
#define TOP_SUB1 0x0UL
#define ADDR_MASK_TOP_SUB1 0xcUL
#define ADDR_FMASK_TOP_SUB1 0xcUL
#define TOP_SUB1_SIZE 4 /* 0x4 */

/* REG sub2 */
#define TOP_SUB2 0x4UL
#define ADDR_MASK_TOP_SUB2 0xcUL
#define ADDR_FMASK_TOP_SUB2 0xcUL
#define TOP_SUB2_SIZE 4 /* 0x4 */

/* REG sub3 */
#define TOP_SUB3 0x8UL
#define ADDR_MASK_TOP_SUB3 0xcUL
#define ADDR_FMASK_TOP_SUB3 0xcUL
#define TOP_SUB3_SIZE 4 /* 0x4 */

#ifndef __ASSEMBLER__
struct top {
  /* [0x0]: SUBMAP */
  struct sub1 sub1;

  /* [0x4]: SUBMAP */
  struct sub2 sub2;

  /* [0x8]: SUBMAP */
  struct sub3 sub3;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__TOP__H__ */
