#ifndef __CHEBY__MBOX_REGS__H__
#define __CHEBY__MBOX_REGS__H__
#define MBOX_REGS_SIZE 12 /* 0xc */

/* Mailbox to the fip urv */
#define MBOX_REGS_MBOXOUT 0x0UL

/* Mailbox from the fip urv */
#define MBOX_REGS_MBOXIN 0x4UL

/* Status for mailboxes */
#define MBOX_REGS_STATUS 0x8UL
#define MBOX_REGS_STATUS_MBIN 0x1UL
#define MBOX_REGS_STATUS_MBOUT 0x2UL

#ifndef __ASSEMBLER__
struct mbox_regs {
  /* [0x0]: REG (wo) Mailbox to the fip urv */
  uint32_t mboxout;

  /* [0x4]: REG (ro) Mailbox from the fip urv */
  uint32_t mboxin;

  /* [0x8]: REG (ro) Status for mailboxes */
  uint32_t status;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__MBOX_REGS__H__ */
