#ifndef __CHEBY__FIP_URV_REGS__H__
#define __CHEBY__FIP_URV_REGS__H__

#include <stdint.h>


#include "mbox_regs.h"
#define FIP_URV_REGS_SIZE 16384 /* 0x4000 = 16KB */

/* (comment missing) */
#define FIP_URV_REGS_PLC_CTRL 0x0UL
#define FIP_URV_REGS_PLC_CTRL_RSTN 0x1UL
#define FIP_URV_REGS_PLC_CTRL_RSTN_MASK 0x1UL
#define FIP_URV_REGS_PLC_CTRL_RSTN_SHIFT 0
#define FIP_URV_REGS_PLC_CTRL_RSTN_PRESET 0x0UL

/* (comment missing) */
#define FIP_URV_REGS_FIP_STATUS 0x4UL
#define FIP_URV_REGS_FIP_STATUS_VAR1_RDY 0x1UL
#define FIP_URV_REGS_FIP_STATUS_VAR1_RDY_MASK 0x1UL
#define FIP_URV_REGS_FIP_STATUS_VAR1_RDY_SHIFT 0
#define FIP_URV_REGS_FIP_STATUS_VAR3_RDY 0x2UL
#define FIP_URV_REGS_FIP_STATUS_VAR3_RDY_MASK 0x2UL
#define FIP_URV_REGS_FIP_STATUS_VAR3_RDY_SHIFT 1

/* (comment missing) */
#define FIP_URV_REGS_FIP_VAR1 0x8UL
#define FIP_URV_REGS_FIP_VAR1_ACC 0x1UL
#define FIP_URV_REGS_FIP_VAR1_ACC_MASK 0x1UL
#define FIP_URV_REGS_FIP_VAR1_ACC_SHIFT 0

/* (comment missing) */
#define FIP_URV_REGS_FIP_VAR3 0xcUL
#define FIP_URV_REGS_FIP_VAR3_ACC 0x1UL
#define FIP_URV_REGS_FIP_VAR3_ACC_MASK 0x1UL
#define FIP_URV_REGS_FIP_VAR3_ACC_SHIFT 0

/* (comment missing) */
#define FIP_URV_REGS_MAILBOXES 0x10UL
#define ADDR_MASK_FIP_URV_REGS_MAILBOXES 0x3ff0UL
#define FIP_URV_REGS_MAILBOXES_SIZE 16 /* 0x10 */

/* (comment missing) */
#define FIP_URV_REGS_PRESENCE 0x20UL
#define FIP_URV_REGS_PRESENCE_EN_MASK 0xffUL
#define FIP_URV_REGS_PRESENCE_EN_SHIFT 0

/* (comment missing) */
#define FIP_URV_REGS_LEDS 0x24UL
#define FIP_URV_REGS_LEDS_VAL_MASK 0x3fUL
#define FIP_URV_REGS_LEDS_VAL_SHIFT 0

/* (comment missing) */
#define FIP_URV_REGS_BOARDS 0x40UL
#define FIP_URV_REGS_BOARDS_SIZE 4 /* 0x4 */

/* (comment missing) */
#define FIP_URV_REGS_BOARDS_PINS 0x0UL

/* (comment missing) */
#define FIP_URV_REGS_FIP_REG 0x800UL
#define ADDR_MASK_FIP_URV_REGS_FIP_REG 0x3800UL
#define FIP_URV_REGS_FIP_REG_SIZE 2048 /* 0x800 = 2KB */

/* (comment missing) */
#define FIP_URV_REGS_PLC_MEM 0x2000UL
#define ADDR_MASK_FIP_URV_REGS_PLC_MEM 0x2000UL
#define FIP_URV_REGS_PLC_MEM_SIZE 8192 /* 0x2000 = 8KB */

#ifndef __ASSEMBLER__
struct fip_urv_regs {
  /* [0x0]: REG (rw) (comment missing) */
  uint32_t plc_ctrl;

  /* [0x4]: REG (ro) (comment missing) */
  uint32_t fip_status;

  /* [0x8]: REG (rw) (comment missing) */
  uint32_t fip_var1;

  /* [0xc]: REG (rw) (comment missing) */
  uint32_t fip_var3;

  /* [0x10]: SUBMAP (comment missing) */
  struct mbox_regs mailboxes;

  /* padding to: 32 Bytes */
  uint32_t __padding_0[1];

  /* [0x20]: REG (ro) (comment missing) */
  uint32_t presence;

  /* [0x24]: REG (rw) (comment missing) */
  uint32_t leds;

  /* padding to: 64 Bytes */
  uint32_t __padding_1[6];

  /* [0x40]: REPEAT (comment missing) */
  struct boards {
    /* [0x0]: REG (ro) (comment missing) */
    uint32_t pins;
  } boards[8];

  /* padding to: 2048 Bytes */
  uint32_t __padding_2[488];

  /* [0x800]: SUBMAP (comment missing) */
  uint32_t fip_reg[512];

  /* padding to: 8192 Bytes */
  uint32_t __padding_3[1024];

  /* [0x2000]: SUBMAP (comment missing) */
  uint32_t plc_mem[2048];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__FIP_URV_REGS__H__ */
