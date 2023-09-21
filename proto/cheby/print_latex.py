import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import w, wln
from pathlib import Path
import re

# Generate Latex Documentation
#
# Note: Python requires that '\' be escaped as '\\' and
# curly brackets need to be repeated when using format().


def escape_printable(text):
    # Remove whitespaces at start and end of string
    text = text.strip()

    # Escape special characters
    SPECIAL_CHARS = ['\\', '&', '%', '$', '#', '_', '{', '}', '~', '^']
    for char in SPECIAL_CHARS:
        text = text.replace(char, '\\' + char)

    # Allow line breaks after '_' and '.' in long strings
    ALLOW_BREAK_CHARS = ['.', '_']
    for char in ALLOW_BREAK_CHARS:
        text = text.replace(char, char + '\\allowbreak{}')

    return text


def print_reg(fd, r, raw, print_reg_drawing):

    # Register Summary
    wln(fd, "\\begin{regsummary}")
    wln(fd, "HW Prefix & {}\\\\".format(escape_printable(r.c_name)))
    wln(fd, "HW Address & 0x{:x}\\\\".format(raw.abs_addr))
    wln(fd, "C Prefix & {}\\\\".format(escape_printable(raw.name)))
    wln(fd, "C Block Offset & 0x{:x}\\\\".format(r.c_address))
    wln(fd, "\\end{regsummary}\n")

    # Register description
    # Print only if available and register contains fields
    if r.description is not None and r.has_fields():
        desc = escape_printable(r.description)

        pattern = r"(\S+)\n(\S+)"
        replacement = r"\1 \\\\\n\2"
        desc = re.sub(pattern, replacement, desc)

        wln(fd, "{desc}\n".format(desc=desc))

    # Drawing of contents
    if print_reg_drawing:
        descr = gen_doc.build_regdescr_table(r)
        wln(fd, "\\begin{regdraw}")
        for desc_raw in descr:
            for i, col in enumerate(desc_raw):
                style = ''
                if col.style == 'field':
                    style = 'bg=lightgray'

                if col.colspan > 1:
                    w(fd, "\\SetCell[c={}]{{c, {}}} ".format(col.colspan, style))
                elif style != '':
                    w(fd, "\\SetCell{{{}}} ".format(style))

                w(fd, "{} ".format(escape_printable(col.content)))
                if i < len(desc_raw) - 1:
                    w(fd, "& ")
            wln(fd, '\\\\')
        wln(fd, "\\end{regdraw}\n")

    # Description of bit ranges in register
    wln(fd, "\\begin{regdesc}")

    for f in r.children:
        if r.has_fields():
            desc_src = f
        else:
            desc_src = r

        # Bit range
        if f.hi is not None:
            w(fd, '{}:{} & '.format(f.hi, f.lo))
        else:
            w(fd, '{} & '.format(f.lo))

        # Access
        w(fd, '{} & '.format(r.access or ''))

        # Name
        w(fd, '{} & '.format(escape_printable(desc_src.name)))

        # Description + comment
        desc = desc_src.description or ''
        if desc_src.comment is not None:
            desc += '\n\n' + desc_src.comment

        desc = escape_printable(desc)
        desc = desc.replace('\n', ' \\newline ')

        w(fd, '{{{}}}'.format(desc))
        wln(fd, '\\\\')

    wln(fd, "\\end{regdesc}\n\n")


def print_map_summary(fd, summary):
    wln(fd, "\\begin{memmap}")
    for r in summary.raws:
        w(fd, "{} & ".format(r.address))
        w(fd, "{} & ".format(r.typ))
        if isinstance(r.node, tree.Reg):
            w(fd, "\\hyperref[sec:{}]{{{}}} & ".format(r.name, escape_printable(r.name)))
        else:
            w(fd, "{} & ".format(escape_printable(r.name)))
        w(fd, "{}".format(escape_printable(r.node.c_name)))
        wln(fd, '\\\\')
    wln(fd, "\\end{memmap}")
    wln(fd)


def print_reg_description(fd, summary, print_reg_drawing):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "\\subsubsection{{{}}}".format(escape_printable(ra.name)))
            wln(fd, '\\label{{sec:{}}}'.format(ra.name))
            print_reg(fd, r, ra, print_reg_drawing)


def print_root(fd, root, print_reg_drawing):
    wln(fd, "\\section{Memory Map Summary}")
    wln(fd, root.description or '(no description)')
    wln(fd)
    if root.version is not None:
        wln(fd, "Version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        print_map_summary(fd, summary)
        wln(fd, "\\section{Register Description}")
        print_reg_description(fd, summary, print_reg_drawing)
    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            wln(fd, "\\subsection{{For Space {}}}".format(escape_printable(space.name)))
            print_map_summary(fd, summary)
        for summary, space in summaries:
            wln(fd, "\\subsection{{Register Description for Space {}}}".format(escape_printable(space.name)))
            wln(fd)
            print_reg_description(fd, summary, print_reg_drawing)


def print_latex(fd, n, print_reg_drawing=True):
    # Print latex documentation of root n to file descriptor fd

    if isinstance(n, tree.Root):
        print_root(fd, n, print_reg_drawing)
    else:
        raise AssertionError


def copy_template(fd_target):
    # Copy the template for the main file to the directory of the register file

    # Path of template source is relative to the executed script
    path_source = Path(__file__).parent / 'data' / 'main_template.tex'

    # Copy file
    with open(path_source, 'r') as fd_source:
        fd_target.write(fd_source.read())
