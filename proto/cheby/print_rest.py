import cheby.tree as tree
import cheby.gen_doc as gen_doc
from cheby.wrutils import w, wln

# https://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html


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


def print_reg(fd, r, abs_addr):
    wln(fd)
    w(fd, "* HDL name:")
    wln(fd, "  {}".format(r.c_name))
    w(fd, "* address:")
    wln(fd, "  0x{:x}".format(abs_addr))
    w(fd, "* block offset:")
    wln(fd, "  0x{:x}".format(r.c_address))
    w(fd, "* access mode:")
    wln(fd, "  {}".format(r.access))
    wln(fd)
    if r.description:
        wln(fd, r.description)
        wln(fd)
    descr = gen_doc.build_regdescr_table(r)
    wln(fd)
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
            wln(fd, "  {}".format(f.description or "(not documented)"))
        wln(fd)


def print_map_summary(fd, summary):
    t = [["HW address", "Type", "Name", "HDL name"]]
    for r in summary.raws:
        t.append(["{}".format(r.address),
                  "{}".format(r.typ),
                  "{}".format(r.name),
                  "{}".format(r.node.c_name)])
    wtable(fd, t)
    wln(fd)


def print_reg_description(fd, summary, heading):
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "{}".format(ra.name))
            wln(fd, heading * len(ra.name))
            wln(fd)
            print_reg(fd, r, ra.abs_addr)


def print_root(fd, root, heading):
    title = "Memory map summary"
    wln(fd, heading[0] * len(title))
    wln(fd, title)
    wln(fd, heading[0] * len(title))
    wln(fd)
    if root.description is not None:
        wln(fd, root.description)
        wln(fd)
    if root.version is not None:
        wln(fd, "version: {}".format(root.version))
        wln(fd)

    if root.c_address_spaces_map is None:
        summary = gen_doc.MemmapSummary(root)
        print_map_summary(fd, summary)

        title = "Registers description"
        wln(fd, title)
        wln(fd, heading[1] * len(title))
        print_reg_description(fd, summary, heading[2])
    else:
        summaries = [(gen_doc.MemmapSummary(space), space) for space in root.children]
        for summary, space in summaries:
            title = "For space {}".format(space.name)
            wln(fd, title)
            wln(fd, heading[1] * len(title))
            print_map_summary(fd, summary)
        for summary, space in summaries:
            title = "Registers description for space {}\n".format(space.name)
            wln(fd, title)
            wln(fd, heading[1] * len(title))
            print_reg_description(fd, summary, heading[2])

def print_rest(fd, n, heading="#=-"):
    assert isinstance(n, tree.Root)
    print_root(fd, n, heading)
