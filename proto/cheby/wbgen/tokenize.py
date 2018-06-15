import cheby.wbgen.tokens as tokens
import sys


class TokenError(Exception):
    pass


def _is_ident(c):
    if c.isalnum():
        return True
    if c == '_':
        return True
    return False


def _is_xdigit(c):
    return c in "0123456789abcdefABCDEF"


def generate_tokens(filename, readline, comment):
    lineno = 0
    while True:
        line = readline()
        if line == '':
            yield (tokens.EOF, None, (lineno, 0))
        lineno += 1
        line = line.rstrip('\r\n')
        pos = 0
        max = len(line)

        while pos < max:
            tok_pos = pos
            c = line[pos]
            p = (lineno, pos)
            if c.isspace():
                pass
            elif c.isalpha():
                pos += 1
                # Aggregate all alnum characters
                while pos < max and _is_ident(line[pos]):
                    pos += 1
                pos -= 1
                yield (tokens.NAME, line[tok_pos:pos + 1], p)
            elif c == '"':
                pos += 1
                start = pos
                res = ""
                while True:
                    while pos < max and line[pos] != '"':
                        pos += 1
                    if pos < max:
                        res += line[start:pos]
                        break
                    if max >= 1 and line[max - 1] == '\\':
                        res += line[start:pos - 1] + '\n'
                        line = readline()
                        if line == '':
                            raise TokenError("missing end of string")
                        lineno += 1
                        line = line.rstrip('\r\n')
                        start = 0
                        pos = 0
                        max = len(line)
                    else:
                        raise TokenError(
                            "missing end of string at {}:{}".format(
                                lineno, pos))
                res = res.replace(r'\n', '\n').\
                    replace(r'\ ', ' ').replace(r'\\', '\\')
                yield (tokens.STRING, res, p)
            elif c == '{':
                yield (tokens.LBRACE, None, p)
            elif c == '}':
                yield (tokens.RBRACE, None, p)
            elif c == '=':
                yield (tokens.EQUAL, None, p)
            elif c == ';':
                yield (tokens.SEMICOLON, None, p)
            elif c == ',':
                yield (tokens.COMMA, None, p)
            elif c == '-' and pos + 1 < max and line[pos + 1] == '-':
                # A comment
                if pos + 3 < max and line[pos + 2: pos + 4] == '[[':
                    # A block comment
                    pos += 4
                    cpos = pos
                    while True:
                        if pos == max:
                            comment.append(line[cpos:pos])
                            # Read next line
                            line = readline()
                            if line == '':
                                raise TokenError(
                                    "missing end of block comment")
                            lineno += 1
                            line = line.rstrip('\r\n')
                            pos = 0
                            cpos = 0
                            max = len(line)
                        if pos + 1 < max and line[pos:pos + 2] == ']]':
                            comment.append(line[cpos:pos])
                            pos += 2
                            break
                        pos += 1
                else:
                    # line comment
                    comment.append(line[pos + 2:max])
                    pos = max
                break
            elif c.isdigit() or c == '-':
                pos += 1
                # Aggregate all alnum characters
                if pos < max and line[pos] in "xX":
                    # Hex string
                    pos += 1
                    while pos < max and _is_xdigit(line[pos]):
                        pos += 1
                else:
                    while pos < max and line[pos].isdigit():
                        pos += 1
                pos -= 1
                yield (tokens.NUMBER, line[tok_pos:pos + 1], p)
            else:
                raise TokenError(
                    "unknown token '{}' at {}:{}".format(
                        c, lineno, tok_pos))
            pos += 1
