import cheby.parser as parser
import cheby.tree as tree
import copy

def expand_x_hdl_field(f, n, dct):
    # Default values
    f.hdl_type = 'wire' if f._parent.access == 'ro' else 'reg'
    f.hdl_write_strobe = False

    for k, v in dct.items():
        if k == 'type':
            f.hdl_type = parser.read_text(n, k, v)
        elif k == 'write-strobe':
            f.hdl_write_strobe = parser.read_bool(n, k, v)
        else:
            parser.error("unhandled '{}' in x-hdl of {}".format(
                  k, n.get_path()))

def expand_x_hdl(n):
    "Decode x-hdl extensions"
    x_hdl = getattr(n, 'x_hdl', {})
    if isinstance(n, tree.Field):
        expand_x_hdl_field(n, n, x_hdl)
    elif isinstance(n, tree.Reg):
        if len(n.fields) == 1 and isinstance(n.fields[0], tree.FieldReg):
            expand_x_hdl_field(n.fields[0], n, x_hdl)

    # Visit children
    if isinstance(n, tree.CompositeNode):
        for el in n.elements:
            expand_x_hdl(el)
    elif isinstance(n, tree.Reg):
        for f in n.fields:
            expand_x_hdl(f)

def tree_copy(n):
    if isinstance(n, tree.Reg):
        res = copy.copy(n)
        res.fields = [tree_copy(f) for f in n.fields]
        return res
    elif isinstance(n, tree.Field):
        res = copy.copy(n)
        return res
    else:
        raise AssertionError


def unroll_array(n):
    # Transmute the array to a block with children
    res = tree.Block(n._parent)
    res.name = n.name
    res.align = False
    res.c_address = n.c_address
    res.c_sel_bits = n.c_sel_bits
    res.c_blk_bits = n.c_blk_bits
    res.c_size = n.c_size
    assert len(n.elements) == 1
    el = n.elements[0]
    for i in range(n.repeat):
        c = tree_copy(el)
        c.name = "{}{:x}".format(el.name, i)
        c._parent = res
        c.c_address = n.c_address + i * n.c_elsize
        res.elements.append(c)
    return res


def unroll_arrays(n):
    if isinstance(n, tree.Reg):
        return n
    if isinstance(n, tree.Array):
        if n.align == False:
            return unroll_array(n)
    if isinstance(n, tree.CompositeNode):
        nl = [unroll_arrays(el) for el in n.elements]
        n.elements = nl
        return n
    raise AssertionError


def expand_hdl(root):
    expand_x_hdl(root)
    unroll_arrays(root)
