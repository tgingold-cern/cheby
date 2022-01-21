"""Print as a C structure."""
import datetime
import cheby.tree as tree
import cheby.print_consts as print_consts


ACC = {'ro': 'r  ', 'wo': 'w  ', 'rw': 'rw '}

def get_gena(n, name, default=None):
    return n.get_extension('x_gena', name, default)

class Printer(tree.Visitor):
    def __init__(self, fd, root):
        self.fd = fd
        self.root = root
        self.offset = 0
        self.prefix = ''
        self.prefix_stack = []

    def pr_push(self, name, addr):
        self.prefix_stack.append((self.prefix, self.offset))
        self.prefix = self.prefix + name + '_'
        self.offset += addr

    def pr_pop(self):
        self.prefix, self.offset = self.prefix_stack.pop()

    def pr_raw(self, s):
        self.fd.write(s)

    def pr_txt(self, txt):
        self.pr_raw(txt)
        self.pr_raw('\n')

    def pr_children(self, n):
        for el in n.c_sorted_children:
            self.visit(el)

    def pr_block(self, n):
        self.pr_push(n.name, n.c_address)
        self.pr_children(n)
        self.pr_pop()

    def pr_submap(self, n):
        self.pr_push(n.name, 0)
        prev_root = self.root
        self.root = n.c_submap
        self.pr_children(n.c_submap)
        self.root = prev_root
        self.pr_pop()


