"""Generate code to check layout of the C structure."""
import cheby.tree as tree


class ChkGen(tree.Visitor):
    def __init__(self, fd):
        self.fd = fd
        self.struct_prefix = ''

    def cg_raw(self, s):
        self.fd.write(s)

    def cg_assert(self, name, expr):
        self.cg_raw("char assert_{}[({}) ? 1 : -1];\n".format(name, expr))

    def cg_size(self, name, sz):
        self.cg_assert(name, "sizeof(struct {}{}) == {}".format(self.struct_prefix, name, sz))

    def cg_offset(self, tag, name, off):
        self.cg_assert("{}_{}".format(tag, name),
                       "offsetof(struct {}{}, {}) == {}".format(self.struct_prefix, tag, name, off))


@ChkGen.register(tree.Reg)
def chklayout_reg(_cg, _n):
    pass


@ChkGen.register(tree.Block)
def sprint_block(_cg, _n):
    pass


@ChkGen.register(tree.Memory)
def sprint_memory(_cg, _n):
    pass


@ChkGen.register(tree.Repeat)
def sprint_repeat(_cg, _n):
    pass


@ChkGen.register(tree.Submap)
def sprint_submap(cg, n):
    if n.filename is None:
        # Generic interface
        pass
    else:
        sn = n.c_submap
        prev = cg.struct_prefix
        cg.struct_prefix = ''
        cg.cg_size(sn.name, sn.c_size)
        cg.struct_prefix = prev


@ChkGen.register(tree.CompositeNode)
def chklayout_composite(cg, n):
    for el in n.children:
        cg.cg_offset(n.c_name, el.name, el.c_address)
        cg.visit(el)


@ChkGen.register(tree.Root)
def chklayout_root(cg, n):
    cg.cg_size(n.name, n.c_size)
    for el in n.children:
        cg.cg_offset(n.name, el.name, el.c_address)
    if n.c_prefix_c_struct:
        cg.struct_prefix = n.name + '_'
    for el in n.children:
        cg.visit(el)


def gen_chklayout_cheby(fd, root):
    cg = ChkGen(fd)
    cg.cg_raw('#include <stddef.h>\n')
    cg.cg_raw('#include <stdint.h>\n')
    cg.cg_raw('#include "{}.h"\n'.format(root.name))
    chklayout_root(cg, root)
