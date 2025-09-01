import cheby.tree as tree

access_map = {'rw': 'rw', 'ro': 'r', 'wo': 'w'}
endian_map = {'little': 'LE', 'big': 'BE'}


def get_extension(el, name, default=None, required=False):
    """Get the `x-driver-edge` extension for an element"""
    x = el.get_ext_node('x_driver_edge') or {}
    for n in name.split('/'):
        x = x.get(n)
        if x is None:
            if required:
                raise AssertionError('x-driver-edge/{} is required'.format(name))
            else:
                return default
    return x


def clean_string(desc):
    """Clean a description string so that it is OK for a CSV field"""
    if not desc:
        return desc
    # Keep only the first line
    l = desc.splitlines()[0]
    # Replace comma with semicolon
    return str.replace(l, ',', ';')


def clean_args(args, args_list, fmt_list):
    """Clean a dict of args into a space separated key=value list"""
    if args is None:
        return ''
    args_cleaned = []
    for arg, fmt in zip(args_list, fmt_list):
        val = args.get(arg)
        if val is not None:
            args_cleaned.append('{}={}'.format(
                arg.replace('-', '_'),
                fmt(val)
            ))
    return ' '.join(args_cleaned)


class CsvTable(object):
    def __init__(self, *titles):
        self.titles = list(titles)
        self.widths = [len(t) for t in titles]
        self.rows = []
        self.ljustlastcol = True
        self.comment = ""
        self.endnewline = True

    def append(self, **row):
        self.rows.append(dict(**row))

    def count(self):
        return len(self.rows)

    def write(self, fd):
        if self.comment != "":
            fd.write(self.comment)
            fd.write("\n")

        for r in self.rows:
            for i, title in enumerate(self.titles):
                self.widths[i] = max(self.widths[i],
                                     len(str(r.get(title, ''))))

        for title, width in zip(self.titles, self.widths):
            lastcol = title == self.titles[-1]
            if self.ljustlastcol and lastcol:
                fd.write(" {val}".format(val=title))
            else:
                fd.write(" {val:>{width}}".format(val=title, width=width))
            if not lastcol:
                fd.write(",")
        fd.write("\n")

        for r in self.rows:
            for title, width in zip(self.titles, self.widths):
                lastcol = title == self.titles[-1]
                val = r.get(title, '')
                if self.ljustlastcol and lastcol:
                    if val:
                        fd.write(" {val}".format(val=val))
                else:
                    fd.write(" {val:>{width}}".format(val=val, width=width))
                if not lastcol:
                    fd.write(",")
            fd.write("\n")

        if self.endnewline:
            fd.write("\n")

    def write_if_needed(self, fd):
        if self.count != 0:
            self.write(fd)


class DocInfoTable4(CsvTable):
    def __init__(self):
        super().__init__("drv_type", "edge_vers")
        self.comment = "#Document Info table definition"
        self.ljustlastcol = False


class LifTable(CsvTable):
    def __init__(self):
        super().__init__("hw_mod_name", "hw_lif_name", "hw_lif_vers", "edge_vers",
                         "bus", "endian", "description")
        self.comment = "#LIF (Logical Interface) table definition"


class LifTable4(CsvTable):
    def __init__(self):
        super().__init__("hw_mod_name", "hw_lif_name", "hw_lif_vers",
                         "bus", "endian", "description")
        self.comment = "#LIF (Logical Interface) table definition"


class ResourceTable(CsvTable):
    def __init__(self):
        super().__init__("res_def_name", "type", "res_no", "args", "description")
        self.comment = "#Resources (Memory(BARs) - DMA - IRQ) table definition"


class ResourceTable4(ResourceTable):
    def __init__(self):
        super().__init__()
        self.comment = "#Resources (MEM - DMA - IRQ) table definition"


class DeviceIdentTable(CsvTable):
    def __init__(self):
        super().__init__("vendor", "device", "args")
        self.comment = "#Device Identification table definition"


class BlockInstTable(CsvTable):
    def __init__(self):
        super().__init__("block_inst_name", "block_def_name", "res_def_name",
                         "offset", "description")
        self.comment = "#Block instances table definition"


class IntcTable(CsvTable):
    def __init__(self):
        super().__init__("intc_name", "type", "reg_name", "block_def_name",
                         "chained_intc_name", "chained_intc_mask", "args",
                         "description")
        self.comment = "#Interrupt Controller (INTC) table definition"