class MPrinter(Printer):
    def __init__(self, fd, root):
        super(MPrinter, self).__init__(fd, root)
        self.addr = 0x02000000
        self.offset = 0
        self.word_size = root.c_word_size

    def mp_addr(self, n, comment):
        addr = self.addr | ((self.offset + n.c_address) // self.word_size)
        self.pr_txt('#define {:50s} (0x{:08X}){}'.format(self.prefix + n.name, addr, comment))


class HPrinter(Printer):
    def __init__(self, fd, root):
        super(HPrinter, self).__init__(fd, root)


class CPrinter(Printer):
    def __init__(self, fd, root):
        super(CPrinter, self).__init__(fd, root)


def mprint_field(mp, n, f):
    pfx = mp.prefix + n.name + '_' + f.name
    mask = 1 << f.lo
    if f.hi is None:
        comment = 'bit-field-data'
    else:
        comment = 'sub-reg'
        mask = (2 << f.hi) - mask
    mp.pr_txt('#define {:50s} (0x{:08X}) // {}'.format(
        pfx, mask, comment))
    mp.pr_txt('#define {:50s} ({}) // {} shift poZzition'.format(
        pfx + 'ShiftPoz', f.lo, comment))
    mprint_enum(mp, f, pfx)


def mprint_enum(mp, n, pfx):
    enum = n.get_extension('x_enums', 'name', None)
    if enum is None:
        return
    enums = mp.root.c_enums_dict[enum]
    for e in enums.children:
        mp.pr_txt('#define {:50s} {} // code-field'.format(pfx + '_' + e.name, e.value))


def hprint_enum(pr, n):
    enum = n.get_extension('x_enums', 'name', None)
    if enum is None:
        return
    for i in range(2):
        pr.pr_txt('// Not implemented yet: no code-field getter')


def get_ctype(n):
    if n.c_type == 'signed':
        typ = {1: 'int8_t',
               2: 'int16_t',
               4: 'int32_t',
               8: None}[n.c_size]
    elif n.c_type == 'float':
        typ = {4: 'float',
               8: 'double'}[n.c_size]
    else:
        typ = {1: 'unsigned char',
               2: 'unsigned short',
               4: 'unsigned int',
               8: None}[n.c_size]
    return typ


def get_ordered_fields(n):
    if n.has_fields():
        # Convoluted, but comes from Gena.
        bit_fields = sorted(filter(lambda x: x.hi is None, n.children), key=lambda a: a.lo)
        sub_regs = sorted(filter(lambda x: x.hi is not None, n.children), key=lambda a: '{}-{}'.format(a.hi, a.lo))
        return list(bit_fields) + list (sub_regs)
    else:
        return []


def hprint_prototype(pr, n, typ, name):
    pr.pr_txt('{} get_{}(void);'.format(typ, name))
    if not get_gena(n, 'rmw', False) and n.access != 'ro':
        pr.pr_txt('void set_{}({} val);'.format(name, typ))
    else:
        pr.pr_txt('// read-only: {}'.format(name))
    pr.pr_txt('')


def hprint_field(pr, n, f):
    hprint_prototype(pr, n, 'unsigned int', n.name + '_' + f.name)
    hprint_enum(pr, f)


def cprint_field(pr, n, f):
    typ = 'unsigned int'
    name = n.name + '_' + f.name
    pr.pr_txt('{} get_{}() {{'.format(typ, name))  # TODO: Use (void)
    pr.pr_txt('\t{}* preg = ({}*){};'.format(typ, typ, n.name))
    pr.pr_txt('\t{} b_lsb = {};'.format(typ, f.lo))
    pr.pr_txt('\t{} bval = ( (*preg & {}) >> b_lsb );'.format(typ, name))
    pr.pr_txt('\treturn bval;')
    pr.pr_txt('}')
    if not get_gena(n, 'rmw', False) and n.access != 'ro':
        pr.pr_txt('void set_{}({} bval) {{'.format(name, typ))
        pr.pr_txt('\t{}* preg = ({}*){};'.format(typ, typ, n.name))
        pr.pr_txt('\t{} oldval = *preg;'.format(typ))
        pr.pr_txt('\t{} b_lsb = {};'.format(typ, f.lo))
        pr.pr_txt('\t{} newval = (oldval & ~{}) | (bval << b_lsb);'.format(typ, name))
        pr.pr_txt('\t*preg = newval;')
        pr.pr_txt('}')
    else:
        pr.pr_txt('// read-only: {}'.format(name))
    pr.pr_txt('')
    hprint_enum(pr, f)


@MPrinter.register(tree.Reg)
def mprint_reg(mp, n):
    typ = get_ctype(n)
    if typ is None:
        mp.pr_txt('//not implemented ctype for {}: bit_encoding = {}, el_width = {}'.format(
            mp.prefix + n.name, 'unsigned', n.c_size * tree.BYTE_SIZE))
    else:
        if get_gena(n, 'rmw', False):
            acc = 'rmw'
        else:
            acc = ACC[n.access]
        mp.mp_addr(n, '// register-data, {}, {}'.format(acc, typ))
    mprint_enum(mp, n, mp.prefix + n.name)
    for f in get_ordered_fields(n):
        mprint_field(mp, n, f)


@HPrinter.register(tree.Reg)
def hprint_reg(pr, n):
    typ = get_ctype(n)
    name = pr.prefix + n.name
    if typ is None:
        pr.pr_txt('//not implemented ctype for {}: bit_encoding = {}, el_width = {}'.format(
            name, 'unsigned', n.c_size * tree.BYTE_SIZE))
    else:
        hprint_prototype(pr, n, typ, name)
    hprint_enum(pr, n)
    for f in get_ordered_fields(n):
        hprint_field(pr, n, f)


@CPrinter.register(tree.Reg)
def cprint_reg(pr, n):
    typ = get_ctype(n)
    name = pr.prefix + n.name
    if typ is None:
        pr.pr_txt('//not implemented ctype for {}: bit_encoding = {}, el_width = {}'.format(
            name, 'unsigned', n.c_size * tree.BYTE_SIZE))
    else:
        pr.pr_txt('{} get_{}() {{'.format(typ, name))  # TODO: Use (void)
        pr.pr_txt('\t{}* preg = ({}*){};'.format(typ, typ, name))
        pr.pr_txt('\treturn ({}) *preg;'.format(typ))   # TODO: useless cast
        pr.pr_txt('}')
        if not get_gena(n, 'rmw', False) and n.access != 'ro':
            pr.pr_txt('void set_{}({} val) {{'.format(name, typ))
            pr.pr_txt('\t{}* preg = ({}*){};'.format(typ, typ, name))
            pr.pr_txt('\t*preg = val;')
            pr.pr_txt('}')
        else:
            pr.pr_txt('// read-only: {}'.format(name))
        pr.pr_txt('')
    hprint_enum(pr, n)
    for f in get_ordered_fields(n):
        cprint_field(pr, n, f)


@Printer.register(tree.Block)
def print_block(pr, n):
    pr.pr_block(n)


@MPrinter.register(tree.Memory)
def mprint_memory(mp, n):
    acc = ACC[n.children[0].access]
    mp.mp_addr(n, '// memory-data, {:3s}, {}'.format(acc, 'unknown type'))


@HPrinter.register(tree.Memory)
def hprint_memory(pr, n):
    for c in ('g', 's'):
        pr.pr_txt('//not_implemented: {}etter of a memory-data element'.format(c))


@CPrinter.register(tree.Memory)
def cprint_memory(pr, n):
    for c in ('g', 's'):
        pr.pr_txt('//not_implemented: {}etter of a memory-data element'.format(c))


@Printer.register(tree.Submap)
def print_submap(pr, n):
    pr.pr_submap(n)


def gen_gena_dsp_map(fd, root, with_date=True):
    mp = MPrinter(fd, root)
    if with_date:
        ts = datetime.datetime.now()
        mp.pr_txt('#define GENERATED_ON (0x{0:08X})  // generation time, format: hex(yyyymmdd)'.format(int(ts.strftime("%Y%m%d"))))
    version = get_gena(root, 'map-version')
    if version is not None:
        mp.pr_txt("#define MEMMAP_VERSION (0x{:08X}) // memory map version, format: hex(yyyymmdd)".format(int(version)))
    mp.pr_txt('')
    mp.pr_children(root)


def gen_gena_dsp_h(fd, root):
    pr = HPrinter(fd, root)
    pr.pr_children(root)


def gen_gena_dsp_c(fd, root):
    pr = CPrinter(fd, root)
    # TODO: also include .h file
    pr.pr_txt('#include "include\\MemMapDSP_{}.h"'.format(root.name))
    pr.pr_txt('')
    pr.pr_children(root)
