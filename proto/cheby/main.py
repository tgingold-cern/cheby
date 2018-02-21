#!/usr/bin/env python
import sys
import argparse
import parser
import pprint
import sprint
import layout


def main():
    aparser = argparse.ArgumentParser(description='cheby utility')
    aparser.add_argument('--pretty-print', action='store_true',
                         help='display the input in YAML')
    aparser.add_argument('--simple-print', action='store_true',
                         help='display the layout with fields')
    aparser.add_argument('--memmap-print', action='store_true',
                         help='display the layout without fields')
    aparser.add_argument('FILE', nargs='+')

    args = aparser.parse_args()
    for f in args.FILE:
        try:
            t = parser.parse_yaml(f)
        except parser.ParseException as e:
            sys.stderr.write("{}:parse error: {}\n".format(f, e.msg))
            sys.exit(2)

        try:
            layout.layout_cheby(t)
        except layout.LayoutException as e:
            sys.stderr.write("{}:layout error: {}\n".format(f, e.msg))
            sys.exit(2)
        if args.pretty_print:
            pprint.pprint_cheby(sys.stdout, t)
        if args.memmap_print:
            sprint.sprint_cheby(sys.stdout, t, False)
        if args.simple_print:
            sprint.sprint_cheby(sys.stdout, t, True)


if __name__ == '__main__':
    main()
