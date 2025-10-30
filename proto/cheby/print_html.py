import cheby.tree as tree
import cheby.hdltree as hdltree
import cheby.gen_doc as gen_doc
from cheby.gen_wbgen_hdl import get_hdl_entity
from cheby.wrutils import w, wln
import re

JS_DEPS = ["https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-chtml.js"]


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


def format_text(text):
    # Replace newlines with corresponding HTML tag
    text = text.replace("\n", "<br>")

    # Replace strings wrapped by dollar signs ($ and $) indicating a LaTeX equation with
    # inline delimiters (\( and \)) such that the equations can be detected by MathJax
    text = re.sub(r"\$([^$\n\r]+)\$", r"\\(\1\\)", text)

    return text


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


def print_regdescr_reg(_periph, pfx, raw, num, hide_comments=False):
    r = raw.node
    res = '''<a name="{name}"></a>
<h3>{pfx}.{n}. {name}</h3>
<table cellpadding=0 cellspacing=0 border=0>
<tr><td><b>HW prefix:</b></td><td class="td_code">{hdlprefix}</td></tr>
<tr><td><b>HW address:</b></td><td class="td_code">0x{addr:x}</td></tr>
<tr><td><b>C prefix:</b></td><td class="td_code">{cprefix}</td></tr>
<tr><td><b>C block offset:</b></td><td class="td_code">0x{caddr:x}</td></tr>
</table>
'''.format(pfx=pfx, n=num, cprefix=raw.name,
           hdlprefix=r.c_name,
           addr=raw.abs_addr, caddr=r.c_address,
           name=raw.name)

    if r.comment and not hide_comments:
        res += "<p>{}</p>\n".format(format_text(r.comment))

    if r.description:
        res += "<p>{}</p>\n".format(format_text(r.description))

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

    res += '<dl>\n'
    for f in r.children:
        name = f.name or r.name
        access = r.access
        res += '  <dt><b>{name}</b> [<i>{access}</i>]</dt>\n'.format(
            name=name, access=access
        )

        if f.comment and not hide_comments:
            res += "  <dd>{}</dd>\n".format(format_text(f.comment))

        description = format_text(f.description or r.description or "")
        res += "  <dd>{}</dd>\n".format(description)

    res += "</dl>\n"

    return res


def print_regdescr(periph, pfx, raws, hide_comments=False):
    res = ''
    num = 1
    for raw in raws:
        if isinstance(raw.node, tree.Reg):
            res += print_regdescr_reg(periph, pfx, raw, num, hide_comments)
            num += 1
    res += '\n'
    return res


def print_summary_html(_periph, summary):
    "HTML formatter for memmap_summary"
    res = '''<table cellpadding=2 cellspacing=0 border=0>
<tr>
<th>HW address</th>
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
                  hdlprefix=r.node.c_name)
        odd_even = [odd_even[1], odd_even[0]]
    res += '</table>\n'
    return res


def phtml_header(fd, periph, hide_comments=False, include_js_dep=False):
    entity = get_hdl_entity(periph)
    wln(fd, '''<HTML>
<HEAD>
<TITLE>{entity}</TITLE>'''.format(entity=entity))
    wln(fd, '''<STYLE TYPE="text/css" MEDIA="all">
<!--
  BODY { background: white; color: black;
         font-family: Arial,Helvetica; font-size:12; }
  h1 { font-family: Trebuchet MS,Arial,Helvetica; font-size:30;
       color:#404040; }
  h2 { font-family: Trebuchet MS,Arial,Helvetica; font-size:22;
       color:#404040; }
  h3 { font-family: Trebuchet MS,Arial,Helvetica; font-size:16;
       color:#404040; }
  .td_arrow_left { padding:0px; background: #ffffff; text-align: right;
                   font-size:12; }
  .td_arrow_right { padding:0px; background: #ffffff; text-align: left;
                    font-size:12; }
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

    # Print script tags to include external JavaScript dependencies
    if include_js_dep:
        js_deps_html = "\n".join(
            map(
                lambda src: f'<script type="text/javascript" async src="{src}"></script>',
                JS_DEPS,
            )
        )
        wln(fd, js_deps_html)

    wln(fd, '''</HEAD>
<BODY>
<h1 class="heading">{entity}</h1>'''.format(
        entity=entity))

    if periph.comment and not hide_comments:
        wln(fd, "<p>{}</p>".format(format_text(periph.comment)))

    if periph.description:
        wln(fd, "<p>{}</p>".format(format_text(periph.description)))

    if periph.version is not None:
        wln(fd, "<p>Version: {}</p>".format(periph.version))


def phtml_root(fd, root, hide_comments=False, include_js_dep=False):
    phtml_header(fd, root, hide_comments, include_js_dep)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        memmap_summary = print_summary_html(root, summary)
        # Sect1: Memory map summary
        wln(fd, '<h3>1. Memory map summary</h3>')
        w(fd, memmap_summary)
        # Sect2: Registers
        wln(fd)
        wln(fd, '<h3><a name="sect_3_0">2. Register description</a></h3>')
        w(fd, print_regdescr(root, '2', summary.raws, hide_comments))
    else:
        summaries = [(space, gen_doc.MemmapSummary(space)) for space in root.children]
        for i, (space, summary) in enumerate(summaries, 1):
            memmap_summary = print_summary_html(space, summary)
            wln(fd, '<h3>1.{}. Memory map summary for address space {}</h3>\n'.format(
                i, space.name))
            w(fd, memmap_summary)
        for i, (space, summary) in enumerate(summaries, 1):
            # Sect2: Registers
            wln(fd, '<h3>2.{} Register description for address space {}</h3>'.format(
                i, space.name))
            w(fd, print_regdescr(space, '2.{}'.format(i), summary.raws, hide_comments))

    wln(fd, '\n</BODY>\n</HTML>')


def print_html(fd, n, hide_comments=False, include_js_dep=False):
    assert isinstance(n, tree.Root)
    phtml_root(fd, n, hide_comments, include_js_dep)
