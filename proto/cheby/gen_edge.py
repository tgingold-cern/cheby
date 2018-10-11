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

    def write(self, fd, block_id):
        if self.mask is not None:
            mask = "0x{:08x}".format(self.mask)
        else:
            mask = 10 * ' '
        fd.write("{bid:>12}, {name:>11}, {rwmode:>6}, 0x{offset:06x},     {dwidth:>2}, {depth:>5}, "
                 "{mask}, {desc}\n".format(
            bid=block_id, name=self.name, rwmode=self.rwmode,
            offset=self.offset, dwidth=self.dwidth,
            depth=self.depth, mask=mask, desc=self.desc))


class EncoreBlock(object):
    def __init__(self, num):
        self.num = num
        self.regs = []

    def append_reg(self, reg, offset):
        assert isinstance(reg, tree.Reg)
        if not reg.has_fields():
            self.regs.append(EdgeReg(reg.name, reg, offset, 1, None, reg.description))
        else:
            for f in reg.children:
                if f.hi is None:
                    mask = 1
                else:
                    mask = (2 << (f.hi - f.lo)) - 1
                mask = mask << f.lo
                self.regs.append(EdgeReg(f.name, reg, offset, 1, mask, f.description))

    def write(self, fd):
        fd.write("block_def_id,        name, rwmode,   offset, dwidth,"
                 " depth,       mask, description\n")
        for r in self.regs:
            r.write(fd, self.num)

class Encore(object):
    def __init__(self):
        self.blocks = []
        self.inst = []
        self.cur_block = EncoreBlock(0)
        self.next_num = 1

    def instantiate(self, blk):
        self.inst.append(blk)

    def write_instances(self, fd):
        fd.write(
            "block_inst_name, block_def_id, bar_id,    offset, description\n")
        num = 0
        for b in self.inst:
            fd.write("blk{}, {}, 0, 0,\n".format(num, b.num))
            num += 1

    def write(self, fd):
        # Append the block being built
        if self.cur_block is not None \
           and self.cur_block.regs:
            self.instantiate(self.cur_block)
            self.blocks.append(self.cur_block)
        # Write all blocks
        for b in self.blocks:
            b.write(fd)
        # self.write_instances(fd)

def p_vme_header(fd, root):
    fd.write("module,    bus, version, endian, description\n")
    fd.write("{:<10} {}, {:<8} {},     {}\n".format(
        root.name +',',
        "VME", "0.1" + ',', "BE", root.description))
    fd.write("\n")
    fd.write("bar_id, bar_no, addrwidth, dwidth,  size,     "
             "blt_mode, mblt_mode, description\n")
    fd.write("0,      0,      24,        32,      0x{:06x}, "
             "0,        0,         BAR\n".format(root.c_size))
    fd.write("\n")

def p_body(e, n, offset):
    for el in n.children:
        if isinstance(el, tree.Reg):
            e.cur_block.append_reg(el, offset)
        elif isinstance(el, tree.Array) \
            and len(el.children) == 1 \
            and isinstance(el.children[0], tree.Reg) \
            and (el.align is None or el.align):
            # A regular memory
            e.cur_block.append_reg(el.children[0], offset)
        elif isinstance(el, tree.Block):
            p_body(e, el, offset)
        elif isinstance(el, tree.Submap):
            if el.filename is not None:
                p_body(e, el.c_submap, offset + el.c_abs_addr)
            else:
                pass
        else:
            raise AssertionError("unhandled element {}".format(type(el)))

def generate_edge(fd, root):
    e = Encore()
    # Headers are not generated.
    # p_vme_header(fd, root)
    p_body(e, root, 0)
    e.write(fd)
