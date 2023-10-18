import copy
import cheby.parser as parser
import cheby.tree as tree
import cheby.layout as layout

# Decoce x-hdl extensions.


def expand_x_hdl_reg(n, dct):
    # Default values
    n.hdl_write_strobe = False
    n.hdl_read_strobe = False
    n.hdl_write_ack = False
    n.hdl_read_ack = False
    n.hdl_port = 'field'
    n.hdl_type = None
    n.hdl_port_name = None

    if not n.has_fields():
        # x-hdl can also be used for the implicit field.
        init_x_hdl_field(n.children[0])

    for k, v in dct.items():
        if k == 'write-strobe':
            n.hdl_write_strobe = parser.read_bool(n, k, v)
        elif k == 'read-strobe':
            n.hdl_read_strobe = parser.read_bool(n, k, v)
        elif k == 'write-ack':
            n.hdl_write_ack = parser.read_bool(n, k, v)
        elif k == 'read-ack':
            n.hdl_read_ack = parser.read_bool(n, k, v)
        elif k == 'port':
            n.hdl_port = parser.read_text(n, k, v)
            if n.hdl_port not in ['field', 'reg']:
                parser.error("incorrect value for 'port' in x-hdl of {}".format(
                    n.get_path()))
            if not n.has_fields():
                parser.warning(
                    n, "'port' in x-hdl of register '{}' without fields is useless".format(
                        n.get_path()))
        elif k == 'port-name':
            n.hdl_port_name = v
        elif not n.has_fields():
            # x-hdl can also be used for the implicit field.
            expand_x_hdl_field_kv(n.children[0], n, k, v)
        elif k == 'type':
            # Inherited
            n.hdl_type = expand_x_hdl_field_type(n, v)
        else:
            parser.error("unhandled '{}' in x-hdl of reg {}".format(
                k, n.get_path()))

    if n.hdl_port == 'field' and n.hdl_port_name is not None and n.has_fields():
        parser.warning(
            n, "'port-name' in x-hdl of register '{}' is useless".format(
                n.get_path()))

    if not n.has_fields():
        expand_x_hdl_field_validate(n.children[0])


def init_x_hdl_field(f):
    "Set default values for x-hdl attributes of a field"
    f.hdl_port_name = None

    if f.parent.hdl_type is not None:
        f.hdl_type = f.parent.hdl_type
    elif f.parent.constant is not None:
        f.hdl_type = 'const'
    elif f.parent.access == 'ro':
        f.hdl_type = 'wire'
    else:
        f.hdl_type = 'reg'

    f.hdl_lock = None


def expand_x_hdl_field_type(n, v):
    """Decode and check attribute 'type' with value :arg v:
    :arg n: node for error"""
    res = parser.read_text(n, 'type', v)
    if res not in [
        "reg",
        "no-port",
        "wire",
        "const",
        "autoclear",
        "or-clr",
        "or-clr-out",
    ]:
        parser.error("incorrect value for 'type' in x-hdl of {}".format(n.get_path()))
    return res


def expand_x_hdl_field_kv(f, n, k, v):
    "Decode one x-hdl attribute for a field"
    if k == 'type':
        f.hdl_type = expand_x_hdl_field_type(n, v)
    elif k == 'port-name':
        f.hdl_port_name = v
    elif k == 'lock':
        f.hdl_lock = parser.read_bool(n, k, v)
    else:
        parser.error("unhandled '{}' in x-hdl of field {}".format(
            k, n.get_path()))

def expand_x_hdl_field_validate(f):
    # Validate x-hdl attributes
    if f.hdl_type == "no-port":
        if f.parent.access != "rw":
            parser.error(
                "{}: 'no-port' x-hdl.type not allowed for '{}' access".format(
                    f.get_path(), f.parent.access
                )
            )
    if f.hdl_type == 'const':
        if f.parent.access == 'wo':
            parser.error("{}: 'const' x-hdl.type not allowed for 'wo' access".format(
                f.get_path()))
        if f.c_preset is None:
            # Check c_preset as preset may be set on the reg (when there is no field)
            parser.error("{}: 'const' x-hdl.type requires a 'preset' value".format(
                f.get_path()))

    if f.hdl_type == 'autoclear':
        if f.parent.access == 'ro':
            parser.error("{}: 'autoclear' x-hdl.type not allowed for 'ro' access".format(
                f.get_path()))

    if f.hdl_type == 'or-clr':
        if f.parent.access != 'rw':
            parser.error("{}: 'or-clr' x-hdl.type requires 'rw' access".format(
                f.get_path()))

    if (f.hdl_type and f.hdl_type != "reg") and f.hdl_lock:
        parser.error(
            "{}: '{}' x-hdl.type cannot be lockable".format(f.get_path(), f.hdl_type)
        )


