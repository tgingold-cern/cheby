import cheby.tree as tree

class RegsPrinter(object):
    def __init__(self, fd):
        super(RegsPrinter, self).__init__()
        self.fd = fd

    def pr_raw(self, str):
        self.fd.write(str)

    def pr_header(self):
        pass

    def pr_hex_const(self, name, val):
        pass

    def pr_dec_const(self, name, val):
        pass

    def pr_address(self, n):
        self.pr_hex_const("ADDR_{}_{}".format(self.pfx, n.c_name.upper()),
                          n.c_abs_addr)

    def pr_size(self, n, sz):
        self.pr_dec_const("{}_{}_SIZE".format(self.pfx, n.c_name.upper()),
                          sz)

    def pr_field_offset(self, f):
        self.pr_dec_const(
            "{}_{}_OFFSET".format(self.pfx, f.c_name.upper()), f.lo)

    def pr_field_mask(self, f):
        if f.hi is None:
            mask = 1
        else:
            mask = (1 << (f.hi - f.lo + 1)) - 1
        self.pr_hex_const("{}_{}".format(self.pfx, f.c_name.upper()),
                          mask << f.lo)

    def pr_field(self, f):
        self.pr_field_offset(f)
        self.pr_field_mask(f)

    def pr_trailer(self):
        pass


class RegsPrinterVerilog(RegsPrinter):
    def __init__(self, fd, root):
        super(RegsPrinterVerilog, self).__init__(fd)
        self.pfx = root.name.upper()

    def pr_const(self, name, val):
        self.pr_raw("`define {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "'h{:x}".format(val))

    def pr_dec_const(self, name, val):
        self.pr_const(name, "{}".format(val))


class RegsPrinterVHDL(RegsPrinter):
    def __init__(self, fd, root):
        super(RegsPrinterVHDL, self).__init__(fd)
        self.name = root.name
        self.pfx = root.name.upper()

    def pr_header(self):
        self.pr_raw("package {}_Consts is\n".format(self.name))

    def pr_const(self, name, val):
        self.pr_raw("  constant {} : Natural := {};\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const (name, "16#{:x}#".format(val))

    def pr_dec_const(self, name, val):
        self.pr_const (name, "{}".format(val))

    def pr_field_mask(self, f):
        # Not printed as a mask may overflow a natural.
        pass

    def pr_trailer(self):
        self.pr_raw("end package {}_Consts;\n".format(self.name))


class RegsVisitor(tree.Visitor):
    def __init__(self, printer):
        self.printer = printer

    def pr_header(self):
        self.printer.pr_header()

    def pr_address(self, n):
        self.printer.pr_address(n)

    def pr_size(self, n, sz):
        self.printer.pr_size(n, sz)

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
    pr.pr_size(n, n.c_size)


@RegsVisitor.register(tree.Submap)
def pregs_submap(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_size)
    # Recurse ?
    if False and n.filename is not None:
        pregs_complex(pr, n.c_submap)


@RegsVisitor.register(tree.Array)
def pregs_array(pr, n):
    pregs_complex(pr, n)
    pr.pr_size(n, n.c_elsize)

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
