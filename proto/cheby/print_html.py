import cheby.tree as tree
import cheby.hdltree as hdltree
import cheby.gen_doc as gen_doc
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
    res += '<table cellpadding=0 cellspacing=0 border=0>\n'
    descr = gen_doc.build_regdescr_table(r)
    for desc_raw in descr:
        res += '<tr>\n'
        for col in desc_raw:
            res += ' <td class="td_{}" colspan="{}">{}</td>\n'.format(
                col.style, col.colspan, col.content)
        res += '</tr>\n'
    res += '</table>\n'

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


def print_summary_html(periph, summary):
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
        for r in summary.raws:
            res += '''<tr class="tr_{odd_even}">
<td class="td_code">{address}</td>
<td>{typ}</td>
<td><A href="#{cprefix}">{name}</a></td>
<td class="td_code">{hdlprefix}</td>
<td class="td_code">{cprefix}</td>
</tr>\n'''.format(typ=r.typ, odd_even=odd_even[0], address=r.address,
                  cprefix=r.name, name=r.name,
                  periph_prefix=get_hdl_prefix(periph),
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
        h1 { font-family: Trebuchet MS,Arial,Helvetica; font-size:30;
         color:#404040; }
        h2 { font-family: Trebuchet MS,Arial,Helvetica; font-size:22;
         color:#404040; }
        h3 { font-family: Trebuchet MS,Arial,Helvetica; font-size:16;
         color:#404040; }
        .td_arrow_left { padding:0px; background: #ffffff; text-align: right;
                     font-size:12;}
        .td_arrow_right { padding:0px; background: #ffffff; text-align: left;
                      font-size:12;}
        .td_code { font-family:Courier New,Courier; padding: 3px; }
        .td_desc { padding: 3px; }
        .td_sym_center { background: #e0e0f0; padding: 3px; }
        .td_port_name { font-family:Courier New,Courier; background: #e0e0f0;
                    text-align: right; font-weight:bold;
                    padding: 3px; width:200px; }
        .td_pblock_left { font-family:Courier New,Courier; background: #e0e0f0;
                      padding: 0px; text-align: left; }
        .td_pblock_right { font-family:Courier New,Courier;
                           background: #e0e0f0;
                           padding: 0px; text-align: right; }
        .td_bit { background: #ffffff; color:#404040;
                  font-size:10; width: 70px;
                  font-family:Courier New,Courier; padding: 3px;
                  text-align:center; }
        .td_field { background: #e0e0f0; padding: 3px; text-align:center;
                    border: solid 1px black; }
        .td_unused { background: #a0a0a0; padding: 3px; text-align:center;  }
        th { font-weight:bold; color:#ffffff; background: #202080;
             padding:3px; }
        .tr_even { background: #f0eff0; }
        .tr_odd { background: #e0e0f0; }
        -->
</STYLE>''')
    wln(fd, '''</HEAD>
<BODY>
<h1 class="heading">{entity}</h1>
<h3>{description}</h3>
<p>{comment}</p>'''.format(
        entity=entity, description=periph.description,
        comment=periph.comment.replace('\n', '<br>')
            if periph.comment else ''))


def pprint_root(fd, root):
    phtml_header(fd, root)
    summary = gen_doc.MemmapSummary(root)
    memmap_summary = print_summary_html(root, summary)
    # Sect1: Memory map summary
    w(fd, memmap_summary)
    if False:
        # Sect2: Symbol
        w(print_symbol(root))
    # Sect2: Registers
    w(fd, print_regdescr(root, summary.raws))
    wln(fd, '\n</BODY>\n</HTML>')


def pprint(fd, n):
    if isinstance(n, tree.Root):
        pprint_root(fd, n)
    else:
        raise AssertionError
