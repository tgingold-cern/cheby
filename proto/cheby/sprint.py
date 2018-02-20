import tree


class SimplePrinter(tree.Visitor):
    def __init__(self, fd):
        self.fd = fd
        self.indent = 0
        self.base_addr = 0

    def sp_raw(self, str):
        self.fd.write(str)

    def inc(self):
        self.indent += 1

    def dec(self):
        self.indent -= 1

    def sp_name(self, kind, n):
        self.sp_raw('0x{:08x}-0x{:08x}: {}{}: {}\n'.format(
            self.base_addr + n.c_address,
            self.base_addr + n.c_address + n.c_size - 1,
            '  ' * self.indent,
            kind, n.name))


@SimplePrinter.register(tree.NamedNode)
def sprint_named(sp, n):
    sp.sp_name(n)


@SimplePrinter.register(tree.Field)
def sprint_field(sp, n):
    pass


@SimplePrinter.register(tree.Reg)
def sprint_reg(sp, n):
    sp.sp_name('reg', n)


@SimplePrinter.register(tree.Block)
def sprint_block(sp, n):
    sp.sp_name('block', n)
    old_base = sp.base_addr
    sp.base_addr = n.c_address
    sprint_complex(sp, n)
    sp.base_addr = old_base


@SimplePrinter.register(tree.Array)
def sprint_array(sp, n):
    sp.sp_name('array[{}] of {}'.format(n.repeat, n.c_elsize), n)
    old_base = sp.base_addr
    sp.base_addr = 0
    sprint_complex(sp, n)
    sp.base_addr = old_base


@SimplePrinter.register(tree.ComplexNode)
def sprint_complex(sp, n):
    sprint_composite(sp, n)


@SimplePrinter.register(tree.CompositeNode)
def sprint_composite(sp, n):
    sp.inc()
    for el in n.children:
        sp.visit(el)
    sp.dec()


@SimplePrinter.register(tree.Root)
def pprint_root(sp, n):
    for el in n.children:
        sp.visit(el)


def sprint_cheby(fd, root):
    sp = SimplePrinter(fd)
    sp.visit(root)
