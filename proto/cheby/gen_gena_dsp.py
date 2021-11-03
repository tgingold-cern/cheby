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
        self.addr = 0x02000000
        self.offset = 0
        self.root = root
        self.word_size = root.c_word_size
        self.prefix = ''
        self.prefix_stack = []
        self.utypes = {1: 'uint8_t',
                       2: 'unsigned short',
                       4: 'unsigned int',
                       8: None}
        self.stypes = {1: 'int8_t',
                       2: 'int16_t',
                       4: 'int32_t',
                       8: 'int64_t'}
        self.ftypes = {4: 'float',
                       8: 'double'}

    def cp_push(self, name, addr):
        self.prefix_stack.append((self.prefix, self.offset))
        self.prefix = self.prefix + name + '_'
        self.offset += addr

    def cp_pop(self):
        self.prefix, self.offset = self.prefix_stack.pop()

    def cp_raw(self, s):
        self.fd.write(s)

    def cp_txt(self, txt):
        self.cp_raw(txt)
        self.cp_raw('\n')

    def cp_addr(self, n, comment):
        addr = self.addr | ((self.offset + n.c_address) // self.word_size)
        self.cp_txt('#define {:50s} (0x{:08X}){}'.format(self.prefix + n.name, addr, comment))


def cprint_children(cp, n):
    for el in n.c_sorted_children:
        cp.visit(el)


def cprint_field(cp, n, f):
    pfx = n.name + '_' + f.name
    mask = 1 << f.lo
    if f.hi is None:
        comment = 'bit-field-data'
    else:
        comment = 'sub-reg'
        mask = (2 << f.hi) - mask
    cp.cp_txt('#define {:50s} (0x{:08X}) // {}'.format(
        pfx, mask, comment))
    cp.cp_txt('#define {:50s} ({}) // {} shift poZzition'.format(
        pfx + 'ShiftPoz', f.lo, comment))
    cprint_enum(cp, f, pfx)


def cprint_enum(cp, n, pfx):
    enum = n.get_extension('x_enums', 'name', None)
    if enum is None:
        return
    enums = cp.root.c_enums_dict[enum]
    for e in enums.children:
        cp.cp_txt('#define {:50s} {} // code-field'.format(pfx + '_' + e.name, e.value))


@Printer.register(tree.Reg)
def cprint_reg(cp, n):
    #    n.c_address, n.access, n.description or '(no description)'))
    if n.c_type == 'signed':
        typ = cp.stypes[n.c_size]
    elif n.c_type == 'float':
        typ = cp.ftypes[n.c_size]
    else:
        typ = cp.utypes[n.c_size]
    if typ is None:
        cp.cp_txt('//not implemented ctype for {}: bit_encoding = {}, el_width = {}'.format(
            cp.prefix + n.name, 'unsigned', n.c_size * tree.BYTE_SIZE))
    else:
        if get_gena(n, 'rmw', False):
            acc = 'rmw'
        else:
            acc = ACC[n.access]
        cp.cp_addr(n, '// register-data, {}, {}'.format(acc, typ))
    cprint_enum(cp, n, n.name)
    if n.has_fields():
        # Convoluted, but comes from Gena.
        bit_fields = sorted(filter(lambda x: x.hi is None, n.children), key=lambda a: a.lo)
        sub_regs = sorted(filter(lambda x: x.hi is not None, n.children), key=lambda a: '{}-{}'.format(a.hi, a.lo))
        fields = list(bit_fields) + list (sub_regs)
        for f in fields:
            cprint_field(cp, n, f)


@Printer.register(tree.Block)
def cprint_block(cp, n):
    cp.cp_push(n.name, n.c_address)
    cprint_children(cp, n)
    cp.cp_pop()


@Printer.register(tree.Memory)
def cprint_memory(cp, n):
    acc = ACC[n.children[0].access]
    cp.cp_addr(n, '// memory-data, {:3s}, {}'.format(acc, 'unknown type'))


@Printer.register(tree.Repeat)
def cprint_repeat(cp, n):
    cp.cp_txt('/* [0x{:x}]: REPEAT {} */'.format(
        n.c_address, n.description or '(no description)'))
    cprint_children(cp, n)


@Printer.register(tree.Submap)
def cprint_submap(cp, n):
    cp.cp_push(n.name, 0)
    cprint_children(cp, n.c_submap)
    cp.cp_pop()


@Printer.register(tree.CompositeNode)
def cprint_composite(cp, n, pfx):
    cprint_children(cp, n, pfx)


@Printer.register(tree.Root)
def cprint_root(cp, n):
    cprint_children(cp, n)


def gen_gena_dsp_map(fd, root):
    cp = Printer(fd, root)
    ts = datetime.datetime.now()
    cp.cp_txt('#define GENERATED_ON (0x{0:08X})  // generation time, format: hex(yyyymmdd)'.format(int(ts.strftime("%Y%m%d"))))
    version = get_gena(root, 'map-version')
    if version is not None:
        cp.cp_txt("#define MEMMAP_VERSION (0x{:08X}) // memory map version, format: hex(yyyymmdd)".format(int(version)))
    cp.cp_txt('')
    cprint_root(cp, root)
