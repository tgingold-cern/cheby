#ifndef __CHEBY__SAME_LABEL_REG__H__
#define __CHEBY__SAME_LABEL_REG__H__

#define SAME_LABEL_REG_SIZE 16 /* 0x10 */

/* REG no_fields */
#define SAME_LABEL_REG_NO_FIELDS 0x0UL
#define SAME_LABEL_REG_NO_FIELDS_PRESET 0x20UL

/* REG same_name */
#define SAME_LABEL_REG_SAME_NAME 0x4UL
#define SAME_LABEL_REG_SAME_NAME_MASK 0x1UL
#define SAME_LABEL_REG_SAME_NAME_SHIFT 0

/* REG same_name_multi */
#define SAME_LABEL_REG_SAME_NAME_MULTI 0x8UL
#define SAME_LABEL_REG_SAME_NAME_MULTI_MASK 0xfffUL
#define SAME_LABEL_REG_SAME_NAME_MULTI_SHIFT 0

/* REG not_same_reg */
#define SAME_LABEL_REG_NOT_SAME_REG 0xcUL
#define SAME_LABEL_REG_NOT_SAME 0x1UL
#define SAME_LABEL_REG_NOT_SAME_MASK 0x1UL
#define SAME_LABEL_REG_NOT_SAME_SHIFT 0

#ifndef __ASSEMBLER__
struct same_label_reg {
  /* [0x0]: REG (ro) */
  uint8_t no_fields;

  /* padding to: 4 Bytes */
  uint8_t __padding_0[3];

  /* [0x4]: REG (ro) */
  uint32_t same_name;

  /* [0x8]: REG (ro) */
  uint32_t same_name_multi;

  /* [0xc]: REG (ro) */
  uint32_t not_same_reg;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__SAME_LABEL_REG__H__ */
