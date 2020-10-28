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

# Command line option to override word-endianness
# Can be: default, little, big
# Apply to the whole design.
word_endianness = 'default'

def ilog2(val):
    "Return n such as 2**n >= val and 2**(n-1) < val"
    assert val > 0
    v = 1
    for n in range(33):
        if v >= val:
            return n
        v *= 2


def round_pow2(val):
    return 1 << ilog2(val)


def align_floor(n, mul):
    """Return the greatest natural V such as V is a multiple of MUL and V <= N."""
    return (n // mul) * mul


def align(n, mul):
    """Return n aligned to the next multiple of mul.
       This is the lowest natural V such as V is a multiple of MUL and V >= N."""
    return align_floor(n + mul - 1, mul)


def warning(n, msg):
    sys.stderr.write("{}:layout warning: {}\n".format(n.get_root().c_filename, msg))


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

    def duplicate(self):
        res = Layout(self.root)
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
        super(LayoutException, self).__init__()
        self.node = n
        self.msg = msg

    def __str__(self):
        return "{}:layout error: {}".format(
            self.node.get_root().c_filename, self.msg)


def layout_check_name(n):
    if n.name is None:
        raise LayoutException(
            n, "missing name for {}".format(n.get_path()))


def check_enum_type(root, name, n, width):
    en = root.c_enums_dict.get(name)
    if en is None:
        raise LayoutException(
            n, "enumeration '{}' is not defined".format(name))
    if en.width is None:
        if en.c_width > width:
            raise LayoutException(
                n, "width of field {} ({}) is too small for enum {} ({})".format(
                    n.get_path(), width, name, en.c_width))
    else:
        if en.width != width:
            raise LayoutException(
                n, "width of field {} ({}) doesn't match width of enum {} ({})".format(
                    n.get_path(), width, name, en.width))


def layout_field(root, f, parent, pos):
    layout_check_name(f)
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
    if f.preset is not None:
        if isinstance(f.preset, str):
            raise LayoutException(
                f, "preset {} not allowed in field {}".format(f.preset, f.get_path()))
        if f.preset >= (1 << f.c_rwidth):
            raise LayoutException(
                f, "incorrect preset value for field {}".format(f.get_path()))
        f.c_preset = f.preset
    else:
        f.c_preset = None
    # Check type
    if f.type is None:
        enum = f.get_extension('x_enums', 'name', None)
        if enum is not None:
            check_enum_type(root, enum, f, f.c_rwidth)
        else:
            f.c_type = parent.c_type
    else:
        if f.type not in ('signed', 'unsigned'):
            raise LayoutException(
                f, "type of field {} must be either 'signed', 'unsigned' or 'enum'".format(
                    f.get_path()))
        f.c_type = f.type


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
    layout_check_name(n)
    # Check access
    if n.access is None:
        raise LayoutException(
            n, "missing access for register {}".format(n.get_path()))
    if n.access is not None and n.access not in ['ro', 'rw', 'wo']:
        raise LayoutException(
            n, "incorrect access for register {}".format(n.get_path()))
    n.c_size = n.width // tree.BYTE_SIZE
    word_bits = lo.root.c_word_size * tree.BYTE_SIZE
    n.c_nwords = (n.width + word_bits - 1) // word_bits
    if n.c_nwords > 1 and lo.root.c_word_endian == 'none':
        raise LayoutException(
            n, "cannot use multi-words register when word-endian is 'none'")
    gena_rmw = get_gena(n, 'rmw', False)
    resize = get_gena_gen(n, 'resize')
    if get_gena_gen(n, 'srff'):
        if n.access != 'ro':
            raise LayoutException(
                n, "'gen=srff' only for 'access=ro' in register {}".format(
                    n.get_path()))
        if gena_rmw:
            raise LayoutException(
                n, "'gen=srff' incompatible with 'rmw=True' in reg {}".format(
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
    if gena_rmw:
        if resize is not None and resize != (n.width // 2):
            raise LayoutException(
                n, "gen.resize incompatible with rmw=True for {}".format(
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
    if lo.root.c_align_reg:
        # A register is aligned at least on a word and always naturally
        # aligned.
        n.c_align = align(n.c_size, lo.root.c_word_size)
    else:
        n.c_align = lo.root.c_word_size
    names = set()
    if n.children:
        # This register has fields.
        if n.preset is not None:
            raise LayoutException(
                n, "preset is not allowed for register {} with fields".format(n.get_path()))
        if n.constant is not None:
            raise LayoutException(
                n, "constant is not allowed for register {} with fields".format(n.get_path()))
        if resize is not None:
            warning(n, "x-gena:resize is ignored for register {} with fields".format(n.get_path()))
        if n.type is None:
            n.c_type = 'unsigned'
        else:
            if n.type not in ('signed', 'unsigned'):
                raise LayoutException(
                    n, "type register {} with fields must be either 'signed' or 'unsigned'".format(
                        n.get_path()))
            n.c_type = n.type
        pos = [None] * n.width
        for f in n.children:
            if f.name in names:
                raise LayoutException(
                    f, "field '{}' reuse a name in reg {}".format(
                        f.name, n.get_path()))
            names.add(f.name)
            layout_field(lo.root, f, n, pos)
        build_sorted_fields(n)
    else:
        # Create the artificial field
        f = tree.FieldReg(n)
        n.children.append(f)
        build_sorted_fields(n)
        f.name = None
        f.description = n.description
        f.comment = n.comment
        if n.constant is not None and n.preset is not None:
            raise LayoutException(
                n, "reg {}: can not have both 'preset' and 'constant' attributes".format(
                    n.get_path()))
        if n.constant == 'version':
            if lo.root.version is None:
                raise LayoutException(
                    n, "cannot use 'constant: version' for register {} "
                    "without a version at the root".format(n.get_path()))
            if n.c_rwidth != 32:
                raise LayoutException(
                    n, "reg {}: can only use 'preset: version' when width=32".format(
                        n.get_path()))
            v = lo.root.c_version
            f.c_preset = (v[0] << 16) | (v[1] << 8) | v[2]
        elif n.constant == 'ident' or n.constant == 'ident-code':
            v = lo.root.ident
            if v is None:
                raise LayoutException(
                    n, "cannot use 'constant: {}' for register {} without x-map-info:ident".format(
                        n.constant,
                        n.get_path()))
            f.c_preset = v
        elif n.constant == 'memmap-version':
            v = lo.root.c_memmap_version
            if v is None:
                raise LayoutException(
                    n, "cannot use 'constant: memmap-version' for register {} "
                    "without x-map-info:memmap-version".format(n.get_path()))
            f.c_preset = (v[0] << 16) | (v[1] << 8) | v[2]
        elif n.constant == 'map-version':
            v = lo.root.get_extension('x_gena', 'map-version', None)
            if v is None:
                raise LayoutException(
                    n, "cannot use 'constant: map-version' for register {} "
                    "without x-gena:map-version".format(n.get_path()))
            f.c_preset = v
        else:
            f.c_preset = n.preset
        f.lo = 0
        f.hi = n.c_rwidth - 1
        f.c_rwidth = n.c_rwidth
        f.c_iowidth = n.c_iowidth

        if n.type is None:
            enum = n.get_extension('x_enums', 'name', None)
            if enum is not None:
                check_enum_type(lo.root, enum, n, f.c_rwidth)
            else:
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
        root = root.parent
    if not os.path.isabs(filename):
        filename = os.path.join(os.path.dirname(root.c_filename), filename)
    return filename


def load_submap(blk):
    sys.stderr.write('Loading {}...\n'.format(blk.filename))
    filename = compute_submap_absolute_filename(blk)
    return cheby.parser.parse_yaml(filename)


def align_block(n):
    if n.align is None or n.align:
        # Align to power of 2.
        n.c_size = round_pow2(n.c_size)
        n.c_align = round_pow2(n.c_size)


@Layout.register(tree.Submap)
def layout_submap(lo, n):
    if n.filename is None:
        # No filename, this is a generic submap.  So size and bus are required.
        if n.size_val is None:
            raise LayoutException(
                n, "no size in submap '{}'".format(n.get_path()))
        if n.interface is None:
            raise LayoutException(
                n, "no interface for generic submap '{}'".format(n.get_path()))
        if n.interface == 'include':
            raise LayoutException(
                n, "'interface' cannot be 'include' for the generic submap '{}'".format(
                    n.get_path()))
        if n.include is not None:
            raise LayoutException(
                n, "use of 'include' is not allowed when 'filename' is not present")
        if n.align is False:
            raise LayoutException(
                n, "use of 'align' is not allowed in a generic submap")
        n.c_size = n.size_val
        n.c_interface = n.interface
    else:
        if n.size_val is not None:
            raise LayoutException(
                n, "size given for submap '{}'".format(n.get_path()))
        submap = load_submap(n)
        layout_cheby_memmap(submap)
        n.c_submap = submap
        n.c_size = n.c_submap.c_size
        n.c_align = n.c_submap.c_align
        if n.interface == 'include':
            warning(n, "use of 'interface: include' is deprecated (for '{}')".format(n.get_path()))
            warning(n, "use 'include: True' instead")
            n.include = True
            n.interface = None
        if n.interface is None:
            n.c_interface = submap.bus
        else:
            raise LayoutException(
                n, "interface override is not allowed for submap '{}'".format(
                    n.get_path()))
        if n.include is True:
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
            if n.align is False:
                raise LayoutException(
                    n, "use of 'align' is not allowed in a non-include submap")

    n.c_addr_bits = ilog2(n.c_size) - lo.root.c_addr_word_bits
    n.c_width = lo.root.c_word_size * tree.BYTE_SIZE
    align_block(n)


@Layout.register(tree.Block)
def layout_block(lo, n):
    if n.children:
        layout_composite_children(lo, n)
        layout_composite_size(lo, n)
    else:
        # No children.  Set size and alignment
        if n.size_val is None:
            raise LayoutException(
                n, "no size for empty block '{}'".format(n.get_path()))
        else:
            n.c_size = n.size_val
        n.c_align = lo.root.c_word_size
    align_block(n)


@Layout.register(tree.Repeat)
def layout_repeat(lo, n):
    # Sanity check
    # if len(n.children) != 1:
    #    raise LayoutException(
    #        n, "repeat '{}' must have one element".format(n.get_path()))
    if n.count is None:
        raise LayoutException(
            n, "missing repeat count for {}".format(n.get_path()))
    layout_composite_children(lo, n)
    layout_composite_size(lo, n)
    n.c_elsize = align(n.c_size, n.c_align)
    n.c_size = n.c_elsize * n.count
    align_block(n)


@Layout.register(tree.Memory)
def layout_memory(lo, n):
    # Sanity checks
    if len(n.children) != 1 or not isinstance(n.children[0], tree.Reg):
        raise LayoutException(
            n, "memory '{}' must have one element (a register)".format(n.get_path()))
    if n.align is not None and not n.align:
        raise LayoutException(
            n, "memory '{}' must be aligned")
    # Layout the children and use the size of the children as element size.
    layout_composite_children(lo, n)
    n.c_elsize = n.c_size
    if n.memsize_val is None:
        if n.c_depth is None:
            raise LayoutException(
                n, "missing memsize for memory {}".format(n.get_path()))
        # For backward compatibility with array.
        n.memsize_val = n.c_depth * n.c_elsize
    # Align to power of 2.
    n.c_elsize = round_pow2(n.c_elsize)
    # Compute the depth.
    if n.memsize_val % n.c_elsize != 0:
        raise LayoutException(
            n, "memory memsize '{}' is not a multiple of the element")
    if n.c_elsize <= lo.root.c_word_size:
        # Element size is smaller than the word size.  So part of the word is
        # simply discarded/wasted.
        pass
    else:
        # Element size is lager than the word size.  Cap to the word size.
        n.c_elsize = lo.root.c_word_size
    n.c_depth = n.memsize_val // n.c_elsize
    n.c_size = n.c_depth * lo.root.c_word_size
    n.c_align = round_pow2(n.c_size)
    layout_composite_size(lo, n)
    align_block(n)


def build_sorted_children(n):
    """Create c_sorted_children (list of children sorted by address)"""
    n.c_sorted_children = sorted(n.children, key=(lambda x: x.c_address))

def build_sorted_fields(n):
    n.c_sorted_fields = sorted(n.children, key=(lambda x: x.lo))

def layout_composite_children(lo, n):
    layout_check_name(n)

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
    n.c_align = max_align
    n.c_size = 0
    for c in n.children:
        lo1.compute_address(c)
        n.c_size = max(n.c_size, c.c_address + c.c_size)
    # Keep children in order.
    build_sorted_children(n)
    # Check for no-overlap.
    last_addr = 0
    last_node = None
    for c in n.c_sorted_children:
        if c.c_address < last_addr:
            raise LayoutException(
                c, "element {} overlaps {}".format(
                    c.get_path(), last_node.get_path()))
        last_addr = c.c_address + c.c_size
        last_node = c


def layout_composite_size(_lo, n):
    if n.size_val is not None:
        if n.size_val < n.c_size:
            for c in n.children:
                print('0x{:08x} - 0x{:08x}: {}'.format(
                    c.c_address, c.c_address + c.c_size, c.name))
            raise LayoutException(
                n, "size of {} is too small (need {}, get {})".format(
                    n.get_path(), n.c_size, n.size_str))
        n.c_size = n.size_val


def layout_hierarchy(lo, n):
    """Common code for a root or an address space"""
    if not n.children and n.size_val is None:
        raise LayoutException(
            n, "empty description '{}' must have a size".format(n.name))
    n.c_address = 0
    layout_composite_children(lo, n)
    layout_composite_size(lo, n)
    # Number of bits for the address ports (exluding sub-word bits)
    n.c_addr_bits = ilog2(n.c_size) - n.c_addr_word_bits


@Layout.register(tree.AddressSpace)
def layout_address_space(lo, n):
    # Copy bus from the root
    root = lo.root
    n.c_word_bits = root.c_word_bits
    n.c_addr_word_bits = root.c_addr_word_bits
    layout_hierarchy(lo, n)


@Layout.register(tree.Root)
def layout_root(lo, root):
    # A root is considered as an address space
    assert not root.address_spaces
    layout_hierarchy(lo, root)


def layout_semantic_version(n, val):
    if val is None:
        return None
    nums = val.split('.')
    if len(nums) != 3:
        raise LayoutException(
            n, "semantic version must be written as X.Y.Z")
    nval = [int(x) for x in nums]
    rstr = "{}.{}.{}".format(*nval)
    if rstr != val:
        raise LayoutException(
            n, "semantic version must be written as X.Y.Z")
    if any([v < 0 or v > 255 for v in nval]):
        raise LayoutException(
            n, "semantic version cannot be greater than 255")
    return nval


def layout_enums(root):
    for e in root.x_enums:
        if root.c_enums_dict.get(e.name) is not None:
            raise LayoutException(
                e, "duplicate enum name {}".format(e.name))
        else:
            root.c_enums_dict[e.name] = e
        if e.width is None:
            # Could be commented out to automatically size enums.
            raise LayoutException(
                e, "'width' required for enum {}".format(e.name))
        e.c_width = e.width or 1
        for lit in e.children:
            if lit.value < 0:
                raise LayoutException(
                    lit, "enumeration value must be positive")
            elif lit.value == 0:
                lit_width = 1
            else:
                lit_width = ilog2(lit.value)
            if e.width is None:
                e.c_width = max(e.c_width, lit_width)
            else:
                if lit_width > e.width:
                    raise LayoutException(
                        lit, "value is too large (needs a size of {})".format(lit_width))


def layout_bus(root):
    """Extract size/align from a bus"""
    root.c_align_reg = True
    root.c_buserr = False
    if root.bus is None or root.bus == 'wb-32-be':
        root.c_word_size = 4
        root.c_word_endian = 'big'
    elif root.bus.startswith('wb-'):
        params = root.bus[3:]
        root.c_word_endian = 'big'
        if params == '32':
            root.c_word_size = 4
        elif params == '16':
            root.c_word_size = 2
        else:
            raise LayoutException(
                root, "unknown bus size '{}'".format(root.bus))
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
        root.c_align_reg = False
    else:
        raise LayoutException(root, "unknown bus '{}'".format(root.bus))

    # word endianness override.
    if root.word_endian is not None:
        if root.word_endian not in ['none', 'little', 'big']:
            raise LayoutException(root, "incorrect word-endian value '{}'".format(
                root.word_endian))
        root.c_word_endian = root.word_endian
    # Override by the command line
    if word_endianness != 'default':
        root.c_word_endian = word_endianness

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE


def layout_memmap_root(root):
    """Layout a memmap or a submap but not its children"""
    layout_bus(root)

    # version
    root.c_version = layout_semantic_version(root, root.version)

    # x-map-info
    root.c_memmap_version = layout_semantic_version(root, root.memmap_version)

    # x-enums
    layout_enums(root)


def layout_cheby_memmap(root):
    """Layout a memmap or a submap"""
    layout_memmap_root(root)

    # A normal map/submap
    assert not root.address_spaces
    lo = Layout(root)
    lo.visit(root)


def set_abs_address(n, base_addr):
    "Set c_abs_addr - absolute address - on every node rooted by n"
    n.c_abs_addr = base_addr + n.c_address
    if isinstance(n, tree.Reg):
        pass
    elif isinstance(n, tree.Submap):
        if n.filename is not None:
            set_abs_address(n.c_submap, n.c_abs_addr)
    elif isinstance(n, (tree.Memory, tree.Repeat)):
        # Still relative, but need to set c_abs_addr
        for e in n.children:
            set_abs_address(e, 0)
    elif isinstance(n, (tree.Root, tree.Block, tree.AddressSpace)):
        for e in n.children:
            set_abs_address(e, n.c_abs_addr)
    else:
        raise AssertionError


def layout_cheby(n):
    """Layout the root memmap"""
    if not n.address_spaces:
        # No address space, use a default one
        layout_cheby_memmap(n)
        set_abs_address(n, 0)
    else:
        # At least one address space, none selected
        layout_memmap_root(n)
        n.c_address_spaces_map = {s.name: s for s in n.address_spaces}
        # Move root children to spaces
        for c in n.children:
            if not isinstance(c, tree.Submap):
                raise LayoutException(c, "only submaps are allowed in memmap with address spaces")
            if c.address_space is None:
                raise LayoutException(c, "missing address-space")
            if c.address_space not in n.c_address_spaces_map:
                raise LayoutException(c, "address space {} was not declared".format(c.address_space))
            space = n.c_address_spaces_map[c.address_space]
            space.children.append(c)
        # Root children are now spaces
        n.children = n.address_spaces
        for space in n.address_spaces:
            lo = Layout(n)
            lo.visit(space)
            set_abs_address(space, 0)
