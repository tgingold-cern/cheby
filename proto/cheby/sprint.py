import cheby.tree as tree


class SimplePrinter(tree.Visitor):
    def __init__(self, fd, with_fields):
        self.fd = fd
        self.indent = 0
        self.base_addr = 0
        self.with_fields = with_fields

    def sp_raw(self, str):
        self.fd.write(str)

    def inc(self):
        self.indent += 1

    def dec(self):
        self.indent -= 1

    def sp_name(self, kind, n):
        self.sp_raw('0x{:08x}-0x{:08x}: '.format(
            self.base_addr + n.c_address,
            self.base_addr + n.c_address + n.c_size - 1))
        self.sp_raw('{}{}: {}\n'.format('  ' * self.indent, kind, n.name))

    def sp_info(self, info):
        self.sp_raw('                       {}{}\n'.format(
                    '  ' * self.indent, info))

    def sp_field(self, f):
        if f.hi is None:
            self.sp_raw('  {:02}:   '.format(f.lo))
        else:
            self.sp_raw('  {:02}-{:02}:'.format(f.lo, f.hi))
        self.sp_raw(' {}\n'.format(f.name))


@SimplePrinter.register(tree.Reg)
def sprint_reg(sp, n):
    sp.sp_name('reg', n)
    if sp.with_fields:
        for f in n.children:
            sp.sp_field(f)


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
    sp.sp_info("[al: {}, sz: {}, sel: {}, blk: {}] ".format(
                n.c_align, n.c_size, n.c_sel_bits, n.c_blk_bits))
    sp.inc()
    for el in n.children:
        sp.visit(el)
    sp.dec()


@SimplePrinter.register(tree.Root)
def sprint_root(sp, n):
    sp.sp_name('root', n)
    sprint_composite(sp, n)


def sprint_cheby(fd, root, with_fields=True):
    sp = SimplePrinter(fd, with_fields)
    sp.visit(root)
