import cheby.tree as tree


class Context(object):
    def __init__(self):
        self.reg_prefix = False
        self.blk_prefix = False


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
                    f.c_name = nprefix if nprefix else n.name
                elif f.name == '':
                    # Handle anonymous field.  Only one such field is allowed.
                    assert len(n.children) == 1
                    f.c_name = nprefix if nprefix else n.c_name
                else:
                    f.c_name = concat(nprefix, f.name)
        elif isinstance(n, tree.Submap):
            nprefix = n.c_name if ctxt.blk_prefix else prefix
            if n.filename is not None:
                gen_name_children(n.c_submap.children, nprefix, ctxt)
        elif isinstance(n, tree.CompositeNode):
            nprefix = n.c_name if ctxt.blk_prefix else prefix
            gen_name_children(n.children, nprefix, ctxt)
        else:
            raise AssertionError(n)


def gen_name_root(root):
    ctxt = Context()
    ctxt.reg_prefix = root.get_extension('x_hdl', 'reg-prefix')
    if ctxt.reg_prefix is None:
        # Backward compatibility
        ctxt.reg_prefix = root.get_extension('x_hdl', 'reg_prefix', True)
    ctxt.blk_prefix = root.get_extension('x_hdl', 'block-prefix')
    if ctxt.blk_prefix is None:
        # Backward compatibility
        ctxt.blk_prefix = root.get_extension('x_hdl', 'block_prefix', True)
    prefix = None
    gen_name_children(root.children, prefix, ctxt)
