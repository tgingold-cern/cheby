import sys
import cheby.tree as tree
import cheby.layout as layout
import cheby.hdltree as hdltree
from cheby.gen_wbgen_hdl import get_hdl_prefix, get_hdl_entity


def w(fd, str):
        fd.write(str)


def wln(fd, str=""):
    fd.write(str)
    fd.write('\n')


def print_port_name(p):
    if p.size > 1:
        return "{}[{}:0]".format(p.name, p.size - 1)
    else:
        return p.name


def print_port_arrow(p, io='rl'):
    """Output &rarr, &larr, &rArr, &lArr according to the direction and the
       width."""
    return '&' + {'IN': io[0], 'OUT': io[1]}[p.dir] \
        + ('a' if p.size is None or p.size == 1 else 'A') + 'rr;'


def print_access(acc, dflt=None):
    if acc is None:
        acc = dflt
    return {'READ_WRITE': 'read/write',
            'READ_ONLY': 'read-only',
            'WRITE_ONLY': 'write-only'}.get(acc, acc)


def print_symbol_table(left, right):
    res = '<table cellpadding=0 cellspacing=0 border=0>\n'
    for i in range(max(len(left), len(right))):
        if i < len(left):
            ln = left[i]
        else:
            ln = ''
        if i < len(right):
            cstr, r = right[i]
        else:
            cstr, r = ('', '')
        if isinstance(ln, hdltree.HDLPort):
            larr = print_port_arrow(ln, 'rl')
            lname = print_port_name(ln)
        else:
            larr = ''
            lname = ln
        if isinstance(r, hdltree.HDLPort):
            rarr = print_port_arrow(r, 'lr')
            rname = print_port_name(r)
        else:
            rarr = ''
            rname = r
        res += '''<tr>
<td  class="td_arrow_left">
{larr}
</td>
<td  class="td_pblock_left">
{lname}
</td>
<td  class="td_sym_center">
{cstr}
</td>
<td  class="td_pblock_right">
{rname}
</td>
<td  class="td_arrow_right">
{rarr}
</td>
</tr>
'''.format(larr=larr, lname=lname, cstr=cstr, rname=rname, rarr=rarr)

    res += '''</table>
'''
    return res


def print_symbol(periph):
    res = '''
<h3><a name="sect_2_0">2. HDL symbol</a></h3>
'''
    left = []
    for p in periph.bus_ports:
        left.append(p)
    right = []
    for r in periph.regs:
        if isinstance(r, tree.Reg) \
           or isinstance(r, tree.Fifo) \
           or isinstance(r, tree.Ram) \
           or isinstance(r, tree.Irq):
            if not r.code.ports \
               and len(r.fields) == 1 \
               and r.fields[0].access == 'WO_RO':  # FIXME!
                continue
            if right:
                right.append(('&nbsp;', ''))
            right.append(('', "<b>{}:</b>".format(r.name)))
            for p in r.code.ports:
                right.append(('', p))
    for r in periph.regs:
        if isinstance(r, tree.FifoReg):
            right.append(('&nbsp;', ''))
            right.append(('', "<b>{}:</b>".format(r.name)))
    return res + print_symbol_table(left, right)


class SummaryRaw(object):
    def __init__(self, address, typ, name, node):
        self.address = address
        self.typ = typ
        self.name = name
        self.node = node


def print_regdescr_reg(periph, raw, num):
    r = raw.node
    res = '''<a name="{name}"></a>
<h3><a name="sect_3_{n}">2.{n}. {name}</a></h3>
<table cellpadding=0 cellspacing=0 border=0>
<tr><td><b>HW prefix:  </b></td><td class="td_code">{hdlprefix}</td></tr>
<tr><td><b>HW address: </b></td><td class="td_code">0x{addr:x}</td></tr>
<tr><td><b>C prefix:   </b></td><td class="td_code">{cprefix}</td></tr>
<tr><td><b>C offset:   </b></td><td class="td_code">0x{caddr:x}</td></tr>
</table>
'''.format(n=num, cprefix=r.name,
           hdlprefix="{}_{}".format(get_hdl_prefix(periph),
                                    get_hdl_prefix(r)),
           addr=r.c_address, caddr=r.c_address,
           name=raw.name)
    if r.description is not None:
        res += '''<p>
{desc}
</p>
'''.format(desc=r.description.replace('\n', '<br>'))

    # Drawing of the register, with bits.
    for i in range(r.c_size * 8 - 8, -1, -8):
        # One line per byte
        res += '<table cellpadding=0 cellspacing=0 border=0>\n'
        res += '<tr>\n'
        for j in range(7, -1, -1):
            res += '<td class="td_bit">\n{}\n</td>\n'.format(i + j)
        res += '</tr>\n<tr>\n'
        j = 7
        totcol = 0
        while j >= 0:
            # Find the field corresponding to the bit.
            field = None
            for f in r.children:
                if (f.hi is not None and f.hi >= i + j >= f.lo) \
                  or (f.hi is None and f.lo == i + j):
                    field = f
                    break
            totcol += 1
            if field is None:
                res += '<td class="td_unused">\n-\n</td>\n'
                j -= 1
            else:
                # Range of the field
                if f.hi is None:
                    h = 0
                else:
                    h = min(f.hi - f.lo, i + j - f.lo)
                l = max(0, i - f.lo)
                length = h - l + 1
                res += '<td style="border: solid 1px black;" colspan={}  class="td_field">\n'.format(length)
                res += f.name or r.name
                if f.hi is not None:
                    res += "[{}:{}]".format(h, l)
                j -= length
                res += '\n</td>\n'
        for k in range(8 - totcol):
            res += "<td >\n\n</td>\n"
        res += '</tr>\n</table>\n'
    res += '<ul>\n'
    for f in r.children:
        res += '<li><b>\n'
        res += f.name or r.name
        res += '\n</b>[<i>{}</i>]: {}\n'.format(
            r.access, f.description or r.description or '')
        if f.comment is not None:
            res += '<br>'
            res += f.comment.replace('\n', '<br>')
            res += '\n'
    res += '</ul>\n'
    return res