class RolesTable(CsvTable):
    def __init__(self):
        super().__init__("reg_role", "reg_name", "block_def_name", "args")
        self.comment = "#Register Roles table definition"


class EdgeReg(object):
    def __init__(self, reg, block_def_name, name, offset, rwmode, size, depth, mask, flags, desc):
        self.reg = reg

        self.block_def_name = block_def_name
        self.type = 'REG'
        self.name = name
        self.offset = hex(offset)
        self.rwmode = access_map[rwmode]
        self.dwidth = tree.BYTE_SIZE * size
        self.depth = hex(depth)
        self.mask = hex(mask) if mask is not None else ''
        self.flags = flags
        self.description = clean_string(desc) or ''

    def write(self, fd, encore):
        for title, width in zip(encore.block_titles, encore.block_col_widths):
            val = getattr(self, title, '')
            if title == 'description':
                if val:
                    fd.write(" {val}".format(val=val))
            else:
                fd.write(" {val:>{width}},".format(val=val, width=width))
        fd.write("\n")


class EncoreBlock(object):
    def __init__(self, encore, el, block_name='', res_name=''):
        self.el = el
        self.block_name = block_name
        self.regs = []
        self.encore = encore
        self.res_name = res_name
        if block_name not in encore.blocks_set:
            encore.blocks.append(self)
            encore.blocks_set.add(block_name)

    def append_reg(self, reg, name, offset, rwmode, size, depth=1, flags='', desc=None):
        self.regs.append(EdgeReg(reg, self.block_name, name,
                                 offset, rwmode, size, depth, None, flags,
                                 desc or reg.comment))
        try:
            if reg.has_fields():
                for f in reg.children:
                    if not get_extension(f, 'generate', True):
                        continue
                    if f.hi is None:
                        mask = 1
                    else:
                        mask = (2 << (f.hi - f.lo)) - 1
                    mask = mask << f.lo
                    self.regs.append(EdgeReg(reg, self.block_name, "{}_{}".format(name, f.name),
                                             offset, rwmode, size, depth, mask, flags, f.comment))
        except AttributeError:
            pass

    def append_block(self, blk, name, offset, desc):
        self.regs.append(EdgeBlockInst(blk, self.block_name, name, offset, desc))

    def write(self, fd):
        if not self.regs:
            return
        fd.write("#Block table definition\n")
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
        self.description = clean_string(desc) or ''


class Encore(object):
    def __init__(self, root):
        self.root = root
        self.blocks_set = set()
        self.blocks = []
        self.top = EncoreBlock(self, root)
        self.block_titles = ["block_def_name", "type", "name", "offset",
                             "rwmode", "dwidth", "depth", "mask", "flags",
                             "description"]
        self.block_col_widths = [len(t) for t in self.block_titles]

    def write(self, fd):
        if any([not isinstance(c, EdgeBlockInst) for c in self.top.regs]):
            raise AssertionError('only block elements are supported in the root level')

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

        binst_table = BlockInstTable()
        for b in self.top.regs:
            if b.block.regs:
                binst_table.append(block_inst_name=b.name, block_def_name=b.block.block_name,
                                   res_def_name=b.block.res_name, offset=b.offset, description=clean_string(b.description))
        binst_table.write(fd)

        # Deal with roles and interrupt controllers
        intc_table = IntcTable()
        roles_table = RolesTable()

        for b in self.blocks:
            for r in filter(lambda x: type(x) == EdgeReg, b.regs):
                for intc in filter(None, map(lambda x: x.get('interrupt-controller'),
                                             get_extension(r.reg, 'interrupt-controllers', []))):
                    intc_name = intc['name']
                    intc_type = intc['type']

                    if intc_type not in ('INTC_SR', 'INTC_CR'):
                        raise AssertionError("unknown interrupt-controller type {}".format(intc_type))

                    chained = intc.get('chained')
                    if chained is not None:
                        chained_name = chained['name']
                        chained_mask = hex(chained['mask'])
                    else:
                        chained_name = ''
                        chained_mask = ''

                    args = clean_args(intc.get('args'), ('enable-mask', 'ack-mask'), (hex, hex))
                    desc = clean_string(intc.get('description', ''))

                    intc_table.append(intc_name=intc_name, type=intc_type, reg_name=r.name,
                                      block_def_name=r.block_def_name, chained_intc_name=chained_name,
                                      chained_intc_mask=chained_mask, args=args, description=desc)

                if get_extension(r.reg, 'reg-role'):
                    role = get_extension(r.reg, 'reg-role/type', required=True)
                    args = get_extension(r.reg, 'reg-role/args')

                    if role == 'IRQ_V' or role == 'IRQ_L':
                        args_str = ''
                    elif role == 'ASSERT':
                        args_str = clean_args(args, ('min-val', 'max-val'), (hex, hex))
                    else:
                        raise AssertionError("unknown reg-role {}".format(role))

                    roles_table.append(reg_role=role, reg_name=r.name,
                                       block_def_name=r.block_def_name, args=args_str)

        intc_table.write_if_needed(fd)
        roles_table.write_if_needed(fd)


