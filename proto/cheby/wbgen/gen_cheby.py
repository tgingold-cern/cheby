import cheby.wbgen.tree as wbtree
import cheby.wbgen.layout as layout
import cheby.tree as tree
from cheby.schemas_version import VERSIONS

def write_field_content(res, n, parent):
    if n.reset_value is not None:
        res.preset = n.reset_value
    elif n.value is not None:
        # Use preset to store CONSTANT value
        res.preset = n.value
    if not hasattr(res, 'x_wbgen'):
        res.x_wbgen = {}
    res.x_wbgen["type"] = n.typ
    if isinstance(parent, wbtree.FifoCSReg):
        res.x_wbgen["kind"] = n.kind
    elif not isinstance(parent, wbtree.AnyFifoReg):
        res.x_wbgen["access_bus"] = n.access_bus
        res.x_wbgen["access_dev"] = n.access_dev
    res.x_wbgen["clock"] = n.clock
    res.x_wbgen["load"] = n.load
    res.x_wbgen["ack_read"] = n.ack_read
    if n.size is not None and n.size == 1:
        # Explicit the size (range is a single value, so there is no
        # difference with no size)
        res.x_wbgen["size"] = 1
    if n.prefix is None:
        res.x_wbgen["field_description"] = n.name
        res.x_wbgen["field_comment"] = n.desc
    if n.typ == 'PASS_THROUGH':
        if not hasattr(res, 'x_hdl'):
            res.x_hdl = {}
        res.x_hdl["type"] = "wire"

def write_field(n, parent):
    res = tree.Field(parent)
    # In wbgen, prefix is optionnal if there is only one child.
    if n.prefix is not None:
        name = n.prefix
    else:
        name = 'value'  # parent.prefix
    res.name = name
    if n.bit_len != 1:
        res.hi = n.bit_offset + n.bit_len - 1
        res.lo = n.bit_offset
    else:
        res.lo = n.bit_offset
    res.description = n.name
    res.comment = n.desc
    write_field_content(res, n, parent)
    return res

def write_reg(parent, n, addr_off):
    # Compute access mode
    acc = "--"
    accmap = {'--': {'READ_ONLY': 'ro',
                     'WRITE_ONLY': 'wo',
                     'READ_WRITE': 'rw'},
              'ro': {'READ_ONLY': 'ro',
                     'WRITE_ONLY': 'rw',
                     'READ_WRITE': 'rw'},
              'wo': {'READ_ONLY': 'rw',
                     'WRITE_ONLY': 'wo',
                     'READ_WRITE': 'rw'},
              'rw': {'READ_ONLY': 'rw',
                     'WRITE_ONLY': 'rw',
                     'READ_WRITE': 'rw'}}
    for f in n.fields:
        facc = f.access_bus
        if facc is None:
            facc = {'PASS_THROUGH': 'WRITE_ONLY',
                    'MONOSTABLE': 'WRITE_ONLY',
                    'CONSTANT': 'READ_ONLY',
                    'SLV': 'READ_WRITE',
                    'BIT': 'READ_WRITE'}[f.typ]
        acc = accmap[acc][facc]
    res = tree.Reg(parent)
    # write_pre_comment(n.pre_comment)
    res.name = n.prefix
    res.address = (n.addr_base - addr_off) * layout.DATA_BYTES
    res.width = layout.DATA_WIDTH
    res.access = acc
    res.description = n.name
    res.comment = n.desc
    res.x_wbgen = {}
    if isinstance(n, wbtree.FifoCSReg):
        res.x_wbgen["kind"] = "fifocs"
    if len(n.fields) == 1 \
       and n.fields[0].prefix is None \
       and n.fields[0].size == layout.DATA_WIDTH:
        f = n.fields[0]
        if f.desc is not None:
            if n.desc is None:
                res.comment = f.desc
        write_field_content(res, n.fields[0], n)
    else:
        for f in n.fields:
            res.children.append(write_field(f, n))
    wr_strobe = any([f.load == 'LOAD_EXT' or
                     f.typ == 'PASS_THROUGH' for f in n.fields])
    rd_strobe = any([f.ack_read for f in n.fields])
    if wr_strobe or rd_strobe:
        res.x_hdl = {}
        if wr_strobe:
            res.x_hdl["write-strobe"] = True
        if rd_strobe:
            res.x_hdl["read-strobe"] = True
    return res

