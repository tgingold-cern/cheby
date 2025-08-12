import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import wln

#  Generate markdown (asciidoc variant)
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables


def format_text(text):
    return text.replace("\n", " +\n")


def print_reg(fd, r, name, abs_addr, hide_comments=False):
    # Description of Register
    wln(fd, "### Register: {}".format(name))
    wln(fd)

    if r.description:
        wln(fd, format_text(r.description))
        wln(fd)

    if r.comment and not hide_comments:
        wln(fd, format_text(r.comment))
        wln(fd)

    wln(fd, "- **HDL name**: {}".format(r.c_name))
    wln(fd, "- **Address**: 0x{:x}".format(abs_addr))
    wln(fd, "- **Block Offset**: 0x{:x}".format(r.c_address))
    wln(fd, "- **Access Mode**: {}".format(r.access))

    wln(fd)

    # Table of Bit Fields (HTML format)
    descr = gen_doc.build_regdescr_table(r)
    wln(fd, "<table>")
    for desc_raw in descr:
        wln(fd, "  <tr>")
        for col in desc_raw:
            if col.style == "bit":
                wln(fd, "    <td><b>{}</b></td>".format(col.content))
            else:
                attrs = ""
                if col.colspan > 1:
                    attrs = ' colspan="{}" style="text-align: center;"'.format(
                        col.colspan
                    )

                wln(fd, "    <td{}>{}</td>".format(attrs, col.content))

        wln(fd, "  </tr>")

    wln(fd, "</table>")
    wln(fd)

    # Description of Bit Fields (HTML format)
    if r.has_fields():
        for f in r.children:
            wln(fd, "#### Bit: {}".format(f.name))
            wln(fd)

            not_documented = True

            if f.description:
                wln(fd, format_text(f.description))
                wln(fd)
                not_documented = False

            if f.comment and not hide_comments:
                wln(fd, format_text(f.comment))
                wln(fd)
                not_documented = False

            if not_documented:
                wln(fd, "_(not documented)_")
                wln(fd)


def print_map_summary(fd, summary):
    wln(fd, "| HW address | Type | Name | HDL Name |")
    wln(fd, "|------------|------|------|----------|")
    for r in summary.raws:
        wln(fd, "| {} | {} | {} | {} |".format(r.address, r.typ, r.name, r.node.c_name))
    wln(fd)


def print_reg_description(fd, summary, hide_comments=False):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            print_reg(fd, r, ra.name, ra.abs_addr, hide_comments)


def print_root(fd, root, hide_comments=False):
    wln(fd, "## Memory Map Summary")

    if root.description:
        wln(fd, root.description)
        wln(fd)

    if root.version is not None:
        wln(fd, "Version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        print_map_summary(fd, summary)

        wln(fd, "## Registers Description")
        print_reg_description(fd, summary, hide_comments)

    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            wln(fd, "## For Space {}".format(space.name))
            print_map_summary(fd, summary)

        for summary, space in summaries:
            wln(fd, "## Registers Description for Space {}\n".format(space.name))
            print_reg_description(fd, summary, hide_comments)


def print_markdown(fd, n, hide_comments=False):
    if isinstance(n, tree.Root):
        print_root(fd, n, hide_comments)
    else:
        raise AssertionError