def print_regdescr(periph, raws):
    res = '''
<h3><a name="sect_3_0">2. Register description</a></h3>
'''
    num = 1
    for raw in raws:
        if isinstance(raw.node, tree.Reg):
            res += print_regdescr_reg(periph, raw, num)
            num += 1
    res += '\n'
    return res

def gen_memmap_summary(root, name_pfx="", addr_pfx=""):
    "Return a list of SummaryRaw"
    raws = []
    for n in root.c_sorted_children:
        rng = addr_pfx + '0x{:x}-0x{:x}'.format(n.c_abs_addr, n.c_abs_addr + n.c_size - 1)
        name = name_pfx + n.name
        if isinstance(n, tree.Reg):
            rng = addr_pfx + '0x{:x}'.format(n.c_abs_addr)
            raws.append(SummaryRaw(rng, 'REG', name, n))
        elif isinstance(n, tree.Block):
            raws.append(SummaryRaw(rng, 'BLOCK', name, n))
            raws.extend(gen_memmap_summary(n, name + '.', addr_pfx))
        elif isinstance(n, tree.Submap):
            raws.append(SummaryRaw(rng, 'SUBMAP', name, n))
        elif isinstance(n, tree.Array):
            raws.append(SummaryRaw(rng, 'ARRAY', name, n))
            raws.extend(gen_memmap_summary(n, name + '.', addr_pfx + ' +'))
        else:
            assert False, "html: unhandled tree node {}".format(n)
    return raws


def phtml_memmap_summary(root, raws):
    "HTML formatter for memmap_summary"
    res = '<h3><a name="sect_1_0">1. Memory map summary</a></h3>\n'
    res += '''<table cellpadding=2 cellspacing=0 border=0>
<tr>
<th>H/W Address</th>
<th>Type</th>
<th>Name</th>
<th>HDL prefix</th>
<th>C prefix</th>
</tr>
'''
    odd_even = ['odd', 'even']
    for r in raws:
        res += '''<tr class="tr_{odd_even}">
<td class="td_code">{address}</td>
<td>{typ}</td>
<td><A href="#{cprefix}">{name}</a></td>
<td class="td_code">{hdlprefix}</td>
<td class="td_code">{cprefix}</td>
</tr>\n'''.format(typ=r.typ, odd_even=odd_even[0], address=r.address,
                  cprefix=r.name, name=r.name,
                  periph_prefix=get_hdl_prefix(root),
                  hdlprefix=r.node.c_name)
        odd_even = [odd_even[1], odd_even[0]]
    res += '</table>\n'
    return res


def phtml_header(fd, periph):
    entity = get_hdl_entity(periph)
    wln(fd, '''<HTML>
<HEAD>
<TITLE>{entity}</TITLE>'''.format(entity=entity))
    wln(fd, '''<STYLE TYPE="text/css" MEDIA="all">

	<!--
  BODY  { background: white; color: black;
  			  font-family: Arial,Helvetica; font-size:12; }
	h1 { font-family: Trebuchet MS,Arial,Helvetica; font-size:30; color:#404040; }
	h2 { font-family: Trebuchet MS,Arial,Helvetica; font-size:22; color:#404040; }
	h3 { font-family: Trebuchet MS,Arial,Helvetica; font-size:16; color:#404040; }
	.td_arrow_left { padding:0px; background: #ffffff; text-align: right; font-size:12;}
	.td_arrow_right { padding:0px; background: #ffffff; text-align: left; font-size:12;}
	.td_code { font-family:Courier New,Courier; padding: 3px; }
	.td_desc { padding: 3px; }
	.td_sym_center { background: #e0e0f0; padding: 3px; }
	.td_port_name { font-family:Courier New,Courier; background: #e0e0f0; text-align: right; font-weight:bold;padding: 3px; width:200px; }
	.td_pblock_left { font-family:Courier New,Courier; background: #e0e0f0; padding: 0px; text-align: left; }
	.td_pblock_right { font-family:Courier New,Courier; background: #e0e0f0; padding: 0px; text-align: right; }
	.td_bit { background: #ffffff; color:#404040; font-size:10; width: 70px; font-family:Courier New,Courier; padding: 3px; text-align:center; }
	.td_field { background: #e0e0f0; padding: 3px; text-align:center; }
	.td_unused { background: #a0a0a0; padding: 3px; text-align:center;  }
	th { font-weight:bold; color:#ffffff; background: #202080; padding:3px; }
	.tr_even { background: #f0eff0; }
	.tr_odd { background: #e0e0f0; }
	-->
</STYLE>''')
    wln(fd, '''</HEAD>
<BODY>
<h1 class="heading">{entity}</h1>
<h3>{description}</h3>
<p>{comment}</p>'''.format(entity=entity, description=periph.description,
                        comment=periph.comment.replace('\n', '<br>') if periph.comment else ''))


def pprint_root(fd, root):
    phtml_header(fd, root)
    raws = gen_memmap_summary(root)
    memmap_summary = phtml_memmap_summary(root, raws)
    # Sect1: Memory map summary
    w(fd, memmap_summary)
    if False:
        # Sect2: Symbol
        w(print_symbol(root))
    # Sect2: Registers
    w(fd, print_regdescr(root, raws))
    wln(fd, '\n</BODY>\n</HTML>')


def pprint(fd, n):
    if isinstance(n, tree.Root):
        pprint_root(fd, n)
    else:
        raise AssertionError