def expand_x_hdl_field(f, n, dct):
    "Decode all x-hdl attributes for a field"
    init_x_hdl_field(f)

    for k, v in dct.items():
        expand_x_hdl_field_kv(f, n, k, v)

    expand_x_hdl_field_validate(f)

def expand_pipeline(n, v):
    s = parser.read_text(n, 'pipeline', v)
    els = s.split(',')
    vals = {'none': [],
            'in': ['rd-in', 'wr-in'],
            'out': ['rd-out', 'wr-out'],
            'rd': ['rd-in', 'rd-out'],
            'wr': ['wr-in', 'wr-out'],
            'all': ['wr-in', 'wr-out', 'rd-in', 'rd-out'], 
            'rd-in': ['rd-in'],
            'rd-out': ['rd-out'],
            'wr-in': ['wr-in'],
            'wr-out': ['wr-out']}
    # Check values.
    for e in els:
        if e not in vals:
            parser.error("unhandled '{}' in x-hdl/pipeline of {}".format(
                e, n.get_path()))
    # Compute res.
    res = set()
    if 'none' in els:
        if len(els) != 1:
            parser.error("'none' can only be alone in x-hdl/pipeline of {}".format(
                n.get_path()))
        return []
    for e in els:
        res.update(vals[e])
    return sorted(list(res))


def expand_x_hdl_block(n, dct):
    n.hdl_iogroup = None
    for k, v in dct.items():
        if k in ('reg-prefix', 'block-prefix'):
            pass
        elif k == 'iogroup':
            n.hdl_iogroup = parser.read_text(n, k, v)
        else:
            parser.error("unhandled '{}' in x-hdl of {}".format(
                k, n.get_path()))


def expand_x_hdl_memory(n, dct):
    n.hdl_dual_clock = False
    for k, v in dct.items():
        if k == 'dual-clock':
            n.hdl_dual_clock = parser.read_bool(n, k, v)
            if n.interface is not None:
                parser.error("'dual-clock' incompatible with 'interface' for memory {}".format(
                    n.get_path()))
        else:
            parser.error("unhandled '{}' in x-hdl of {}".format(
                k, n.get_path()))


def expand_x_hdl_root(n, dct):
    n.hdl_pipeline = None
    n.hdl_bus_attribute = None
    n.hdl_iogroup = None
    n.hdl_wmask = False
    n.hdl_lock_port = None

    for k, v in dct.items():
        if k in ['busgroup',
                 'reg_prefix', 'reg-prefix', 'block_prefix', 'block-prefix',
                 'name-suffix',
                 'bus-error']:
            pass
        elif k == 'iogroup':
            n.hdl_iogroup = parser.read_text(n, k, v)
        elif k == 'wmask':
            n.hdl_wmask = parser.read_bool(n, k, v)
        elif k == 'bus-attribute':
            if v in ('Xilinx',):
                n.hdl_bus_attribute = v
            else:
                parser.error("bad value for x-hdl:bus-attribute of root {}".format(
                    n.get_path()))
        elif k == 'bus-granularity':
            if v not in ('byte', 'word'):
                parser.error("bad value for x-hdl:bus-granularity for {}".format(
                    n.get_path()))
        elif k == 'pipeline':
            n.hdl_pipeline = expand_pipeline(n, v)
        elif k == 'lock-port':
            n.hdl_lock_port = parser.read_text(n, k, v)
        else:
            parser.error("unhandled '{}' in x-hdl of root {}".format(
                k, n.get_path()))

    # Default pipeline
    if n.hdl_pipeline is None:
        if n.bus == 'avalon-lite-32':
            # No need to pipeline as the avalon interface already inserts a pipeline stage
            pl = []
        else:
            pl = ['wr-in', 'rd-out']
        n.hdl_pipeline = pl

    # Set name of the module.
    suffix = dct.get('name-suffix', '')
    n.hdl_module_name = n.name + suffix

    expand_x_hdl_root_validate(n)


def expand_x_hdl_root_validate(r):
    # Validate x-hdl attributes
    if r.hdl_wmask and not any(
        r.bus.startswith(bus) for bus in ["apb-", "avalon-lite-", "axi4-lite-", "wb-"]
    ):
        parser.error("Bus '{}' does not support the write mask feature".format(r.bus))



def expand_x_hdl_submap(n, dct):
    for k, _ in dct.items():
        if k == 'busgroup':
            if n.include:
                parser.warning(n, "x-hdl:busgroup for included submap '{}' is ignored".format(
                    n.get_path()))
            elif n.filename:
                parser.warning(
                    n, "x-hdl:busgroup for submap '{}' is ignored (defined by the file)".format(
                        n.get_path()))
        else:
            parser.error("unhandled '{}' in x-hdl of {}".format(
                k, n.get_path()))


