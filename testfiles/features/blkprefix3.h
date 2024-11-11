#ifndef __CHEBY__BLKPREFIX3__H__
#define __CHEBY__BLKPREFIX3__H__

#include <stdint.h>

#define BLKPREFIX3_SIZE 12 /* 0xc */

/* (comment missing) */
#define BLKPREFIX3_B1 0x0UL
#define BLKPREFIX3_B1_SIZE 8 /* 0x8 */

/* (comment missing) */
#define BLKPREFIX3_B1_R2 0x0UL
#define BLKPREFIX3_B1_R2_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R2_F1_SHIFT 0
#define BLKPREFIX3_B1_R2_F2 0x10UL
#define BLKPREFIX3_B1_R2_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R2_F2_SHIFT 4

/* (comment missing) */
#define BLKPREFIX3_B1_R3 0x4UL
#define BLKPREFIX3_B1_R3_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R3_F1_SHIFT 0
#define BLKPREFIX3_B1_R3_F2 0x10UL
#define BLKPREFIX3_B1_R3_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R3_F2_SHIFT 4

/* (comment missing) */
#define BLKPREFIX3_B2 0x8UL
#define BLKPREFIX3_B2_SIZE 4 /* 0x4 */

/* (comment missing) */
#define BLKPREFIX3_B2_R3 0x8UL
#define BLKPREFIX3_B2_R3_F1_MASK 0x7UL
#define BLKPREFIX3_B2_R3_F1_SHIFT 0

#ifndef __ASSEMBLER__
struct blkprefix3 {
  /* [0x0]: BLOCK (comment missing) */
  /* [0x0]: REG (rw) (comment missing) */
  uint32_t r2;

  /* [0x4]: BLOCK (comment missing) */
  /* [0x0]: REG (rw) (comment missing) */
  uint32_t r3;

  /* [0x8]: BLOCK (comment missing) */
  struct b2 {
    /* [0x0]: REG (rw) (comment missing) */
    uint32_t r3;
  } b2;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__BLKPREFIX3__H__ */
