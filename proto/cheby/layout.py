"""Layout - perform address layout.
   Check and compute address of all nodes,
   Check fields.

   TODO:
   - check names/description are present
   - check names are C identifiers
"""

import sys
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


def get_gena(n, name, default=None):
    "Get the value from a gena extension"
    return n.get_extension('x_gena', name, default)


def get_gena_gen(n, name, default=None):
    "Get the value of the gena/gen extension"
    gen = get_gena(n, 'gen', None)
    if gen is None:
        return default
    return gen.get(name, default)


class Layout(tree.Visitor):
    def __init__(self, root):
        super(Layout, self).__init__()
        self.root = root
        self.address = 0
        self.word_size = root.c_word_size
        self.align_reg = True

    def duplicate(self):
        res = Layout(self.root)
        res.align_reg = self.align_reg
        return res

    def compute_address(self, n):
        if n.address is None or n.address == 'next':
            self.address = align(self.address, n.c_align)
        else:
            if (n.address % n.c_align) != 0:
                raise LayoutException(
                    n, "unaligned address for {}".format(n.get_path()))
            self.address = n.address
        n.c_address = self.address
        self.address += n.c_size


class LayoutException(Exception):
    def __init__(self, n, msg):
        self.node = n
        self.msg = msg


def layout_named(n):
    if n.name is None:
        raise LayoutException(
            n, "missing name for {}".format(n.get_path()))


def layout_field(f, parent, pos):
    layout_named(f)
    # Check range is present
    if f.lo is None:
        raise LayoutException(
            f, "missing range for field {}".format(f.get_path()))
    # Compute width
    if f.hi is None:
        r = [f.lo]
        f.c_rwidth = 1
        f.c_iowidth = 1
    else:
        if f.hi < f.lo:
            raise LayoutException(
                f, "incorrect range for field {}".format(f.get_path()))
        elif f.hi == f.lo:
            raise LayoutException(
                f, "one-bit range for field {}".format(f.get_path()))
        r = range(f.lo, f.hi + 1)
        f.c_rwidth = f.hi - f.lo + 1
        f.c_iowidth = f.c_rwidth
    # Check for overlap
    if r[-1] >= parent.width:
        raise LayoutException(
            f, "field {} width overflows its register size".format(
                f.get_path()))
    elif r[-1] >= parent.c_rwidth:
        raise LayoutException(
            f, "field {} extends beyond register storage size".format(
                f.get_path()))
    for i in r:
        if pos[i] is None:
            pos[i] = f
        else:
            raise LayoutException(
                f, "field {} overlaps field {} in bit {}".format(
                    f.get_path(), pos[i].get_path(), i))
    # Check preset
    if f.preset is not None and f.preset >= (1 << f.c_rwidth):
        raise LayoutException(
            f, "incorrect preset value for field {}".format(f.get_path()))