def expand_x_hdl(n):
    "Decode x-hdl extensions"
    x_hdl = getattr(n, 'x_hdl', {})
    if isinstance(n, tree.Field):
        expand_x_hdl_field(n, n.parent, x_hdl)
    elif isinstance(n, tree.Reg):
        expand_x_hdl_reg(n, x_hdl)
    elif isinstance(n, tree.Root):
        expand_x_hdl_root(n, x_hdl)
    elif isinstance(n, tree.Submap):
        expand_x_hdl_submap(n, x_hdl)
    elif isinstance(n, (tree.Block, tree.Repeat)):
        expand_x_hdl_block(n, x_hdl)
    elif isinstance(n, tree.Memory):
        expand_x_hdl_memory(n, x_hdl)
    else:
        if x_hdl:
            parser.error("no x-hdl attributes allowed for {}".format(
                n.get_path()))

    # Visit children
    if isinstance(n, tree.Submap):
        if n.filename is not None:
            expand_hdl(n.c_submap)
        return
    if isinstance(n, tree.CompositeNode):
        for el in n.children:
            expand_x_hdl(el)
    elif isinstance(n, tree.Reg):
        for f in n.children:
            expand_x_hdl(f)
    elif isinstance(n, tree.FieldBase):
        pass
    else:
        raise AssertionError(n)


def NamedNode_copy(n, new_parent):
    res = copy.copy(n)
    res._parent = new_parent
    return res


def Reg_copy(n, new_parent):
    res = NamedNode_copy(n, new_parent)
    res.children = [tree_copy(f, res) for f in n.children]
    layout.build_sorted_fields(res)
    return res


def CompositeNode_copy(n, new_parent):
    res = NamedNode_copy(n, new_parent)
    res.children = [tree_copy(f, res) for f in n.children]
    return res


def Submap_copy(n, new_parent):
    res = CompositeNode_copy(n, new_parent)
    if n.c_submap is not None:
        res.c_submap = tree_copy(n.c_submap, res)
    return res


def tree_copy(n, new_parent):
    if isinstance(n, tree.Reg):
        return Reg_copy(n, new_parent)
    elif isinstance(n, tree.Submap):
        return Submap_copy(n, new_parent)
    elif isinstance(n, tree.CompositeNode):
        return CompositeNode_copy(n, new_parent)
    elif isinstance(n, tree.FieldBase):
        return NamedNode_copy(n, new_parent)
    else:
        raise AssertionError(n)


def unroll_repeat(n):
    # Transmute the array to COUNT blocks
    res = tree.RepeatBlock(parent=n.parent, origin=n)
    res.name = n.name
    res.align = n.align
    res.c_address = n.c_address
    res.c_size = n.c_size
    res.c_align = n.c_align
    res.hdl_iogroup = n.hdl_iogroup
    res.count = n.count
    if hasattr(n, 'x_hdl'):
        res.x_hdl = n.x_hdl
    for i in range(n.count):
        blk = tree.Block(res)
        blk.name = "{}".format(i)
        blk.align = n.align
        blk.c_address = i * n.c_elsize
        blk.c_size = n.c_elsize
        blk.c_align = n.c_align
        blk.children = [tree_copy(el, blk) for el in n.children]
        blk.origin = n
        blk.hdl_iogroup = None
        layout.build_sorted_children(blk)
        res.children.append(blk)
    layout.build_sorted_children(res)
    return res


def unroll_repeats(n):
    if isinstance(n, tree.Reg):
        # Nothing to do.
        return n
    if isinstance(n, tree.CompositeNode):
        nl = [unroll_repeats(el) for el in n.children]
        n.children = nl
        layout.build_sorted_children(n)
    if isinstance(n, tree.Repeat):
        # Unroll
        return unroll_repeat(n)
    else:
        return n


def expand_memmap_hdl(root):
    expand_x_hdl(root)
    unroll_repeats(root)
    # Set again the absolute address, as new nodes may have been added (by unroll)
    layout.set_abs_address(root, 0)


def expand_hdl(root):
    if root.c_address_spaces_map:
        x_hdl = getattr(root, 'x_hdl', {})
        expand_x_hdl_root(root, x_hdl)
        for c in root.children:
            expand_memmap_hdl(c)
            c.hdl_module_name = root.hdl_module_name
            c.hdl_bus_attribute = root.hdl_bus_attribute
            c.hdl_pipeline = root.hdl_pipeline
            c.hdl_iogroup = None
            c.bus = root.bus
    else:
        expand_memmap_hdl(root)
