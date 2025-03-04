#ifndef __CHEBY__REPEATINREPEATC__H__
#define __CHEBY__REPEATINREPEATC__H__

#include <stdint.h>

#define REPEATINREPEATC_SIZE 32 /* 0x20 */

/* REG repA */
#define REPEATINREPEATC_REPA 0x0UL
#define REPEATINREPEATC_REPA_SIZE 8 /* 0x8 */

/* REG block1 */
#define REPEATINREPEATC_REPA_BLOCK1 0x0UL
#define ADDR_MASK_REPEATINREPEATC_REPA_BLOCK1 0x18UL
#define ADDR_FMASK_REPEATINREPEATC_REPA_BLOCK1 0x18UL
#define REPEATINREPEATC_REPA_BLOCK1_SIZE 8 /* 0x8 */

/* REG repB */
#define REPEATINREPEATC_REPA_BLOCK1_REPB 0x0UL
#define REPEATINREPEATC_REPA_BLOCK1_REPB_SIZE 4 /* 0x4 */

/* REG reg1 */
#define REPEATINREPEATC_REPA_BLOCK1_REPB_REG1 0x0UL

#ifndef __ASSEMBLER__
struct repeatInRepeatC {
  /* [0x0]: REPEAT */
  struct repeatInRepeatC_repA {
    /* [0x0]: BLOCK */
    struct repeatInRepeatC_repA_block1 {
      /* [0x0]: REPEAT */
      struct repeatInRepeatC_repA_block1_repB {
        /* [0x0]: REG (rw) */
        uint8_t reg1;

        /* padding to: 4 Bytes */
        uint8_t __padding_0[3];
      } repB[2];
    } block1;
  } repA[4];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__REPEATINREPEATC__H__ */
