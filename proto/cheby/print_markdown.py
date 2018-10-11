import sys
import cheby.tree as tree
import cheby.layout as layout
import cheby.hdltree as hdltree
from cheby.gen_wbgen_hdl import get_hdl_prefix, get_hdl_entity
import cheby.gen_doc as gen_doc

#  Generate markdown (asciidoc variant)
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables

def w(fd, str):
        fd.write(str)


def wln(fd, str=""):
    fd.write(str)
    fd.write('\n')


def print_root(fd, root):
    wln(fd, "== Memory map summary")
    wln(fd, root.description)
    wln(fd)

    wln(fd, "|===")
    wln(fd, "|HW address | Type | Name")
    summary = gen_doc.MemmapSummary(root)
    for r in summary.raws:
        wln(fd)
        wln(fd, "|{}".format(r.address))
        wln(fd, "|{}".format(r.typ))
        wln(fd, "|{}".format(r.name))
    wln(fd, "|===")
    wln(fd)

    wln(fd, "== Registers description")
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "=== {}".format(ra.name))
            wln(fd, "address: 0x{:x}".format(r.c_abs_addr))
            if r.description:
                wln(fd)
                wln(fd, r.description)
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


def print_markdown(fd, n):
    if isinstance(n, tree.Root):
        print_root(fd, n)
    else:
        raise AssertionError
