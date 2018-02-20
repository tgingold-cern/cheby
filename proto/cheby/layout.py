"""Layout - perform address layout.
   Check and compute address of all nodes,
   Check fields.
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


def align(n, mul):
    """Return n aligned to the next multiple of mul"""
    return ((n + mul - 1) // mul) * mul


class Layout(tree.Visitor):
    def __init__(self, word_size):
        super(Layout, self).__init__()
        self.address = 0
        self.word_size = word_size
        self.align = 0

    def compute_address(self, n):
        if n.address is None or n.address == 'next':
            self.address = align(self.address, n.c_align)
        else:
            if n.address < self.address:
                raise LayoutException(
                    "address going backward for {}".format(n.get_path()))
            if (n.address % n.c_align) != 0:
                raise LayoutException(
                    "unaligned address for {}".format(n.get_path()))
            self.address = n.address
        n.c_address = self.address
        self.address += n.c_size
        self.align = max(self.align, n.c_align)


class LayoutException(Exception):
    def __init__(self, msg):
        self.msg = msg


@Layout.register(tree.Reg)
def layout_reg(lo, n):
    # doc: Width must be 8, 16, 32, 64
    # Maybe infer width from fields ?
    # Maybe have a default ?
    if n.width not in [8, 16, 32, 64]:
        raise LayoutException(
            "incorrect width for register {}".format(n.get_path()))
    n.c_size = align(n.width / 8, lo.word_size)
    n.c_align = n.c_size
    if n.fields:
        # TODO
        pass
    elif n.type is not None:
        raise LayoutException(
            "register {} with type not yet supported".format(
                n.get_path()))
    else:
        # Default is 'unsigned'
        pass
    lo.compute_address(n)


@Layout.register(tree.Block)
def layout_block(lo, n):
    layout_composite(lo, n)
    lo.compute_address(n)


@Layout.register(tree.Array)
def layout_array(lo, n):
    layout_composite(lo, n)
    if n.repeat is None:
        raise LayoutException(
            "missing repeat count for {}".format(n.get_path()))
    n.c_elsize = align(n.c_size, n.c_align)
    n.c_size = n.c_elsize * n.repeat
    lo.compute_address(n)


@Layout.register(tree.CompositeNode)
def layout_composite(lo, n):
    if not n.children:
        raise LayoutException(
            "composite element '{}' has no children".format(n.get_path()))
    lo1 = Layout(lo.word_size)
    for c in n.children:
        lo1.visit(c)
    n.c_size = lo1.address
    n.c_align = lo1.align


@Layout.register(tree.Root)
def layout_root(lo, n):
    for c in n.children:
        lo.visit(c)
    n.c_size = lo.address
    n.c_align = lo.align


def layout_cheby(n):
    if n.bus is None or n.bus == 'wb-32-be':
        n.c_word_size = 4
    else:
        raise LayoutException("unknown bus '{}'".format(n.bus))
    lo = Layout(n.c_word_size)
    lo.visit(n)
