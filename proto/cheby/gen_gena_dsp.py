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
        self.utypes = {1: 'unsigned char',
                       2: 'unsigned short',
                       4: 'unsigned int',
                       8: None}
        self.stypes = {1: 'int8_t',
                       2: 'int16_t',
                       4: 'int32_t',
                       8: None}
        self.ftypes = {4: 'float',
                       8: 'double'}

    def mp_push(self, name, addr):
        self.prefix_stack.append((self.prefix, self.offset))
        self.prefix = self.prefix + name + '_'
        self.offset += addr

    def mp_pop(self):
        self.prefix, self.offset = self.prefix_stack.pop()

    def mp_raw(self, s):
        self.fd.write(s)

    def mp_txt(self, txt):
        self.mp_raw(txt)
        self.mp_raw('\n')

    def mp_addr(self, n, comment):
        addr = self.addr | ((self.offset + n.c_address) // self.word_size)
        self.mp_txt('#define {:50s} (0x{:08X}){}'.format(self.prefix + n.name, addr, comment))


def mprint_children(mp, n):
    for el in n.c_sorted_children:
        mp.visit(el)


def mprint_field(mp, n, f):
    pfx = n.name + '_' + f.name
    mask = 1 << f.lo
    if f.hi is None:
        comment = 'bit-field-data'
    else:
        comment = 'sub-reg'
        mask = (2 << f.hi) - mask
    mp.mp_txt('#define {:50s} (0x{:08X}) // {}'.format(
        pfx, mask, comment))
    mp.mp_txt('#define {:50s} ({}) // {} shift poZzition'.format(
        pfx + 'ShiftPoz', f.lo, comment))
    mprint_enum(mp, f, pfx)


def mprint_enum(mp, n, pfx):
    enum = n.get_extension('x_enums', 'name', None)
    if enum is None:
        return
    enums = mp.root.c_enums_dict[enum]
    for e in enums.children:
        mp.mp_txt('#define {:50s} {} // code-field'.format(pfx + '_' + e.name, e.value))


@Printer.register(tree.Reg)
def mprint_reg(mp, n):
    #    n.c_address, n.access, n.description or '(no description)'))
    if n.c_type == 'signed':
        typ = mp.stypes[n.c_size]
    elif n.c_type == 'float':
        typ = mp.ftypes[n.c_size]
    else:
        typ = mp.utypes[n.c_size]
    if typ is None:
        mp.mp_txt('//not implemented ctype for {}: bit_encoding = {}, el_width = {}'.format(
            mp.prefix + n.name, 'unsigned', n.c_size * tree.BYTE_SIZE))
    else:
        if get_gena(n, 'rmw', False):
            acc = 'rmw'
        else:
            acc = ACC[n.access]
        mp.mp_addr(n, '// register-data, {}, {}'.format(acc, typ))
    mprint_enum(mp, n, n.name)
    if n.has_fields():
        # Convoluted, but comes from Gena.
        bit_fields = sorted(filter(lambda x: x.hi is None, n.children), key=lambda a: a.lo)
        sub_regs = sorted(filter(lambda x: x.hi is not None, n.children), key=lambda a: '{}-{}'.format(a.hi, a.lo))
        fields = list(bit_fields) + list (sub_regs)
        for f in fields:
            mprint_field(mp, n, f)


@Printer.register(tree.Block)
def mprint_block(mp, n):
    mp.mp_push(n.name, n.c_address)
    mprint_children(mp, n)
    mp.mp_pop()


@Printer.register(tree.Memory)
def mprint_memory(mp, n):
    acc = ACC[n.children[0].access]
    mp.mp_addr(n, '// memory-data, {:3s}, {}'.format(acc, 'unknown type'))


@Printer.register(tree.Repeat)
def mprint_repeat(mp, n):
    mp.mp_txt('/* [0x{:x}]: REPEAT {} */'.format(
        n.c_address, n.description or '(no description)'))
    mprint_children(mp, n)


@Printer.register(tree.Submap)
def mprint_submap(mp, n):
    mp.mp_push(n.name, 0)
    mprint_children(mp, n.c_submap)
    mp.mp_pop()


@Printer.register(tree.CompositeNode)
def mprint_composite(mp, n, pfx):
    mprint_children(mp, n, pfx)


@Printer.register(tree.Root)
def mprint_root(mp, n):
    mprint_children(mp, n)


def gen_gena_dsp_map(fd, root, with_date=True):
    mp = Printer(fd, root)
    if with_date:
        ts = datetime.datetime.now()    
        mp.mp_txt('#define GENERATED_ON (0x{0:08X})  // generation time, format: hex(yyyymmdd)'.format(int(ts.strftime("%Y%m%d"))))
    version = get_gena(root, 'map-version')
    if version is not None:
        mp.mp_txt("#define MEMMAP_VERSION (0x{:08X}) // memory map version, format: hex(yyyymmdd)".format(int(version)))
    mp.mp_txt('')
    mprint_root(mp, root)
