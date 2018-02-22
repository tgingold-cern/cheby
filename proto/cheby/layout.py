"""Layout - perform address layout.
   Check and compute address of all nodes,
   Check fields.

   TODO:
   - check names are uniq (case ?)
   - check names/description are present
   - check names are C identifiers
"""

import tree

BYTE_SIZE = 8


def ilog2(val):
    "Return n such as 2**n >= val and 2**(n-1) < val"
    assert val > 0
    v = 1
    for n in range(32):
        if v >= val:
            return n
        v *= 2


def align(n, mul):
    """Return n aligned to the next multiple of mul"""
    return ((n + mul - 1) // mul) * mul


class Layout(tree.Visitor):
    def __init__(self, word_size):
        super(Layout, self).__init__()
        self.address = 0
        self.word_size = word_size
        self.align = 0
        self.ranges = []    # tuple (lo, hi, node)
        self.ordered = False

    def compute_address(self, n):
        if n.address is None or n.address == 'next':
            self.address = align(self.address, n.c_align)
        else:
            if self.ordered and n.address < self.address:
                raise LayoutException(
                    "address going backward for {}".format(n.get_path()))
            if (n.address % n.c_align) != 0:
                raise LayoutException(
                    "unaligned address for {}".format(n.get_path()))
            self.address = n.address
        n.c_address = self.address
        self.address += n.c_size
        self.align = max(self.align, n.c_align)
        if not self.ordered:
            # Check for no overlap.
            # TODO: emit a warning ? Not allow overlap ?
            n_lo = n.c_address
            n_hi = n.c_address + n.c_size - 1
            for lo, hi, e in self.ranges:
                if lo <= n_hi and hi >= n_lo:
                    raise LayoutException(
                        "element {} overlap {}".format(
                            n.get_path(), e.get_path()))
            self.ranges.append((n_lo, n_hi, n))


class LayoutException(Exception):
    def __init__(self, msg):
        self.msg = msg


def layout_field(f, parent, pos):
    if f.lo is None:
        raise LayoutException(
            "missing range for field {}".format(f.get_path()))
    if f.hi is None:
        r = [f.lo]
    else:
        if f.hi < f.lo:
            raise LayoutException(
                "incorrect range for field {}".format(f.get_path()))
        elif f.hi == f.lo:
            raise LayoutException(
                "one-bit range for field {}".format(f.get_path()))
        r = range(f.lo, f.hi + 1)
    if r[-1] >= parent.c_size * BYTE_SIZE:
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
    n.c_size = align(n.width / BYTE_SIZE, lo.word_size)
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


@Layout.register(tree.Array)
def layout_array(lo, n):
    layout_composite(lo, n)
    if n.repeat is None:
        raise LayoutException(
            "missing repeat count for {}".format(n.get_path()))
    n.c_elsize = align(n.c_size, n.c_align)
    n.c_size = n.c_elsize * n.repeat


@Layout.register(tree.CompositeNode)
def layout_composite(lo, n):
    if not n.elements:
        raise LayoutException(
            "composite element '{}' has no elements".format(n.get_path()))
    lo1 = Layout(lo.word_size)
    # Compute size and alignment of elements.
    for c in n.elements:
        lo1.visit(c)
        lo1.compute_address(c)
    if not lo.ordered:
        n.elements = sorted(n.elements, key=(lambda x: x.c_address))
    n.c_size = lo1.address
    n.c_align = lo1.align


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
