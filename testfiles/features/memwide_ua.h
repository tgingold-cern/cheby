#ifndef __CHEBY__MEMWIDE_UA__H__
#define __CHEBY__MEMWIDE_UA__H__
#define MEMWIDE_UA_SIZE 256 /* 0x100 */

/* The first register (with some fields) */
#define MEMWIDE_UA_REGA 0x0UL
#define MEMWIDE_UA_REGA_FIELD0 0x2UL

/* None */
#define MEMWIDE_UA_TS 0x80UL
#define MEMWIDE_UA_TS_SIZE 16 /* 0x10 */

/* None */
#define MEMWIDE_UA_TS_RISE_SEC 0x0UL

/* None */
#define MEMWIDE_UA_TS_RISE_NS 0x4UL

/* None */
#define MEMWIDE_UA_TS_FALL_SEC 0x8UL

#ifndef __ASSEMBLER__
struct memwide_ua {
  /* [0x0]: REG (rw) The first register (with some fields) */
  uint32_t regA;

  /* padding to: 128 Bytes */
  uint32_t __padding_0[31];

  /* [0x80]: MEMORY (no description) */
  struct ts {
    /* [0x0]: REG (ro) (no description) */
    uint32_t rise_sec;

    /* [0x4]: REG (ro) (no description) */
    uint32_t rise_ns;

    /* [0x8]: REG (ro) (no description) */
    uint32_t fall_sec;

    /* padding to: 16 Bytes */
    uint32_t __padding_0[1];
  } ts[8];
};
#endif /* !__ASSEMBLER__*/

#endif /* __CHEBY__MEMWIDE_UA__H__ */
