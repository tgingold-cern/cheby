import cheby.tree as tree
import cheby.gen_doc as gen_doc

#  Generate markdown (asciidoc variant)
#  Ref: https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/#tables


def w(fd, str):
        fd.write(str)


def wln(fd, str=""):
    fd.write(str)
    fd.write('\n')

def wtable(fd, table):
    lens=[len(x) for x in table[0]]
    for j in range(1, len(table)):
        for i in range(len(lens)):
            lens[i] = max(lens[i], len(table[j][i]))
    wln(fd, '+' + ''.join('-' * (l + 2) + '+' for l in lens))
    for l in table:
        cnt = ''
        for i in range(len(lens)):
            if l[i] == '\0':
                cnt += ' ' * (lens[i] + 3)
            else:
                cnt += '| ' + l[i].ljust(lens[i]) + ' '
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
            sz = max(sz, (len(col.content) + col.colspan - 1) / col.colspan)
    wln(fd, '+' + ('-' * (sz + 0) + '+') * 8)
    for desc_raw in descr:
        for col in desc_raw:
            w(fd, '|' + col.content.rjust((sz + 1) * col.colspan - 1))
        wln(fd, '|')
        wln(fd, '+' + ('-' * (sz + 0) + '+') * 8)
    wln(fd)

    if r.has_fields():
        t = []
        for f in r.children:
            wln(fd, f.name)
            wln(fd, "  {}".format(f.comment or f.description or '(not documented)'))
        wln(fd)


def print_root(fd, root):
    wln(fd, "##################")
    wln(fd, "Memory map summary")
    wln(fd, "##################")
    wln(fd)
    wln(fd, root.description)
    wln(fd)

    t = [["HW address", "Type", "Name", "HDL name"]]
    summary = gen_doc.MemmapSummary(root)
    for r in summary.raws:
        t.append(["{}".format(r.address), "{}".format(r.typ), "{}".format(r.name), "{}".format(r.node.c_name)])
    wtable(fd, t)
    wln(fd)

    wln(fd, "Registers description")
    wln(fd, "=====================")
    for ra in summary.raws:
        r = ra.node
        if isinstance(r, tree.Reg):
            wln(fd, "{}".format(ra.name))
            wln(fd, "-" * len(ra.name))
            wln(fd)
            print_reg(fd, r, ra.abs_addr)


def print_rest(fd, n):
    assert isinstance(n, tree.Root)
    print_root(fd, n)
