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

    def pp_str(self, name, s):
        if s is None:
            return
        self.pp_indent()
        self.pp_raw("{}: {}\n".format(name, s))


@PrettyPrinter.register(tree.NamedNode)
def pprint_named(pp, n):
    pp.pp_str('name', n.name)
    pp.pp_str('description', n.description)
    pp.pp_str('comment', n.comment)


@PrettyPrinter.register(tree.Field)
def pprint_field(pp, n):
    pp.pp_obj('field')
    pprint_named(pp, n)
    if n.hi is None:
        pp.pp_str('range', "{}".format(n.lo))
    else:
        pp.pp_str('range', "{}-{}".format(n.hi, n.lo))
    pp.pp_str('preset', n.preset)
    pp.pp_endobj()


@PrettyPrinter.register(tree.Reg)
def pprint_reg(pp, n):
    pp.pp_obj('reg')
    pprint_named(pp, n)
    pp.pp_str('width', n.width)
    pp.pp_str('type', n.type)
    pp.pp_str('access', n.access)
    pp.pp_str('address', n.address)
    if len(n.fields) == 1 and isinstance(n.fields[0], tree.FieldReg):
        pp.pp_str('preset', n.preset)
    elif n.fields:
        pp.pp_list('fields')
        for el in n.fields:
            pprint_field(pp, el)
        pp.pp_endlist()
    pp.pp_endobj()


@PrettyPrinter.register(tree.Block)
def pprint_block(pp, n):
    pp.pp_obj('block')
    pp.pp_str('submap_file', n.submap_file)
    pp.pp_str('interface', n.interface)
    pprint_complex(pp, n)
    pp.pp_endobj()


@PrettyPrinter.register(tree.Array)
def pprint_array(pp, n):
    pp.pp_obj('array')
    pp.pp_str('repeat', n.repeat)
    pprint_complex(pp, n)
    pp.pp_endobj()


@PrettyPrinter.register(tree.ComplexNode)
def pprint_complex(pp, n):
    pp.pp_str('address', n.address)
    pp.pp_str('align', n.align)
    pp.pp_str('size', n.size)
    pprint_composite(pp, n)


@PrettyPrinter.register(tree.CompositeNode)
def pprint_composite(pp, n):
    pprint_named(pp, n)
    if n.elements:
        pp.pp_list('elements')
        for el in n.elements:
            pp.visit(el)
        pp.pp_endlist()


@PrettyPrinter.register(tree.Root)
def pprint_root(pp, n):
    pp.pp_str('bus', n.bus)
    pprint_composite(pp, n)


def pprint_cheby(fd, root):
    pp = PrettyPrinter(fd)
    pp.visit(root)
