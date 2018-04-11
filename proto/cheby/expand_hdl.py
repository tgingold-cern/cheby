import parser
import tree

def expand_x_hdl_field(f, n, dct):
    # Default values
    f.hdl_type = 'wire' if f._parent.access == 'ro' else 'reg'
    f.hdl_write_strobe = False

    for k, v in dct.iteritems():
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


def expand_hdl(root):
    expand_x_hdl(root)
