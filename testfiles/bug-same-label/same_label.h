#ifndef __CHEBY__SAME_LABEL_REG__H__
#define __CHEBY__SAME_LABEL_REG__H__

#include <stdint.h>

#define SAME_LABEL_REG_SIZE 16 /* 0x10 */

/* Register without fields. */
#define SAME_LABEL_REG_NO_FIELDS 0x0UL
#define SAME_LABEL_REG_NO_FIELDS_PRESET 0x20UL

/* Register with same-name field. */
#define SAME_LABEL_REG_SAME_NAME 0x4UL

/* Register with multi-bit same-name field. */
#define SAME_LABEL_REG_SAME_NAME_MULTI 0x8UL
#define SAME_LABEL_REG_SAME_NAME_MULTI_MASK 0xfffUL
#define SAME_LABEL_REG_SAME_NAME_MULTI_SHIFT 0

/* Register with different-name field. */
#define SAME_LABEL_REG_NOT_SAME_REG 0xcUL
#define SAME_LABEL_REG_NOT_SAME 0x1UL

#ifndef __ASSEMBLER__
struct same_label_reg {
  /* [0x0]: REG (ro) Register without fields. */
  uint8_t no_fields;

  /* padding to: 4 Bytes */
  uint8_t __padding_0[3];

  /* [0x4]: REG (ro) Register with same-name field. */
  uint32_t same_name;

  /* [0x8]: REG (ro) Register with multi-bit same-name field. */
  uint32_t same_name_multi;

  /* [0xc]: REG (ro) Register with different-name field. */
  uint32_t not_same_reg;
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__SAME_LABEL_REG__H__ */
