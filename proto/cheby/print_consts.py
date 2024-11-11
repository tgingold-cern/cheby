import cheby.tree as tree
import cheby.layout as layout


class ConstsPrinter(object):
    def __init__(self, fd, root, sep="_", num="({})", indexOff=0):
        super(ConstsPrinter, self).__init__()
        self.fd = fd
        self.root = root
        self.pfx = root.name.upper()
        self.sep = sep
        self.num = num
        self.indexOff = indexOff

    def pr_raw(self, s):
        self.fd.write(s)

    def pr_header(self):
        pass

    def pr_const(self, name, val):
        """Print a constant, :param val: is a string.
           Must be overridden"""
        raise Exception

    def pr_hex_const(self, name, val):
        "Unsized hex constant"
        pass

    def pr_hex_data(self, name, val, width):
        "Hex constant using the width of the data"
        self.pr_hex_const(name, val)

    def pr_hex_addr(self, name, val):
        "Hex constant using the width of the address"
        self.pr_hex_const(name, val)

    def pr_dec_const(self, name, val):
        self.pr_const(name, "{}".format(val))

    def pr_name(self, n):
        if n == self.root:
            return self.pfx
        else:
            if self.sep != "_":
                # Return node names concatenated with separator
                if n.name.isdecimal():
                    num = int(n.name) + self.indexOff
                    return "{}{}".format(self.pr_name(n.parent), self.num.format(num))
                else:
                    return "{}{}{}".format(self.pr_name(n.parent), self.sep, n.name)
            else:
                # Return c_name with prefix
                # (see also comment in pr_field() calling pr_field_address())
                return "{}_{}".format(self.pfx, n.c_name.upper())

    def pr_address(self, n):
        if self.sep != "_":
            name = self.pr_name(n) + self.sep + "ADDR"
        else:
            name = "ADDR_" + self.pr_name(n)
        self.pr_hex_addr(name, n.c_abs_addr)

    def pr_address_mask(self, n):
        if self.sep != "_":
            name = self.pr_name(n) + self.sep + "MASK"
        else:
            name = "ADDR_MASK_" + self.pr_name(n)

        self.pr_hex_addr(name, layout.round_pow2(n._parent.c_size) - n.c_size)

    def pr_size(self, n, sz):
        self.pr_dec_const(self.pr_name(n) + self.sep + "SIZE", sz)

    def pr_version(self, n, name, nums):
        v = (nums[0] << 16) | (nums[1] << 8) | nums[2]
        self.pr_hex_const(self.pr_name(n) + self.sep + name, v)

    def pr_ident(self, n, name, val):
        self.pr_hex_const(self.pr_name(n) + self.sep + name, val)

    def pr_reg(self, n):
        if n.has_fields():
            return
        f = n.children[0]
        if f.c_preset is not None:
            self.pr_preset(self.pr_name(n), f.c_preset, n.width)

    def pr_field_offset(self, f):
        self.pr_dec_const(self.pr_name(f) + self.sep + "OFFSET", f.lo)

    def compute_width(self, f):
        if f.hi is None:
            return 1
        else:
            return f.hi - f.lo + 1

    def compute_mask(self, f):
        mask = (1 << self.compute_width(f)) - 1
        return mask << f.lo

    def pr_field_address(self, f):
        if self.sep != "_":
            name = self.pr_name(f) + self.sep + "ADDR"
        else:
            name = "ADDR_" + self.pr_name(f)
        self.pr_hex_addr(name, f.parent.c_abs_addr)

    def pr_field_width(self, f):
        self.pr_dec_const(self.pr_name(f) + self.sep + "WIDTH", self.compute_width(f))

    def pr_field_mask(self, f):
        self.pr_hex_data(self.pr_name(f), self.compute_mask(f), f._parent.width)

    def pr_field(self, f):
        if self.sep != "_" or f.parent.c_name != f.c_name:
            # If there is a register containing a single field and both share the same
            # name, both of their c_name s will be equal. Hence, when the default
            # separator "_" is selected, pr_name() will return the same name for the
            # register as well as for the field. Printing the address for the register
            # and the field will therefore lead to the same constant printed twice.
            # In that case, this condition blocks the field address constant to be
            # printed here.
            self.pr_field_address(f)

        self.pr_field_width(f)
        self.pr_field_offset(f)
        self.pr_field_mask(f)

        if f.c_preset is not None:
            self.pr_preset(self.pr_name(f), f.c_preset, f.c_rwidth)

    def pr_preset(self, name, preset, width):
        name = name + self.sep + "PRESET"
        self.pr_hex_data(name, preset, width)

    def pr_enum(self, name, val, wd):
        self.pr_hex_const(name, val)

    def pr_trailer(self):
        pass


