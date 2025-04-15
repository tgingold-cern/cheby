import cheby.tree as tree


def pr_memsize(val):
    if val % 1024 == 0:
        val //= 1024
        if val % 1024 == 0:
            val //= 1024
            return "{}M".format(val)
        return "{}K".format(val)
    return "{}".format(val)

class SimplePrinter(tree.Visitor):
    def __init__(self, fd, with_fields, with_info):
        self.fd = fd
        self.indent = 0
        self.base_addr = 0
        self.with_fields = with_fields
        self.with_info = with_info

    def sp_raw(self, s):
        self.fd.write(s)

    def inc(self):
        self.indent += 1

    def dec(self):
        self.indent -= 1

    def sp_name(self, kind, n):
        self.sp_raw('0x{:08x}-0x{:08x}: '.format(
            self.base_addr + n.c_address,
            self.base_addr + n.c_address + n.c_size - 1))
        self.sp_raw('{}{}: {}'.format('  ' * self.indent, kind, n.name))
        if self.with_info:
            self.sp_raw(' ({})'.format(n.c_name))
        self.sp_raw('\n')

    def sp_info(self, info):
        self.sp_raw('                       {}{}\n'.format(
            '  ' * self.indent, info))

    def sp_field(self, f):
        if f.hi is None:
            self.sp_raw('  {:02}:   '.format(f.lo))
        else:
            self.sp_raw('  {:02}-{:02}:'.format(f.lo, f.hi))
        name = f.name
        if name is None:
            assert isinstance(f, tree.FieldReg)
            name = f.parent.name
        self.sp_raw(' {}\n'.format(name))


@SimplePrinter.register(tree.Reg)
def sprint_reg(sp, n):
    sp.sp_name('reg', n)
    if sp.with_info:
        sp.sp_info('[al: {}, sz: {}, addr: {:08x}, abs_addr: {:08x}]'.format(
            pr_memsize(n.c_align), pr_memsize(n.c_size), n.c_address, sp.base_addr + n.c_address))
    if sp.with_fields:
        for f in n.children:
            sp.sp_field(f)

def sprint_block_children(sp, n):
    old_base = sp.base_addr
    sp.base_addr += n.c_address
    sprint_composite(sp, n)
    sp.base_addr = old_base


@SimplePrinter.register(tree.Block)
def sprint_block(sp, n):
    sp.sp_name('block', n)
    sprint_block_children(sp, n)


@SimplePrinter.register(tree.RepeatBlock)
def sprint_repeatblock(sp, n):
    sp.sp_name('repeat-block', n)
    sprint_block_children(sp, n)


@SimplePrinter.register(tree.Submap)
def sprint_submap(sp, n):
    sp.sp_name('submap', n)
    old_base = sp.base_addr
    sp.base_addr += n.c_address
    if n.filename is not None:
        sprint_composite(sp, n.c_submap)
    sp.base_addr = old_base


def sprint_composite_with_base_0(sp, n):
    old_base = sp.base_addr
    sp.base_addr = 0
    sprint_composite(sp, n)
    sp.base_addr = old_base


@SimplePrinter.register(tree.Memory)
def sprint_memory(sp, n):
    sp.sp_name('memory[{}] of {}'.format(n.c_depth, n.c_elsize), n)
    sprint_composite_with_base_0(sp, n)


@SimplePrinter.register(tree.Repeat)
def sprint_repeat(sp, n):
    sp.sp_name('repeat[{}] of {}'.format(n.count, n.c_elsize), n)
    sprint_composite_with_base_0(sp, n)


@SimplePrinter.register(tree.CompositeNode)
def sprint_composite(sp, n):
    sp.sp_info("[al: {}, sz: {}]".format(pr_memsize(n.c_align), pr_memsize(n.c_size)))
    sp.inc()
    for el in n.c_sorted_children:
        sp.visit(el)
    sp.dec()


@SimplePrinter.register(tree.AddressSpace)
def sprint_address_space(sp, n):
    sp.sp_name('address space', n)
    if sp.with_info:
        sp.sp_info('[word_bits: {}, addr_word_bits: {}, addr_bits: {}]'.format(
            n.c_word_bits, n.c_addr_word_bits, n.c_addr_bits))
    sprint_composite(sp, n)


@SimplePrinter.register(tree.Root)
def sprint_root(sp, n):
    if n.c_address_spaces_map is None:
        sp.sp_name('root', n)
        if sp.with_info:
            sp.sp_info('[word_bits: {}, addr_word_bits: {}, addr_bits: {}]'.format(
                n.c_word_bits, n.c_addr_word_bits, n.c_addr_bits))
        sprint_composite(sp, n)
    else:
        for el in n.children:
            sp.visit(el)



def sprint_cheby(fd, root, with_fields=True, with_verbose=False):
    sp = SimplePrinter(fd, with_fields, with_verbose)
    sp.visit(root)
