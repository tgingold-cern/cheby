#!/usr/bin/env python
import sys
import os.path
import time
import argparse
import cheby.parser
import cheby.print_pretty as pprint
import cheby.sprint as sprint
import cheby.gen_c as gen_c
import cheby.gen_laychk as gen_laychk
import cheby.layout as layout
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.print_verilog as print_verilog
import cheby.gen_edge as gen_edge
import cheby.gen_silecs as gen_silecs
import cheby.gen_custom as gen_custom
import cheby.expand_hdl as expand_hdl
import cheby.gen_name as gen_name
import cheby.gen_gena_memmap as gen_gena_memmap
import cheby.gen_gena_regctrl as gen_gena_regctrl
import cheby.gen_gena_dsp as gen_gena_dsp
import cheby.gen_wbgen_hdl as gen_wbgen_hdl
import cheby.print_html as print_html
import cheby.print_markdown as print_markdown
import cheby.print_asciidoc as print_asciidoc
import cheby.print_rest as print_rest
import cheby.print_latex as print_latex
import cheby.print_consts as print_consts
import cheby.gen_devicetree as gen_devicetree
import cheby.gen_device_script as gen_device_script
import cheby.gen_header as gen_header
import cheby.hdl.globals


def decode_args():
    aparser = argparse.ArgumentParser(description='cheby utility',
                                      prog='cheby')
    aparser.add_argument('--version', action='version',
                         version='%(prog)s ' + cheby.__version__)
    aparser.add_argument('--example', action='store_true',
                         help='print a simple example (for a starting point)')
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
    aparser.add_argument('--print-memmap-verbose', nargs='?', const='-',
                         help='verbose display of the layout')
    aparser.add_argument('--gen-c', nargs='?', const='-',
                         help='generate c header file')
    aparser.add_argument('--c-style', choices=['neutral', 'arm'],
                         default='neutral', help='select style for --gen-c')
    aparser.add_argument('--gen-c-check-layout', nargs='?', const='-',
                         help='generate c file to check layout of the header')
    aparser.add_argument(
        "--gen-c-bit-struct",
        action="store_true",
        help="generate structures for bit fields in registers",
    )
    aparser.add_argument('--hdl', choices=['vhdl', 'verilog', 'sv'], default='vhdl',
                         help='select language for hdl generation')
    aparser.add_argument('--gen-hdl', nargs='?', const='-',
                         help='generate hdl file')
    aparser.add_argument('--hdl-preload', action='store_true',
                         help='preload registers with their preset value if it exists '
                              '(if this flag is not supplied, the preset value is only written to the registers '
                              'by the reset routine).')
    aparser.add_argument(
        '--consts-style',
        choices=[
            'h',
            'matlab',
            'matlab-struct',
            'python',
            'sv',
            'tcl',
            'verilog',
            'vhdl',
            'vhdl-ohwr',
            'vhdl-orig',
        ],
        default='verilog',
        help='select style for --gen-consts',
    )
    aparser.add_argument('--gen-consts', nargs='?', const='-',
                         help='generate constants as hdl file')
    aparser.add_argument('--gen-edge', nargs='?', const='-',
                         help='generate EDGE file')
    aparser.add_argument('--gen-edge3', nargs='?', const='-',
                         help=argparse.SUPPRESS)
    aparser.add_argument('--gen-silecs', nargs='?', const='-',
                         help='generate Silecs file')
    aparser.add_argument('--gen-devicetree', nargs='?', const='-',
                         help='generate devicetree file')
    aparser.add_argument('--gen-install-script', nargs='?', const='-',
                         help='generate device install script')
    aparser.add_argument('--custom', nargs='?', default='gen_custom.py', const='gen_custom.py',
                         help='filename of custom user-code to run')
    aparser.add_argument('--gen-custom', nargs='?', const='-',
                         help='generate a file by running custom user-code')
    aparser.add_argument('--gen-gena-memmap', nargs='?', const='-',
                         help='generate Gena MemMap file')
    aparser.add_argument('--gen-gena-regctrl', nargs='?', const='-',
                         help='generate Gena RegCtrl file')
    aparser.add_argument('--gen-gena-dsp-map', nargs='?', const='-',
                         help='generate Gena DSP MemMap file')
    aparser.add_argument('--gen-gena-dsp-h', nargs='?', const='-',
                         help='generate Gena DSP access header file')
    aparser.add_argument('--gen-gena-dsp-c', nargs='?', const='-',
                         help='generate Gena DSP access C file')
    aparser.add_argument('--gen-gena-dsp', action='store_true',
                         help='generate Gena DSP files (in DSP/ and DSP/include')
    aparser.add_argument('--gena-common-visual', action='store_true',
                         help='use CommonVisual library in gena code')
    aparser.add_argument('--gen-wbgen-hdl', nargs='?', const='-',
                         help='generate wbgen hdl')
    aparser.add_argument('--no-header', action='store_const', const='none', dest='header',
                         help='do not generate comment header')
    # default doesn't work - conflict with store_const of --no-header ?
    aparser.add_argument(
        "--header",
        choices=["none", "args", "commit", "full"],
        help="define if each generated file should contain a header containing the "
        + "arguments used for cheby, its version, user, and time"
    )
    aparser.add_argument('--doc', choices=['html', 'md', 'asciidoc', 'rest', 'latex'], default='html',
                         help='select language for doc generation')
    aparser.add_argument('--gen-doc', nargs='?', const='-',
                         help='generate documentation')
    aparser.add_argument(
        "--doc-hide-comments",
        help="Exclude comment field from being added to documentation.",
        action="store_true",
    )
    aparser.add_argument('--doc-no-reg-drawing', help='Disable generation of register drawings in documentation',
                         action='store_true')
    aparser.add_argument('--doc-copy-template', help='Target file to copy a template for the main file (Latex only).',
                        type=str)
    aparser.add_argument(
        "--doc-include-js-dep",
        help="Include external JavaScript dependencies for HTML documentation "
        + "generation",
        action="store_true",
    )
    aparser.add_argument('--rest-headers', default='#=-',
                         help='Ordered set of characters to be used for ReST heading levels')
    aparser.add_argument('--input', '-i',
                         help='input file')
    aparser.add_argument('--ff-reset', choices=['sync', 'async'], default='sync',
                         help='select synchronous or asynchronous reset for flip-flops')
    aparser.add_argument('--word-endian', choices=['default', 'big', 'little'], default='default',
                         help='override the word-endianness in memmory maps')
    aparser.add_argument('--address-space',
                         help='specify address space for --gen-hdl')
    aparser.add_argument('--out-prefix', default='',
                         help='specify path prefix for automatic output files')

    aparser.add_argument('--wb-lib-name',
                         default = cheby.hdl.globals.libname,
                        help = 'Specify name of VHDL library where wishbone_pkg is compiled')
    aparser.add_argument('--axil-lib-name',
                         default = cheby.hdl.globals.libname,
                        help = 'Specify name of VHDL library where AXI_pkg is compiled')
    args = aparser.parse_args()
    cheby.hdl.globals.gconfig.hdl_lang = args.hdl
    cheby.hdl.globals.gconfig.rst_sync = (args.ff_reset != 'async')
    cheby.hdl.globals.gconfig.preload_reg_preset = args.hdl_preload
    layout.word_endianness = args.word_endian

    return args

