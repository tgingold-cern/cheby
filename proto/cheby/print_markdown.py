import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import wln

#  Generate markdown (asciidoc variant)
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables


def format_text(text):
    return text.replace("\n", " +\n")


def print_reg(fd, r, abs_addr, hide_comments=False):
    wln(fd, "[horizontal]")
    wln(fd, "HDL name:: {}".format(r.c_name))
    wln(fd, "address:: 0x{:x}".format(abs_addr))
    wln(fd, "block offset:: 0x{:x}".format(r.c_address))
    wln(fd, "access mode:: {}".format(r.access))

    if r.description:
        wln(fd)
        wln(fd, format_text(r.description))

    if r.comment:
        wln(fd)
        wln(fd, format_text(r.comment))

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

            not_documented = True
            if f.description:
                wln(fd, format_text(f.description))
                not_documented = False

            if f.comment and not hide_comments:
                if f.description:
                    wln(fd, "+")
                wln(fd, format_text(f.comment))
                not_documented = False

            if not_documented:
                wln(fd, "(not documented)")

        wln(fd)


def print_map_summary(fd, summary):
    wln(fd, "|===")
    wln(fd, "|HW address | Type | Name | HDL name")
    for r in summary.raws:
        wln(fd)
        wln(fd, "|{}".format(r.address))
        wln(fd, "|{}".format(r.typ))
        wln(fd, "|{}".format(r.name))
        wln(fd, "|{}".format(r.node.c_name))
    wln(fd, "|===")
    wln(fd)


def print_reg_description(fd, summary, hide_comments=False):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "=== {}".format(ra.name))
            print_reg(fd, r, ra.abs_addr, hide_comments)


def print_root(fd, root, hide_comments=False):
    wln(fd, "== Memory map summary")
    wln(fd, root.description or '(no description)')
    wln(fd)
    if root.version is not None:
        wln(fd, "version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        print_map_summary(fd, summary)
        wln(fd, "== Registers description")
        print_reg_description(fd, summary, hide_comments)
    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            wln(fd, "== For space {}".format(space.name))
            print_map_summary(fd, summary)
        for summary, space in summaries:
            wln(fd, "== Registers description for space {}\n".format(space.name))
            print_reg_description(fd, summary, hide_comments)


def print_markdown(fd, n, hide_comments=False):
    if isinstance(n, tree.Root):
        print_root(fd, n, hide_comments)
    else:
        raise AssertionError
