#ifndef __CHEBY__MBOX_REGS__H__
#define __CHEBY__MBOX_REGS__H__

#define MBOX_REGS_SIZE 12 /* 0xc */

/* REG mboxout */
#define MBOX_REGS_MBOXOUT 0x0UL

/* REG mboxin */
#define MBOX_REGS_MBOXIN 0x4UL

/* REG status */
#define MBOX_REGS_STATUS 0x8UL
#define MBOX_REGS_STATUS_MBIN 0x1UL
#define MBOX_REGS_STATUS_MBIN_MASK 0x1UL
#define MBOX_REGS_STATUS_MBIN_SHIFT 0
#define MBOX_REGS_STATUS_MBOUT 0x2UL
#define MBOX_REGS_STATUS_MBOUT_MASK 0x2UL
#define MBOX_REGS_STATUS_MBOUT_SHIFT 1

#ifndef __ASSEMBLER__
/* Bit Field Structures */
/* [0x8]: REG status */
typedef struct {
  uint32_t mbin: 1;
  uint32_t mbout: 1;
  uint32_t _bits_2_to_31: 30;
} status_s;

typedef union {
  uint32_t v;
  status_s s;
} status_u;

/* Register Map Structure */
struct mbox_regs {
  /* [0x0]: REG (wo) */
  uint32_t mboxout;

  /* [0x4]: REG (ro) */
  uint32_t mboxin;

  /* [0x8]: REG (ro) */
  status_u status;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__MBOX_REGS__H__ */