def required_access_mode(n):
    """Calculate the minimum required access mode from all children
      - all 'ro'  => 'ro'
      - all 'wo'  => 'wo'
      - otherwise => 'rw'
    """
    m = []
    for el in n.children:
        if isinstance(el, (tree.Block, tree.Memory)):
            m.append(required_access_mode(el))
        elif isinstance(el, tree.Submap):
            m.append(required_access_mode(el.c_submap))
        else:
            m.append(el.access)
    m = list(set(m))
    if len(m) == 1:
        return m[0]
    else:
        # Must be some combination which requires 'rw'
        return 'rw'


def process_body(b, n, offset, res_name, name_prefix=[], block_prefix=[], name_suffix=[], top=False):
    for el in n.children:
        if not get_extension(el, 'generate', True):
            continue

        el_name_cat = name_prefix + [el.name] + name_suffix
        el_name = '_'.join(el_name_cat)

        el_addr = offset + el.c_address

        if isinstance(el, tree.Reg):
            b.append_reg(el, el_name, el_addr, el.access, el.c_size)

        elif isinstance(el, tree.Memory):
            flags = ''
            if get_extension(el, 'fifo', False):
                flags = 'FIFO'
            r = el.children[0]
            b.append_reg(r, el_name, el_addr, r.access, r.c_size, el.c_depth, flags, el.comment)

        elif isinstance(el, tree.Repeat):
            # TODO: expand should be able to work on any repeat structure but full size can't be easily calculated here
            if len(el.children) == 1 and isinstance(el.children[0], tree.Reg):
                r = el.children[0]
                if not get_extension(el, 'expand', False):
                    b.append_reg(r, el_name, el_addr, r.access, r.c_size, el.count, '', el.comment)
                else:
                    for i in range(0, el.count):
                        b.append_reg(r, "{}_{}".format(el_name, i), el_addr+(i*r.c_size), r.access, r.c_size)
            else:
                b2 = EncoreBlock(b.encore, el, el_name, res_name)
                b.append_block(b2, el_name, el_addr, el.comment)
                for i in range(0, el.count):
                    process_body(b2, el, i*el.c_elsize, res_name, name_suffix=[str(i)])

        elif isinstance(el, (tree.Block, tree.Submap)):
            use_block_prefix = get_extension(el, 'block-prefix', True)

            if isinstance(el, tree.Submap):
                if el.filename is None or not get_extension(el, 'expand', True):
                    word_size = getattr(el, 'c_word_size', b.encore.root.c_word_size)
                    access = 'rw'
                    b.append_reg(el, el_name, el_addr, access, word_size, el.c_size // word_size, '', el.comment)
                    continue

                prefix = []
                name = el.c_submap.name
                node = el.c_submap
                include = el.include
            else:
                if not get_extension(el, 'expand', True):
                    word_size = b.encore.root.c_word_size
                    access = required_access_mode(el)
                    b.append_reg(el, el_name, el_addr, access, word_size, el.c_size // word_size, '', el.comment)
                    continue

                if use_block_prefix and not top:
                    prefix = block_prefix + [n.name]
                    name = '_'.join(prefix + [el.name])
                else:
                    prefix = []
                    name = el.name
                node = el
                include = False

            include = get_extension(el, 'include', include)

            if include:
                process_body(b, node, el_addr, res_name, el_name_cat if use_block_prefix else name_prefix, prefix)
            else:
                b2 = EncoreBlock(b.encore, el, name, res_name)
                b.append_block(b2, el_name, el_addr, el.comment)
                process_body(b2, node, 0, res_name, [], prefix)

        else:
            raise AssertionError("unhandled element {}".format(type(el)))


def vme_addr_space(bus):
    """Bus type to default VME addrspace mapping, as done in reksio"""
    if bus.startswith('cern-be-vme'):
        if bus.endswith('-8') or bus.endswith('-16'):
            return 'A24'
        else:
            return 'A32'
    elif bus.startswith('wb-16'):
        return 'A16'
    else:
        return 'A32'


def generate_edge3(fd, root):
    e = Encore(root)

    # LIF table contents using extensions defined by reksio
    hw_mod_name = get_extension(root, 'module-type', root.name)
    hw_lif_name = get_extension(root, 'board-type', hw_mod_name.lower())
    hw_lif_vers = str(get_extension(root, 'driver-version', '1.0.0')) + \
                  str(get_extension(root, 'driver-version-suffix', ''))
    edge_vers = str(get_extension(root, 'schema-version', '3.0'))
    bus = get_extension(root, 'bus-type', 'VME')
    endian = get_extension(root, 'endianness', 'big' if bus == 'VME' else 'little')
    description = get_extension(root, 'description', root.comment)

    fd.write("#Encore Driver GEnerator version: {}\n\n".format(edge_vers))

    edge_major_vers = int(edge_vers.split('.')[0])

    # Document Info table (new in EDGE4)
    if edge_major_vers >= 4:
        docinfo_table = DocInfoTable4()
        docinfo_table.append(drv_type='DRV', edge_vers=edge_vers)
        docinfo_table.write(fd)

    # LIF table
    lif_table = LifTable4() if edge_major_vers >= 4 else LifTable()
    lif_table.append(hw_mod_name=hw_mod_name, hw_lif_name=hw_lif_name,
                     hw_lif_vers=hw_lif_vers, edge_vers=edge_vers, bus=bus,
                     endian=endian_map[endian], description=clean_string(description))
    lif_table.write(fd)

    # Device identification table, only for non-VME busses
    if bus != 'VME':
        devid_table = DeviceIdentTable()

        if bus == 'PCI':
            args = clean_args({
                'subvendor': get_extension(root, 'device-info/subvendor-id'),
                'subdevice': get_extension(root, 'device-info/subdevice-id'),
            }, ('subvendor', 'subdevice'), (hex, hex))

        elif bus == 'VME64x':
            args = clean_args({
                'revision': get_extension(root, 'device-info/revision-id', required=True),
            }, ('revision',), (hex,))

        elif bus == 'PLATFORM':
            args = ''

        vendor = hex(get_extension(root, 'device-info/vendor-id', required=True))
        device = hex(get_extension(root, 'device-info/device-id', required=True))

        devid_table.append(vendor=vendor, device=device, args=args)
        devid_table.write(fd)

    # Resource table
    # TODO: PLATFORM bus IRQ/DMA resources
    rsrc_table = ResourceTable4() if edge_major_vers >= 4 else ResourceTable()

    for i, el in enumerate(root.children):
        if not isinstance(el, tree.AddressSpace):
            raise AssertionError('there must be an address-space defined')

        num = get_extension(el, 'number', i)

        args = {
            'addrspace': get_extension(el, 'addr-mode', vme_addr_space(root.bus)),
            'dwidth': get_extension(el, 'data-width', root.c_word_size * tree.BYTE_SIZE),
            'size': el.c_size,
            'dma': get_extension(el, 'dma-mode')
        }

        if bus == 'VME':
            args_str = clean_args(args,
                                  ('addrspace', 'dwidth', 'size', 'dma'),
                                  (str, str, hex, str))
        elif bus == 'VME64x':
            args_str = clean_args(args,
                                  ('addrspace', 'dwidth', 'dma'),
                                  (str, str, str))
        else:
            args_str = ''

        rsrc_table.append(res_def_name=el.name, type='MEM', res_no=num,
                          args=args_str, description=clean_string(el.comment))

        process_body(e.top, el, 0, el.name, top=True)

    rsrc_table.write(fd)

    # Write body
    e.write(fd)

    # TODO: extra package table
    # TODO: hardware simulation table
