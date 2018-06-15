"""Expand registers: create registers for FIFOs"""
import cheby.wbgen.tree as tree
import cheby.wbgen.layout as layout


irq_regs = [
    ('disable', 'idr', 'WO_RO', 'WRITE_ONLY',
     'Writing 1 disables handling of the interrupt associated with'
     ' corresponding bit. Writin 0 has no effect.',
     "write 1: disable interrupt '{name}'\nwrite 0: no effect"),
    ('enable', 'ier', 'WO_RO', 'WRITE_ONLY',
     'Writing 1 enables handling of the interrupt associated with'
     ' corresponding bit. Writin 0 has no effect.',
     "write 1: enable interrupt '{name}'\nwrite 0: no effect"),
    ('mask', 'imr', 'RO_WO', 'READ_ONLY',
     'Shows which interrupts are enabled. 1 means that the interrupt'
     ' associated with the bitfield is enabled',
     "read 1: interrupt '{name}' is enabled\nread 0: interrupt '{name}'"
     " is disabled"),
    ('status', 'isr', 'RW_RW', 'READ_WRITE',
     'Each bit represents the state of corresponding interrupt. 1 means the'
     ' interrupt is pending. Writing 1 to a bit clears the corresponding'
     ' interrupt. Writing 0 has no effect.',
     "read 1: interrupt '{name}' is pending\nread 0: interrupt not pending\n"
     "write 1: clear interrupt '{name}'\nwrite 0: no effect")]


def expand_irq(irqs, periph):
    res = []
    for reg_name, reg_prefix, mode, access_bus, desc, field_desc in irq_regs:
        r = tree.IrqReg()
        r.c_prefix = "EIC_{}".format(reg_prefix.upper())
        r.prefix = "eic_{}".format(reg_prefix)
        r.name = "Interrupt {} register".format(reg_name)
        r.desc = desc
        if reg_name == 'disable':
            r.align = 8  # For compatibility (??)
        res.append(r)
        off = 0
        for irq in irqs:
            f = tree.Field()
            f.prefix = irq.prefix
            f.c_prefix = irq.c_prefix
            f.name = irq.name
            f.typ = 'BIT'
            f.bit_offset = off
            f.bit_len = 1
            f.access = mode
            f.access_bus = access_bus
            f.desc = field_desc.format(name=irq.name)
            r.fields.append(f)
            off += 1
    return res


fifo_fields = [
    ('FIFO_FULL', 'full', 'full flag', 'READ_ONLY',
     "1: FIFO '{name}' is full\n0: FIFO is not full"),
    ('FIFO_EMPTY', 'empty', 'empty flag', 'READ_ONLY',
     "1: FIFO '{name}' is empty\n0: FIFO is not empty"),
    ('FIFO_CLEAR', 'clear_bus', 'clear', 'WRITE_ONLY',
     "write 1: clears FIFO '{name}\nwrite 0: no effect")]


def expand_fifo(n, periph):
    n.regs = []
    # Pack registers
    if n.direction == 'CORE_TO_BUS':
        dir_str = 'output'
        acc = 'RO_WO'
        bus_acc = 'READ_ONLY'
    else:
        dir_str = 'input'
        acc = 'WO_RO'
        bus_acc = 'WRITE_ONLY'
    num = 0
    width = 0
    fields = list(n.fields)  # Copy list.
    while fields:
        # Create a register
        r = tree.FifoReg()
        r.parent = n
        r.num = num
        r.c_prefix = "{}_R{}".format(n.get_c_prefix(), num)
        r.prefix = "{}_r{}".format(n.get_hdl_prefix(), num)
        r.name = "FIFO '{}' data {} register {}".format(n.name, dir_str, num)
        n.regs.append(r)
        num += 1

        # Insert the first field
        f = fields.pop(0)
        assert f.bit_offset % layout.DATA_WIDTH == 0
        off = f.bit_offset
        f.bit_offset = 0
        f.access = acc
        f.access_bus = bus_acc
        f.fifo_offset = width
        width += f.bit_len
        r.fields.append(f)

        # Try to insert more fields
        while fields:
            f = fields[0]
            if f.bit_offset + f.bit_len > off + layout.DATA_WIDTH:
                break
            f.bit_offset -= off
            f.fifo_offset = width
            width += f.bit_len
            r.fields.append(f)
            f.access = acc
            f.access_bus = bus_acc
            del fields[0]
    n.width = width
    # Create CSR
    r = tree.FifoCSReg()
    r.parent = n
    r.c_prefix = "{}_CSR".format(n.get_c_prefix())
    r.prefix = "{}_csr".format(n.get_hdl_prefix())
    r.name = "FIFO '{}' control/status register".format(n.name)
    n.regs.append(r)
    off = 16
    for flag, name, comment, acc_bus, desc in fifo_fields:
        if flag in n.flags_bus:
            f = tree.Field()
            f.name = "FIFO {}".format(comment)
            f.kind = name
            f.c_prefix = name.upper()
            f.prefix = name
            f.bit_offset = off
            f.bit_len = 1
            f.typ = 'BIT'
            f.access_bus = acc_bus
            f.desc = desc.format(name=n.name)
            r.fields.append(f)
        off += 1
    if 'FIFO_COUNT' in n.flags_bus:
        f = tree.Field()
        f.name = "FIFO counter"
        f.kind = "count"
        f.c_prefix = "usedw".upper()
        f.prefix = 'count'
        f.bit_offset = 0
        f.bit_len = n.log2_size
        f.size = f.bit_len
        f.access_bus = 'READ_ONLY'
        f.desc = "Number of data records currently " \
            "being stored in FIFO '{}'".format(n.name)
        r.fields.append(f)


def build_ordered_regs(n):
    """Create ordered list of regs."""
    # Ordered regs: regular regs, interrupt, fifo regs, ram
    res = [r for r in n.regs if (isinstance(r, tree.Reg)
                                 or isinstance(r, tree.Irq)
                                 or isinstance(r, tree.Fifo))]
    res.extend([r for r in n.regs if isinstance(r, tree.IrqReg)])
    res.extend([r for r in n.regs if (isinstance(r, tree.FifoReg)
                                      or isinstance(r, tree.FifoCSReg))])
    res.extend([r for r in n.regs if isinstance(r, tree.Ram)])
    n.ordered_regs = res


def expand(periph):
    """Create regs for irq and fifo."""
    # First gather irqs and create the controller.
    irqs = [r for r in periph.regs if isinstance(r, tree.Irq)]
    if irqs:
        irq_regs = expand_irq(irqs, periph)
        periph.regs.extend(irq_regs)

    # Then expand fifos
    for fifo in periph.regs:
        if isinstance(fifo, tree.Fifo):
            expand_fifo(fifo, periph)
            periph.regs.extend(fifo.regs)
    build_ordered_regs(periph)
