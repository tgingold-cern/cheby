"""Print as a C structure."""
import cheby.tree as tree


class CPrinter(tree.Visitor):
    def __init__(self, fd):
        self.fd = fd
        self.indent = 0
        self.utypes = {1: 'uint8_t',
                       2: 'uint16_t',
                       4: 'uint32_t',
                       8: 'uint64_t'}
        self.stypes = {1: 'int8_t',
                       2: 'int16_t',
                       4: 'int32_t',
                       8: 'int64_t'}
        self.ftypes = {4: 'float',
                       8: 'double'}

    def cp_raw(self, str):
        self.fd.write(str)

    def inc(self):
        self.indent += 1

    def dec(self):
        self.indent -= 1

    def start_struct(self, name):
        self.cp_raw('{}struct {} {{\n'.format(
            '  ' * self.indent, name))
        self.inc()

    def end_struct(self, name):
        self.dec()
        if name is None:
            self.cp_txt('};')
        else:
            self.cp_txt('}} {};'.format(name))

    def cp_txt(self, txt):
        self.cp_raw('{}{}\n'.format('  ' * self.indent, txt))



@CPrinter.register(tree.Reg)
def cprint_reg(cp, n):
    cp.cp_txt('/* [0x{:x}]: REG {} */'.format(
              n.c_address, n.description))
    if n.c_type == 'signed':
        typ = cp.stypes[n.c_size]
    elif n.c_type == 'float':
        typ = cp.ftypes[n.c_size]
    else:
        typ = cp.utypes[n.c_size]
    cp.cp_txt('{} {};'.format(typ, n.name))


@CPrinter.register(tree.Block)
def sprint_block(cp, n):
    cp.cp_txt('/* [0x{:x}]: BLOCK {} */'.format(
              n.c_address, n.description))
    cp.start_struct(n.name)
    cprint_complex(cp, n)
    cp.end_struct(n.name)


@CPrinter.register(tree.Array)
def sprint_array(cp, n):
    cp.cp_txt('/* [0x{:x}]: ARRAY {} */'.format(
              n.c_address, n.description))
    cp.start_struct(n.name)
    cprint_complex(cp, n)
    cp.end_struct('{}[{}]'.format(n.name, n.repeat))


@CPrinter.register(tree.ComplexNode)
def cprint_complex(cp, n):
    cprint_composite(cp, n)


@CPrinter.register(tree.CompositeNode)
def cprint_composite(cp, n):
    addr = 0
    pad_id = 0
    for el in n.c_sorted_children:
        diff = el.c_address - addr
        assert diff >= 0
        if diff > 0:
            # Pad
            # Note: the 4 is not related to bus size, but to C types.
            if addr % 4 == 0 and diff % 4 == 0:
                sz = 4
            else:
                sz = 1
            cp.cp_txt('/* padding to: {} words */'.format(el.c_address // sz))
            cp.cp_txt('{} __padding_{}[{}];'.format(
                cp.utypes[sz], pad_id, diff // sz))
            pad_id += 1
        cp.visit(el)
        addr = el.c_address + el.c_size


@CPrinter.register(tree.Root)
def cprint_root(cp, n):
    cp.start_struct(n.name)
    cprint_composite(cp, n)
    cp.end_struct(None)


def cprint_cheby(fd, root):
    cp = CPrinter(fd)
    cprint_root(cp, root)
