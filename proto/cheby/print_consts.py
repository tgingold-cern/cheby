import cheby.tree as tree


class ConstsPrinter(object):
    def __init__(self, fd, root):
        super(ConstsPrinter, self).__init__()
        self.fd = fd
        self.root = root
        self.pfx = root.name.upper()

    def pr_raw(self, str):
        self.fd.write(str)

    def pr_header(self):
        pass

    def pr_hex_const(self, name, val):
        pass

    def pr_dec_const(self, name, val):
        pass

    def pr_name(self, n):
        if n == self.root:
            return self.pfx
        else:
            return "{}_{}".format(self.pfx, n.c_name.upper())

    def pr_address(self, n):
        self.pr_hex_const("ADDR_" + self.pr_name(n), n.c_abs_addr)

    def pr_size(self, n, sz):
        self.pr_dec_const(self.pr_name(n) + "_SIZE", sz)

    def pr_version(self, n, nums):
        v = (nums[0] << 16) | (nums[1] << 8) | nums[2]
        self.pr_hex_const(self.pr_name(n) + "_VERSION", v)

    def pr_reg(self, n):
        if n.has_fields():
            return
        f = n.children[0]
        if f.c_preset is not None:
            self.pr_hex_const(self.pr_name(n) + '_PRESET', f.c_preset)

    def pr_field_offset(self, f):
        self.pr_dec_const(self.pr_name(f) + "_OFFSET", f.lo)

    def compute_mask(self, f):
        if f.hi is None:
            mask = 1
        else:
            mask = (1 << (f.hi - f.lo + 1)) - 1
        return mask << f.lo

    def pr_field_mask(self, f):
        self.pr_hex_const(self.pr_name(f), self.compute_mask(f))

    def pr_field(self, f):
        self.pr_field_offset(f)
        self.pr_field_mask(f)

    def pr_trailer(self):
        pass


class ConstsPrinterVerilog(ConstsPrinter):
    def __init__(self, fd, root):
        super(ConstsPrinterVerilog, self).__init__(fd, root)

    def pr_const(self, name, val):
        self.pr_raw("`define {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "'h{:x}".format(val))

    def pr_dec_const(self, name, val):
        self.pr_const(name, "{}".format(val))


class ConstsPrinterVHDL(ConstsPrinter):
    def __init__(self, fd, root):
        super(ConstsPrinterVHDL, self).__init__(fd, root)
        self.name = root.name

    def pr_header(self):
        self.pr_raw("package {}_Consts is\n".format(self.name))

    def pr_const(self, name, val):
        self.pr_raw("  constant {} : Natural := {};\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "16#{:x}#".format(val))

    def pr_dec_const(self, name, val):
        self.pr_const(name, "{}".format(val))

    def pr_field_mask(self, f):
        # Not printed as a mask may overflow a natural.
        pass

    def pr_trailer(self):
        self.pr_raw("end package {}_Consts;\n".format(self.name))


class ConstsPrinterH(ConstsPrinter):
    "Printer for the C language"
    def __init__(self, fd, root):
        super(ConstsPrinterH, self).__init__(fd, root)

    def pr_const(self, name, val):
        self.pr_raw("#define {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name,
                      "0x{:x}UL{}".format(val, "L" if val >= 2**32 else ""))

    def pr_dec_const(self, name, val):
        self.pr_const(name, "{}".format(val))


class ConstsPrinterC(ConstsPrinterH):
    "Printer used by gen_c"
    def __init__(self, fd, root):
        super(ConstsPrinterC, self).__init__(fd, root)

    def pr_size(self, n, sz):
        self.pr_dec_const(self.pr_name(n) + "_SIZE", sz)

    def pr_address(self, n):
        self.pr_raw('\n')
        self.pr_raw('/* {} */\n'.format(n.description))
        self.pr_hex_const(self.pr_name(n), n.c_abs_addr)

    def pr_field(self, f):
        if f.hi is None:
            # A single bit
            self.pr_hex_const(self.pr_name(f), self.compute_mask(f))
        else:
            # A multi-bit field
            self.pr_hex_const(self.pr_name(f) + '_MASK', self.compute_mask(f))
            self.pr_dec_const(self.pr_name(f) + "_SHIFT", f.lo)


class ConstsVisitor(tree.Visitor):
    def __init__(self, printer):
        self.printer = printer

    def pr_header(self):
        self.printer.pr_header()

    def pr_address(self, n):
        self.printer.pr_address(n)

    def pr_size(self, n, sz):
        self.printer.pr_size(n, sz)

    def pr_reg(self, n):
        self.printer.pr_reg(n)

    def pr_field(self, f):
        self.printer.pr_field(f)

    def pr_trailer(self):
        self.printer.pr_trailer()


@ConstsVisitor.register(tree.Reg)
def pconsts_reg(pr, n):
    pr.pr_address(n)
    pr.pr_reg(n)
    if n.has_fields():
        for f in n.children:
            pr.pr_field(f)


@ConstsVisitor.register(tree.Block)
def pconsts_block(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_size)
    pconsts_composite(pr, n)


@ConstsVisitor.register(tree.Submap)
def pconsts_submap(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_size)
    # Recurse ?
    if False and n.filename is not None:
        pconsts_composite(pr, n.c_submap)


@ConstsVisitor.register(tree.Array)
def pconsts_array(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_elsize)
    pconsts_composite(pr, n)


@ConstsVisitor.register(tree.Memory)
def pconsts_memory(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_elsize)
    pconsts_composite(pr, n)


@ConstsVisitor.register(tree.Repeat)
def pconsts_repeat(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_elsize)
    pconsts_composite(pr, n)


@ConstsVisitor.register(tree.CompositeNode)
def pconsts_composite(pr, n):
    for el in n.children:
        pr.visit(el)


@ConstsVisitor.register(tree.Root)
def pconsts_root(pr, n):
    pr.printer.pr_size(n, n.c_size)
    if n.version is not None:
        pr.printer.pr_version(n, n.c_version)
    for el in n.children:
        pr.visit(el)


def pconsts_for_gen_c(fd, root):
    pr = ConstsVisitor(ConstsPrinterC(fd, root))
    pr.visit(root)


def pconsts_cheby(fd, root, style):
    cls = {'verilog': ConstsPrinterVerilog,
           'vhdl': ConstsPrinterVHDL,
           'h': ConstsPrinterH}
    pr = ConstsVisitor(cls[style](fd, root))
    pr.pr_header()
    pr.visit(root)
    pr.pr_trailer()
