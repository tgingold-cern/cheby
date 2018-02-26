"""Layout - perform address layout.
   Check and compute address of all nodes,
   Check fields.

   TODO:
   - check names are uniq (case ?)
   - check names/description are present
   - check names are C identifiers
   - check preset values are in the range.
"""

import tree


def ilog2(val):
    "Return n such as 2**n >= val and 2**(n-1) < val"
    assert val > 0
    v = 1
    for n in range(32):
        if v >= val:
            return n
        v *= 2


def round_pow2(val):
    return 1 << ilog2(val)


def align(n, mul):
    """Return n aligned to the next multiple of mul"""
    return ((n + mul - 1) // mul) * mul


class Layout(tree.Visitor):
    def __init__(self, word_size):
        super(Layout, self).__init__()
        self.address = 0
        self.word_size = word_size

    def compute_address(self, n):
        if n.address is None or n.address == 'next':
            self.address = align(self.address, n.c_align)
        else:
            if (n.address % n.c_align) != 0:
                raise LayoutException(
                    "unaligned address for {}".format(n.get_path()))
            self.address = n.address
        n.c_address = self.address
        self.address += n.c_size


class LayoutException(Exception):
    def __init__(self, msg):
        self.msg = msg


def layout_field(f, parent, pos):
    if f.lo is None:
        raise LayoutException(
            "missing range for field {}".format(f.get_path()))
    if f.hi is None:
        r = [f.lo]
        f.c_width = 1
    else:
        if f.hi < f.lo:
            raise LayoutException(
                "incorrect range for field {}".format(f.get_path()))
        elif f.hi == f.lo:
            raise LayoutException(
                "one-bit range for field {}".format(f.get_path()))
        r = range(f.lo, f.hi + 1)
        f.c_width = f.hi - f.lo + 1
    if r[-1] >= parent.c_size * tree.BYTE_SIZE:
        raise LayoutException(
            "field {} overflows its register size".format(f.get_path()))
    for i in r:
        if pos[i] is None:
            pos[i] = f
        else:
            raise LayoutException(
                "field {} overlaps field {} in bit {}".format(
                    f.get_path(), pos[i].get_path(), i))


@Layout.register(tree.Reg)
def layout_reg(lo, n):
    # doc: Width must be 8, 16, 32, 64
    # Maybe infer width from fields ?
    # Maybe have a default ?
    if n.width not in [8, 16, 32, 64]:
        raise LayoutException(
            "incorrect width for register {}".format(n.get_path()))
    n.c_size = align(n.width / tree.BYTE_SIZE, lo.word_size)
    n.c_align = n.c_size
    if n.fields:
        if n.type is not None:
            raise LayoutException(
                "register {} with both a type and fields".format(n.get_path()))
        pos = [None] * n.width
        for f in n.fields:
            layout_field(f, n, pos)
    elif n.type is not None:
        raise LayoutException(
            "register {} with type not yet supported".format(
                n.get_path()))
    else:
        # Default is 'unsigned'
        pass


@Layout.register(tree.Block)
def layout_block(lo, n):
    layout_composite(lo, n)
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_size = round_pow2(n.c_size)
        n.c_align = round_pow2(n.c_size)


@Layout.register(tree.Array)
def layout_array(lo, n):
    layout_composite(lo, n)
    if n.repeat is None:
        raise LayoutException(
            "missing repeat count for {}".format(n.get_path()))
    n.c_elsize = align(n.c_size, n.c_align)
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_elsize = round_pow2(n.c_elsize)
        n.c_size = n.c_elsize * round_pow2(n.repeat)
        n.c_align = n.c_size
    else:
        n.c_size = n.c_elsize * n.repeat


@Layout.register(tree.CompositeNode)
def layout_composite(lo, n):
    # Sanity check
    if not n.elements:
        raise LayoutException(
            "composite element '{}' has no elements".format(n.get_path()))
    lo1 = Layout(lo.word_size)
    # Compute size and alignment of elements.
    max_align = 0
    for c in n.elements:
        lo1.visit(c)
        max_align = max(max_align, c.c_align)
    # Aligned composite elements have the max alignment
    has_aligned = False
    for c in n.elements:
        if isinstance(c, tree.ComplexNode) and (c.align is None or c.align):
            c.c_align = max_align
            has_aligned = True
    for c in n.elements:
        lo1.compute_address(c)
    n.c_size = lo1.address
    n.c_align = max_align
    if has_aligned:
        n.c_blk_bits = ilog2(max_align)
        n.c_sel_bits = ilog2(n.c_size) - n.c_blk_bits
    else:
        n.c_blk_bits = ilog2(n.c_size)
        n.c_sel_bits = 0
    # Keep elements in order.
    n.elements = sorted(n.elements, key=(lambda x: x.c_address))
    # Check for no-overlap.
    last_addr = 0
    last_node = None
    for c in n.elements:
        if c.c_address < last_addr:
            raise LayoutException("element {} overlap {}".format(
                c.get_path(), last_node.get_path()))
        last_addr = c.c_address + c.c_size
        last_node = c


@Layout.register(tree.Root)
def layout_root(lo, n):
    layout_composite(lo, n)


def layout_cheby(n):
    if n.bus is None or n.bus == 'wb-32-be':
        n.c_word_size = 4
    else:
        raise LayoutException("unknown bus '{}'".format(n.bus))
    lo = Layout(n.c_word_size)
    lo.visit(n)