class ConstsPrinterVerilog(ConstsPrinter):
    def pr_const(self, name, val):
        self.pr_raw("`define {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "'h{:x}".format(val))

    def pr_enum(self, name, val, wd):
        self.pr_const (name, "{}'h{:x}".format(wd, val))


class ConstsPrinterSystemVerilog(ConstsPrinter):
    def __init__(self, fd, root):
        super(ConstsPrinterSystemVerilog, self).__init__(fd, root)
        self.pkg_name = root.hdl_module_name + '_Consts'

    def pr_header(self):
        self.pr_raw("package {};\n".format(self.pkg_name))

    def pr_const(self, name, val):
        self.pr_raw("  localparam {} = {};\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "'h{:x}".format(val))

    def pr_hex_data(self, name, val, width):
        self.pr_const(name, "{}'h{:x}".format(width, val))

    def pr_enum(self, name, val, wd):
        self.pr_const (name, "{}'h{:x}".format(wd, val))

    def pr_trailer(self):
        self.pr_raw("endpackage\n")


class ConstsPrinterVHDL(ConstsPrinter):
    def __init__(self, fd, root):
        super(ConstsPrinterVHDL, self).__init__(fd, root)
        self.pkg_name = root.hdl_module_name + '_Consts'

    def pr_header(self):
        # Enums and constants use std_logic_vector.
        self.pr_raw("library ieee;\n")
        self.pr_raw("use ieee.std_logic_1164.all;\n")
        self.pr_raw("\n")

        self.pr_raw("package {} is\n".format(self.pkg_name))

    def pr_const(self, name, val):
        self.pr_raw("  constant {} : Natural := {};\n".format(name, val))

    def pr_const_width(self, name, val, width):
        self.pr_raw("  constant {} : std_logic_vector({}-1 downto 0) := {};\n".format(name, width, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "16#{:x}#".format(val))

    def pr_bin_data(self, name, val, width):
        bin_val = "{:b}".format(val).zfill(width)
        self.pr_const_width(name, "\"{}\"".format(bin_val), width)

    def pr_hex_data(self, name, val, width):
        if width % 4 == 0:
            hex_width = round(width / 4)
            hex_val = "{:x}".format(val).zfill(hex_width)
            self.pr_const_width(name, "x\"{}\"".format(hex_val), width)
        else:
            # Fall back to a binary constant for improved tool compatibility
            self.pr_bin_data(name, val, width)

    def pr_field_mask(self, f):
        # Not printed as a mask may overflow a natural.
        pass

    def pr_enum(self, name, val, wd):
        self.pr_raw ("  constant {} : std_logic_vector ({} downto 0) := \"{:0{wd}b}\";\n".format(name, wd - 1, val, wd=wd))

    def pr_trailer(self):
        self.pr_raw("end package {};\n".format(self.pkg_name))


class ConstsPrinterVHDLOhwr(ConstsPrinterVHDL):
    def __init__(self, fd, root):
        super(ConstsPrinterVHDLOhwr, self).__init__(fd, root)
        self.pkg_name = root.hdl_module_name + '_consts_pkg'

    def pr_const(self, name, val):
        super().pr_const("c_" + name, val)

    def pr_const_width(self, name, val, width):
        super().pr_const_width("c_" + name, val, width)

    def pr_address(self, n):
        # ADDR is a suffix.
        self.pr_hex_const(self.pr_name(n) + "_ADDR", n.c_abs_addr)


class ConstsPrinterH(ConstsPrinter):
    "Printer for the C language"
    def pr_const(self, name, val):
        self.pr_raw("#define {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name,
                      "0x{:x}UL{}".format(val, "L" if val >= 2**32 else ""))


class ConstsPrinterC(ConstsPrinterH):
    "Printer used by gen_c"
    def pr_size(self, n, sz):
        cmt = "0x{:x}".format(sz)
        if sz >= 1024 and (sz % 1024) == 0:
            cmt += " = {}KB".format(sz // 1024)
        self.pr_raw("#define {} {} /* {} */\n".format(self.pr_name(n) + "_SIZE", sz, cmt))

    def pr_address(self, n):
        self.pr_raw('\n')
        self.pr_raw('/* {} */\n'.format(n.comment or n.description or "(comment missing)"))
        self.pr_hex_const(self.pr_name(n), n.c_abs_addr)

    def pr_field(self, f):
        if f.hi is None:
            # A single bit
            if self.sep != "_" or f.parent.c_name != f.c_name:
                # If there is a register containing a single field and both share the same
                # name, both of their c_name s will be equal. Hence, when the default
                # separator "_" is selected, pr_name() will return the same name for the
                # register as well as for the field. Printing the address for the register
                # and the field will therefore lead to the same constant printed twice.
                # In that case, this condition blocks the field address constant to be
                # printed here.
                self.pr_hex_const(self.pr_name(f), self.compute_mask(f))

        # Always print _MASK and _SHIFT constants
        self.pr_hex_const(self.pr_name(f) + '_MASK', self.compute_mask(f))
        self.pr_dec_const(self.pr_name(f) + "_SHIFT", f.lo)

        if f.c_preset is not None:
            self.pr_preset(self.pr_name(f), f.c_preset, f.c_rwidth)


class ConstsPrinterPython(ConstsPrinter):
    def pr_const(self, name, val):
        self.pr_raw("{} = {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "0x{:x}".format(val))


class ConstsPrinterMatlab(ConstsPrinter):
    def __init__(self, fd, root, sep="_"):
        super().__init__(fd, root, sep, num="({})", indexOff=1)

    def pr_const(self, name, val):
        self.pr_raw("{} = {};\n".format(name, val))

    def pr_hex_const(self, name, val):
        # Matlab does not support hexadecimal values
        self.pr_dec_const(name, val)


class ConstsPrinterTCL(ConstsPrinter):
    def pr_const(self, name, val):
        self.pr_raw("set {} {}\n".format(name, val))

    def pr_hex_const(self, name, val):
        self.pr_const(name, "0x{:x}".format(val))


class ConstsVisitor(tree.Visitor):
    def __init__(self, printer):
        self.printer = printer

    def pr_header(self):
        self.printer.pr_header()

    def pr_address(self, n):
        self.printer.pr_address(n)

    def pr_address_mask(self, n):
        self.printer.pr_address_mask(n)

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
    if n.parent.hdl_blk_prefix:
        pr.pr_address(n)
        pr.pr_size(n, n.c_size)
    pconsts_composite_children(pr, n)


@ConstsVisitor.register(tree.RepeatBlock)
def pconsts_repeatblock(pr, n):
    pconsts_block(pr, n)


@ConstsVisitor.register(tree.Submap)
def pconsts_submap(pr, n):
    pr.pr_address(n)
    pr.pr_address_mask(n)
    pr.pr_size(n, n.c_size)
    # Recurse ?
    if False and (n.filename is not None):
        pconsts_composite_children(pr, n.c_submap)


@ConstsVisitor.register(tree.Memory)
def pconsts_memory(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_elsize)
    pconsts_composite_children(pr, n)


@ConstsVisitor.register(tree.Repeat)
def pconsts_repeat(pr, n):
    pr.pr_address(n)
    pr.pr_size(n, n.c_elsize)
    pconsts_composite_children(pr, n)


@ConstsVisitor.register(tree.AddressSpace)
def pconsts_address_space(pr, n):
    pconsts_composite_children(pr, n)


def pconsts_composite_children(pr, n):
    for el in n.children:
        pr.visit(el)


def pconsts_enums(pr, root):
    for en in root.x_enums:
        #  pr.comment("Enumeration {}".format(en.name))
        for val in en.children:
            pr.printer.pr_enum("C_{}_{}".format(en.name, val.name), val.value, en.width)

@ConstsVisitor.register(tree.Root)
def pconsts_root(pr, n):
    if n.c_address_spaces_map is None:
        pr.printer.pr_size(n, n.c_size)
    if n.version is not None:
        pr.printer.pr_version(n, 'VERSION', n.c_version)
    if n.c_memmap_version is not None:
        pr.printer.pr_version(n, 'MEMMAP_VERSION', n.c_memmap_version)
    if n.ident is not None:
        pr.printer.pr_ident(n, 'IDENT', n.ident)
    pconsts_composite_children(pr, n)
    pconsts_enums(pr, n)

def pconsts_for_gen_c(fd, root):
    pr = ConstsVisitor(ConstsPrinterC(fd, root))
    pr.visit(root)


class StructVisitor(ConstsVisitor):
    def __init__(self, printer):
        self.printer = printer

        # Set hierarchical separator
        self.printer.sep = "."

        # Avoid printing of mask
        # The mask property comes without dedicated suffix and would overwrite/be
        # overwritten by the remaining properties of the structure. Instead, the field
        # width is printed.
        self.printer.pr_field_mask = self.printer.pr_field_width

        # Avoid printing of properties on nodes that are not leaves (i.e., fields)
        self.printer.pr_size = lambda *args: None
        self.printer.pr_version = lambda *args: None
        self.printer.pr_ident = lambda *args: None

    def pr_address(self, n):
        # Avoid printing of properties on nodes that are not leaves (i.e., fields)
        pass

    def pr_address_mask(self, n):
        # Avoid printing of properties on nodes that are not leaves (i.e., fields)
        pass

    def pr_size(self, n, sz):
        # Avoid printing of properties on nodes that are not leaves (i.e., fields)
        pass


@StructVisitor.register(tree.RepeatBlock)
def pstruct_repeatblock(pr, n):
    # Avoid adding any elements (such as address) to list-like substructure
    pconsts_composite_children(pr, n)


def pconsts_cheby(fd, root, style):
    form = "consts"
    if style.endswith("-struct"):
        form = "struct"
        style = style[:-7]

    cls_style = {
        'h': ConstsPrinterH,
        'matlab': ConstsPrinterMatlab,
        'python': ConstsPrinterPython,
        'sv': ConstsPrinterSystemVerilog,
        'tcl': ConstsPrinterTCL,
        'verilog': ConstsPrinterVerilog,
        'vhdl': ConstsPrinterVHDL,
        'vhdl-ohwr': ConstsPrinterVHDLOhwr,
        'vhdl-orig': ConstsPrinterVHDL,
    }
    cls_form = {
        'consts': ConstsVisitor,
        'struct': StructVisitor
    }

    pr = cls_form[form](cls_style[style](fd, root))

    pr.pr_header()
    pr.visit(root)
    pr.pr_trailer()
