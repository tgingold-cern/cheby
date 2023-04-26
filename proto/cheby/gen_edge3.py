import cheby.tree as tree

access_map = {'rw': 'rw', 'ro': 'r', 'wo': 'w'}


def clean_string(desc):
    """Clean a description string so that it is OK for a CSV field"""
    if not desc:
        return desc
    # Keep only the first line
    l = desc.splitlines()[0]
    # Replace comma with spaces
    return str.replace(l, ',', ' ')


class EdgeReg(object):
    def __init__(self, name, reg, offset, depth, mask, desc):
        self.name = name
        self.rwmode = access_map[reg.access]
        self.offset = reg.c_address + offset
        self.dwidth = tree.BYTE_SIZE * reg.c_size
        self.depth = depth
        self.mask = mask
        self.desc = desc or ''

    def write(self, fd, block_name):
        if self.mask is not None:
            mask = "{:>#10x}".format(self.mask)
        else:
            mask = 10 * ' '
        # block_def_name,     type,                    name,   offset, rwmode, dwidth,  depth,       mask, flags, description
        fd.write("{bid:>14}, {type:>8}, {name:>23}, {offset:>#8x}, {rwmode:>6},"
                 "     {dwidth:>2}, {depth:>#6x}, {mask}, {flags:>5}, {desc}\n".format(
                     bid=block_name, type='REG', name=self.name, rwmode=self.rwmode,
                     offset=self.offset, dwidth=self.dwidth,
                     depth=self.depth, mask=mask, flags='', desc=clean_string(self.desc)))


class EncoreBlock(object):
    def __init__(self, block_name, encore):
        self.block_name = block_name
        self.regs = []
        self.encore = encore
        if block_name not in encore.blocks_set:
            encore.blocks.append(self)
            encore.blocks_set.add(block_name)


    def append_reg(self, reg, name, offset, depth=1, desc=None):
        assert isinstance(reg, tree.Reg)
        self.regs.append(EdgeReg(name, reg, offset, depth, None, desc or reg.description))
        if reg.has_fields():
            for f in reg.children:
                if f.hi is None:
                    mask = 1
                else:
                    mask = (2 << (f.hi - f.lo)) - 1
                mask = mask << f.lo
                self.regs.append(EdgeReg(
                    "{}_{}".format(name, f.name), reg, offset, depth, mask, f.description))

    def append_block(self, blk, name, offset, desc):
        self.regs.append(EdgeBlockInst(blk, name, offset, desc))

    def write(self, fd):
        fd.write("block_def_name,     type,                    name,"
                 "   offset, rwmode, dwidth,  depth,       mask, flags, description\n")
        for r in self.regs:
            r.write(fd, self.block_name)


class EdgeBlockInst(object):
    def __init__(self, block, name, offset, desc):
        assert isinstance(block, EncoreBlock)
        self.block = block
        self.name = name
        self.offset = offset
        self.desc = desc

    def write(self, fd, block_name):
        # block_def_name,     type,                    name,   offset, rwmode, dwidth,  depth,       mask, flags, description
        fd.write("{bid:>14}, {type:>8}, {name:>23}, {offset:>#8x}, {rwmode:>6},"
                 "     {dwidth:>2}, {depth:>6}, {mask}, {flags:>5}, {desc}\n".format(
                     bid=block_name, type=self.block.block_name, name=self.name, rwmode='',
                     offset=self.offset, dwidth='',
                     depth='', mask='', flags='', desc=clean_string(self.desc)))


class Encore(object):
    def __init__(self):
        self.blocks_set = set()
        self.blocks = []
        self.top = None

    def write(self, fd):
        # Write all blocks
        for b in self.blocks:
            if b == self.top:
                continue
            b.write(fd)
            fd.write('\n')
        self.top.write(fd)
        fd.write('\n')

        fd.write("block_inst_name, block_def_name, res_def_name,   offset, description\n")
        fd.write("{:>15}, {:>14}, {:>12}, {:>#8x}, {}\n".format(
            self.top.block_name, self.top.block_name, "Registers", 0, "Top level"))


def p_vme_header(fd, root):
    fd.write("module,    bus, version, endian, description\n")
    fd.write("{:<10} {}, {:<8} {},     {}\n".format(
        root.name + ',', "VME", "0.1" + ',', "BE", clean_string(root.description)))
    fd.write("\n")
    fd.write("bar_id, bar_no, addrwidth, dwidth,  size,     "
             "blt_mode, mblt_mode, description\n")
    fd.write("0,      0,      24,        32,      0x{:06x}, "
             "0,        0,         BAR\n".format(root.c_size))
    fd.write("\n")


def process_body(b, n, offset):
    for el in n.children:
        if isinstance(el, tree.Reg):
            b.append_reg(el, el.name, offset)
        elif isinstance(el, tree.Memory):
            b.append_reg(el.children[0], el.name, offset + el.c_address, el.c_depth, el.description)
        elif isinstance(el, tree.Repeat):
            if len(el.children) == 1 and isinstance(el.children[0], tree.Reg):
                b.append_reg(el.children[0], el.name, offset + el.c_address, el.count, el.description)
            else:
                # TODO
                b2 = EncoreBlock(el.name, b.encore)
                process_body(b2, el, 0)
                for i in range(0, el.count):
                    b.instantiate("{}_{}".format(el.name, i), b2, offset + el.c_abs_addr + i * el.c_elsize)
        elif isinstance(el, tree.Block):
            process_body(b, el, offset)
        elif isinstance(el, tree.Submap):
            if el.filename is not None:
                sub_block = EncoreBlock(el.c_submap.name, b.encore)
                b.append_block(sub_block, el.name, offset + el.c_address, el.description)
                process_body(sub_block, el.c_submap, 0)
            else:
                pass
        else:
            raise AssertionError("unhandled element {}".format(type(el)))


def generate_edge3(fd, root):
    e = Encore()
    # Headers are not generated.
    # p_vme_header(fd, root)
    b = EncoreBlock("Top", e)
    e.top = b
    process_body(b, root, 0)

    fd.write("hw_mod_name, hw_lif_name, hw_lif_vers, edge_vers, bus, endian, description\n")
    fd.write("{:<10}, {}, 3.0.1,       3.0, VME,     BE, {}\n".format(
        root.name, root.name, clean_string(root.description)))
    fd.write("\n")

    # TODO: args
    fd.write("res_def_name, type, res_no,"
             "                                                args, description\n")
    fd.write("   Registers,  MEM,      0, ,\n")
    fd.write("\n")

    e.write(fd)
