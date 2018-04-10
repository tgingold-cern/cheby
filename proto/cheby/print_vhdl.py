"""Generate VHDL from HDL tree"""

import hdltree


def w(fd, str):
    fd.write(str)


def wln(fd, str=""):
    w(fd, str)
    w(fd, '\n')


def generate_header(fd, module):
    wln(fd, "library ieee;")
    wln(fd, "use ieee.std_logic_1164.all;")
    wln(fd, "use ieee.numeric_std.all;")
    for d in module.deps:
        wln(fd, "use work.{}.all;".format(d))
    wln(fd)


def generate_type_mark(s):
    return {'L': 'std_logic_vector',
            'U': 'unsigned',
            'S': 'signed'}[s.typ]


def generate_vhdl_type(p):
    if p.size:
        return "{}({} downto 0)".format(generate_type_mark(p), p.size - 1)
    else:
        assert p.typ in 'LI', p.typ
        return {'L': 'std_logic', 'I': 'integer'}[p.typ]


def generate_port(fd, p):
    if p.comment:
        wln(fd)
        wln(fd, "    -- {}".format(p.comment))
    typ = generate_vhdl_type(p)
    if p.dir == 'IN':
        dir = "in   "
    elif p.dir == 'OUT':
        dir = "out  "
    else:
        dir = "inout"
    w(fd, "    {:<32} : {dir} {typ}".format(p.name, dir=dir, typ=typ))


def generate_param(fd, p):
    if p.comment:
        wln(fd, "-- {}".format(p.comment))
    typ = generate_vhdl_type(p)
    w(fd, "        {} : {typ}".format(p.name, typ=typ))
    if p.value:
        w(fd, " := {}".format(generate_expr(p.value)))


def generate_signal(fd, s):
    if s.size:
        typ = generate_vhdl_type(s)
    else:
        typ = "std_logic"
    w(fd, "  signal {:<40} : {typ};\n".format(s.name, typ=typ))


operator = {hdltree.HDLAnd: 'and',
            hdltree.HDLOr:  'or',
            hdltree.HDLNot: 'not',
            hdltree.HDLEq: '='}


def generate_expr(e, nested=False):
    if isinstance(e, hdltree.HDLObject):
        return e.name
    elif isinstance(e, hdltree.HDLBinary):
        res = "{} {} {}".format(generate_expr(e.left, True),
                                operator[type(e)],
                                generate_expr(e.right, True))
        if nested:
            return "({})".format(res)
        else:
            return res
    elif isinstance(e, hdltree.HDLUnary):
        res = "{} {}".format(operator[type(e)], generate_expr(e.expr, True))
        if nested:
            return "({})".format(res)
        else:
            return res
    elif isinstance(e, hdltree.HDLReplicate):
        return "(others => {})".format(generate_expr(e.expr, False))
    elif isinstance(e, hdltree.HDLBit):
        return "'{}'".format(e.val)
    elif isinstance(e, hdltree.HDLUndef):
        return "'X'"
    elif isinstance(e, hdltree.HDLConst):
        if e.size is None or e.size == 1:
            # A bit.
            return "'{}'".format(e.val)

        # Certainly overkill, patches welcome!
        res = '"'
        for i in range(e.size - 1, -1, -1):
            res += '1' if ((e.val >> i) & 1) == 1 else '0'
        res += '"'
        return res
    elif isinstance(e, hdltree.HDLNumber):
        return "{}".format(e.val)
    elif isinstance(e, hdltree.HDLBool):
        if e.val:
            return "true"
        else:
            return "false"
    elif isinstance(e, hdltree.HDLSlice):
        if e.size == 1:
            return "{}({})".format(generate_expr(e.prefix), e.index)
        else:
            return "{}({} downto {})".format(
                generate_expr(e.prefix), e.index + e.size - 1, e.index)
    elif isinstance(e, hdltree.HDLIndex):
        return "{}({})".format(generate_expr(e.prefix), e.index)
    else:
        assert False, "unhandled hdl expr {}".format(e)


def get_base_name(s):
    if isinstance(s, hdltree.HDLObject):
        return s
    elif isinstance(s, hdltree.HDLSlice) or isinstance(s, hdltree.HDLIndex):
        return s.prefix
    else:
        return None


def generate_assign(fd, s):
    base_targ = get_base_name(s.target)
    base_expr = get_base_name(s.expr)
    targ = generate_expr(s.target)
    expr = generate_expr(s.expr)
    if base_expr is not None and base_targ.typ != base_expr.typ:
        wln(fd, "{} <= {}({});".format(
            targ, generate_type_mark(base_targ), expr))
    else:
        wln(fd, "{} <= {};".format(targ, expr))


