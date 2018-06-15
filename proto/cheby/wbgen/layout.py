"""Layout a peripheral: set addresses and bits."""
import cheby.wbgen.tree as tree
import cheby.wbgen.field_layout as field_layout

DATA_WIDTH = field_layout.DATA_WIDTH
DATA_BYTES = field_layout.DATA_BYTES


def align_offset(offset, algn):
    if offset == 0:
        # Looks artificial, needed for EIC ?
        return algn
    diff = offset % algn
    if diff != 0:
        return offset + algn - diff
    else:
        return offset


def layout_anyreg(r, offset):
    # Align
    if r.align is not None:
        offset = align_offset(offset, r.align)
    r.addr_base = offset
    offset += 1

    # Sanity check
    for f in r.fields:
        assert f.bit_offset + f.bit_len <= DATA_WIDTH

    return offset


def layout(n):
    """Do layout of Peripheral n."""

    # The registers (that includes Fifos as they have been expanded)
    offset = 0
    for r in n.ordered_regs:
        if isinstance(r, tree.Reg) \
           or isinstance(r, tree.IrqReg) \
           or isinstance(r, tree.FifoReg) \
           or isinstance(r, tree.FifoCSReg):
            offset = layout_anyreg(r, offset)
    reg_len = offset

    # The rams
    max_ram_size = 0
    nbr_rams = 0
    for r in n.regs:
        if isinstance(r, tree.Ram):
            assert r.width <= DATA_WIDTH
            sz = r.size
            assert sz > 0
            if r.wrap_bits:
                sz = sz << r.wrap_bits
            r.ram_wrap_size = sz
            max_ram_size = max(max_ram_size, sz)
            nbr_rams += 1

    # Split the address space into blocks (of equal length). One block
    # for registers (if any) and one block per ram
    nbr_blocks = nbr_rams + (1 if reg_len > 0 else 0)
    block_size = max(reg_len, max_ram_size)
    assert block_size > 0, "there must be at least one reg or one ram"
    # Round to a power of 2.
    n.blk_bits = field_layout.ilog2(block_size)
    n.sel_bits = field_layout.ilog2(nbr_blocks)
    n.reg_bits = 0 if reg_len == 0 else field_layout.ilog2(reg_len)
    block_size = 1 << n.blk_bits

    # Assign ram addresses
    ram_off = block_size if reg_len > 0 else 0
    for r in n.regs:
        if isinstance(r, tree.Ram):
            r.addr_base = ram_off
            r.addr_len = r.ram_wrap_size
            ram_off += block_size
