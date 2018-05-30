"""LUA tree (low-level one)"""


class Literal(object):
    def __init__(self, val):
        self._val = val


class LitNumeral(Literal):
    pass


class LitString(Literal):
    pass


class LitName(Literal):
    pass


class LitTable(Literal):
    pass


class Decl(object):
    def __init__(self, name, val, comment):
        self._name = name
        self._val = val
        self._comment = comment


class Table(Decl):
    pass


class Field(Decl):
    pass
