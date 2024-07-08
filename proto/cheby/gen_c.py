"""Print as a C structure."""
import cheby.tree as tree
import cheby.print_consts as print_consts
from operator import attrgetter


class CPrinter(tree.Visitor):
    def __init__(self, style, gen_bit_struct=False):
        self.struct_prefix = ""
        self._reg_struct_buffer = ""
        self._bit_struct_buffer = ""
        self._reg_struct_indent = 0
        self._bit_struct_indent = 0
        self._padding_ids = [0]

        self.submaps = []

        assert style in ["neutral", "arm"]
        self.style = style

        self.gen_bit_struct = gen_bit_struct
        self.utypes = {1: "uint8_t", 2: "uint16_t", 4: "uint32_t", 8: "uint64_t"}
        self.stypes = {1: "int8_t", 2: "int16_t", 4: "int32_t", 8: "int64_t"}
        self.ftypes = {4: "float", 8: "double"}
        self.access = {
            "ro": ["__IM", "volatile const"],
            "rw": ["__IOM", "volatile"],
            "wo": ["__OM", "volatile"],
        }

    @staticmethod
    def has_bit_fields(n):
        return len(n.children) > 1 or n.children[0].name is not None

    def get_type(self, n):
        if self.gen_bit_struct and self.has_bit_fields(n):
            return self.get_bit_union_name(n)
        elif n.c_type == "signed":
            return self.stypes[n.c_size]
        elif n.c_type == "float":
            return self.ftypes[n.c_size]
        else:
            return self.utypes[n.c_size]

    def reg_struct_start(self, n):
        self.reg_struct_txt("struct {}{} {{".format(self.struct_prefix, n.c_name))

        self._reg_struct_indent += 1
        # track padding IDs per struct
        self._padding_ids.append(0)

    def reg_struct_txt(self, txt=""):
        if txt:
            self._reg_struct_buffer += "{}{}".format(
                "  " * self._reg_struct_indent, txt
            )
        self._reg_struct_buffer += "\n"

    def reg_struct_end(self, name=""):
        self._reg_struct_indent -= 1
        self._padding_ids.pop()

        if name:
            name = " {}".format(name)
        self.reg_struct_txt("}}{};".format(name))

    @property
    def reg_struct(self):
        return self._reg_struct_buffer

    @property
    def padding_idx(self):
        # Get current padding index for returning
        padding_idx = self._padding_ids[-1]

        # Increment index counter
        self._padding_ids[-1] += 1

        return padding_idx

    def bit_struct_start(self, n):
        # Start struct definition
        self.bit_struct_txt("typedef struct {")
        self._bit_struct_indent += 1

    def bit_struct_field(self, n, name, width):
        self.bit_struct_txt("{} {}: {};".format(self.utypes[n.c_size], name, width))

    def bit_struct_txt(self, txt=""):
        if txt:
            self._bit_struct_buffer += "{}{}".format(
                "  " * self._bit_struct_indent, txt
            )
        self._bit_struct_buffer += "\n"

    def bit_struct_end(self, n):
        # End struct definition
        self._bit_struct_indent -= 1
        self.bit_struct_txt("}} {};".format(self.get_bit_struct_name(n)))

        # Start and end union definition
        self.bit_struct_txt("\ntypedef union {")
        self._bit_struct_indent += 1
        self.bit_struct_txt("{} v;".format(self.utypes[n.c_size]))
        self.bit_struct_txt("{} s;".format(self.get_bit_struct_name(n)))
        self._bit_struct_indent -= 1
        self.bit_struct_txt("}} {};\n".format(self.get_bit_union_name(n)))

    def get_bit_struct_name(self, n, suffix="_s"):
        return "{}{}{}".format(self.struct_prefix, n.c_name, suffix)

    def get_bit_union_name(self, n):
        return self.get_bit_struct_name(n, "_u")

    @property
    def bit_struct(self):
        return self._bit_struct_buffer


