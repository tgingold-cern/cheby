#ifndef __CHEBY__REPEATINREPEAT__H__
#define __CHEBY__REPEATINREPEAT__H__

#include <stdint.h>

#define REPEATINREPEAT_SIZE 32 /* 0x20 */

/* (comment missing) */
#define REPEATINREPEAT_REPA 0x0UL
#define REPEATINREPEAT_REPA_SIZE 8 /* 0x8 */

/* (comment missing) */
#define REPEATINREPEAT_REPA_BLOCK1 0x0UL
#define REPEATINREPEAT_REPA_BLOCK1_SIZE 8 /* 0x8 */

/* (comment missing) */
#define REPEATINREPEAT_REPA_BLOCK1_REPB 0x0UL
#define REPEATINREPEAT_REPA_BLOCK1_REPB_SIZE 4 /* 0x4 */

/* (comment missing) */
#define REPEATINREPEAT_REPA_BLOCK1_REPB_REG1 0x0UL

#ifndef __ASSEMBLER__
struct repeatInRepeat {
  /* [0x0]: REPEAT (comment missing) */
  struct repA {
    /* [0x0]: BLOCK (comment missing) */
    struct repA_block1 {
      /* [0x0]: REPEAT (comment missing) */
      struct repA_block1_repB {
        /* [0x0]: REG (rw) (comment missing) */
        uint8_t reg1;

        /* padding to: 4 Bytes */
        uint8_t __padding_0[3];
      } repB[2];
    } block1;
  } repA[4];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__REPEATINREPEAT__H__ */
