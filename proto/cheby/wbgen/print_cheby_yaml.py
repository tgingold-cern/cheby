import sys
import cheby.wbgen.tree as tree
import cheby.wbgen.layout as layout

# TODO:
#  xml-ize strings (description, name)
#  check identifiers are uniq and valid


class Writer_YAML(object):
    def __init__(self, file=sys.stdout, verbose=True, strict=True):
        self.file = file
        self.verbose = verbose
        self.block_addr = [0]
        self.indent = 0
        self.islist = [False]
        self.strict = strict      # True to keep strings as is.

    def wraw(self, s):
        """Raw write of string s."""
        self.file.write(s)

    def w(self, s):
        """Write s"""
        self.wraw(s)

    def windent(self):
        """Indent to current level."""
        self.w('  ' * self.indent)

    def wtext(self, text):
        """Write random text."""
        self.w(text)

    def wseq(self, name):
        self.windent()
        if self.islist[-1]:
            self.w('- ')
            self.indent += 1
        self.w('{}:\n'.format(name))
        self.indent += 1
        self.islist.append(False)

    def wlist(self, name):
        self.windent()
        self.w('{}:\n'.format(name))
        self.islist.append(True)

    def welist(self):
        """End list."""
        f = self.islist.pop()
        assert f

    def weseq(self):
        """End seq."""
        f = self.islist.pop()
        assert not f
        self.indent -= 1
        if self.islist[-1]:
            self.indent -= 1

    def wattr_yaml(self, name, val):
        self.windent()
        self.w('{}: {}\n'.format(name, val))

    trans = {"'": "''", "\n": r"\n", "\\": r"\\"}

    def quote_str(self, txt):
        if any(c in txt for c in "'[]\n:\\") or txt.startswith('-'):
            return "'" + ''.join([self.trans.get(c, c) for c in txt]) + "'"
        elif txt.lower() in ['on', 'off', 'false', 'true', 'yes', 'no']:
            return "'" + txt + "'"
        else:
            return txt

    def wattr_str(self, name, val):
        """Write attribute (only if not None)."""
        if val is None:
            return
        if isinstance(val, bool):
            self.wattr_yaml(name, "'{}'".format(val))
        else:
            self.wattr_yaml(name, self.quote_str(val))

    def wattr_bool(self, name, val):
        if val is None:
            return
        assert isinstance(val, bool)
        self.wattr_yaml(name, val)

    def wattr_num(self, name, val):
        if val is None:
            return
        self.wattr_yaml(name, "{}".format(val))

    def write_pre_comment(self, str):
        if not str:
            return
        for l in str.split('\n'):
            self.w('# {}\n'.format(l))

    def write_address(self, addr):
        self.wattr_num("address", "0x{:x}".format(
                       (addr - self.block_addr[-1]) * layout.DATA_BYTES))

    def write_comment(self, txt, name='comment'):
        if txt is None:
            return
        self.windent()
        if self.strict:
            self.w('{}: {}\n'.format(name, self.quote_str(txt)))
        else:
            txt = txt.rstrip()
            if any(c in txt for c in "'[]\n:") or txt.startswith('-'):
                self.w('{}: |\n'.format(name))
                self.indent += 1
                for l in txt.split('\n'):
                    self.windent()
                    self.w(l.strip())
                    self.w('\n')
                self.indent -= 1
            else:
                self.w('{}: {}\n'.format(name, txt))

    def write_field_content(self, n, parent):
        if n.reset_value is not None:
            self.wattr_str("preset", "0x{:x}".format(n.reset_value))
        elif n.value is not None:
            # Use preset to store CONSTANT value
            self.wattr_str("preset", "0x{:x}".format(n.value))
        self.wseq("x-wbgen")
        if isinstance(parent, tree.FifoCSReg):
            self.wattr_str("kind", n.kind)
        elif not isinstance(parent, tree.AnyFifoReg):
            self.wattr_str("access_bus", n.access_bus)
            self.wattr_str("access_dev", n.access_dev)
        self.wattr_str("ack_read", n.ack_read)
        self.wattr_str("clock", n.clock)
        if n.prefix is None:
            self.wattr_str("field_description", n.name)
            self.write_comment(n.desc, "field_comment")
        self.wattr_str("load", n.load)
        if n.size is not None and n.size == 1:
            # Explicit the size (range is a single value, so there is no
            # difference with no size)
            self.wattr_num("size", 1)
        self.wattr_str("type", n.typ)
        self.weseq()

        if n.typ == 'PASS_THROUGH':
            self.wseq("x-hdl")
            self.wattr_str("type", "wire")
            self.weseq()

    def write_field(self, n, parent):
        self.wseq("field")
        # In wbgen, prefix is optionnal if there is only one child.
        if n.prefix is not None:
            name = n.prefix
        else:
            name = 'value'  # parent.prefix
        self.wattr_str("name", name)
        self.wattr_str("description", n.name)
        self.write_comment(n.desc)
        if n.bit_len != 1:
            self.wattr_str("range",
                           "{}-{}".format(n.bit_offset + n.bit_len - 1,
                                          n.bit_offset))
        else:
            self.wattr_num("range", n.bit_offset)
        self.write_field_content(n, parent)
        self.weseq()

    def write_reg(self, n):
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
        self.write_pre_comment(n.pre_comment)
        self.wseq("reg")
        self.wattr_str("name", n.prefix)
        self.wattr_str("description", n.name)
        self.write_comment(n.desc)
        self.wattr_num("width", layout.DATA_WIDTH)
        self.wattr_str("access", acc)
        self.write_address(n.addr_base)
        if isinstance(n, tree.FifoCSReg):
            self.wseq("x-wbgen")
            self.wattr_str("kind", "fifocs")
            self.weseq()
        wr_strobe = any([f.load == 'LOAD_EXT' or
                         f.typ == 'PASS_THROUGH' for f in n.fields])
        rd_strobe = any([f.ack_read for f in n.fields])
        if wr_strobe or rd_strobe:
            self.wseq("x-hdl")
            if wr_strobe:
                self.wattr_bool("write-strobe", True)
            if rd_strobe:
                self.wattr_bool("read-strobe", True)
            self.weseq()
        if len(n.fields) == 1 \
           and n.fields[0].prefix is None \
           and n.fields[0].size == layout.DATA_WIDTH:
            f = n.fields[0]
            if f.desc is not None:
                if n.desc is None:
                    self.write_comment(f.desc)
            self.write_field_content(n.fields[0], n)
        else:
            self.wlist("children")
            for f in n.fields:
                self.write_field(f, n)
            self.welist()
        self.weseq()

    def write_fifo(self, n):
        self.write_pre_comment(n.pre_comment)
        addr = n.regs[0].addr_base
        self.wseq("block")
        self.wattr_str("name", n.prefix)
        self.wattr_str("description", n.name)
        self.write_comment(n.desc)
        self.write_address(addr)
        self.wattr_bool("align", False)
        self.wattr_num("size", len(n.regs) * layout.DATA_BYTES)

        self.wseq("x-wbgen")
        self.wattr_str("clock", n.clock)
        self.wattr_num("depth", n.size)
        self.wattr_str("direction", n.direction)
        self.wattr_str("kind", "fifo")
        self.wattr_str("optional", n.optional)
        if 'FIFO_COUNT' in n.flags_dev:
            self.wattr_bool("wire_count", True)
        if 'FIFO_EMPTY' in n.flags_dev:
            self.wattr_bool("wire_empty", True)
        if 'FIFO_FULL' in n.flags_dev:
            self.wattr_bool("wire_full", True)
        self.weseq()

        self.wlist("children")
        self.block_addr.append(addr)
        for r in n.regs:
            r.pre_comment = None
            self.write_reg(r)
        self.block_addr.pop()
        self.welist()
        self.weseq()

    def write_ram(self, n):
        # self.write_pre_comment(n.pre_comment)
        addr = n.addr_base
        self.wseq("memory")
        self.wattr_str("name", n.prefix)
        self.wattr_str("description", n.name)
        self.write_comment(n.desc)
        self.write_address(addr)
        self.wattr_num("memsize", n.size * n.width // 8)

        self.wseq("x-wbgen")
        self.wattr_str("access_dev", n.access_dev)
        self.wattr_bool("byte_select", n.byte_select)
        self.wattr_str("clock", n.clock)
        self.wattr_str("kind", 'ram')
        self.weseq()

        self.wlist("children")
        self.wseq("reg")
        self.wattr_str("name", 'data')
        self.wattr_num("width", n.width)
        accmap = {'READ_ONLY': 'ro', 'WRITE_ONLY': 'wo', 'READ_WRITE': 'rw'}
        self.wattr_str("access", accmap[n.access_bus])
        self.weseq()
        self.welist()
        self.weseq()

    def write_irqs(self, regs, irqs):
        # self.write_pre_comment(n.pre_comment)
        addr = regs[0].addr_base
        self.wseq("block")
        self.wattr_str("name", "eic")
        self.write_address(addr)
        self.wattr_bool("align", False)

        self.wseq("x-wbgen")
        self.wlist("irqs")
        for irq, pos in irqs:
            self.wseq("irq")
            self.wattr_bool("ack_line", irq.ack_line)
            self.write_comment(irq.desc)
            self.wattr_str("description", irq.name)
            self.wattr_bool("mask_line", irq.mask_line)
            self.wattr_str("name", irq.prefix)
            self.wattr_num("pos", pos)
            self.wattr_str("trigger", irq.trigger)
            self.weseq()
        self.welist()
        self.wattr_str("kind", 'irq')
        self.weseq()

        self.wlist("children")
        self.block_addr.append(addr)
        for r in regs:
            r.pre_comment = None
            self.write_reg(r)
        self.block_addr.pop()
        self.welist()
        self.weseq()

    def write_top(self, n):
        self.write_pre_comment(n.pre_comment)
        self.wseq('memory-map')
        self.wattr_str("name", n.prefix if n.prefix else n.hdl_prefix)
        self.wattr_str("description", n.name)
        self.write_comment(n.desc)
        self.wattr_str("bus", 'wb-32-be')
        self.wseq("x-wbgen")
        self.wattr_str("hdl_entity", n.hdl_entity)
        self.wattr_str("hdl_prefix", n.hdl_prefix)
        self.wattr_str("c_prefix", n.c_prefix)
        self.wattr_num("version", n.version)
        self.weseq()
        self.wlist("children")
        # Gather irqs
        irqs = []
        irq_regs = []
        pos = 0
        for r in n.regs:
            if isinstance(r, tree.IrqReg):
                irq_regs.append(r)
            elif isinstance(r, tree.Irq):
                irqs.append((r, pos))
            pos += 1
        # Generate
        for r in n.regs:
            if isinstance(r, tree.Reg):
                self.write_reg(r)
            elif isinstance(r, tree.Fifo):
                self.write_fifo(r)
            elif isinstance(r, tree.Ram):
                self.write_ram(r)
            elif isinstance(r, tree.IrqReg):
                pass
            elif isinstance(r, tree.FifoReg):
                pass
            elif isinstance(r, tree.FifoCSReg):
                pass
            elif isinstance(r, tree.Irq):
                pass
            else:
                assert False, "unhandled register {}".format(r)
        # Generate for irqs
        if irqs:
            self.write_irqs(irq_regs, irqs)
        self.welist()
        self.weseq()


def print_cheby(stream, n, strict=True):
    Writer_YAML(file=stream, strict=strict).write_top(n)
