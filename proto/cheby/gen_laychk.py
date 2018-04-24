"""Generate code to check layout of the C structure."""
import cheby.tree as tree


class ChkGen(tree.Visitor):
    def __init__(self, fd):
        self.fd = fd

    def cg_raw(self, str):
        self.fd.write(str)

    def cg_assert(self, name, expr):
        self.cg_raw("char assert_{}[({}) ? 1 : -1];\n".format(name, expr))

    def cg_size(self, name, sz):
        self.cg_assert(name, "sizeof(struct {}) == {}".format(name, sz))

    def cg_offset(self, tag, name, off):
        self.cg_assert("{}_{}".format(tag, name),
                       "offsetof(struct {}, {}) == {}".format(tag, name, off))


@ChkGen.register(tree.Reg)
def chklayout_reg(cg, n):
    pass


@ChkGen.register(tree.Block)
def sprint_block(cg, n):
    cg.cg_size(n.name, n.c_size)
    chklayout_complex(cg, n)


@ChkGen.register(tree.Array)
def sprint_array(cg, n):
    cg.cg_size(n.name, n.c_elsize)
    chklayout_complex(cg, n)


@ChkGen.register(tree.ComplexNode)
def chklayout_complex(cg, n):
    chklayout_composite(cg, n)


@ChkGen.register(tree.CompositeNode)
def chklayout_composite(cg, n):
    for el in n.elements:
        cg.cg_offset(n.name, el.name, el.c_address)
        cg.visit(el)


@ChkGen.register(tree.Root)
def chklayout_root(cg, n):
    cg.cg_size(n.name, n.c_size)
    chklayout_composite(cg, n)


def gen_chklayout_cheby(fd, root):
    cg = ChkGen(fd)
    cg.cg_raw('#include <stddef.h>\n')
    cg.cg_raw('#include <stdint.h>\n')
    cg.cg_raw('#include "{}.h"\n'.format(root.name))
    chklayout_root(cg, root)
