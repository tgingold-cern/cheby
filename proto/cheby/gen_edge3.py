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
    def __init__(self, reg, block_def_name, name, offset, flags, depth, mask, desc):
        assert isinstance(reg, tree.Reg)
        self.reg = reg

        self.block_def_name = block_def_name
        self.type = 'REG'
        self.name = name
        self.offset = hex(reg.c_address + offset)
        self.rwmode = access_map[reg.access]
        self.dwidth = tree.BYTE_SIZE * reg.c_size
        self.depth = hex(depth)
        self.mask = hex(mask) if mask is not None else ''
        self.flags = flags
        self.description = desc or ''

    def write(self, fd, encore):
        for title, width in zip(encore.block_titles, encore.block_col_widths):
            val = getattr(self, title, '')
            if title == 'description':
                fd.write(" {val}".format(val=val))
            else:
                fd.write(" {val:>{width}},".format(val=val, width=width))
        fd.write("\n")


class EncoreBlock(object):
    def __init__(self, block_name, encore):
        self.block_name = block_name
        self.regs = []
        self.encore = encore
        if block_name not in encore.blocks_set:
            encore.blocks.append(self)
            encore.blocks_set.add(block_name)

    def append_reg(self, reg, name, offset, flags='', depth=1, desc=None):
        self.regs.append(EdgeReg(reg, self.block_name, name,
                                 offset, flags, depth, None, desc or reg.description))
        if reg.has_fields():
            if not reg.get_extension('x_driver_edge', 'include-fields', 'True'):
                return
            for f in reg.children:
                if f.hi is None:
                    mask = 1
                else:
                    mask = (2 << (f.hi - f.lo)) - 1
                mask = mask << f.lo
                self.regs.append(EdgeReg(reg, self.block_name, "{}_{}".format(name, f.name),
                                         offset, flags, depth, mask, f.description))

    def append_block(self, blk, name, offset, desc):
        self.regs.append(EdgeBlockInst(blk, self.block_name, name, offset, desc))

    def write(self, fd):
        for title, width in zip(self.encore.block_titles, self.encore.block_col_widths):
            if title == 'description':
                fd.write(" {val}".format(val=title))
            else:
                fd.write(" {val:>{width}},".format(val=title, width=width))
        fd.write("\n")

        for r in self.regs:
            r.write(fd, self.encore)


class EdgeBlockInst(EdgeReg):
    def __init__(self, block, block_def_name, name, offset, desc):
        assert isinstance(block, EncoreBlock)
        self.block = block

        self.block_def_name = block_def_name
        self.type = self.block.block_name
        self.name = name
        self.offset = hex(offset)
        self.description = desc or ''


class Encore(object):
    def __init__(self):
        self.blocks_set = set()
        self.blocks = []
        self.top = None
        self.block_titles = ["block_def_name", "type", "name", "offset",
                             "rwmode", "dwidth", "depth", "mask", "flags",
                             "description"]
        self.block_col_widths = [len(t) for t in self.block_titles]

    def write(self, fd):
        top_needed = any([not isinstance(c, EdgeBlockInst) for c in self.top.regs])

        # Determine maximum width of each column across all blocks
        for b in self.blocks:
            for r in b.regs:
                for i, title in enumerate(self.block_titles):
                    self.block_col_widths[i] = max(self.block_col_widths[i],
                                                   len(str(getattr(r, title, ''))))
        # Write all blocks
        for b in self.blocks:
            if b == self.top:
                continue
            b.write(fd)
            fd.write('\n')
        if top_needed:
            self.top.write(fd)
            fd.write('\n')

        fd.write("block_inst_name, block_def_name, res_def_name,   offset, description\n")
        if top_needed:
            fd.write("{:>15}, {:>14}, {:>12}, {:>8}, {}\n".format(
                self.top.block_name, self.top.block_name, "Registers", 0, "Top level"))
        else:
            for b in self.top.regs:
                fd.write("{:>15}, {:>14}, {:>12}, {:>8}, {}\n".format(
                    b.name, b.block.block_name, "Registers", b.offset, b.description))


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
            flags = ''
            if el.get_extension('x_driver_edge', 'fifo', False):
                flags = 'FIFO'
            b.append_reg(el.children[0], el.name, offset + el.c_address, flags, el.c_depth, el.description)
        elif isinstance(el, tree.Repeat):
            if len(el.children) == 1 and isinstance(el.children[0], tree.Reg):
                b.append_reg(el.children[0], el.name, offset + el.c_address, '', el.count, el.description)
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