def write_fifo(parent, n):
    res = tree.Block(parent)
    # self.write_pre_comment(n.pre_comment)
    addr = n.regs[0].addr_base
    res.name = n.prefix
    res.address = addr * layout.DATA_BYTES
    res.size_str = "{}".format(len(n.regs) * layout.DATA_BYTES)
    res.description = n.name
    res.comment = n.desc
    res.align = False

    res.x_wbgen = {}
    res.x_wbgen["kind"] = "fifo"
    res.x_wbgen["direction"] = n.direction
    res.x_wbgen["depth"] = n.size
    res.x_wbgen["clock"] = n.clock
    if 'FIFO_FULL' in n.flags_dev:
        res.x_wbgen["wire_full"] = True
    if 'FIFO_EMPTY' in n.flags_dev:
        res.x_wbgen["wire_empty"] = True
    if 'FIFO_COUNT' in n.flags_dev:
        res.x_wbgen["wire_count"] = True
    res.x_wbgen["optional"] = n.optional
    
    #self.block_addr.append(addr)
    for r in n.regs:
        r.pre_comment = None
        res.children.append(write_reg(res, r, addr))
    #self.block_addr.pop()
    return res

def write_ram(parent, n):
    # self.write_pre_comment(n.pre_comment)
    res = tree.Memory(parent)
    addr = n.addr_base
    res.name = n.prefix
    res.address = addr * layout.DATA_BYTES
    res.memsize_str = "{}".format(n.size * n.width // 8)
    res.description = n.name
    res.comment = n.desc

    res.x_wbgen = {}
    res.x_wbgen["kind"] = 'ram'
    res.x_wbgen["access_dev"] = n.access_dev
    res.x_wbgen["clock"] = n.clock
    res.x_wbgen["byte_select"] = n.byte_select

    r = tree.Reg(res)
    res.children.append(r)
    r.name = 'data'
    r.width = n.width
    accmap = {'READ_ONLY': 'ro', 'WRITE_ONLY': 'wo', 'READ_WRITE': 'rw'}
    r.access = accmap[n.access_bus]
    return res

def write_irqs(parent, regs, irqs):
    # self.write_pre_comment(n.pre_comment)
    addr = regs[0].addr_base
    res = tree.Block(parent)
    res.name = "eic"
    res.address = addr * layout.DATA_BYTES
    res.align = False

    res.x_wbgen = {}
    res.x_wbgen["kind"] = 'irq'
    lst = []
    for irq, pos in irqs:
        e = {}
        e["name"] = irq.prefix
        e["trigger"] = irq.trigger
        e["pos"] = pos
        e["ack_line"] = irq.ack_line
        e["mask_line"] = irq.mask_line
        e["description"] = irq.name
        e["comment"] = irq.desc
        lst.append(e)
    res.x_wbgen["irq"] = lst

    for r in regs:
        r.pre_comment = None
        res.children.append(write_reg(res, r, addr))

    return res

def gen_root(n):
    # TODO: n.pre_comment ?
    res = tree.Root()
    res.bus = 'wb-32-be'
    res.name = n.prefix if n.prefix else n.hdl_prefix
    res.description = n.name
    res.comment = n.desc
    res.schema_version = VERSIONS
    res.x_wbgen = {"hdl_entity": n.hdl_entity,
                   "hdl_prefix": n.hdl_prefix,
                   "c_prefix": n.c_prefix,
                   "version": n.version}
    # Gather irqs
    irqs = []
    irq_regs = []
    pos = 0
    for r in n.regs:
        if isinstance(r, wbtree.IrqReg):
            irq_regs.append(r)
        elif isinstance(r, wbtree.Irq):
            irqs.append((r, pos))
        pos += 1
    # Generate
    for r in n.regs:
        if isinstance(r, wbtree.Reg):
            res.children.append(write_reg(res, r, 0))
        elif isinstance(r, wbtree.Fifo):
            res.children.append(write_fifo(res, r))
        elif isinstance(r, wbtree.Ram):
            res.children.append(write_ram(res, r))
        elif isinstance(r, wbtree.IrqReg):
            pass
        elif isinstance(r, wbtree.FifoReg):
            pass
        elif isinstance(r, wbtree.FifoCSReg):
            pass
        elif isinstance(r, wbtree.Irq):
            pass
        else:
            assert False, "unhandled register {}".format(r)
    # Generate for irqs
    if irqs:
        res.children.append(write_irqs(res, irq_regs, irqs))
    return res

def gen_cheby(root):
    return gen_root(root)
