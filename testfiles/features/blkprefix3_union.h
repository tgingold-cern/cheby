#ifndef __CHEBY__BLKPREFIX3__H__
#define __CHEBY__BLKPREFIX3__H__

#include <stdint.h>

#define BLKPREFIX3_SIZE 12 /* 0xc */

/* REG b1 */
#define BLKPREFIX3_B1 0x0UL
#define ADDR_MASK_BLKPREFIX3_B1 0x8UL
#define ADDR_FMASK_BLKPREFIX3_B1 0x8UL
#define BLKPREFIX3_B1_SIZE 8 /* 0x8 */

/* REG r2 */
#define BLKPREFIX3_B1_R2 0x0UL
#define BLKPREFIX3_B1_R2_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R2_F1_SHIFT 0
#define BLKPREFIX3_B1_R2_F2 0x10UL
#define BLKPREFIX3_B1_R2_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R2_F2_SHIFT 4

/* REG r3 */
#define BLKPREFIX3_B1_R3 0x4UL
#define BLKPREFIX3_B1_R3_F1_MASK 0x7UL
#define BLKPREFIX3_B1_R3_F1_SHIFT 0
#define BLKPREFIX3_B1_R3_F2 0x10UL
#define BLKPREFIX3_B1_R3_F2_MASK 0x10UL
#define BLKPREFIX3_B1_R3_F2_SHIFT 4

/* REG b2 */
#define BLKPREFIX3_B2 0x8UL
#define ADDR_MASK_BLKPREFIX3_B2 0xcUL
#define ADDR_FMASK_BLKPREFIX3_B2 0xcUL
#define BLKPREFIX3_B2_SIZE 4 /* 0x4 */

/* REG r3 */
#define BLKPREFIX3_B2_R3 0x8UL
#define BLKPREFIX3_B2_R3_F1_MASK 0x7UL
#define BLKPREFIX3_B2_R3_F1_SHIFT 0

#ifndef __ASSEMBLER__
/* Bit Field Structures */
/* [0x0]: REG r2 */
typedef struct {
  uint32_t f1: 3;
  uint32_t : 1;
  uint32_t f2: 1;
  uint32_t : 27;
} b1_r2_s;

typedef union {
  uint32_t v;
  b1_r2_s s;
} b1_r2_u;

/* [0x0]: REG r3 */
typedef struct {
  uint32_t f1: 3;
  uint32_t : 1;
  uint32_t f2: 1;
  uint32_t : 27;
} b1_r3_s;

typedef union {
  uint32_t v;
  b1_r3_s s;
} b1_r3_u;

/* [0x0]: REG r3 */
typedef struct {
  uint32_t f1: 3;
  uint32_t : 29;
} b2_r3_s;

typedef union {
  uint32_t v;
  b2_r3_s s;
} b2_r3_u;

/* Register Map Structure */
struct blkprefix3 {
  /* [0x0]: BLOCK */
  /* [0x0]: REG (rw) */
  b1_r2_u r2;

  /* [0x4]: BLOCK */
  /* [0x0]: REG (rw) */
  b1_r3_u r3;

  /* [0x8]: BLOCK */
  struct b2 {
    /* [0x0]: REG (rw) */
    b2_r3_u r3;
  } b2;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__BLKPREFIX3__H__ */