def generate_seq(fd, s, level):
    indent = '  ' * level
    if isinstance(s, hdltree.HDLAssign):
        w(fd, indent)
        generate_assign(fd, s)
    elif isinstance(s, hdltree.HDLIfElse):
        w(fd, indent)
        wln(fd, "if {} then".format(generate_expr(s.cond)))
        for s1 in s.then_stmts:
            generate_seq(fd, s1, level + 1)
        if s.else_stmts is not None:
            w(fd, indent)
            wln(fd, "else")
            for s1 in s.else_stmts:
                generate_seq(fd, s1, level + 1)
        w(fd, indent)
        wln(fd, "end if;")
    elif isinstance(s, hdltree.HDLSwitch):
        w(fd, indent)
        wln(fd, "case {} is".format(generate_expr(s.expr)))
        for c in s.choices:
            w(fd, indent)
            if isinstance(c, hdltree.HDLChoiceExpr):
                wln(fd, "when {} => ".format(generate_expr(c.expr)))
            elif isinstance(c, hdltree.HDLChoiceDefault):
                wln(fd, "when others =>")
            for s1 in c.stmts:
                generate_seq(fd, s1, level + 1)
        w(fd, indent)
        wln(fd, "end case;")
    elif isinstance(s, hdltree.HDLComment):
        w(fd, indent)
        wln(fd, "-- {}".format(s.comment))
    else:
        assert False, "unhandled hdl seq {}".format(s)


def generate_stmts(fd, stmts, indent):
    sindent = "  " * indent
    gen_num = 0
    for s in stmts:
        if isinstance(s, hdltree.HDLComment):
            wln(fd)
            w(fd, sindent)
            wln(fd, "-- {}".format(s.comment))
        elif isinstance(s, hdltree.HDLAssign):
            w(fd, sindent)
            generate_assign(fd, s)
        elif isinstance(s, hdltree.HDLComb):
            w(fd, sindent)
            w(fd, "process (")
            first = True
            for e in s.sensitivity:
                if first:
                    first = False
                else:
                    w(fd, ", ")
                w(fd, generate_expr(e))
            wln(fd, "  )")
            wln(fd, "  begin")
            for s1 in s.stmts:
                generate_seq(fd, s1, 2)
            wln(fd, "  end process;")
            wln(fd, "  ")
            wln(fd, "  ")
        elif isinstance(s, hdltree.HDLSync):
            wln(fd, sindent + "process ({}, {})".format(generate_expr(s.clk),
                                                        generate_expr(s.rst)))
            wln(fd, sindent + "begin")
            wln(fd, sindent + "  if {} = '0' then ".format(
                generate_expr(s.rst)))
            for s1 in s.rst_stmts:
                generate_seq(fd, s1, indent + 2)
            wln(fd, sindent + "  elsif rising_edge({}) then".format(
                generate_expr(s.clk)))
            for s1 in s.sync_stmts:
                generate_seq(fd, s1, indent + 2)
            wln(fd, sindent + "  end if;")
            wln(fd, sindent + "end process;")
        elif isinstance(s, hdltree.HDLInstance):
            wln(fd, sindent + "{} : {}".format(s.name, s.module_name))

            def generate_map(mapping, indent):
                first = True
                for p, e in mapping:
                    if first:
                        first = False
                    else:
                        wln(fd, ",")
                    w(fd, "  " * indent)
                    w(fd, "  {:<20} => {}".format(p, generate_expr(e)))
                wln()
            if s.params:
                wln(fd, sindent + "  generic map (")
                generate_map(fd, s.params, indent + 1)
                wln(fd, sindent + "  )")
            if s.conns:
                wln(fd, sindent + "  port map (")
                generate_map(fd, s.conns, indent + 1)
                wln(fd, sindent + "  );")
            wln(fd, sindent)
        elif isinstance(s, hdltree.HDLGenIf):
            wln(fd, sindent + "genblock_{}: if ({}) generate".format(
                gen_num, generate_expr(s.cond)))
            generate_stmts(fd, s.stmts, indent + 1)
            wln(fd, sindent + "end generate genblock_{};".format(gen_num))
            gen_num += 1
        else:
            assert False, "unhandled hdl stmt {}".format(s)


def print_vhdl(fd, module):
    generate_header(fd, module)
    wln(fd, "entity {} is".format(module.name))

    def _generate_inters(lst, name, gen_el):
        if lst:
            wln(fd, "  {} (".format(name))
            first = True
            for p in lst:
                if first:
                    first = False
                else:
                    wln(fd, ";")
                gen_el(fd, p)
            if name == "port":
                wln(fd)
            else:
                w(fd, "  ")
            wln(fd, "  );")
    _generate_inters(module.params, "generic", generate_param)
    _generate_inters(module.ports, "port", generate_port)
    wln(fd, "end {};".format(module.name))
    wln(fd)
    wln(fd, "architecture syn of {} is".format(module.name))
    for s in module.signals:
        generate_signal(fd, s)
    wln(fd)
    wln(fd, "begin")
    generate_stmts(fd, module.stmts, 1)
    wln(fd, "end syn;")
