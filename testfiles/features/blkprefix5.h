#ifndef __CHEBY__BLKPREFIX3__H__
#define __CHEBY__BLKPREFIX3__H__

#include <stdint.h>

#define BLKPREFIX3_SIZE 48 /* 0x30 */

/* (comment missing) */
#define BLKPREFIX3_B1 0x0UL
#define BLKPREFIX3_B1_SIZE 32 /* 0x20 */

/* (comment missing) */
#define BLKPREFIX3_B1_R1 0x0UL
#define BLKPREFIX3_B1_R1_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R1_F1_SHIFT 0
#define BLKPREFIX3_B1_R1_F2 0x10UL
#define BLKPREFIX3_B1_R1_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R1_F2_SHIFT 4

/* (comment missing) */
#define BLKPREFIX3_B1_R2 0x8UL

/* (comment missing) */
#define BLKPREFIX3_B1_R3 0x10UL
#define BLKPREFIX3_B1_R3_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R3_F1_SHIFT 0
#define BLKPREFIX3_B1_R3_F2 0x10UL
#define BLKPREFIX3_B1_R3_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R3_F2_SHIFT 4

/* (comment missing) */
#define BLKPREFIX3_B1_R4 0x18UL

/* (comment missing) */
#define BLKPREFIX3_B2 0x20UL
#define BLKPREFIX3_B2_SIZE 16 /* 0x10 */

/* (comment missing) */
#define BLKPREFIX3_B2_R1 0x20UL
#define BLKPREFIX3_B2_R1_F1_MASK 0x7UL
#define BLKPREFIX3_B2_R1_F1_SHIFT 0

/* (comment missing) */
#define BLKPREFIX3_B2_R2 0x28UL

#ifndef __ASSEMBLER__
struct blkprefix3 {
  /* [0x0]: BLOCK (comment missing) */
  /* [0x0]: REG (rw) (comment missing) */
  uint32_t r1;

  /* padding to: 8 Bytes */
  uint32_t __padding_0[1];

  /* [0x8]: REG (rw) (comment missing) */
  uint64_t r2;

  /* [0x10]: BLOCK (comment missing) */
  /* [0x0]: REG (rw) (comment missing) */
  uint32_t r3;

  /* padding to: 8 Bytes */
  uint32_t __padding_1[1];

  /* [0x8]: REG (rw) (comment missing) */
  uint64_t r4;

  /* [0x20]: BLOCK (comment missing) */
  struct b2 {
    /* [0x0]: REG (rw) (comment missing) */
    uint32_t r1;

    /* padding to: 8 Bytes */
    uint32_t __padding_0[1];

    /* [0x8]: REG (rw) (comment missing) */
    uint64_t r2;
  } b2;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__BLKPREFIX3__H__ */
