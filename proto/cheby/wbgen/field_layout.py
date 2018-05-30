"""Layout a peripheral: set addresses and bits."""
import tree

DATA_WIDTH = 32
DATA_BYTES = DATA_WIDTH // 8


def ilog2(val):
    "Return n such as 2**n >= val and 2**(n-1) < val"
    assert val > 0
    v = 1
    for n in range(32):
        if v >= val:
            return n
        v *= 2


class LayoutError(Exception):
    pass


class FieldLayout(tree.Visitor):
    def __init__(self):
        self.bit = 0    # bit number for the next field

    def align_bit(self, algn):
        if self.bit == 0:
            self.bit = algn
            return
        diff = self.bit % algn
        if diff != 0:
            self.bit += algn - diff


@FieldLayout.register(tree.Peripheral)
def layout_periph(v, n):
    for r in n.regs:
        v.visit(r)


@FieldLayout.register(tree.Reg)
def layout_reg(v, n):
    v.bit = 0

    # Layout fields
    for f in n.fields:
        layout_field(v, f, True)
        assert v.bit <= DATA_WIDTH


@FieldLayout.register(tree.Fifo)
def layout_fifo(v, n):
    v.bit = 0
    n.log2_size = ilog2(n.size)

    for f in n.fields:
        layout_field(v, f, False)


@FieldLayout.register(tree.Irq)
def layout_irq(v, n):
    pass


@FieldLayout.register(tree.Ram)
def layout_ram(v, n):
    n.addr_bits = ilog2(n.size)


def compute_access(field):
    """Compute the abbreviated access from access_bus and access_dev"""
    bus_acc = field.access_bus
    dev_acc = field.access_dev
    abbrev = {'READ_WRITE': 'RW', 'READ_ONLY': 'RO', 'WRITE_ONLY': 'WO'}
    if bus_acc is None:
        bus_acc = {'PASS_THROUGH': 'WO', 'MONOSTABLE': 'WO',
                   'CONSTANT': 'RO'}.get(field.typ, 'RW')
    else:
        bus_acc = abbrev.get(bus_acc)
    if dev_acc is None:
        dev_acc = {'CONSTANT': 'WO'}.get(field.typ, 'RO')
    else:
        dev_acc = abbrev.get(dev_acc)
    field.access = '{}_{}'.format(bus_acc, dev_acc)
    if field.access not in ['RO_WO', 'WO_RO', 'RW_RW', 'RW_RO']:
        raise LayoutError("incorrect access {} for '{}'".format(
                          field.access, field.name))


def layout_field(v, n, one_word):
    # Align
    #  print 'Field: {}, align={}, bit={}'.format(n.name, n.align, v.bit)
    if n.align:
        v.align_bit(n.align)
    if n.range is not None:
        lo, hi = n.range
        n.bit_len = ilog2(max(abs(lo), abs(hi)))
        if lo < 0:
            n.bit_len += 1
    elif n.size is None:
        n.bit_len = 1
    else:
        assert n.size > 0
        n.bit_len = n.size
    # FIFO can span multiple I/O registers
    if (v.bit % DATA_WIDTH) + n.bit_len > DATA_WIDTH:
        # Never cross a word, realign.
        v.align_bit(DATA_WIDTH)
    n.bit_offset = v.bit
    v.bit += n.bit_len
    # Define access from user declarations.
    compute_access(n)


def field_layout(n):
    """Do field layout of Peripheral n."""
    FieldLayout().visit(n)
