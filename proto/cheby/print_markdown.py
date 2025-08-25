import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import w, wln

#  Generate markdown (asciidoc variant)
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
    wln(fd, "### Register: {}".format(raw.name))
    wln(fd)

    wln(fd, "- **HW Prefix**: {}".format(r.c_name))
    wln(fd, "- **HW Address**: 0x{:x}".format(raw.abs_addr))
    wln(fd, "- **C Prefix**: {}".format(raw.name))
    wln(fd, "- **C Block Offset**: 0x{:x}".format(r.c_address))
    wln(fd, "- **Access**: {}".format(ACCESSES[r.access]))
    wln(fd)

    if r.description:
        wln(fd, format_text(r.description))
        wln(fd)

    if r.comment and not hide_comments:
        wln(fd, format_text(r.comment))
        wln(fd)

    if print_reg_drawing:
        # Graphical representation of bit fields in register (HTML format)
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

    # Table of Bit Fileds
    wln(fd, "| Bits | Name | Description |")
    wln(fd, "|------|------|------------|")

    for f in r.children:
        if r.has_fields():
            desc_src = f
        else:
            desc_src = r

        # Bit range
        if f.hi is not None:
            w(fd, '| {}:{} | '.format(f.hi, f.lo))
        else:
            w(fd, '| {} | '.format(f.lo))

        # Name
        w(fd, '{} | '.format(format_text(desc_src.name)))

        # Description + comment
        desc = desc_src.description or ""
        if desc_src.comment and not hide_comments:
            desc += "\n\n" + desc_src.comment

        desc = desc.replace('\n', '<br>')

        wln(fd, '{} |'.format(desc))

    wln(fd)


def print_map_summary(fd, summary):
    wln(fd, "| HW address | Type | Name | HDL Name |")
    wln(fd, "|------------|------|------|----------|")
    for r in summary.raws:
        wln(fd, "| {} | {} | {} | {} |".format(r.address, r.typ, r.name, r.node.c_name))
    wln(fd)


def print_reg_description(fd, summary, hide_comments=False, print_reg_drawing=True):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            print_reg(fd, r, ra, hide_comments, print_reg_drawing)


def print_root(fd, root, hide_comments=False, print_reg_drawing=True):
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
        print_reg_description(fd, summary, hide_comments, print_reg_drawing)

    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            wln(fd, "## For Space {}".format(space.name))
            print_map_summary(fd, summary)

        for summary, space in summaries:
            wln(fd, "## Registers Description for Space {}\n".format(space.name))
            print_reg_description(fd, summary, hide_comments, print_reg_drawing)


def print_markdown(fd, n, hide_comments=False, print_reg_drawing=True):
    if isinstance(n, tree.Root):
        print_root(fd, n, hide_comments, print_reg_drawing)
    else:
        raise AssertionError
