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
                if field.hi is None:
                    h = 0
                else:
                    h = min(field.hi - field.lo, i + j - field.lo)
                l = max(0, i - field.lo)
                length = h - l + 1
                content = field.name or reg.name
                if field.hi is not None:
                    content += "[{}:{}]".format(h, l)
                col = TableCell(content=content, colspan=length, style="field")
                j -= length
            cols.append(col)
        raws.append(cols)
    return raws


class SummaryRaw(object):
    def __init__(self, address, typ, name, node, abs_addr, hdl_name=None):
        self.address = address
        self.typ = typ
        self.name = name
        self.node = node
        self.abs_addr = abs_addr
        self.hdl_name = hdl_name


class MemmapSummary(object):
    def __init__(self, root):
        self.ndigits = (layout.ilog2(root.c_size) + 3) // 4
        self.raws = []
        self.gen_raws(root, '', '', 0, '')

    def gen_raws(self, parent, name_pfx, addr_pfx, addr_base, hdl_pfx):
        "Fill raws (list of SummaryRaw)"
        for n in parent.c_sorted_children:
            # Need to compute address for external submap.
            n_addr = addr_base + n.c_address
            rng = addr_pfx + '0x{:0{w}x}-0x{:0{w}x}'.format(
                n_addr, n_addr + n.c_size - 1, w=self.ndigits)
            name = name_pfx + n.name
            hdl_name = hdl_pfx + n.name if hdl_pfx else n.name
            if isinstance(n, tree.Reg):
                rng = addr_pfx + '0x{:0{w}x}'.format(n_addr, w=self.ndigits)
                self.raws.append(SummaryRaw(rng, 'REG', name, n, n_addr, hdl_name))
            elif isinstance(n, (tree.RepeatBlock, tree.Block, tree.Submap)):
                if isinstance(n, tree.Submap):
                    typ = 'SUBMAP'
                    child = n.c_submap if n.filename is not None else None
                else:
                    iogrp = getattr(n, 'hdl_iogroup', None)
                    typ = 'BLOCK ({})'.format(iogrp) if iogrp else 'BLOCK'
                    child = n
                self.raws.append(SummaryRaw(rng, typ, name, n, n_addr, hdl_name))
                if child is not None:
                    flatten = getattr(n, 'hdl_iogroup_flatten', True)
                    iogrp = getattr(n, 'hdl_iogroup', None)
                    if n.get_extension('x_hdl', 'name-prefix') is False:
                        next_name_pfx = name_pfx
                        next_hdl_pfx = hdl_pfx
                    else:
                        if isinstance(n, tree.RepeatBlock):
                            idx_sep = '.' if getattr(n, 'hdl_repeat_idx_separator', True) else ''
                            next_name_pfx = name + idx_sep
                        else:
                            next_name_pfx = name + '.'
                        next_hdl_pfx = hdl_name + '_'
                    if iogrp and not flatten:
                        next_hdl_pfx = (hdl_pfx if hdl_pfx else '') + iogrp + '.'
                    self.gen_raws(child, next_name_pfx, addr_pfx, n_addr, next_hdl_pfx)
            elif isinstance(n, tree.Memory):
                self.raws.append(SummaryRaw(rng, 'MEMORY', name, n, n_addr, hdl_name))
                self.gen_raws(n, name + '.', addr_pfx + ' +', n_addr, hdl_name + '_')
            elif isinstance(n, tree.Repeat):
                if n.count and n.c_elsize:
                    self.raws.append(SummaryRaw(rng, "REPEAT", name, n, n_addr, hdl_name))
                    for i in range(n.count):
                        self.gen_raws(n, f"{name}.{i}.", addr_pfx,
                                      n_addr + i * n.c_elsize, f"{hdl_name}_{i}_")
            else:
                print(f"MemmapSummary: implementation for tree node of type {type(n)} is missing. Skipping it.")
