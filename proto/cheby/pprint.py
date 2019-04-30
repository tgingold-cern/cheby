import cheby.tree as tree


class PrettyPrinter(tree.Visitor):
    def __init__(self, fd):
        self.fd = fd
        self.indent = ['']

    def pp_raw(self, str):
        self.fd.write(str)

    def pp_indent(self):
        self.pp_raw(self.indent[-1])

    def pp_list(self, name):
        self.pp_indent()
        self.pp_raw(name + ':\n')
        self.indent.append(' ' * len(self.indent[-1]) + '  - ')

    def pp_endlist(self):
        self.indent.pop()

    def pp_obj(self, name):
        self.pp_indent()
        self.pp_raw(name + ':\n')
        self.indent.append(' ' * len(self.indent[-1]) + '  ')

    def pp_endobj(self):
        self.indent.pop()

    def pp_int(self, name, s):
        if s is None:
            return
        self.pp_indent()
        self.pp_raw("{}: {}\n".format(name, s))

    def pp_bool(self, name, s):
        self.pp_int(name, s)

    def pp_hex(self, name, s):
        if s is None:
            return
        self.pp_indent()
        self.pp_raw("{}: 0x{:x}\n".format(name, s))

    trans = {"'": "''", "\n": r"\n", ":": r"\:"}

    def pp_str(self, name, s):
        if s is None:
            return
        self.pp_indent()
        if any(c in s for c in "'[]\n:"):
            s = "'" + ''.join([self.trans.get(c, c) for c in s]) + "'"
        elif s.lower() in ['on', 'off', 'false', 'true']:
            s = "'" + s + "'"
        self.pp_raw("{}: {}\n".format(name, s))


def pprint_extension(pp, name, n):
    if isinstance(n, dict):
        if len(n) == 0:
            # Discard empty dict.
            return
        pp.pp_obj(name)
        for k in sorted(n):
            v = n[k]
            pprint_extension(pp, k, v)
        pp.pp_endobj()
    elif isinstance(n, list):
        pp.pp_list(name + 's')
        for e in n:
            pprint_extension(pp, name, e)
        pp.pp_endlist()
    elif isinstance(n, str):
        pp.pp_str(name, n)
    elif isinstance(n, bool):
        pp.pp_bool(name, n)
    elif isinstance(n, int):
        pp.pp_int(name, n)
    else:
        raise AssertionError(n)


def pprint_extensions(pp, n):
    for name in ['x-gena',
                 'x-hdl',
                 'x-fesa',
                 'x-driver-edge',
                 'x-conversions',
                 'x-cern-info']:
        attr = name.replace('-', '_')
        if hasattr(n, attr):
            pprint_extension(pp, name, getattr(n, attr))


def pprint_address(pp, n):
    if n.address is None:
        pass
    elif n.address == 'next':
        pp.pp_str('address', 'next')
    else:
        pp.pp_hex('address', n.address)


@PrettyPrinter.register(tree.NamedNode)
def pprint_named(pp, n):
    pp.pp_str('name', n.name)
    pp.pp_str('description', n.description)
    pp.pp_str('comment', n.comment)
    pp.pp_str('note', n.note)


@PrettyPrinter.register(tree.Field)
def pprint_field(pp, n):
    pp.pp_obj('field')
    pprint_named(pp, n)
    if n.hi is None:
        pp.pp_str('range', "{}".format(n.lo))
    else:
        pp.pp_str('range', "{}-{}".format(n.hi, n.lo))
    pp.pp_hex('preset', n.preset)
    pprint_extensions(pp, n)
    pp.pp_endobj()


@PrettyPrinter.register(tree.Reg)
def pprint_reg(pp, n):
    pp.pp_obj('reg')
    pprint_named(pp, n)
    pp.pp_int('width', n.width)
    pp.pp_str('type', n.type)
    pp.pp_str('access', n.access)
    pprint_address(pp, n)
    has_one = not n.has_fields()
    if has_one:
        pp.pp_hex('preset', n.preset)
    pprint_extensions(pp, n)
    if not has_one and n.children:
        pp.pp_list('children')
        for el in n.children:
            pprint_field(pp, el)
        pp.pp_endlist()
    pp.pp_endobj()


@PrettyPrinter.register(tree.Block)
def pprint_block(pp, n):
    pp.pp_obj('block')
    pprint_complex_head(pp, n)
    pprint_complex_tail(pp, n)
    pp.pp_endobj()


@PrettyPrinter.register(tree.Submap)
def pprint_submap(pp, n):
    pp.pp_obj('submap')
    pprint_complex_head(pp, n)
    pp.pp_str('filename', n.filename)
    pp.pp_str('interface', n.interface)
    pprint_complex_tail(pp, n)
    pp.pp_endobj()


@PrettyPrinter.register(tree.Array)
def pprint_array(pp, n):
    pp.pp_obj('array')
    pprint_complex_head(pp, n)
    pp.pp_int('repeat', n.repeat)
    pprint_complex_tail(pp, n)
    pp.pp_endobj()


def pprint_complex_head(pp, n):
    pprint_composite_head(pp, n)
    pprint_address(pp, n)
    pp.pp_bool('align', n.align)
    pp.pp_int('size', n.size)


def pprint_complex_tail(pp, n):
    pprint_composite_tail(pp, n)


def pprint_composite_head(pp, n):
    pprint_named(pp, n)


def pprint_composite_tail(pp, n):
    pprint_extensions(pp, n)
    if n.children:
        pp.pp_list('children')
        for el in n.children:
            pp.visit(el)
        pp.pp_endlist()


@PrettyPrinter.register(tree.Root)
def pprint_root(pp, n):
    pp.pp_obj('memory-map')
    pprint_composite_head(pp, n)
    pp.pp_str('bus', n.bus)
    pp.pp_int('size', n.size)
    pprint_composite_tail(pp, n)
    pp.pp_endobj()


def pprint_cheby(fd, root):
    pp = PrettyPrinter(fd)
    pp.visit(root)
