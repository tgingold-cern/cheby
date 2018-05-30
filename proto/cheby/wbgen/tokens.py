"""WBgen tokens (a small subset of LUA tokens)."""

EOF = 0
LBRACE = 1
RBRACE = 2
NUMBER = 3
STRING = 4
NAME = 5
EQUAL = 6
SEMICOLON = 7
COMMA = 8

tok_name = {v: n for n, v in globals().items() if isinstance(v, int)}
