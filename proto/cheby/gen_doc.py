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
            n_addr = addr_base + n.c_address
            rng = addr_pfx + '0x{:0{w}x}-0x{:0{w}x}'.format(
                n_addr, n_addr + n.c_size - 1, w=self.ndigits)
            name = name_pfx + n.name
            hdl = (hdl_pfx + n.name) if hdl_pfx else ''
            if isinstance(n, tree.Reg):
                rng = addr_pfx + '0x{:0{w}x}'.format(n_addr, w=self.ndigits)
                self.raws.append(SummaryRaw(
                    rng, 'REG', name, n, n_addr,
                    hdl_name=hdl or None))
            elif isinstance(n, tree.RepeatBlock):
                iogrp = getattr(n, 'hdl_iogroup', None)
                flatten = getattr(n, 'hdl_iogroup_flatten', True)
                indexing = getattr(n, 'hdl_repeat_indexing', False)
                name_idx_sep = getattr(n, 'hdl_repeat_idx_separator', None)
                hdl_idx_sep = getattr(n, 'hdl_repeat_idx_separator', None)
                if name_idx_sep is None:
                    name_idx_sep = '.'
                if hdl_idx_sep is None:
                    hdl_idx_sep = '_'
                if indexing:
                    if iogrp and not flatten:
                        summary_hdl_name = iogrp
                        hdl_repeat_name = '{}{}'.format(hdl_pfx, iogrp)
                        typ = 'REPEAT [0..{}] ({})'.format(
                            len(n.children) - 1, iogrp)
                    else:
                        hdl_repeat_name = hdl or n.name
                        summary_hdl_name = hdl_repeat_name
                        typ = 'REPEAT [0..{}]'.format(len(n.children) - 1)
                    self.raws.append(SummaryRaw(
                        rng, typ, name, n, n_addr,
                        hdl_name=summary_hdl_name))
                    for i, child in enumerate(n.children):
                        self.gen_raws(
                            child, "{}{}{}.".format(name, name_idx_sep, i),
                            addr_pfx, n_addr + child.c_address,
                            '{}({}).'.format(hdl_repeat_name, i))
                elif iogrp and not flatten:
                    typ = 'REPEAT ({})'.format(iogrp)
                    self.raws.append(SummaryRaw(
                        rng, typ, name, n, n_addr,
                        hdl_name=iogrp))
                    iogrp_pfx = (hdl_pfx or '') + iogrp + hdl_idx_sep
                    self.gen_raws(
                        n, name + name_idx_sep, addr_pfx, n_addr, iogrp_pfx)
                else:
                    typ = 'REPEAT ({})'.format(iogrp) if iogrp else 'BLOCK'
                    resolved_hdl = hdl if hdl else n.name
                    self.raws.append(SummaryRaw(
                        rng, typ, name, n, n_addr,
                        hdl_name=hdl or None))
                    self.gen_raws(
                        n, name + name_idx_sep, addr_pfx, n_addr,
                        resolved_hdl + hdl_idx_sep)
            elif isinstance(n, tree.Block):
                iogrp = getattr(n, 'hdl_iogroup', None)
                flatten = getattr(n, 'hdl_iogroup_flatten', True)
                skip_name = n.get_extension('x_hdl', 'name-prefix') is False
                next_name = name_pfx if skip_name else name + '.'
                if iogrp and not flatten:
                    typ = 'BLOCK ({})'.format(iogrp)
                    self.raws.append(SummaryRaw(
                        rng, typ, name, n, n_addr,
                        hdl_name=hdl or None))
                    self.gen_raws(
                        n, next_name, addr_pfx, n_addr,
                        '{}{}.'.format(hdl_pfx, iogrp))
                else:
                    typ = 'BLOCK ({})'.format(iogrp) if iogrp else 'BLOCK'
                    self.raws.append(SummaryRaw(
                        rng, typ, name, n, n_addr,
                        hdl_name=hdl or None))
                    next_hdl = hdl_pfx if skip_name else (hdl + '_' if hdl else '')
                    self.gen_raws(n, next_name, addr_pfx, n_addr, next_hdl)
            elif isinstance(n, tree.Submap):
                self.raws.append(SummaryRaw(
                    rng, 'SUBMAP', name, n, n_addr,
                    hdl_name=hdl or None))
                if n.filename is not None:
                    skip_name = n.get_extension('x_hdl', 'name-prefix') is False
                    next_name = name_pfx if skip_name else name + '.'
                    next_hdl = hdl_pfx if skip_name else (hdl + '_' if hdl else '')
                    self.gen_raws(n.c_submap, next_name, addr_pfx, n_addr, next_hdl)
            elif isinstance(n, tree.Memory):
                self.raws.append(SummaryRaw(rng, 'MEMORY', name, n, n_addr))
                self.gen_raws(
                    n, name + '.', addr_pfx + ' +', n_addr, hdl_pfx)
            elif isinstance(n, tree.Repeat):
                if n.count and n.c_elsize:
                    iogrp = getattr(n, 'hdl_iogroup', None)
                    typ = 'REPEAT ({})'.format(iogrp) if iogrp else 'REPEAT'
                    self.raws.append(SummaryRaw(rng, typ, name, n, n_addr))
                    for i in range(n.count):
                        self.gen_raws(
                            n, "{}.{}.".format(name, i),
                            addr_pfx, n_addr + i * n.c_elsize, hdl_pfx)
            else:
                print("MemmapSummary: implementation for tree node of "
                      "type {} is missing. Skipping it.".format(type(n)))
