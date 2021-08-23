import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import wln

#  Generate markdown (asciidoc variant)
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables


def print_reg(fd, r, abs_addr):
    wln(fd, "[horizontal]")
    wln(fd, "HDL name:: {}".format(r.c_name))
    wln(fd, "address:: 0x{:x}".format(abs_addr))
    wln(fd, "block offset:: 0x{:x}".format(r.c_address))
    wln(fd, "access mode:: {}".format(r.access))
    for t in (r.comment, r.description):
        if t:
            wln(fd)
            wln(fd, t)
    wln(fd)
    descr = gen_doc.build_regdescr_table(r)
    wln(fd, '[cols="8*^"]')
    wln(fd, "|===")
    for desc_raw in descr:
        wln(fd)
        for col in desc_raw:
            style = ""
            if col.colspan > 1:
                style += "{}+".format(col.colspan)
            if col.style == 'field':
                style += 's'
            wln(fd, "{}| {}".format(style, col.content))
    wln(fd, "|===")

    if r.has_fields():
        wln(fd)
        for f in r.children:
            wln(fd, "{}::".format(f.name))
            if f.comment:
                wln(fd, f.comment)
                if f.description:
                    wln(fd, '+')
            if f.description:
                wln(fd, f.description)
            if not any((f.comment, f.description)):
                wln(fd, '(not documented)')
        wln(fd)


def print_root(fd, root):
    wln(fd, "== Memory map summary")
    wln(fd, root.description or '(no description)')
    wln(fd)
    if root.version is not None:
        wln(fd, "version: {}".format(root.version))
        wln(fd)

    wln(fd, "|===")
    wln(fd, "|HW address | Type | Name | HDL name")
    summary = gen_doc.MemmapSummary(root)
    for r in summary.raws:
        wln(fd)
        wln(fd, "|{}".format(r.address))
        wln(fd, "|{}".format(r.typ))
        wln(fd, "|{}".format(r.name))
        wln(fd, "|{}".format(r.node.c_name))
    wln(fd, "|===")
    wln(fd)

    wln(fd, "== Registers description")
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "=== {}".format(ra.name))
            print_reg(fd, r, ra.abs_addr)


def print_markdown(fd, n):
    if isinstance(n, tree.Root):
        print_root(fd, n)
    else:
        raise AssertionError
