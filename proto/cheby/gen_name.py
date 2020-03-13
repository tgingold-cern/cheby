import cheby.tree as tree
import cheby.parser as parser


class Context(object):
    def __init__(self):
        self.reg_prefix = False
        self.blk_prefix = False
        self.names = {}

    def set_field_name(self, field, name):
        """Set c_name of :param field: to :param name: and detect collisions"""
        if name in self.names:
            parser.error("field '{}' and '{}' have the same name '{}'".format(
                         self.names[name].get_path(), field.get_path(), name))
        self.names[name] = field
        field.c_name = name


def concat(l, r):
    assert r
    if l is None:
        return r
    else:
        return l + '_' + r


def concat_if(prefix, suffix, cond):
    if cond:
        return concat(prefix, suffix)
    else:
        return prefix


def gen_name_children(children, prefix, ctxt):
    for n in children:
        n.c_name = concat(prefix, n.name)
        if isinstance(n, tree.Reg):
            nprefix = concat_if(prefix, n.name, ctxt.reg_prefix)
            for f in n.children:
                if isinstance(f, tree.FieldReg):
                    cname = nprefix if nprefix else n.name
                elif f.name == '':
                    # Handle anonymous field.  Only one such field is allowed.
                    assert len(n.children) == 1
                    cname = nprefix if nprefix else n.c_name
                else:
                    cname = concat(nprefix, f.name)
                ctxt.set_field_name(f, cname)
        elif isinstance(n, tree.CompositeNode):
            nprefix = n.c_name if ctxt.blk_prefix else prefix
            if isinstance(n, tree.Submap):
                if n.filename is not None:
                    gen_name_children(n.c_submap.children, nprefix, ctxt)
            else:
                gen_name_children(n.children, nprefix, ctxt)
        else:
            raise AssertionError(n)


def gen_name_root(root):
    ctxt = Context()
    ctxt.reg_prefix = root.get_extension('x_hdl', 'reg-prefix')
    if ctxt.reg_prefix is None:
        # Backward compatibility
        ctxt.reg_prefix = root.get_extension('x_hdl', 'reg_prefix', None)
        if ctxt.reg_prefix is not None:
            parser.warning(root, "reg_prefix is deprecated, use 'reg-prefix' instead")
        else:
            ctxt.reg_prefix = True
    ctxt.blk_prefix = root.get_extension('x_hdl', 'block-prefix')
    if ctxt.blk_prefix is None:
        # Backward compatibility
        ctxt.blk_prefix = root.get_extension('x_hdl', 'block_prefix', None)
        if ctxt.blk_prefix is not None:
            parser.warning(root, "block_prefix is deprecated, use 'block-prefix' instead")
        else:
            ctxt.blk_prefix = True
    prefix = None
    gen_name_children(root.children, prefix, ctxt)
