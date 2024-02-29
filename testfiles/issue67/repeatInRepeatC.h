#ifndef __CHEBY__REPEATINREPEATC__H__
#define __CHEBY__REPEATINREPEATC__H__
#define REPEATINREPEATC_SIZE 32 /* 0x20 */

/* None */
#define REPEATINREPEATC_REPA 0x0UL
#define REPEATINREPEATC_REPA_SIZE 8 /* 0x8 */

/* None */
#define REPEATINREPEATC_REPA_BLOCK1 0x0UL
#define REPEATINREPEATC_REPA_BLOCK1_SIZE 8 /* 0x8 */

/* None */
#define REPEATINREPEATC_REPA_BLOCK1_REPB 0x0UL
#define REPEATINREPEATC_REPA_BLOCK1_REPB_SIZE 4 /* 0x4 */

/* None */
#define REPEATINREPEATC_REPA_BLOCK1_REPB_REG1 0x0UL

#ifndef __ASSEMBLER__
struct repeatInRepeatC {
  /* [0x0]: REPEAT (no description) */
  struct repeatInRepeatC_repA {
    /* [0x0]: BLOCK (no description) */
    struct repeatInRepeatC_repA_block1 {
      /* [0x0]: REPEAT (no description) */
      struct repeatInRepeatC_repA_block1_repB {
        /* [0x0]: REG (rw) (no description) */
        uint8_t reg1;

        /* padding to: 4 Bytes */
        uint8_t __padding_0[3];
      } repB[2];
    } block1;
  } repA[4];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__REPEATINREPEATC__H__ */
