#! /usr/bin/env python
import sys
import os.path
import wbgen.parser
import wbgen.ltree2tree
import wbgen.field_layout
import wbgen.layout
import wbgen.expand_reg
import wbgen.print_cheby_yaml


def convert(stream, filename):
    lt = wbgen.parser.parse(filename, open(filename).readline)

    t = wbgen.ltree2tree.convert(lt)
    wbgen.field_layout.field_layout(t)

    wbgen.expand_reg.expand(t)
    wbgen.layout.layout(t)
    wbgen.print_cheby_yaml.print_cheby(stream, t, False)


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: wbgen2cheby FILE\n")
        sys.exit(2)
    filename = sys.argv[1]
    (_, ext) = os.path.splitext(filename)
    if ext != '.wb':
        sys.stderr.write("unhandled file format '{}'\n".format(ext))
        sys.exit(1)
    convert(sys.stdout, filename)
    sys.exit(0)


if __name__ == "__main__":
    main()
