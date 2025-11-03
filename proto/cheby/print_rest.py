import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import w, wln

# https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html


def format_text(text):
    return text.replace("\n", "\n  ")


def wtable(fd, table):
    lens = [len(x) for x in table[0]]
    for j in range(1, len(table)):
        for i, _ in enumerate(lens):
            lens[i] = max(lens[i], len(table[j][i]))
    wln(fd, '+' + ''.join('-' * (l + 2) + '+' for l in lens))
    for l in table:
        cnt = ''
        for i, v in enumerate(lens):
            if l[i] == '\0':
                cnt += ' ' * (v + 3)
            else:
                cnt += '| ' + l[i].ljust(v) + ' '
        wln(fd, cnt + '|')
        wln(fd, '+' + ''.join('-' * (l + 2) + '+' for l in lens))


def print_reg(fd, r, raw, heading, hide_comments=False, print_reg_drawing=True):
    ACCESSES = {
        "rw": "read/write",
        "wo": "write-only",
        "ro": "read-only",
    }

    # Description of Register
    title = "Register: {}".format(raw.name)
    wln(fd, title)
    wln(fd, heading * len(title))
    wln(fd)

    wln(fd, "* HW Prefix: {}".format(r.c_name))
    wln(fd, "* HW Address: 0x{:x}".format(raw.abs_addr))
    wln(fd, "* C Prefix: {}".format(raw.name))
    wln(fd, "* C Block Offset: 0x{:x}".format(r.c_address))
    wln(fd, "* Access: {}".format(ACCESSES[r.access]))
    wln(fd)

    if r.comment and not hide_comments:
        wln(fd, r.comment)
        wln(fd)

    if r.description:
        wln(fd, r.description)
        wln(fd)

    if print_reg_drawing:
        descr = gen_doc.build_regdescr_table(r)
        # Compute the max size of cells
        sz = 2  # Room for at least 2 digits
        for desc_raw in descr:
            for col in desc_raw:
                sz = max(sz, (len(col.content) + col.colspan - 1) // col.colspan)
        wln(fd, '+' + ('-' * (sz + 0) + '+') * 8)
        for desc_raw in descr:
            for col in desc_raw:
                w(fd, '|' + col.content.rjust((sz + 1) * col.colspan - 1))
            wln(fd, '|')
            wln(fd, '+' + ('-' * (sz + 0) + '+') * 8)
        wln(fd)

    if r.has_fields():
        for f in r.children:
            wln(fd, f.name)

            not_documented = True
            if f.comment and not hide_comments:
                wln(fd, "  {}".format(format_text(f.comment)))
                not_documented = False

            if f.description:
                if f.comment and not hide_comments:
                    wln(fd)
                wln(fd, "  {}".format(format_text(f.description)))
                not_documented = False

            if not_documented:
                wln(fd, "  (not documented)")

        wln(fd)


def print_map_summary(fd, summary):
    t = [["HW address", "Type", "Name", "HDL Name"]]
    for r in summary.raws:
        t.append(["{}".format(r.address),
                  "{}".format(r.typ),
                  "{}".format(r.name),
                  "{}".format(r.node.c_name)])
    wtable(fd, t)
    wln(fd)


def print_reg_description(fd, summary, heading, hide_comments=False, print_reg_drawing=True):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            print_reg(fd, r, ra, heading, hide_comments, print_reg_drawing)


def print_root(fd, root, heading, hide_comments=False, print_reg_drawing=True):
    title = "Memory Map Summary"
    wln(fd, heading[0] * len(title))
    wln(fd, title)
    wln(fd, heading[0] * len(title))
    wln(fd)

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

        title = "Registers Description"
        wln(fd, title)
        wln(fd, heading[1] * len(title))
        wln(fd)
        print_reg_description(fd, summary, heading[2], hide_comments, print_reg_drawing)
    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            title = "For Space {}".format(space.name)
            wln(fd, title)
            wln(fd, heading[1] * len(title))
            wln(fd)
            print_map_summary(fd, summary)
        for summary, space in summaries:
            title = "Registers Description for Space {}\n".format(space.name)
            wln(fd, title)
            wln(fd, heading[1] * len(title))
            wln(fd)
            print_reg_description(fd, summary, heading[2], hide_comments, print_reg_drawing)


def print_rest(fd, n, heading="#=-", hide_comments=False, print_reg_drawing=True):
    if isinstance(n, tree.Root):
        print_root(fd, n, heading, hide_comments, print_reg_drawing)
    else:
        raise AssertionError
