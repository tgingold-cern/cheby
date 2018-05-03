"""Layout - perform address layout.
   Check and compute address of all nodes,
   Check fields.

   TODO:
   - check names/description are present
   - check names are C identifiers
"""

import os.path
import cheby.tree as tree
import cheby.parser


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
        self.align_reg = True

    def duplicate(self):
        res = Layout(self.word_size)
        res.align_reg = self.align_reg
        return res

    def compute_address(self, n):
        if n.address is None or n.address == 'next':
            self.address = align(self.address, n.c_align)
        else:
            if (n.address % n.c_align) != 0:
                raise LayoutException(n,
                    "unaligned address for {}".format(n.get_path()))
            self.address = n.address
        n.c_address = self.address
        self.address += n.c_size


class LayoutException(Exception):
    def __init__(self, n, msg):
        self.node = n
        self.msg = msg


def layout_named(n):
    if n.name is None:
        raise LayoutException(n,
            "missing name for {}".format(n.get_path()))


def layout_field(f, parent, pos):
    layout_named(f)
    # Check range is present
    if f.lo is None:
        raise LayoutException(f,
            "missing range for field {}".format(f.get_path()))
    # Compute width
    if f.hi is None:
        r = [f.lo]
        f.c_width = 1
    else:
        if f.hi < f.lo:
            raise LayoutException(f,
                "incorrect range for field {}".format(f.get_path()))
        elif f.hi == f.lo:
            raise LayoutException(f,
                "one-bit range for field {}".format(f.get_path()))
        r = range(f.lo, f.hi + 1)
        f.c_width = f.hi - f.lo + 1
    # Check for overlap
    if r[-1] >= parent.width:
        raise LayoutException(f,
            "field {} overflows its register size".format(f.get_path()))
    for i in r:
        if pos[i] is None:
            pos[i] = f
        else:
            raise LayoutException(f,
                "field {} overlaps field {} in bit {}".format(
                    f.get_path(), pos[i].get_path(), i))
    # Check preset
    if f.preset is not None and f.preset >= (1 << f.c_width):
        raise LayoutException(f,
            "incorrect preset value for field {}".format(f.get_path()))


@Layout.register(tree.Reg)
def layout_reg(lo, n):
    # doc: Width must be 8, 16, 32, 64
    # Maybe infer width from fields ?
    # Maybe have a default ?
    if n.width is None:
        raise LayoutException(n,
            "missing width for register {}".format(n.get_path()))
    elif n.width not in [8, 16, 32, 64]:
        raise LayoutException(n,
            "incorrect width for register {}".format(n.get_path()))
    layout_named(n)
    # Check access
    if n.access is None:
        raise LayoutException(n,
            "missing access for register {}".format(n.get_path()))
    if n.access is not None and n.access not in ['ro', 'rw', 'wo', 'cst']:
        raise LayoutException(n,
            "incorrect access for register {}".format(n.get_path()))
    n.c_size = n.width // tree.BYTE_SIZE
    if lo.align_reg:
        # A register is aligned at least on a word and always naturally aligned.
        n.c_align = align(n.c_size, lo.word_size)
    else:
        n.c_align = lo.word_size
    names = set()
    if n.fields:
        if n.type is not None:
            raise LayoutException(n,
                "register {} with both a type and fields".format(n.get_path()))
        n.c_type = None
        pos = [None] * n.width
        for f in n.fields:
            if f.name in names:
                raise LayoutException(f,
                    "field '{}' reuse a name in reg {}".format(
                        f.name, n.get_path()))
            names.add(f.name)
            layout_field(f, n, pos)
    else:
        # Create the artificial field
        f = tree.FieldReg(n)
        n.fields.append(f)
        f.name = n.name
        f.description = n.description
        f.lo = 0
        f.hi = n.width - 1
        f.c_width = n.width

        if n.type is None:
            # Default is unsigned
            n.c_type = 'unsigned'
        elif n.type in ['signed', 'unsigned']:
            n.c_type = n.type
        elif n.type == 'float':
            n.c_type = n.type
            if n.width not in [32, 64]:
                raise LayoutException(n,
                    "incorrect width for float register {}".format(
                        n.get_path()))
        else:
            raise LayoutException(n,
                "incorrect type for register {}".format(n.get_path()))


