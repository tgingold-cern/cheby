#!/usr/bin/env python
import sys
import os.path
import time
import argparse
import cheby.parser
import cheby.pprint as pprint
import cheby.sprint as sprint
import cheby.gen_c as gen_c
import cheby.gen_laychk as gen_laychk
import cheby.layout as layout
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.print_verilog as print_verilog
import cheby.print_encore as print_encore
import cheby.expand_hdl as expand_hdl
import cheby.gen_name as gen_name
import cheby.gen_gena_memmap as gen_gena_memmap
import cheby.gen_gena_regctrl as gen_gena_regctrl
import cheby.gen_wbgen_hdl as gen_wbgen_hdl
import cheby.print_html as print_html


def decode_args():
    aparser = argparse.ArgumentParser(description='cheby utility')
    aparser.add_argument('--print-pretty', nargs='?', const='-',
                         help='regenerate in YAML')
    aparser.add_argument('--print-simple', nargs='?', const='-',
                         help='display the layout with fields')
    aparser.add_argument('--print-simple-expanded', nargs='?', const='-',
                         help='display the expanded layout with fields')
    aparser.add_argument('--print-pretty-expanded', nargs='?', const='-',
                         help='display the expanded input in YAML')
    aparser.add_argument('--print-memmap', nargs='?', const='-',
                         help='display the layout without fields')
    aparser.add_argument('--gen-c', nargs='?', const='-',
                         help='generate c header file')
    aparser.add_argument('--gen-c-check-layout', nargs='?', const='-',
                         help='generate c file to check layout of the header')
    aparser.add_argument('--hdl', choices=['vhdl', 'verilog'], default='vhdl',
                         help='select language for hdl generation')
    aparser.add_argument('--gen-hdl', nargs='?', const='-',
                         help='generate hdl file')
    aparser.add_argument('--gen-encore', nargs='?', const='-',
                         help='generate encore file')
    aparser.add_argument('--gen-gena-memmap', nargs='?', const='-',
                         help='generate Gena MemMap file')
    aparser.add_argument('--gen-gena-regctrl', nargs='?', const='-',
                         help='generate Gena RegCtrl file')
    aparser.add_argument('--gen-wbgen-hdl', nargs='?', const='-',
                         help='generate wbgen hdl')
    aparser.add_argument('--gen-doc', nargs='?', const='-',
                         help='generate documentation (html)')
    aparser.add_argument('--input', '-i', required=True,
                         help='input file')

    return aparser.parse_args()


def print_hdl(out, lang, h):
    if lang == 'vhdl':
        print_vhdl.print_vhdl(out, h)
    elif lang == 'verilog':
        print_verilog.print_verilog(out, h)
    else:
        raise AssertionError('unknown hdl language {}'.format(lang))


class open_filename(object):
    """Handle '-' as stdout, but wrap the file in a class so that it is not
     closed at the exit of the 'with' statement."""
    def __init__(self, name):
        self.name = name
    def __enter__(self):
        if self.name == '-':
            self.fh = sys.stdout
        else:
            self.fh = open(self.name, 'w')
        return self.fh
    def __exit__(self, etype, value, traceback):
        if self.name != '-':
            self.fh.close()
    def __getattr__(self, val):
        return getattr(self.fh, val) # pass on


def handle_file(args, filename):
    t = cheby.parser.parse_yaml(filename)

    layout.layout_cheby(t)

    if args.print_pretty is not None:
        with open_filename(args.print_pretty) as f:
            pprint.pprint_cheby(f, t)
    if args.print_memmap is not None:
        with open_filename(args.print_memmap) as f:
            sprint.sprint_cheby (f, t, False)
    if args.print_simple is not None:
        with open_filename(args.print_simple) as f:
            sprint.sprint_cheby(f, t, True)
    if args.gen_c is not None:
        with open_filename(args.gen_c) as f:
            gen_c.gen_c_cheby(f, t)
    if args.gen_c_check_layout is not None:
        with open_filename(args.gen_c_check_layout) as f:
            gen_laychk.gen_chklayout_cheby(f, t)
    if args.gen_encore is not None:
        with open_filename(args.gen_encore) as f:
            print_encore.print_encore(f, t)
    if args.gen_gena_memmap is not None:
        with open_filename(args.gen_gena_memmap) as f:
            h = gen_gena_memmap.gen_gena_memmap(t)
            print_vhdl.print_vhdl(f, h)
    # Decode x-hdl
    expand_hdl.expand_hdl(t)
    if args.print_simple_expanded is not None:
        with open_filename(args.print_simple_expanded) as f:
            sprint.sprint_cheby(f, t, True)
    if args.print_pretty_expanded is not None:
        with open_filename(args.print_pretty_expanded) as f:
            pprint.pprint_cheby(f, t)
    if args.gen_gena_regctrl is not None:
        if not args.gen_gena_memmap:
            gen_gena_memmap.gen_gena_memmap(t)
        with open_filename(args.gen_gena_regctrl) as f:
            h = gen_gena_regctrl.gen_gena_regctrl(t)
            print_vhdl.print_vhdl(f, h)
    gen_name.gen_name_root(t)
    if args.gen_doc is not None:
        with open_filename(args.gen_doc) as f:
            print_html.pprint(f, t)
    if args.gen_wbgen_hdl is not None:
        h = gen_wbgen_hdl.expand_hdl(t)
        with open_filename(args.gen_wbgen_hdl) as f:
            (basename, _) = os.path.splitext(os.path.basename(filename))
            c = {'vhdl': '--', 'verilog': '//'}[args.hdl]
            l = c[0] * 79
            ext = {'vhdl': 'vhdl', 'verilog': 'v'}[args.hdl]
            f.write(
"""{l}
{c} Title          : Wishbone slave core for {name}
{l}
{c} File           : {basename}.{ext}
{c} Author         : auto-generated by wbgen2 from {basename}.wb
{c} Created        : {date}
{c} Standard       : VHDL'87
{l}
{c} THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE {basename}.wb
{c} DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
{l}

""".format(name=t.description, basename=basename,
           date=time.strftime("%a %b %d %X %Y"), c=c, l=l, ext=ext))
            print_vhdl.style = 'wbgen'
            print_hdl(f, args.hdl, h)
    if args.gen_hdl is not None:
        h = gen_hdl.generate_hdl(t)
        with open_filename(args.gen_hdl) as f:
            print_hdl(f, args.hdl, h)


def main():
    args = decode_args()
    f = args.input
    try:
        handle_file(args, f)
    except cheby.parser.ParseException as e:
        sys.stderr.write("{}:parse error: {}\n".format(f, e.msg))
        sys.exit(2)
    except layout.LayoutException as e:
        sys.stderr.write("{}:layout error: {}\n".format(
            e.node.get_root().c_filename, e.msg))
        sys.exit(2)
    except gen_hdl.HdlError as e:
        sys.stderr.write("{}:HDL error: {}\n".format(f, e.msg))
        sys.exit(2)


if __name__ == '__main__':
    main()
