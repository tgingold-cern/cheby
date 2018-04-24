#!/usr/bin/env python
import sys
import argparse
import cheby.parser
import cheby.pprint as pprint
import cheby.sprint as sprint
import cheby.cprint as cprint
import cheby.gen_laychk as gen_laychk
import cheby.layout as layout
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.print_encore as print_encore
import cheby.expand_hdl as expand_hdl


def decode_args():
    aparser = argparse.ArgumentParser(description='cheby utility')
    aparser.add_argument('--print-pretty', action='store_true',
                         help='display the input in YAML')
    aparser.add_argument('--print-simple', action='store_true',
                         help='display the layout with fields')
    aparser.add_argument('--print-simple-expanded', action='store_true',
                         help='display the expanded layout with fields')
    aparser.add_argument('--print-memmap', action='store_true',
                         help='display the layout without fields')
    aparser.add_argument('--print-c', action='store', nargs='?', const='.',
                         help='display the c header file')
    aparser.add_argument('--print-c-check-layout', action='store_true',
                         help='generate c file to check layout of the header')
    aparser.add_argument('--gen-vhdl', action='store_true',
                         help='generate vhdl file')
    aparser.add_argument('--gen-encore', action='store_true',
                         help='generate encore file')
    aparser.add_argument('FILE', nargs='+')

    return aparser.parse_args()


def handle_file(args, filename):
    t = cheby.parser.parse_yaml(filename)

    layout.layout_cheby(t)

    if args.print_pretty:
        pprint.pprint_cheby(sys.stdout, t)
    if args.print_memmap:
        sprint.sprint_cheby(sys.stdout, t, False)
    if args.print_simple:
        sprint.sprint_cheby(sys.stdout, t, True)
    if args.print_c is not None:
        if args.print_c == '-':
            cprint.cprint_cheby(sys.stdout, t)
        else:
            if args.print_c == '.':
                name = t.name + '.h'
            else:
                name = args.print_c
            fd = open(name, 'w')
            cprint.cprint_cheby(fd, t)
            fd.close()
    if args.print_c_check_layout:
        gen_laychk.gen_chklayout_cheby(sys.stdout, t)
    if args.gen_encore:
        print_encore.print_encore(sys.stdout, t)
    # Decode x-hdl
    expand_hdl.expand_hdl(t)
    if args.print_simple_expanded:
        sprint.sprint_cheby(sys.stdout, t, True)
    if args.gen_vhdl:
        if False:
            pprint.pprint_cheby(sys.stdout, t)
        h = gen_hdl.generate_hdl(t)
        print_vhdl.print_vhdl(sys.stdout, h)


def main():
    args = decode_args()
    for f in args.FILE:
        try:
            handle_file(args, f)
        except cheby.parser.ParseException as e:
            sys.stderr.write("{}:parse error: {}\n".format(f, e.msg))
            sys.exit(2)
        except layout.LayoutException as e:
            sys.stderr.write("{}:layout error: {}\n".format(f, e.msg))
            sys.exit(2)
        except gen_hdl.HdlError as e:
            sys.stderr.write("{}:HDL error: {}\n".format(f, e.msg))
            sys.exit(2)


if __name__ == '__main__':
    main()
