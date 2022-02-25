import cheby.tree as tree
import cheby.parser as parser


class Context(object):
    def __init__(self):
        self.reg_prefix = True
        self.blk_prefix = True
        self.stack = []     # stack of saved states
        self.names = {}

    def check_field_name(self, field):
        """Detect collisions of field names"""
        name = field.c_name
        if name in self.names:
            parser.error("field '{}' and '{}' have the same name '{}'".format(
                self.names[name].get_path(), field.get_path(), name))
        self.names[name] = field

    def push(self):
        self.stack.append((self.reg_prefix, self.blk_prefix))

    def pop(self):
        self.reg_prefix, self.blk_prefix = self.stack.pop()


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


def gen_name_children(parent, prefix, ctxt):
    ctxt.push()

    # Prefix control
    rpfx = parent.get_extension('x_hdl', 'reg-prefix')
    if rpfx is None:
        # Backward compatibility
        rpfx = parent.get_extension('x_hdl', 'reg_prefix', None)
        if rpfx is not None:
            parser.warning(parent, "reg_prefix is deprecated, use 'reg-prefix' instead")
    if rpfx is not None:
        ctxt.reg_prefix = rpfx

    bpfx = parent.get_extension('x_hdl', 'block-prefix')
    if bpfx is None:
        # Backward compatibility
        bpfx = parent.get_extension('x_hdl', 'block_prefix', None)
        if bpfx is not None:
            parser.warning(parent, "block_prefix is deprecated, use 'block-prefix' instead")
    if bpfx is not None:
        ctxt.blk_prefix = bpfx

    # Keep the values for --gen-consts.
    parent.hdl_blk_prefix = ctxt.blk_prefix
    parent.hdl_reg_prefix = ctxt.reg_prefix

    # If the parent is expanded from a repeat, append the index.
    if isinstance(parent, tree.Block) and isinstance(parent.origin, tree.Repeat) and not ctxt.blk_prefix:
        for n in parent.children:
            n.name += parent.name

    for n in parent.children:
        n.c_name = concat(prefix, n.name)
        if isinstance(n, tree.Reg):
            nprefix = concat_if(prefix, n.name, ctxt.reg_prefix)
            for f in n.children:
                if isinstance(f, tree.FieldReg):
                    # If the register is the field, then reg-prefix does not
                    # apply.
                    assert f.name is None
                    f.c_name = concat(prefix, n.name)
                elif f.name == '':
                    # Handle anonymous field.  Only one such field is allowed.
                    assert len(n.children) == 1
                    f.c_name = nprefix if nprefix else n.c_name
                else:
                    f.c_name = concat(nprefix, f.name)
                if not isinstance(parent, tree.Memory):
                    # Do no try to detect collisions for fields of a memory: they are not
                    # exported as ports.
                    ctxt.check_field_name(f)
        elif isinstance(n, tree.CompositeNode):
            nprefix = n.c_name if ctxt.blk_prefix else prefix
            if isinstance(n, tree.Submap):
                if n.filename is not None:
                    gen_name_children(n.c_submap, nprefix, ctxt)
            else:
                gen_name_children(n, nprefix, ctxt)
        else:
            raise AssertionError(n)
    ctxt.pop()


def gen_name_hierarchy(n):
    ctxt = Context()
    prefix = None
    gen_name_children(n, prefix, ctxt)


def gen_name_memmap(root):
    if root.c_address_spaces_map:
        for a in root.children:
            gen_name_hierarchy(a)
    else:
        gen_name_hierarchy(root)
