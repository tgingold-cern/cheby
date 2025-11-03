import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import w, wln

#  Generate asciidoc
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables


def format_text(text):
    return text.replace("\n", " +\n")


def print_reg(fd, r, raw, hide_comments=False, print_reg_drawing=True):
    ACCESSES = {
        "rw": "read/write",
        "wo": "write-only",
        "ro": "read-only",
    }

    # Description of Register
    wln(fd, "=== Register: {}".format(raw.name))
    wln(fd)

    wln(fd, "[horizontal]")
    wln(fd, "HW Prefix:: {}".format(r.c_name))
    wln(fd, "HW Address:: 0x{:x}".format(raw.abs_addr))
    wln(fd, "C Prefix:: {}".format(raw.name))
    wln(fd, "C Block Offset:: 0x{:x}".format(r.c_address))
    wln(fd, "Access:: {}".format(ACCESSES[r.access]))
    wln(fd)

    if r.comment and not hide_comments:
        wln(fd, format_text(r.comment))
        wln(fd)

    if r.description:
        wln(fd, format_text(r.description))
        wln(fd)

    if print_reg_drawing:
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
        wln(fd)

    if r.has_fields():
        for f in r.children:
            wln(fd, "{}::".format(f.name))

            not_documented = True
            if f.comment and not hide_comments:
                wln(fd, format_text(f.comment))
                not_documented = False

            if f.description:
                if f.comment and not hide_comments:
                    wln(fd, "+")
                wln(fd, format_text(f.description))
                not_documented = False

            if not_documented:
                wln(fd, "(not documented)")

        wln(fd)


def print_map_summary(fd, summary):
    wln(fd, "|===")
    wln(fd, "|HW address | Type | Name | HDL Name")
    for r in summary.raws:
        wln(fd)
        wln(fd, "|{}".format(r.address))
        wln(fd, "|{}".format(r.typ))
        wln(fd, "|{}".format(r.name))
        wln(fd, "|{}".format(r.node.c_name))
    wln(fd, "|===")
    wln(fd)


def print_reg_description(fd, summary, hide_comments=False, print_reg_drawing=True):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            print_reg(fd, r, ra, hide_comments, print_reg_drawing)


def print_root(fd, root, hide_comments=False, print_reg_drawing=True):
    wln(fd, "== Memory Map Summary")

    if root.comment and not hide_comments:
        wln(fd, root.comment)
        wln(fd)

    if root.description:
        wln(fd, root.description)
        wln(fd)

    if root.version is not None:
        wln(fd, "Version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        print_map_summary(fd, summary)
        wln(fd, "== Registers Description")
        print_reg_description(fd, summary, hide_comments, print_reg_drawing)
    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            wln(fd, "== For Space {}".format(space.name))
            print_map_summary(fd, summary)
        for summary, space in summaries:
            wln(fd, "== Registers Description for Space {}\n".format(space.name))
            print_reg_description(fd, summary, hide_comments, print_reg_drawing)


def print_asciidoc(fd, n, hide_comments=False, print_reg_drawing=True):
    if isinstance(n, tree.Root):
        print_root(fd, n, hide_comments, print_reg_drawing)
    else:
        raise AssertionError