def print_hdl(out, lang, h):
    if lang == 'vhdl':
        print_vhdl.print_vhdl(out, h)
    elif lang == 'verilog' or lang == 'sv':
        print_verilog.print_verilog(out, h)
    else:
        raise AssertionError('unknown hdl language {}'.format(lang))


class open_filename(object):
    """Handle '-' as stdout, but wrap the file in a class so that it is not
     closed at the exit of the 'with' statement."""

    def __init__(self, name):
        self.name = name
        self.fh = None

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
        return getattr(self.fh, val)  # pass on

def handle_file(args, filename):
    t = cheby.parser.parse_yaml(filename)

    layout.layout_cheby(t)

    if args.print_pretty is not None:
        with open_filename(args.print_pretty) as f:
            pprint.pprint_cheby(f, t)
    if args.print_memmap is not None:
        with open_filename(args.print_memmap) as f:
            sprint.sprint_cheby(f, t, False)
    if args.print_simple is not None:
        with open_filename(args.print_simple) as f:
            sprint.sprint_cheby(f, t, True)
    if args.gen_gena_memmap is not None:
        with open_filename(args.gen_gena_memmap) as f:
            h = gen_gena_memmap.gen_gena_memmap(t)
            gen_header.gen_comment_header_maybe(f, args.header, args.hdl)
            print_vhdl.print_vhdl(f, h)
    if args.gen_custom is not None:
        with open_filename(args.gen_custom) as f:
            gen_custom.generate_custom(f, t, args.custom)
    if args.gen_devicetree is not None:
        with open_filename(args.gen_devicetree) as f:
            gen_devicetree.generate_devicetree(f, t)
    if args.gen_install_script is not None:
        with open_filename(args.gen_install_script) as f:
            gen_device_script.generate_device_script(f, t)
    if args.gen_edge is not None:
        with open_filename(args.gen_edge) as f:
            gen_edge.generate_edge(f, t)
    if args.gen_edge3 is not None:
        sys.stderr.write('warning: --gen_edge3 is deprecated, please use --gen_edge instead\n')
        with open_filename(args.gen_edge3) as f:
            gen_edge.generate_edge(f, t)

    # Generate names for C code (but do not expand)
    gen_name.gen_name_memmap(t)

    if args.print_memmap_verbose is not None:
        with open_filename(args.print_memmap_verbose) as f:
            sprint.sprint_cheby(f, t, False, True)
    if args.gen_c is not None:
        with open_filename(args.gen_c) as f:
            gen_c.gen_c_cheby(f, t, args.c_style, args.gen_c_bit_struct)
    if args.gen_c_check_layout is not None:
        with open_filename(args.gen_c_check_layout) as f:
            gen_laychk.gen_chklayout_cheby(f, t)

    # Decode x-hdl, unroll
    expand_hdl.expand_hdl(t)
    # Regenerate names and sorted children after unrolling.
    gen_name.gen_name_memmap(t)
    layout.sort_tree(t)

    if args.gen_silecs is not None:
        with open_filename(args.gen_silecs) as f:
            gen_silecs.generate_silecs(f, t)
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
            h = gen_gena_regctrl.gen_gena_regctrl(t, args.gena_common_visual)
            gen_header.gen_comment_header_maybe(f, args.header, args.hdl)
            print_vhdl.print_vhdl(f, h)
    if args.gen_gena_dsp_map is not None:
        with open_filename(args.gen_gena_dsp_map) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_map(f, t)
    if args.gen_gena_dsp_h is not None:
        with open_filename(args.gen_gena_dsp_h) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_h(f, t)
    if args.gen_gena_dsp_c is not None:
        with open_filename(args.gen_gena_dsp_c) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_c(f, t)
    if args.gen_gena_dsp:
        os.makedirs("DSP/include", exist_ok=True)
        with open_filename("DSP/include/MemMapDSP_{}.h".format(t.name)) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_map(f, t)
        with open_filename("DSP/include/vmeacc_{}.h".format(t.name)) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_h(f, t, 'h')
        with open_filename("DSP/vmeacc_{}.c".format(t.name)) as f:
            gen_header.gen_comment_header_maybe(f, args.header, 'h')
            gen_gena_dsp.gen_gena_dsp_c(f, t)
    if args.gen_doc is not None:
        with open_filename(args.gen_doc) as f:
            if args.doc == "html":
                print_html.print_html(
                    f, t, args.doc_hide_comments, args.doc_include_js_dep
                )
            elif args.doc == "md":
                print_markdown.print_markdown(
                    f, t, args.doc_hide_comments, not args.doc_no_reg_drawing
                )
            elif args.doc == "asciidoc":
                print_asciidoc.print_asciidoc(
                    f, t, args.doc_hide_comments, not args.doc_no_reg_drawing
                )
            elif args.doc == "rest":
                print_rest.print_rest(
                    f, t, args.rest_headers, args.doc_hide_comments, not args.doc_no_reg_drawing
                )
            elif args.doc == "latex":
                print_latex.print_latex(
                    f, t, args.doc_hide_comments, not args.doc_no_reg_drawing
                )
            else:
                raise AssertionError('unknown doc format {}'.format(args.doc))
    if args.doc_copy_template is not None:
        # Copy template to filename specified as argument
        with open_filename(args.doc_copy_template) as f:
            if args.doc == 'latex':
                print_latex.copy_template(f)
            else:
                raise AssertionError('Unknown doc format {} for template copying.'.format(args.doc))

    if args.gen_consts is not None:
        with open_filename(args.gen_consts) as f:
            gen_header.gen_comment_header_maybe(f, args.header, args.consts_style)
            print_consts.pconsts_cheby(f, t, args.consts_style)

    if args.gen_wbgen_hdl is not None:
        h = gen_wbgen_hdl.expand_hdl(t)
        with open_filename(args.gen_wbgen_hdl) as f:
            if args.header != 'none':
                (basename, _) = os.path.splitext(os.path.basename(filename))
                c = {'vhdl': '--', 'verilog': '//', 'sv': '//'}[args.hdl]
                l = c[0] * 79
                ext = {'vhdl': 'vhdl', 'verilog': 'v', 'sv': 'sv'}[args.hdl]
                header = """{l}
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

"""
                f.write(header.format(name=t.description, basename=basename,
                                      date=time.strftime("%a %b %d %X %Y"),
                                      c=c, l=l, ext=ext))
            print_vhdl.style = 'wbgen'
            print_hdl(f, args.hdl, h)
    if args.gen_hdl is not None:
        if not t.c_address_spaces_map:
            if not (args.address_space is None):
                sys.stderr.write('error: --address-space not allowed (no address space)\n')
                sys.exit(2)
            top = t
        else:
            if args.address_space is None:
                sys.stderr.write('error: --address-space required\n')
                sys.exit(2)
            top = t.c_address_spaces_map.get(args.address_space)
            if top is None:
                sys.stderr.write('error: no address space "{}"\n'.format(args.address_space))
                sys.exit(2)
        h = gen_hdl.generate_hdl(top, args.wb_lib_name, args.axil_lib_name)
        if args.gen_hdl == '+units':
            if args.hdl == 'verilog' or args.hdl == 'sv':
                print_verilog.print_verilog_per_units(h, args.out_prefix)
            else:
                raise AssertionError('unhandled language {}'.format(args.hdl))
        else:
            with open_filename(args.gen_hdl) as f:
                gen_header.gen_comment_header_maybe_version(f, args.header, args.hdl, t.version)
                print_hdl(f, args.hdl, h)


def print_example():
    sys.stdout.write("""memory-map:
  bus: wb-32-be
  name: example
  description: An example of a cheby memory map
  children:
    - reg:
        name: regA
        description: The first register (with some fields)
        width: 32
        access: rw
        children:
          - field:
              name: field0
              description: 1-bit field
              range: 1
""")

def main():
    args = decode_args()
    if args.example:
        print_example()
        sys.exit(0)

    f = args.input
    if f is None:
        sys.stderr.write('error: argument --input/-i is required\n')
        sys.exit(2)
    try:
        handle_file(args, f)
    except cheby.parser.ParseException as e:
        sys.stderr.write("{}:{}\n".format(f, e))
        sys.exit(2)
    except layout.LayoutException as e:
        sys.stderr.write(str(e) + '\n')
        sys.exit(2)


if __name__ == '__main__':
    main()
