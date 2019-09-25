import cheby.tree as tree

access_map = {'rw': 'rw', 'ro': 'r', 'wo': 'w'}


class EdgeReg(object):
    def __init__(self, name, reg, offset, depth, mask, desc):
        self.name = name
        self.rwmode = access_map[reg.access]
        self.offset = reg.c_abs_addr + offset
        self.dwidth = tree.BYTE_SIZE * reg.c_size
        self.depth = depth
        self.mask = mask
        self.desc = desc or ''

    def write(self, fd, block_name):
        if self.mask is not None:
            mask = "0x{:08x}".format(self.mask)
        else:
            mask = 10 * ' '
        fd.write("{bid:>14}, {name:>11}, {rwmode:>6}, 0x{offset:06x},"
                 "     {dwidth:>2}, 0x{depth:<5x}, {mask}, 0, {desc}\n".format(
                     bid=block_name, name=self.name, rwmode=self.rwmode,
                     offset=self.offset, dwidth=self.dwidth,
                     depth=self.depth, mask=mask, desc=self.desc))


class EncoreBlock(object):
    def __init__(self, block_name):
        self.block_name = block_name
        self.regs = []

    def append_reg(self, reg, offset):
        assert isinstance(reg, tree.Reg)
        if not reg.has_fields():
            self.regs.append(EdgeReg(
                reg.name, reg, offset, 1, None, reg.description))
        else:
            for f in reg.children:
                if f.hi is None:
                    mask = 1
                else:
                    mask = (2 << (f.hi - f.lo)) - 1
                mask = mask << f.lo
                self.regs.append(EdgeReg(
                    "{}_{}".format(reg.name, f.name), reg, offset, 1, mask, f.description))

    def write(self, fd):
        fd.write("block_def_name,    reg_name, rwmode,   offset, dwidth,"
                 " depth,       mask, flags, description\n")
        for r in self.regs:
            r.write(fd, self.block_name)


class Encore(object):
    def __init__(self):
        self.blocks = []
        self.inst = []

    def instantiate(self, name, blk, off):
        self.inst.append((name, blk, off))

    def write_instances(self, fd):
        fd.write(
            "block_inst_name, block_def_name, bar_def_name,    offset, description\n")
        for name, blk, off in self.inst:
            fd.write("{}, {}, bar0, 0x{:08x},\n".format(name, blk.block_name, off))

    def write(self, fd):
        # Write all blocks
        s = []
        for _, b, _ in self.inst:
            if b not in s:
                b.write(fd)
                fd.write('\n')
                s.append(b)
        self.write_instances(fd)


def p_vme_header(fd, root):
    fd.write("module,    bus, version, endian, description\n")
    fd.write("{:<10} {}, {:<8} {},     {}\n".format(
        root.name + ',', "VME", "0.1" + ',', "BE", root.description))
    fd.write("\n")
    fd.write("bar_id, bar_no, addrwidth, dwidth,  size,     "
             "blt_mode, mblt_mode, description\n")
    fd.write("0,      0,      24,        32,      0x{:06x}, "
             "0,        0,         BAR\n".format(root.c_size))
    fd.write("\n")


def p_body(e, b, n, offset):
    for el in n.children:
        if isinstance(el, tree.Reg):
            b.append_reg(el, offset)
        elif isinstance(el, tree.Array):
            if len(el.children) == 1 \
               and isinstance(el.children[0], tree.Reg) \
               and (el.align is None or el.align):
                # A regular memory
                b.append_reg(el.children[0], offset)
            else:
                b2 = EncoreBlock(el.name)
                p_body(e, b2, el, 0)
                for i in range(0, el.repeat_val):
                    e.instantiate("{}_{}".format(el.name, i), b2, offset + el.c_abs_addr + i * el.c_elsize)
        elif isinstance(el, tree.Block):
            p_body(e, b, el, offset)
        elif isinstance(el, tree.Submap):
            if el.filename is not None:
                p_body(e, b, el.c_submap, offset + el.c_abs_addr)
            else:
                pass
        else:
            raise AssertionError("unhandled element {}".format(type(el)))


def generate_edge(fd, root):
    e = Encore()
    # Headers are not generated.
    # p_vme_header(fd, root)
    b = EncoreBlock("sys")
    e.instantiate("sys", b, 0)
    p_body(e, b, root, 0)

    fd.write("hw_mod_name, hw_lif_name, hw_lif_vers, edge_vers, bus, endian, description\n")
    fd.write("{:<10}, {}, dev, 2.0.0, VME, BE, {}\n".format(
        root.name, root.name, root.description))
    fd.write("\n")

    fd.write("bar_def_name, bar_no, addrspace, dwidth, size,    blt_mode, mblt_mode, description\n")
    fd.write("bar0,         0,      A24,       32,     0x10000, 0,        0,       ,\n")
    fd.write("\n")

    e.write(fd)