@Layout.register(tree.Reg)
def layout_reg(lo, n):
    # doc: Width must be 8, 16, 32, 64
    # Maybe infer width from fields ?
    # Maybe have a default ?
    if n.width is None:
        raise LayoutException(
            n, "missing width for register {}".format(n.get_path()))
    elif n.width not in [8, 16, 32, 64]:
        raise LayoutException(
            n, "incorrect width for register {}".format(n.get_path()))
    layout_named(n)
    # Check access
    if n.access is None:
        raise LayoutException(
            n, "missing access for register {}".format(n.get_path()))
    if n.access is not None and n.access not in ['ro', 'rw', 'wo']:
        raise LayoutException(
            n, "incorrect access for register {}".format(n.get_path()))
    n.c_size = n.width // tree.BYTE_SIZE
    word_bits = lo.word_size * tree.BYTE_SIZE
    n.c_nwords = (n.width + word_bits - 1) // word_bits
    if n.c_nwords > 1 and lo.root.c_word_endian == 'none':
        raise LayoutException(
            n, "cannot use multi-words register when word-endian is 'none'")
    gena_type = get_gena(n, 'type')
    resize = get_gena_gen(n, 'resize')
    if get_gena_gen(n, 'srff'):
        if n.access != 'ro':
            raise LayoutException(
                n, "'gen=srff' only for 'access=ro' in register {}".format(
                    n.get_path()))
        if gena_type is not None:
            raise LayoutException(
                n, "'gen=srff' incompatible with 'type=' in reg {}".format(
                    n.get_path()))
        if n.width < word_bits:
            raise LayoutException(
                n, "width cannot be smaller than a word for srff {}".format(
                    n.get_path()))
    if get_gena_gen(n, 'bus-out'):
        if n.access != 'ro':
            raise LayoutException(
                n, "'gen=bus-out' only for 'access=ro' in register {}".format(
                    n.get_path()))
    if gena_type == 'rmw':
        if resize is not None and resize != (n.width // 2):
            raise LayoutException(
                n, "gen.resize incompatible with type=rmw for {}".format(
                    n.get_path()))
        # RMW registers uses the top half part to mask bits.
        n.c_rwidth = n.width // 2
        n.c_iowidth = n.width // 2
        n.c_mwidth = n.width
    else:
        n.c_rwidth = n.width
        n.c_mwidth = n.width
        if resize is None:
            n.c_iowidth = n.width
        else:
            n.c_iowidth = resize
    if lo.align_reg:
        # A register is aligned at least on a word and always naturally
        # aligned.
        n.c_align = align(n.c_size, lo.word_size)
    else:
        n.c_align = lo.word_size
    names = set()
    if n.children:
        if n.type is not None:
            raise LayoutException(
                n, "register {} with both a type and fields".format(
                    n.get_path()))
        n.c_type = None
        pos = [None] * n.width
        for f in n.children:
            if f.name in names:
                raise LayoutException(
                    f, "field '{}' reuse a name in reg {}".format(
                        f.name, n.get_path()))
            names.add(f.name)
            layout_field(f, n, pos)
    else:
        # Create the artificial field
        f = tree.FieldReg(n)
        n.children.append(f)
        f.name = None
        f.description = n.description
        f.preset = n.preset
        f.lo = 0
        f.hi = n.c_rwidth - 1
        f.c_rwidth = n.c_rwidth
        f.c_iowidth = n.c_iowidth

        if n.type is None:
            # Default is unsigned
            n.c_type = 'unsigned'
        elif n.type in ['signed', 'unsigned']:
            n.c_type = n.type
        elif n.type == 'float':
            n.c_type = n.type
            if n.width not in [32, 64]:
                raise LayoutException(
                    n, "incorrect width for float register {}".format(
                        n.get_path()))
        else:
            raise LayoutException(
                n, "incorrect type for register {}".format(n.get_path()))


def compute_submap_absolute_filename(sm):
    filename = sm.filename
    root = sm
    while not isinstance(root, tree.Root):
        root = root._parent
    if not os.path.isabs(filename):
        filename = os.path.join(os.path.dirname(root.c_filename), filename)
    return filename


def load_submap(blk):
    sys.stderr.write('Loading {}...\n'.format(blk.filename))
    filename = compute_submap_absolute_filename(blk)
    return cheby.parser.parse_yaml(filename)


def align_block(lo, n):
    n.c_blk_bits = ilog2(n.c_size)
    n.c_width = lo.word_size * tree.BYTE_SIZE
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_size = round_pow2(n.c_size)
        n.c_align = round_pow2(n.c_size)


@Layout.register(tree.Submap)
def layout_submap(lo, n):
    if n.filename is None:
        # No filename, this is a generic submap.  So size and bus are required.
        if n.size is None:
            raise LayoutException(
                n, "no size in submap '{}'".format(n.get_path()))
        if n.interface is None:
            raise LayoutException(
                n, "no interface for generic submap '{}'".format(n.get_path()))
        n.c_size = n.size
        n.c_interface = n.interface
    else:
        if n.size is not None:
            raise LayoutException(
                n, "size given for submap '{}'".format(n.get_path()))
        submap = load_submap(n)
        layout_cheby_memmap(submap)
        n.c_submap = submap
        n.c_size = n.c_submap.c_size
        if n.interface is None:
            n.c_interface = submap.bus
        elif n.interface == 'include':
            # Check compatibility of word-endianness.
            if ((lo.root.c_word_endian == 'big' and submap.c_word_endian == 'little')
                or (lo.root.c_word_endian == 'little' and submap.c_word_endian == 'big')):
                # FIXME: check with 3 levels: big <- none <- little
                raise LayoutException(
                    n, "cannot include submap '{}' with opposite word endianness".format(
                        n.get_path()))
            elif (lo.root.c_word_endian == 'none' and submap.c_word_endian != 'none'):
                raise LayoutException(
                    n, "cannot include submap '{}' with word endianness != 'none'".format(
                        n.get_path()))
        else:
            raise LayoutException(
                n, "interface override is not allowed for submap '{}'".format(
                    n.get_path()))
    n.c_addr_bits = ilog2(n.c_size) - lo.root.c_addr_word_bits
    align_block(lo, n)


@Layout.register(tree.Block)
def layout_block(lo, n):
    if n.children:
        layout_composite(lo, n)
    elif n.size is None:
        raise LayoutException(
            n, "no size in block '{}'".format(n.get_path()))
    else:
        n.c_size = n.size
    align_block(lo, n)


@Layout.register(tree.Array)
def layout_array(lo, n):
    # Sanity check
    if len(n.children) != 1:
        raise LayoutException(
            n, "array '{}' must have one element".format(n.get_path()))
    if n.repeat is None:
        raise LayoutException(
            n, "missing repeat count for {}".format(n.get_path()))
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


def build_sorted_children(n):
    """Create c_sorted_children (list of children sorted by address)"""
    n.c_sorted_children = sorted(n.children, key=(lambda x: x.c_address))


@Layout.register(tree.CompositeNode)
def layout_composite(lo, n):
    layout_named(n)

    # Check each child has a unique name.
    names = set()
    for c in n.children:
        if c.name in names:
            raise LayoutException(
                c, "child {} reuse name '{}'".format(c.get_path(), c.name))
        names.add(c.name)

    # Compute size and alignment of children.
    lo1 = lo.duplicate()
    max_align = 0
    for c in n.children:
        lo1.visit(c)
        max_align = max(max_align, c.c_align)
    has_aligned = False
    for c in n.children:
        if isinstance(c, tree.ComplexNode) and (c.align is None or c.align):
            has_aligned = True
    n.c_size = 0
    for c in n.children:
        lo1.compute_address(c)
        n.c_size = max(n.c_size, c.c_address + c.c_size)
    n.c_align = max_align
    if n.size is not None:
        if n.size < n.c_size:
            for c in n.children:
                print('0x{:08x} - 0x{:08x}: {}'.format(
                    c.c_address, c.c_address + c.c_size, c.name))
            raise LayoutException(
                n, "size of {} is too small (need {}, get {})".format(
                    n.get_path(), n.c_size, n.size))
        n.c_size = n.size
    if has_aligned:
        n.c_blk_bits = ilog2(n.c_align)
        n.c_sel_bits = ilog2(n.c_size) - n.c_blk_bits
    else:
        n.c_blk_bits = ilog2(n.c_size)
        n.c_sel_bits = 0
    # Keep children in order.
    build_sorted_children(n)
    # Check for no-overlap.
    last_addr = 0
    last_node = None
    for c in n.c_sorted_children:
        if c.c_address < last_addr:
            raise LayoutException(
                c, "element {} overlap {}".format(
                    c.get_path(), last_node.get_path()))
        last_addr = c.c_address + c.c_size
        last_node = c


@Layout.register(tree.Root)
def layout_root(lo, root):
    if not root.children:
        raise LayoutException(root, "empty description '{}'".format(root.name))
    root.c_address = 0
    layout_composite(lo, root)


def layout_cheby_memmap(root):
    flag_align_reg = True
    root.c_buserr = False
    if root.bus is None or root.bus == 'wb-32-be':
        root.c_word_size = 4
        root.c_word_endian = 'big'
    elif root.bus == 'axi4-lite-32':
        root.c_word_size = 4
        root.c_word_endian = 'little'
    elif root.bus.startswith('cern-be-vme-'):
        params = root.bus[12:].split('-')
        root.c_word_endian = 'big'
        if params[0] == 'err':
            root.c_buserr = True
            del params[0]
        else:
            root.c_buserr = False
        if params[0] == 'split':
            root.c_bussplit = True
            del params[0]
        else:
            root.c_bussplit = False
        if len(params) != 1:
            raise LayoutException(root, "unknown bus '{}'".format(root.bus))
        if params[0] == '32':
            root.c_word_size = 4
        elif params[0] == '16':
            root.c_word_size = 2
        elif params[0] == '8':
            root.c_word_size = 1
        else:
            raise LayoutException(
                root, "unknown bus size '{}'".format(root.bus))
        flag_align_reg = False
    else:
        raise LayoutException(root, "unknown bus '{}'".format(root.bus))

    # word endianness override.
    if root.word_endian is not None:
        if root.word_endian not in ['none', 'little', 'big']:
            raise LayoutException(root, "incorrect word-endian value '{}'".format(
                root.word_endian))
        root.c_word_endian = root.word_endian

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE

    lo = Layout(root)
    lo.align_reg = flag_align_reg
    lo.visit(root)

    # Number of bits for the address ports (exluding sub-word bits)
    root.c_addr_bits = ilog2(root.c_size) - root.c_addr_word_bits


def set_abs_address(n, base_addr):
    "Set c_abs_addr - absolute address - on every node rooted by n"
    n.c_abs_addr = base_addr + n.c_address
    if isinstance(n, tree.Reg):
        pass
    elif isinstance(n, tree.Submap):
        if n.interface == 'include':
            set_abs_address(n.c_submap, n.c_abs_addr)
    elif isinstance(n, tree.Array):
        # Still relative, but need to set c_abs_addr
        for e in n.children:
            set_abs_address(e, 0)
    elif isinstance(n, (tree.Root, tree.Block)):
        for e in n.children:
            set_abs_address(e, n.c_abs_addr)
    else:
        raise AssertionError


def layout_cheby(n):
    layout_cheby_memmap(n)
    set_abs_address(n, 0)
