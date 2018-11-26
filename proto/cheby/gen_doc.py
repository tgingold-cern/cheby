import cheby.tree as tree
import cheby.layout as layout


class TableCell(object):
    def __init__(self, content, colspan=1, style=None):
        self.content = content
        self.colspan = colspan
        self.style = style


def build_regdescr_table(reg):
    raws = []
    for i in range(reg.c_size * 8 - 8, -1, -8):
        # One line per byte
        cols = []
        for j in range(7, -1, -1):
            cols.append(TableCell(content="{}".format(i + j),
                                  style='bit'))
        raws.append(cols)
        cols = []
        j = 7
        while j >= 0:
            # Find the field corresponding to the bit.
            field = None
            for f in reg.children:
                if (f.hi is not None and f.hi >= i + j >= f.lo) \
                  or (f.hi is None and f.lo == i + j):
                    field = f
                    break
            if field is None:
                col = TableCell(content="-", style="unused")
                j -= 1
            else:
                # Range of the field
                if f.hi is None:
                    h = 0
                else:
                    h = min(f.hi - f.lo, i + j - f.lo)
                l = max(0, i - f.lo)
                length = h - l + 1
                content = f.name or reg.name
                if f.hi is not None:
                    content += "[{}:{}]".format(h, l)
                col = TableCell(content=content, colspan=length, style="field")
                j -= length
            cols.append(col)
        raws.append(cols)
    return raws


class SummaryRaw(object):
    def __init__(self, address, typ, name, node, abs_addr):
        self.address = address
        self.typ = typ
        self.name = name
        self.node = node
        self.abs_addr = abs_addr


class MemmapSummary(object):
    def __init__(self, root):
        self.root = root
        self.ndigits = (layout.ilog2(root.c_size) + 3) // 4
        self.raws = []
        self.gen_raws(root, '', '', 0)

    def gen_raws(self, parent, name_pfx, addr_pfx, addr_base):
        "Fill raws (list of SummaryRaw)"
        for n in parent.c_sorted_children:
            # Need to compute address for external submap.
            n_addr = addr_base + n.c_address
            rng = addr_pfx + '0x{:0{w}x}-0x{:0{w}x}'.format(
                n_addr, n_addr + n.c_size - 1, w=self.ndigits)
            name = name_pfx + n.name
            if isinstance(n, tree.Reg):
                rng = addr_pfx + '0x{:0{w}x}'.format(n_addr, w=self.ndigits)
                self.raws.append(SummaryRaw(rng, 'REG', name, n, n_addr))
            elif isinstance(n, tree.Block):
                self.raws.append(SummaryRaw(rng, 'BLOCK', name, n, n_addr))
                self.gen_raws(n, name + '.', addr_pfx, n_addr)
            elif isinstance(n, tree.Submap):
                self.raws.append(SummaryRaw(rng, 'SUBMAP', name, n, n_addr))
                if n.filename is not None:
                    self.gen_raws(n.c_submap, name + '.', addr_pfx, n_addr)
            elif isinstance(n, tree.Array):
                self.raws.append(SummaryRaw(rng, 'ARRAY', name, n, n_addr))
                self.gen_raws(n, name + '.', addr_pfx + ' +', 0)
            else:
                assert False, "MemmapSummary: unhandled tree node {}".format(n)
