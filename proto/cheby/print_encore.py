import cheby.tree as tree

class EncoreBlock(object):
    def __init__(self, num):
        self.num = num
        self.regs = []

    def write_field_reg(self, r, f, fd):
        fd.write("{:>12}, {:>10}, {:>6}, 0x{:06x}, {}, {}, , , , , {}\n".format(
            self.num, f.name,
            'rw', r.c_address, 8 * r.c_size, 1, f.description or ''))

    def write_field(self, r, f, fd):
        if f.hi is None:
            mask = 1
        else:
            mask = (2 << (f.hi - f.lo)) - 1
        mask = mask << f.lo
        fd.write("{:>12}, {:>11}, {:>6},  0x{:06x},     {},       {},      , "
                 "0x{:08x}, , , {}\n".format(
            self.num, r.name + '_' + f.name,
            'rw', r.c_address, 8 * r.c_size, 1, mask, f.description or ''))

    def write(self, fd):
        fd.write("block_def_id,        name, rwmode,    offset, dwidth,"
                 "   depth,   role,      mask, min_ref, max_ref, description\n")
        for r in self.regs:
            if not isinstance(r, tree.Reg):
                raise AssertionError
            elif isinstance(r.children[0], tree.FieldReg):
                self.write_field_reg(r, r.children[0], fd)
            else:
                for f in r.children:
                    self.write_field(r, f, fd)
        fd.write('\n')

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
        self.write_instances(fd)

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

def p_body(e, n):
    for el in n.children:
        if isinstance(el, tree.Reg):
            e.cur_block.regs.append(el)
        elif isinstance(el, tree.Array) \
            and len(el.children) == 1 \
            and isinstance(el.children[0], tree.Reg) \
            and (el.align is None or el.align):
            # A regular memory
            e.cur_block.regs.append(el)
        elif isinstance(el, tree.Block) and el.interface is None:
            raise AssertionError
        else:
            raise AssertionError("unhandled element {}".format(type(el)))

def print_encore(fd, root):
    e = Encore()
    p_vme_header(fd, root)
    p_body(e, root)
    e.write(fd)
