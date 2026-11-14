import re

import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.gen_wbgen_hdl import get_hdl_entity
from cheby.wrutils import w, wln

#  Generate Markdown documentation


def format_text(text):
    # Preserve hard line breaks using the standard Markdown convention
    # (two trailing spaces before the newline).
    return text.replace("\n", "  \n")


def md_escape_cell(text):
    """Escape characters that break Markdown table cells."""
    if text is None:
        return ""
    return str(text).replace("|", "\\|").replace("\n", "<br>")


def md_code(text):
    """Wrap *text* in backticks, escaping any backticks inside."""
    if text is None:
        return ""
    s = str(text).replace("`", "'")
    return "`{}`".format(s)


def gitlab_slugify(text):
    """Slugify heading text the way GitLab Flavored Markdown does (GitHub
    gives the same result for Cheby headings).

    Rules (see GitLab docs, Heading anchors):
      1. lowercase
      2. remove characters except letters, numbers, hyphens, underscores
         (spaces kept until step 3; punctuation such as '.' is dropped)
      3. spaces become hyphens
    """
    s = text.lower()
    # Keep unicode letters/digits/underscore (\w), hyphens and spaces.
    s = re.sub(r"[^\w\- ]+", "", s, flags=re.UNICODE)
    return s.replace(" ", "-")


class GitlabAnchorSet(object):
    """Allocate unique heading anchors matching GitLab's duplicate rules."""

    def __init__(self):
        self._seen = {}

    def allocate(self, heading_text):
        base = gitlab_slugify(heading_text)
        count = self._seen.get(base, 0)
        self._seen[base] = count + 1
        if count:
            return "{}-{}".format(base, count)
        return base


def reg_heading_text(pfx, num, name):
    return "{}.{}. {}".format(pfx, num, name)


def precompute_register_slugs(root):
    """Map each register SummaryRaw (by id) to its heading anchor.

    Headings are allocated in the same order they are written to the file so
    duplicate-suffix numbering matches GitLab.
    """
    anchors = GitlabAnchorSet()
    slugs = {}

    anchors.allocate(get_hdl_entity(root))

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        anchors.allocate("1. Memory map summary")
        anchors.allocate("2. Register description")
        num = 1
        for ra in summary.raws:
            if isinstance(ra.node, tree.Reg):
                slugs[id(ra)] = anchors.allocate(
                    reg_heading_text("2", num, ra.name)
                )
                num += 1
        return [(summary, None, slugs)]

    summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
    for i, (_summary, space) in enumerate(summaries, 1):
        anchors.allocate(
            "1.{}. Memory map summary for address space {}".format(i, space.name)
        )

    result = []
    for i, (summary, space) in enumerate(summaries, 1):
        space_slugs = {}
        anchors.allocate(
            "2.{} Register description for address space {}".format(i, space.name)
        )
        num = 1
        pfx = "2.{}".format(i)
        for ra in summary.raws:
            if isinstance(ra.node, tree.Reg):
                space_slugs[id(ra)] = anchors.allocate(
                    reg_heading_text(pfx, num, ra.name)
                )
                num += 1
        result.append((summary, space, space_slugs))
    return result


def print_reg(fd, r, raw, num, pfx, hide_comments=False, print_reg_drawing=True):
    ACCESSES = {
        "rw": "read/write",
        "wo": "write-only",
        "ro": "read-only",
    }

    # Description of Register
    wln(fd, "### {}".format(reg_heading_text(pfx, num, raw.name)))
    wln(fd)

    wln(fd, "- **HW Prefix**: {}".format(raw.hdl_name if raw.hdl_name else r.c_name))
    wln(fd, "- **HW Address**: 0x{:x}".format(raw.abs_addr))
    wln(fd, "- **C Prefix**: {}".format(raw.name))
    wln(fd, "- **C Block Offset**: 0x{:x}".format(r.c_address))
    wln(fd, "- **Access**: {}".format(ACCESSES[r.access]))
    wln(fd)

    if r.comment and not hide_comments:
        wln(fd, format_text(r.comment))
        wln(fd)

    if r.description:
        wln(fd, format_text(r.description))
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
                        # Use the deprecated `align` attribute rather than
                        # `style="text-align: center;"` because GitLab's HTML
                        # sanitizer strips inline `style` but keeps `align`.
                        attrs = ' colspan="{}" align="center"'.format(
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
        desc = ""
        if desc_src.comment and not hide_comments:
            desc += desc_src.comment
        if desc_src.description:
            if desc_src.comment and not hide_comments:
                desc += "\n\n"
            desc += desc_src.description

        desc = desc.replace('\n', '<br>')

        wln(fd, '{} |'.format(desc))

    wln(fd)


def print_map_summary(fd, summary, hide_comments=False, reg_slugs=None):
    if reg_slugs is None:
        reg_slugs = {}
    wln(fd, "| HW address | Type | Name | Description |")
    wln(fd, "| --- | --- | --- | --- |")
    for r in summary.raws:
        # Only registers have a section in the register description.
        slug = reg_slugs.get(id(r)) if isinstance(r.node, tree.Reg) else None
        if slug:
            name_cell = "[{}](#{})".format(md_escape_cell(r.name), slug)
        else:
            name_cell = md_escape_cell(r.name)
        desc = md_escape_cell(gen_doc.brief_description(r.node, hide_comments))
        wln(
            fd,
            "| {} | {} | {} | {} |".format(
                md_code(r.address),
                md_escape_cell(r.typ),
                name_cell,
                desc,
            ),
        )
    wln(fd)


def print_reg_description(fd, summary, pfx, hide_comments=False, print_reg_drawing=True):
    num = 1
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            print_reg(fd, r, ra, num, pfx, hide_comments, print_reg_drawing)
            num += 1


def print_root(fd, root, hide_comments=False, print_reg_drawing=True):
    spaces = precompute_register_slugs(root)

    wln(fd, "# {}".format(get_hdl_entity(root)))
    wln(fd)

    if root.comment and not hide_comments:
        wln(fd, format_text(root.comment))
        wln(fd)

    if root.description:
        wln(fd, format_text(root.description))
        wln(fd)

    if root.version is not None:
        wln(fd, "Version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary, _space, reg_slugs = spaces[0]

        wln(fd, "## 1. Memory map summary")
        wln(fd)
        print_map_summary(fd, summary, hide_comments, reg_slugs)

        wln(fd, "## 2. Register description")
        wln(fd)
        print_reg_description(fd, summary, "2", hide_comments, print_reg_drawing)
    else:
        for i, (summary, space, reg_slugs) in enumerate(spaces, 1):
            wln(fd, "## 1.{}. Memory map summary for address space {}".format(
                i, space.name))
            wln(fd)
            print_map_summary(fd, summary, hide_comments, reg_slugs)

        for i, (summary, space, _reg_slugs) in enumerate(spaces, 1):
            wln(fd, "## 2.{} Register description for address space {}".format(
                i, space.name))
            wln(fd)
            print_reg_description(
                fd, summary, "2.{}".format(i), hide_comments, print_reg_drawing
            )


def print_markdown(fd, n, hide_comments=False, print_reg_drawing=True):
    if isinstance(n, tree.Root):
        print_root(fd, n, hide_comments, print_reg_drawing)
    else:
        raise AssertionError
