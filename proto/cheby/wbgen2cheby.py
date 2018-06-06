#! /usr/bin/env python
import sys
import os.path
import argparse
import cheby.wbgen.parser
import cheby.wbgen.ltree2tree
import cheby.wbgen.field_layout
import cheby.wbgen.layout
import cheby.wbgen.expand_reg
import cheby.wbgen.print_cheby_yaml


def convert(stream, filename):
    lt = cheby.wbgen.parser.parse(filename, open(filename).readline)

    t = cheby.wbgen.ltree2tree.convert(lt)
    cheby.wbgen.field_layout.field_layout(t)

    cheby.wbgen.expand_reg.expand(t)
    cheby.wbgen.layout.layout(t)
    cheby.wbgen.print_cheby_yaml.print_cheby(stream, t, False)


def main():
    aparser = argparse.ArgumentParser(description='wbgen to cheby converter')
    aparser.add_argument('FILE')
    args = aparser.parse_args()

    filename = args.FILE
    (_, ext) = os.path.splitext(filename)
    if ext != '.wb':
        sys.stderr.write("unhandled file format '{}'\n".format(ext))
        sys.exit(1)
    convert(sys.stdout, filename)
    sys.exit(0)


if __name__ == "__main__":
    main()
