import cheby.tree as tree


class RegsPrinter(tree.Visitor):
    def __init__(self, fd, root):
        self.fd = fd
        self.pfx = root.name.upper()

    def pr_raw(self, str):
        self.fd.write(str)

    def pr_address(self, n):
        self.pr_raw("`define ADDR_{}_{} 'h{:x}\n".format(
            self.pfx, n.c_name.upper(), n.c_abs_addr))

    def pr_field(self, f):
        self.pr_raw("`define {}_{}_OFFSET {}\n".format(
            self.pfx, f.c_name.upper(), f.lo))
        if f.hi is None:
            mask = 1
        else:
            mask = (1 << (f.hi - f.lo + 1)) - 1
        self.pr_raw("`define {}_{} 'h{:x}\n".format(
            self.pfx, f.c_name.upper(), mask << f.lo))


@RegsPrinter.register(tree.Reg)
def pregs_reg(pr, n):
    pr.pr_address(n)
    if n.has_fields():
        for f in n.children:
            pr.pr_field(f)


@RegsPrinter.register(tree.Block)
def pregs_block(pr, n):
    pregs_complex(pr, n)


@RegsPrinter.register(tree.Submap)
def pregs_submap(pr, n):
    pr.pr_address(n)
    # Recurse ?
    if False and n.filename is not None:
        pregs_complex(pr, n.c_submap)


@RegsPrinter.register(tree.Array)
def pregs_array(pr, n):
    pregs_complex(pr, n)


@RegsPrinter.register(tree.ComplexNode)
def pregs_complex(pr, n):
    pr.pr_address(n)
    pregs_composite(pr, n)


@RegsPrinter.register(tree.CompositeNode)
def pregs_composite(pr, n):
    for el in n.children:
        pr.visit(el)


@RegsPrinter.register(tree.Root)
def pregs_root(pr, n):
    pregs_composite(pr, n)


def pregs_cheby(fd, root):
    pr = RegsPrinter(fd, root)
    pr.visit(root)