def maybe_pad(cp, diff, addr, pad_target):
    if diff == 0:
        return
    # Pad
    # Note: the 4 is not related to bus size, but to C types.
    if addr % 4 == 0 and diff % 4 == 0:
        sz = 4
    else:
        sz = 1
    cp.reg_struct_txt()
    cp.reg_struct_txt("/* padding to: {} Bytes */".format(pad_target))
    cp.reg_struct_txt(
        "{} __padding_{}[{}];".format(cp.utypes[sz], cp.padding_idx, diff // sz)
    )


def cprint_children(cp, n, size, off):
    "Generate declarations for children of :param n:, and pad to :param size:"
    addr = 0

    for i in range(len(n.c_sorted_children)):
        el = n.c_sorted_children[i]
        diff = el.c_address - addr
        assert diff >= 0
        maybe_pad(cp, diff, addr, el.c_address)
        if i != 0:
            cp.reg_struct_txt()
        cp.visit(el)
        if isinstance(el, tree.Submap) and el.filename is not None:
            # Boxed instance.  There might be a difference of size
            # between the real submap and how much memory is used
            # in this map.
            addr = el.c_address + el.c_submap.c_size
        else:
            if isinstance(el, tree.Repeat):
                # There might be a gap between the size of the repeat block,
                # and the size of the element * count.
                rep_size = el.c_elsize * el.count
                addr = el.c_address + rep_size
                maybe_pad(cp, el.c_size - rep_size, addr, el.c_address)
            elif isinstance(el, tree.Memory):
                # Likewise.
                addr = el.c_address + el.memsize_val
                maybe_pad(cp, el.c_size - el.memsize_val, addr, el.c_address)
            addr = el.c_address + el.c_size
    # Last pad
    maybe_pad(cp, size - addr, addr, off + size)


def comment(n):
    if n.comment:
        return " {}".format(n.comment)
    else:
        return ""


@CPrinter.register(tree.Reg)
def cprint_reg(cp, n):
    # Create union structures for register with bit fields
    if cp.has_bit_fields(n):
        cp.bit_struct_txt(
            "/* [0x{:x}]: REG {} */".format(n.c_address, n.comment or n.name)
        )
        cp.bit_struct_start(n)

        bit_idx = 0
        for n_child in sorted(n.children, key=attrgetter("lo")):
            if bit_idx < n_child.lo:
                # Insert padding
                pad_width = n_child.lo - bit_idx
                cp.bit_struct_field(n, "", pad_width)
                bit_idx += pad_width

            cp.bit_struct_field(n, n_child.name, n_child.c_rwidth)
            bit_idx += n_child.c_rwidth

        if bit_idx < 8 * n.c_size:
            # Insert padding at the end
            cp.bit_struct_field(n, "", 8 * n.c_size - bit_idx)

        cp.bit_struct_end(n)

    # Structure field for register
    cp.reg_struct_txt(
        "/* [0x{:x}]: REG ({}){} */".format(n.c_address, n.access, comment(n))
    )

    typ = cp.get_type(n)
    if cp.style == "arm":
        acc = cp.access[n.access][0]
        cp.reg_struct_txt("{} {} {};".format(acc, typ, n.name))
    else:
        cp.reg_struct_txt("{} {};".format(typ, n.name))


@CPrinter.register(tree.Block)
def cprint_block(cp, n):
    cp.reg_struct_txt("/* [0x{:x}]: BLOCK{} */".format(n.c_address, comment(n)))
    if n.hdl_blk_prefix:
        cp.reg_struct_start(n)
    cprint_children(cp, n, n.c_size, n.c_address)
    if n.hdl_blk_prefix:
        cp.reg_struct_end(n.name)


@CPrinter.register(tree.Memory)
def cprint_memory(cp, n):
    cp.reg_struct_txt("/* [0x{:x}]: MEMORY{} */".format(n.c_address, comment(n)))
    cp.reg_struct_start(n)
    cprint_children(cp, n, n.c_elsize, 0)
    cp.reg_struct_end("{}[{}]".format(n.name, n.memsize_val // n.c_elsize))


@CPrinter.register(tree.Repeat)
def cprint_repeat(cp, n):
    cp.reg_struct_txt("/* [0x{:x}]: REPEAT{} */".format(n.c_address, comment(n)))
    cp.reg_struct_start(n)
    cprint_children(cp, n, n.c_elsize, 0)
    cp.reg_struct_end("{}[{}]".format(n.name, n.count))


@CPrinter.register(tree.Submap)
def cprint_submap(cp, n):
    cp.reg_struct_txt("/* [0x{:x}]: SUBMAP{} */".format(n.c_address, comment(n)))
    if n.filename is None:
        # Should depend on bus size ?
        if n.c_size % 4 == 0:
            sz = 4
        else:
            sz = 1
        cp.reg_struct_txt("{} {}[{}];".format(cp.utypes[sz], n.name, n.c_size // sz))
    else:
        cp.reg_struct_txt("struct {} {};".format(n.c_submap.name, n.name))
        cp.submaps.append(n.c_submap)


@CPrinter.register(tree.CompositeNode)
def cprint_composite(cp, n):
    cprint_children(cp, n, n.c_size, n.c_address)


@CPrinter.register(tree.Root)
def cprint_root(cp, n):
    if n.version:
        cp.reg_struct_txt("/* For {} version: {} */".format(n.name, n.version))
    if n.c_address_spaces_map is None:
        cp.reg_struct_start(n)
        if n.c_prefix_c_struct:
            cp.struct_prefix = n.name + "_"
        cprint_composite(cp, n)
        cp.reg_struct_end()
    else:
        for i, el in enumerate(n.children):
            if i != 0:
                cp.reg_struct_txt()
            cp.struct_prefix = n.name + "_"
            cp.reg_struct_start(el)
            cp.visit(el)
            cp.reg_struct_end()


def to_cmacro(name):
    return "__CHEBY__{}__H__".format(name.upper())


def gen_c_cheby(fd, root, style, gen_bit_struct=False):
    cp = CPrinter(style, gen_bit_struct)

    # Print in a buffer, needed to gather submaps.
    cprint_root(cp, root)

    csym = to_cmacro(root.name)
    fd.write("#ifndef {}\n".format(csym))
    fd.write("#define {}\n\n".format(csym))
    # That would be useful for users, but not correct for kernels.
    # We could add '#ifndef __KERNEL__', but that's only for linux.
    if False:
        fd.write("#include <stdint.h>\n\n")

    # Add the includes for submaps
    submaps = [n.name for n in cp.submaps]
    if submaps:
        fd.write("\n")
        # Ideally we want an ordered set.
        done = set()
        for s in submaps:
            if s not in done:
                done.add(s)
                # Note: we assume the filename is the name of the memmap + h
                fd.write('#include "{}.h"\n'.format(s))

    if cp.style == "arm":
        # Add definition of access macros
        fd.write("\n")
        for m in sorted(cp.access):
            acc = cp.access[m]
            fd.write("#ifndef {}\n".format(acc[0]))
            fd.write("  #define {} {}\n".format(acc[0], acc[1]))
            fd.write("#endif\n")

    #  Consts
    print_consts.pconsts_for_gen_c(fd, root)
    fd.write("\n")

    fd.write("#ifndef __ASSEMBLER__\n")
    if gen_bit_struct and cp.bit_struct:
        fd.write("/* Bit Field Structures */\n")
        fd.write(cp.bit_struct)
        fd.write("/* Register Map Structure */\n")
    fd.write(cp.reg_struct)
    fd.write("#endif /* !__ASSEMBLER__*/\n")
    fd.write("\n")
    fd.write("#endif /* {} */\n".format(csym))
