import cheby.parser as parser
import cheby.tree as tree
import cheby.layout as layout
import copy

# Decoce x-hdl extensions.


def expand_x_hdl_reg(n, dct):
    # Default values
    n.hdl_write_strobe = False
    n.hdl_read_strobe = False
    n.hdl_write_ack = False
    n.hdl_read_ack = False
    n.hdl_port = 'field'

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
                parser.error("'port' in x-hdl of register '{}' without fields is useless".format(
                    n.get_path()))
        elif not n.has_fields():
            # x-hdl can also be used for the implicit field.
            expand_x_hdl_field_kv(n.children[0], n, k, v)
        else:
            parser.error("unhandled '{}' in x-hdl of reg {}".format(
                         k, n.get_path()))


def init_x_hdl_field(f):
    "Set default values for x-hdl attributes of a field"
    f.hdl_type = 'wire' if f._parent.access == 'ro' else 'reg'


def expand_x_hdl_field_kv(f, n, k, v):
    "Decode one x-hdl attribute for a field"

    if k == 'type':
        f.hdl_type = parser.read_text(n, k, v)
        if f.hdl_type not in ['wire', 'reg', 'const']:
            parser.error("incorrect value for 'type' in x-hdl of {}".format(
                n.get_path()))
        elif f.hdl_type == 'const' and n.access != 'ro':
            parser.error("'const' x-hdl.type only allowed for 'ro' access for {}".format(
                n.get_path()))
    else:
        parser.error("unhandled '{}' in x-hdl of field {}".format(
            k, n.get_path()))


def expand_x_hdl_field(f, n, dct):
    "Decode all x-hdl attributes for a field"
    init_x_hdl_field(f)

    for k, v in dct.items():
        expand_x_hdl_field_kv(f, n, k, v)


def expand_pipeline(n, v):
    s = parser.read_text(n, 'pipeline', v)
    els = s.split(',')
    vals = {'none': [],
            'in': ['rd-in', 'wr-in'],
            'out': ['rd-out', 'wr-out'],
            'rd': ['rd-in', 'rd-out'],
            'wr': ['wr-in', 'wr-out'],
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
    return list(res)

def expand_x_hdl_root(n, dct):
    n.hdl_pipeline = ['wr-in', 'rd-out']
    for k, v in dct.items():
        if k in ['busgroup', 'iogroup', 'reg_prefix', 'block_prefix']:
            pass
        elif k == 'pipeline':
            n.hdl_pipeline = expand_pipeline(n, v)
        else:
            parser.error("unhandled '{}' in x-hdl of root {}".format(
                         k, n.get_path()))


def expand_x_hdl_submap(n, dct):
    for k, _ in dct.items():
        if k == 'busgroup':
            pass
        else:
            parser.error("unhandled '{}' in x-hdl of {}".format(
                         k, n.get_path()))


def expand_x_hdl(n):
    "Decode x-hdl extensions"
    x_hdl = getattr(n, 'x_hdl', {})
    if isinstance(n, tree.Field):
        expand_x_hdl_field(n, n, x_hdl)
    elif isinstance(n, tree.Reg):
        expand_x_hdl_reg(n, x_hdl)
    elif isinstance(n, tree.Root):
        expand_x_hdl_root(n, x_hdl)
    elif isinstance(n, tree.Submap):
        expand_x_hdl_submap(n, x_hdl)
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


def tree_copy(n, new_parent):
    if isinstance(n, tree.Reg) or isinstance(n, tree.CompositeNode):
        res = copy.copy(n)
        res._parent = new_parent
        res.children = [tree_copy(f, res) for f in n.children]
        return res
    elif isinstance(n, tree.FieldBase):
        res = copy.copy(n)
        res._parent = new_parent
        return res
    else:
        raise AssertionError(n)


def unroll_array(n):
    # Transmute the array to a block with children
    res = tree.Block(n._parent)
    res.name = n.name
    res.align = False
    res.c_address = n.c_address
    res.c_sel_bits = n.c_sel_bits
    res.c_blk_bits = n.c_blk_bits
    res.c_size = n.c_size
    assert len(n.children) == 1
    el = n.children[0]
    for i in range(n.repeat_val):
        c = tree_copy(el, res)
        c.name = "{}_{}".format(el.name, i)
        c.c_address = i * n.c_elsize
        res.children.append(c)
    layout.build_sorted_children(res)
    return res


def unroll_arrays(n):
    if isinstance(n, tree.Reg):
        # Nothing to do.
        return n
    if isinstance(n, tree.Array) and n.align is False:
        # Unroll
        return unroll_array(n)
    if isinstance(n, tree.CompositeNode):
        nl = [unroll_arrays(el) for el in n.children]
        n.children = nl
        layout.build_sorted_children(n)
        return n
    raise AssertionError


def expand_hdl(root):
    expand_x_hdl(root)
    unroll_arrays(root)
    layout.set_abs_address(root, 0)
