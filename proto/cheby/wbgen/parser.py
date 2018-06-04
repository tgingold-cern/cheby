import tokens
import tokenize
import ltree


class ParseError(Exception):
    pass


class LookAhead(object):
    def __init__(self, gen):
        self._gen = gen
        self._next = None

    def next(self):
        if self._next is not None:
            res = self._next
            self._next = None
            return res
        else:
            return self._gen.next()

    def unget(self, val):
        assert self._next is None
        self._next = val


def gather_comments(comment):
    if not comment:
        return None
    pre_comment = '\n'.join(comment)
    del comment[:]
    return pre_comment


def parse_expr(it, comment):
    (t, v, p) = it.next()
    if t == tokens.NUMBER:
        val = ltree.LitNumeral(v)
    elif t == tokens.STRING:
        val = ltree.LitString(v)
    elif t == tokens.NAME:
        (t1, v1, p1) = it.next()
        if t1 == tokens.LBRACE:
            pre_comment = gather_comments(comment)
            val = ltree.Table(
                v, parse_tableconstructor(it, comment), pre_comment)
        else:
            it.unget((t1, v1, p1))
            val = ltree.LitName(v)
    elif t == tokens.LBRACE:
        val = ltree.LitTable(parse_tableconstructor(it, comment))
    else:
        raise ParseError("expression expected at {}:{}".format(
                         p[0], p[1]))
    return val


def parse_tableconstructor(it, comment):
    """Parse '{' [fieldlist] '}'
       fieldlist ::= field { fieldsep field } [ fieldsep ]
       The last token before the call was '{'."""
    fields = []
    while True:
        # Parse a field
        # field ::= Name '=' exp | exp
        (t, name, p) = it.next()
        pre_comment = gather_comments(comment)
        if t == tokens.NAME:
            (t1, v1, p1) = it.next()
            if t1 == tokens.EQUAL:
                val = parse_expr(it, comment)
                f = ltree.Field(name, val, pre_comment)
            elif t1 == tokens.LBRACE:
                f = ltree.Table(
                    name, parse_tableconstructor(it, comment), pre_comment)
            else:
                it.unget((t1, v1, p1))
                f = ltree.LitName(name)
        elif t == tokens.RBRACE:
            break
        else:
            it.unget((t, name, p))
            f = parse_expr(it, comment)
        fields.append(f)

        # Separator
        (t, v, p) = it.next()
        if t == tokens.COMMA or t == tokens.SEMICOLON:
            (t, v, p) = it.next()
            if t == tokens.RBRACE:
                break
            else:
                it.unget((t, v, p))
        elif t == tokens.RBRACE:
            break
        else:
            raise ParseError("',' or ';' expected at {}:{}".format(
                             p[0], p[1]))
    return fields


def parse_stmt(it, comment):
    (t, name, p) = it.next()
    if t != tokens.NAME:
        raise ParseError(
            "name expected for a statement at {}:{}".format(
                p[0], p[1]))
    pre_comment = gather_comments(comment)
    (s, v, p) = it.next()
    if s == tokens.LBRACE:
        return ltree.Table(
            name, parse_tableconstructor(it, comment), pre_comment)
    elif s == tokens.EQUAL:
        # Discard the name
        return parse_expr(it, pre_comment)
    else:
        raise ParseError(
            "expression expected after name at {}:{}".format(
                p[0], p[1]))


def parse(filename, readline):
    comment = []
    it = LookAhead(tokenize.generate_tokens(filename, readline, comment))
    res = parse_stmt(it, comment)
    (t, v, p) = it.next()
    if t == tokens.SEMICOLON:
        # Ending semicolon is optional.
        (t, v, p) = it.next()
    if t != tokens.EOF:
        raise ParseError("garbage at end of file ({}:{})".format(p[0], p[1]))
    return res
