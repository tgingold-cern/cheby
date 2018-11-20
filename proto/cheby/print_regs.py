import cheby.tree as tree

class RegsPrinter(object):
    def __init__(self, fd):
        super(RegsPrinter, self).__init__()
        self.fd = fd

    def pr_raw(self, str):
        self.fd.write(str)

    def pr_header(self):
        pass

    def pr_address(self, n):
        pass

    def pr_field(self, f):
        pass

    def pr_trailer(self):
        pass


class RegsPrinterVerilog(RegsPrinter):
    def __init__(self, fd, root):
        super(RegsPrinterVerilog, self).__init__(fd)
        self.pfx = root.name.upper()

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


class RegsPrinterVHDL(RegsPrinter):
    def __init__(self, fd, root):
        super(RegsPrinterVHDL, self).__init__(fd)
        self.name = root.name
        self.pfx = root.name.upper()

    def pr_header(self):
        self.pr_raw("package {}_Consts is\n".format(self.name))

    def pr_address(self, n):
        self.pr_raw("  constant ADDR_{}_{} : Natural := 16#{:x}#;\n".format(
            self.pfx, n.c_name.upper(), n.c_abs_addr))

    def pr_field(self, f):
        self.pr_raw("  constant {}_{}_OFFSET : Natural := {};\n".format(
            self.pfx, f.c_name.upper(), f.lo))

    def pr_trailer(self):
        self.pr_raw("end package {}_Consts;\n".format(self.name))


class RegsVisitor(tree.Visitor):
    def __init__(self, printer):
        self.printer = printer

    def pr_header(self):
        self.printer.pr_header()

    def pr_address(self, n):
        self.printer.pr_address(n)

    def pr_field(self, f):
        self.printer.pr_field(f)

    def pr_trailer(self):
        self.printer.pr_trailer()


@RegsVisitor.register(tree.Reg)
def pregs_reg(pr, n):
    pr.pr_address(n)
    if n.has_fields():
        for f in n.children:
            pr.pr_field(f)


@RegsVisitor.register(tree.Block)
def pregs_block(pr, n):
    pregs_complex(pr, n)


@RegsVisitor.register(tree.Submap)
def pregs_submap(pr, n):
    pr.pr_address(n)
    # Recurse ?
    if False and n.filename is not None:
        pregs_complex(pr, n.c_submap)


@RegsVisitor.register(tree.Array)
def pregs_array(pr, n):
    pregs_complex(pr, n)


@RegsVisitor.register(tree.ComplexNode)
def pregs_complex(pr, n):
    pr.pr_address(n)
    pregs_composite(pr, n)


@RegsVisitor.register(tree.CompositeNode)
def pregs_composite(pr, n):
    for el in n.children:
        pr.visit(el)


@RegsVisitor.register(tree.Root)
def pregs_root(pr, n):
    pregs_composite(pr, n)


def pregs_cheby(fd, root, style):
    cls = {'verilog': RegsPrinterVerilog,
           'vhdl': RegsPrinterVHDL}
    pr = RegsVisitor(cls[style](fd, root))
    pr.pr_header()
    pr.visit(root)
    pr.pr_trailer()