def load_submap(blk, filename):
    root = blk
    while not isinstance(root, tree.Root):
        root = root._parent
    # FIXME: create a directory ?
    print('Loading {}...'.format(filename))
    if not os.path.isabs(filename):
        filename = os.path.join(os.path.dirname(root.c_filename), filename)
    submap = cheby.parser.parse_yaml(filename)
    layout_cheby(submap)
    return submap

@Layout.register(tree.Block)
def layout_block(lo, n):
    if n.elements:
        layout_composite(lo, n)
    else:
        if n.submap_file:
            n.c_submap = load_submap(n, n.submap_file)
            n.c_size = n.c_submap.c_size
        elif n.size is None:
            raise LayoutException(n,
                "no size in block '{}'".format(n.get_path()))
        else:
            n.c_size = n.size
        n.c_blk_bits = ilog2(n.c_size)
        n.c_width = lo.word_size * tree.BYTE_SIZE
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_size = round_pow2(n.c_size)
        n.c_align = round_pow2(n.c_size)


@Layout.register(tree.Array)
def layout_array(lo, n):
    # Sanity check
    if len(n.elements) != 1:
        raise LayoutException(n,
            "array '{}' must have one element".format(n.get_path()))
    if n.repeat is None:
        raise LayoutException(n,
            "missing repeat count for {}".format(n.get_path()))
    layout_composite(lo, n)
    n.c_elsize = align(n.c_size, n.c_align)
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_elsize = round_pow2(n.c_elsize)
        n.c_size = n.c_elsize * n.repeat
        n.c_align = n.c_elsize * round_pow2(n.repeat)
    else:
        n.c_size = n.c_elsize * n.repeat
    # FIXME: only significant when aligned ?
    n.c_blk_bits = ilog2(n.c_elsize)
    n.c_sel_bits = ilog2(n.c_size) - n.c_blk_bits


@Layout.register(tree.CompositeNode)
def layout_composite(lo, n):
    layout_named(n)

    # Check each child has a unique name.
    names = set()
    for c in n.elements:
        if c.name in names:
            raise LayoutException(c,
                "child {} reuse name '{}'".format(c.get_path(), c.name))
        names.add(c.name)

    # Compute size and alignment of elements.
    lo1 = lo.duplicate()
    max_align = 0
    for c in n.elements:
        lo1.visit(c)
        max_align = max(max_align, c.c_align)
    has_aligned = False
    for c in n.elements:
        if isinstance(c, tree.ComplexNode) and (c.align is None or c.align):
            has_aligned = True
    n.c_size = 0
    for c in n.elements:
        lo1.compute_address(c)
        n.c_size = max(n.c_size, c.c_address + c.c_size)
    n.c_align = max_align
    if n.size is not None:
        if n.size < n.c_size:
            for c in n.elements:
                print('0x{:08x} - 0x{:08x}: {}'.format(
                    c.c_address, c.c_address + c.c_size, c.name))
            raise LayoutException(n,
                "size of {} is too small (need {}, get {})".format(
                    n.get_path(), n.c_size, n.size))
        n.c_size = n.size
    if has_aligned:
        n.c_blk_bits = ilog2(n.c_align)
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
            raise LayoutException(c,
                "element {} overlap {}".format(
                    c.get_path(), last_node.get_path()))
        last_addr = c.c_address + c.c_size
        last_node = c


@Layout.register(tree.Root)
def layout_root(lo, n):
    if not n.elements:
        raise LayoutException(n, "empty description '{}'".format(n.name))
    n.c_address = 0
    layout_composite(lo, n)


def layout_cheby(n):
    flag_align_reg = True
    if n.bus is None or n.bus == 'wb-32-be':
        n.c_word_size = 4
    elif n.bus == 'cern-be-vme-32':
        n.c_word_size = 4
        flag_align_reg = False
    elif n.bus == 'cern-be-vme-16':
        n.c_word_size = 2
        flag_align_reg = False
    elif n.bus == 'cern-be-vme-8':
        n.c_word_size = 1
        flag_align_reg = False
    else:
        raise LayoutException(n, "unknown bus '{}'".format(n.bus))
    lo = Layout(n.c_word_size)
    lo.align_reg = flag_align_reg
    lo.visit(n)
