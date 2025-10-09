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


def gen_name_children(parent, prefix, itfprefix, ctxt):
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
        suffix = parent.name
    else:
        suffix = ''

    for n in parent.children:
        n.c_name = concat(prefix, n.name) + suffix
        if isinstance(n, tree.Reg):
            nprefix = concat_if(prefix, n.name, ctxt.reg_prefix)
            if nprefix is not None:
                nprefix += suffix
            for f in n.children:
                # print("n.c_name: {}, field name: {}, f: {}, parent: {}".format(n.c_name, f.name, f, parent))
                if isinstance(f, tree.FieldReg):
                    # If the register is the field, then reg-prefix does not
                    # apply.
                    assert f.name is None
                    f.c_name = concat(prefix, n.name) + suffix
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
            # Also deal with interface names, although this is specific to hdl
            # TODO: it is the best place for that ?
            if n.get_extension('x_hdl', 'iogroup', None):
                # This creates a new interface, just clear the prefix
                n.c_itfname = None
            elif isinstance(parent, tree.RepeatBlock):
                # Do not add index for repeat blocks.
                n.c_itfname = itfprefix
            else:
                n.c_itfname = concat_if(itfprefix, n.name, ctxt.blk_prefix)
            nprefix = n.c_name if ctxt.blk_prefix else prefix
            # print("n.c_name: {}, n.c_itfname: {}, prefix: {}, nprefix: {}".format(n.c_name, n.c_itfname, prefix, nprefix))
            if isinstance(n, tree.Submap):
                if n.filename is not None:
                    gen_name_children(n.c_submap, nprefix, n.c_itfname, ctxt)
            else:
                gen_name_children(n, nprefix, n.c_itfname, ctxt)
        else:
            raise AssertionError(n)
    ctxt.pop()


def gen_name_hierarchy(n):
    ctxt = Context()
    n.c_name = n.name
    n.c_itfname = None
    gen_name_children(n, None, None, ctxt)


def gen_name_memmap(root):
    if root.c_address_spaces_map:
        # Note: address spaces don't add a prefix.
        for a in root.children:
            gen_name_hierarchy(a)
    else:
        gen_name_hierarchy(root)
