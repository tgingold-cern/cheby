#! /usr/bin/env python3
"""Simple test program"""
import sys
import os
import subprocess
import argparse
import cheby.parser as parser
import cheby.layout as layout
import cheby.print_pretty as pprint
import cheby.sprint as sprint
import cheby.gen_c as gen_c
import cheby.gen_name as gen_name
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.print_verilog as print_verilog
import cheby.gen_laychk as gen_laychk
import cheby.expand_hdl as expand_hdl
import cheby.gen_gena_memmap as gen_gena_memmap
import cheby.gen_gena_regctrl as gen_gena_regctrl
import cheby.gen_gena_dsp as gen_gena_dsp
import cheby.gena2cheby as gena2cheby
import cheby.wbgen2cheby as wbgen2cheby
import cheby.gen_wbgen_hdl as gen_wbgen_hdl
import cheby.print_consts as print_consts
import cheby.print_html as print_html
import cheby.print_markdown as print_markdown
import cheby.print_latex as print_latex
import cheby.print_rest as print_rest
import cheby.gen_custom as gen_custom
import cheby.gen_edge3 as gen_edge3
import cheby.gen_silecs as gen_silecs
from cheby.hdl.globals import gconfig, gconfig_scope

srcdir = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                      '../testfiles/')

args = None
nbr_tests = 0


class TestError(Exception):
    def __init__(self, msg):
        super().__init__()
        self.msg = msg


def werr(s):
    sys.stderr.write(s + '\n')


def error(msg):
    if args.keep:
        werr('error: {}'.format(msg))
    else:
        raise TestError('error: {}'.format(msg))


class write_null(object):
    """A class that could be used as a very simple write-only stream"""
    def write(self, s):
        pass


class write_buffer(object):
    """A class that could be used as a very simple write stream"""
    def __init__(self):
        self.buffer = ''

    def write(self, s):
        self.buffer += s

    def get(self):
        return self.buffer

def elab_vhdl(vhdl_file):
    """Function to elaborate VHDL"""
    vhdl_pkgs = [srcdir + 'tb/cheby_pkg.vhd', srcdir + 'tb/wishbone_pkg.vhd']
    res = subprocess.run(['ghdl', '-s', '-Werror=runtime-error'] + vhdl_pkgs + [vhdl_file])
    if res.returncode != 0:
        error('VHDL elaboration failed for {}'.format(vhdl_file))

def elab_sv(sv_file, top_entity):
    """Function to elaborate SV/Verilog"""
    # Allow the definition of a different verilator command
    if 'VERILATOR' in os.environ:
        verilator_cmd = os.environ['VERILATOR']
    else:
        verilator_cmd = 'verilator'
    if args.verbose:
        print('Running elaboration with verilator command {}.'.format(verilator_cmd))

    sv_pkgs = [srcdir + 'tb/dpssram.sv', srcdir + 'tb/wishbone_pkg.sv']
    res = subprocess.run([verilator_cmd, '--lint-only', '--top-module', top_entity] + sv_pkgs + [sv_file])
    if res.returncode != 0:
        error('SV/Verilog elaboration failed for {}'.format(sv_file))

def check_c_syntax(c_file):
    """Function to check C syntax using gcc"""
    res = subprocess.run(['gcc', '-fsyntax-only', '-Wall', '-Werror', c_file])
    if res.returncode != 0:
        error('C syntax check failed for {}'.format(c_file))

def parse_ok(f):
    try:
        return parser.parse_yaml(f)
    except parser.ParseException as e:
        error('unexpected parse error for {}: {}'.format(f, e))


def parse_err(f):
    try:
        parser.parse_yaml(f)
    except parser.ParseException:
        return
    error('parse error expected for {}'.format(f))


def test_parser():
    global nbr_tests
    for f in ['demo', 'features/simple_reg1', 'features/simple_reg2',
              'features/block1', 'features/submap2', 'features/submap3',
              'features/block4', 'parser/extension1']:
        f += '.cheby'
        if args.verbose:
            print('test parser: {}'.format(f))
        parse_ok(srcdir + f)
        nbr_tests += 1
    for f in ['no-such-file', 'error1',
              'err_name_type1', 'err_width_type1',
              'err_align_type1',
              'parse_err_elem1', 'parse_err_elem2',
              'parse_err_reg1',
              'parse_err_field1', 'parse_err_field2',
              'parse_err_field3',
              'parse_err_array1', 'parse_err_array2',
              'parse_err_block1',
              'err_cnt', 'err_cnt2', 'err_extension']:
        if args.verbose:
            print('test parser: {}'.format(f))
        parse_err(srcdir + 'parser/' + f + '.cheby')
        nbr_tests += 1


def layout_ok(t):
    try:
        layout.layout_cheby(t)
    except layout.LayoutException:
        error('unexpected layout error for {}'.format(t.name))


def layout_err(t):
    try:
        layout.layout_cheby(t)
    except layout.LayoutException:
        return
    error('layout error expected for {}'.format(t.name))


def test_layout():
    global nbr_tests
    hfiles = []
    for f in ['padding-block/reg', 'demo', 'features/block1', 'features/array1', 'features/array2',
              'bug-gen-c/fids-errmiss',
              'bug-gen-c-02/mbox_regs',
              'bug-gen-c-02/fip_urv_regs',
              'issue99/m1', 'issue99/m2']:
        f += '.cheby'
        if args.verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_ok(t)

        # Generate C source and header files, check syntax for both version
        hname = t.name + '.h'
        cname = t.name + '.c'
        gen_name.gen_name_memmap(t)
        with open(cname, 'w') as fd:
            gen_laychk.gen_chklayout_cheby(fd, t)
        with open(hname, 'w') as fd:
            gen_c.gen_c_cheby(fd, t, 'neutral')
        if args.elaborate:
            check_c_syntax(hname)
            check_c_syntax(cname)

        with open(hname, 'w') as fd:
            gen_c.gen_c_cheby(fd, t, 'arm')
        if args.elaborate:
            check_c_syntax(hname)
            check_c_syntax(cname)
        hfiles.append(hname)
        os.remove(cname)
        nbr_tests += 1
    for f in hfiles:
        os.remove(f)
    for f in ['layout/err_bus_name',
              'layout/err_reg_addr1', 'layout/err_reg_addr2',
              'layout/err_reg_width1',
              'layout/err_reg_type1', 'layout/err_reg_type2',
              'layout/err_reg_type3',
              'layout/err_field1', 'layout/err_field2', 'layout/err_field3',
              'layout/err_field4', 'layout/err_field5', 'layout/err_field6',
              'layout/err_field_name1', 'layout/err_field_name2',
              'layout/err_reg_name1', 'layout/err_reg_name2',
              'layout/err_reg_acc1', 'layout/err_reg_acc2',
              'layout/err_field_preset1',
              'layout/err_noelements',
              'layout/err_arr1', 'layout/err_arr2',
              'layout/err_block_size1',
              'layout/err_presets2',
              'layout/err_enum_name', 'layout/err_enum_invalid',
              'layout/err_enum_width',
              'layout/err_submap_align1', 'layout/err_submap_align2',
              'layout/err_submap_size1',
              'issue14/test-err',
              'issue57/m1', 'issue71/m1', 'features/enums3']:
        f += '.cheby'
        if args.verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_err(t)
        nbr_tests += 1


def test_print():
    global nbr_tests
    fd = write_null()
    for f in ['demo', 'features/reg_value1', 'features/reg_value2',
              'features/reg_value3', 'demo_all', 'features/semver1',
              'issue55/modulation', 'issue124/project']:
        f += '.cheby'
        t = parse_ok(srcdir + f)
        layout_ok(t)
        pprint.pprint_cheby(fd, t)
        sprint.sprint_cheby(fd, t)
        gen_name.gen_name_memmap(t)
        gen_c.gen_c_cheby(fd, t, 'neutral')
        nbr_tests += 1

def test_gconfig_scope():
    global nbr_tests

    gconfig.restore_defaults()
    assert gconfig.hdl_lang == None
    gconfig.hdl_lang = 'verilog'
    gconfig.my_var = 'value'

    # restore_defaults should restore values and remove extra attributes
    gconfig.restore_defaults()
    assert gconfig.hdl_lang == None
    assert not hasattr(gconfig, 'my_var')

    # Test config scoping
    with gconfig_scope():
        assert gconfig.hdl_lang == None
        gconfig.hdl_lang = 'sv'
        gconfig.my_var = 'value'
        with gconfig_scope():
            assert gconfig.hdl_lang == 'sv'
            assert gconfig.my_var == 'value'
            gconfig.hdl_lang = 'verilog'
        assert gconfig.hdl_lang == 'sv'
    assert gconfig.hdl_lang == None
    assert not hasattr(gconfig, 'my_var')

    nbr_tests += 1

def compare_buffer_and_file(buf, filename):
    # Well, there is certainly a python diff module...
    buf = buf.buffer
    try:
        ref = open(filename, 'r').read()
        if ref == buf:
            return True
    except:
        # Usually an IO error.
        if not args.regen:
            raise
    if args.regen:
        open(filename, 'w').write(buf)
        werr('Regenerate {}'.format(filename))
        return True
    buf_lines = buf.splitlines()
    ref_lines = ref.splitlines()
    nlines = len(buf_lines)
    if nlines != len(ref_lines):
        werr('Number of lines mismatch')
        return False
    if args.keep:
        return False
    for i in range(nlines):
        if buf_lines[i] == ref_lines[i]:
            print('=' + buf_lines[i])
            continue
        print('>' + buf_lines[i])
        print('<' + ref_lines[i])
    return False


def test_genc_ref():
    global nbr_tests
    for f in ['issue103/top',
              'bug-gen-c-02/mbox_regs', 'bug-gen-c-02/fip_urv_regs',
              'issue67/repeatInRepeat', 'issue67/repeatInRepeatC',
              'bug-same-label/same_label',
              'features/blkprefix3', 'features/blkprefix5']:
        cheby_file = srcdir + f + '.cheby'
        t = parse_ok(cheby_file)
        layout_ok(t)
        gen_name.gen_name_memmap(t)

        # Generate C header files and compare to golden file
        h_file = srcdir + f + '.h'
        buf = write_buffer()
        gen_c.gen_c_cheby(buf, t, 'neutral')
        if not compare_buffer_and_file(buf, h_file):
            error('c header generation error for {}'.format(f))

        # Generate C header files with union structs for bit fields and
        # compare to golden file
        h_file = srcdir + f + '_union.h'
        buf = write_buffer()
        gen_c.gen_c_cheby(buf, t, 'neutral', True)
        if not compare_buffer_and_file(buf, h_file):
            error('c header generation error (with union structs) for {}'.format(f))

        # Check C syntax
        # Note: Exclude issue103/top because it includes other header files
        # not generated here.
        if f != 'issue103/top' and args.elaborate:
            check_c_syntax(h_file)
        nbr_tests += 1


def test_hdl():
    # Just generate vhdl (without baseline)
    global nbr_tests
    fd = write_null()
    for f in ['features/simple_reg3', 'features/simple_reg4_ro',
              'features/reg_value1', 'features/reg_value2', 'features/reg_value3',
              'features/field_value1', 'features/field_value2',
              'features/field_range1',
              'features/submap_align1',
              'wb_slave_vic',
              '../examples/svec-leds/leds',
              'inter-mt/mt_cpu_xb',
              'inter-mt/mt_cpu_xb-include',
              'inter-mt/mt_cpu_xb-extern',
              'inter-mt/mt_cpu_xb-busgroup',
              'inter-mt/mt_cpu_xb-busgroup2',
              'inter-mt/mt_cpu_lr-busgroup',
              'demo_all', 'features/big_addr', 'issue24/map_arrays',
              'features/cern_info', 'issue22/map_ro', 'issue22/map_rw',
              'demo_all_old',
              'access/const_ro', 'access/const_rw',
              'access/autoclear_rw', 'access/autoclear_wo',
              'access/orclr_rw', 'issue46/types', 'issue58/port',
              'issue60/busgroup-axi4', 'issue60/busgroup-cernbe',
              'issue60/busgroup-filename', 'issue60/busgroup-include',
              'issue60/busgroup-interface', 'issue82/m1',
              'issue95/m1', 'issue95/m2', 'issue95/m3', 'issue95/sm1', 'issue95/sm3',
              'features/avalon-noaddr', 'issue129/acdipole_ip', 'issue129/acdipole_ip-orig',
              'issue67/repeatInRepeat', 'features/sram_iogroup1']:
        if args.verbose:
            print('test hdl: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        if t.c_address_spaces_map is None:
            h = gen_hdl.generate_hdl(t)
            print_vhdl.print_vhdl(fd, h)
        else:
            for sp in t.children:
                h = gen_hdl.generate_hdl(sp)
                print_vhdl.print_vhdl(fd, h)
        nbr_tests += 1

def expand_hdl_err(t):
    try:
        expand_hdl.expand_hdl(t)
    except parser.ParseException:
        return
    error('hdl error expected for {}'.format(t.name))


def gen_name_err(t):
    try:
        gen_name.gen_name_memmap(t)
    except parser.ParseException:
        return
    error('hdl error expected for {}'.format(t.name))


def test_hdl_err():
    global nbr_tests
    # Error in expand_hdl
    for f in ['issue11/test_port1_err1', 'issue11/test_port_err2',
              'access/const_err_wo', 'access/const_err_nopreset',
              'access/autoclear_err_ro',
              'access/orclr_err_ro', 'access/orclr_err_wo',
              'issue109/test']:
        if args.verbose:
            print('test hdl error: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl_err(t)
        gen_name.gen_name_memmap(t)
        nbr_tests += 1
    # Error in gen_name
    for f in ['issue65/m1']:
        if args.verbose:
            print('test hdl error: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name_err(t)
        nbr_tests += 1
    # Error in gen-gena-regctrl
    for f in ['issue44b/gena8memIn16map', 'issue44b/gena16memIn32map']:
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        gen_gena_memmap.gen_gena_memmap(t)
        try:
            gen_gena_regctrl.gen_gena_regctrl(t, True)
            error('gen regctrl error expected for {}'.format(f))
        except layout.LayoutException as e:
            assert(str(e) != '')
        nbr_tests += 1

def test_hdl_ref():
    # Generate HDL, compare with a baseline and potentially elaborate.
    global nbr_tests

    for f in ['fmc-adc01/fmc_adc_alt_trigin', 'fmc-adc01/fmc_adc_alt_trigout',
              'issue9/test', 'issue10/test',
              'issue8/simpleMap_bug', 'issue8/simpleMap_noBug',
              'issue14/test-axi', 'issue14/test-be', 'issue14/test-le',
              'issue11/test_port1_reg', 'issue11/test_port1',
              'issue11/test_port1_field',
              'issue11/test_port2_reg', 'issue11/test_port2_wire',
              'issue13/mainMap2', 'memory01/mainMap',
              'memory01/sramro', 'memory01/sramwo', 'memory01/sramrw',
              'issue39/addressingMemory',
              'issue40/bugConstraints',
              'issue41/bugBlockFields',
              'issue45/test8', 'issue45/test16',
              'features/wires1', 'features/semver1', 'features/semver2',
              'features/mapinfo2',
              'features/enums1', 'features/enums2',
              'features/orclrout_rw',
              'features/blkprefix1', 'features/blkprefix2', 'features/blkprefix3',
              'features/blkprefix4', 'features/blkprefix5',
              'features/regprefix1', 'features/regprefix2', 'features/regprefix3',
              'features/mem64ro', 'features/mem64rodual',
              'features/iogroup1', 'features/iogroup2', 'features/repeat-iogroup1',
              'features/repeat-iogroup2', 'features/repeat-iogroup3',
              'features/repeat-iogroup4',
              'features/no_port', 'features/memwide',
              'issue52/hwInfo',
              'bug-gen_wt/m1',
              'issue59/inherit', 'issue64/simple_reg1', 'issue66/m1',
              'issue44/m1', 'issue75/m1',
              'features/xilinx_attrs', 'features/xilinx_attrs_cern',
              'features/axi4_byte', 'features/axi4_word', 'features/axi4_submap_wb',
              'features/reg128', 'features/reg-strobe',
              'issue77/m1', 'issue77/m2', 'issue77/m3',
              'issue77/s1', 'issue77/s2', 'issue77/s3', 'issue77/s4',
              'issue77/s5', 'issue77/s6',
              'issue79/CSR', 'bug-memory/mem64ro', 'issue87/qsm_regs', 'issue89/map',
              'issue92/blockInMap', 'issue90/bugDPSSRAMbwSel',
              'bug-repmem/bran', 'bug-empty/noout', 'bug-empty/noinp',
              'bug-cernbe/repro', 'bug-cernbe/sub_repro']:
        if args.verbose:
            print('test hdl with ref: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '.vhdl'
        verilog_file = srcdir + f + '.v'
        sv_file = srcdir + f + '.sv'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        h = gen_hdl.generate_hdl(t)

        # Generate VHDL
        buf_vhdl = write_buffer()
        print_vhdl.print_vhdl(buf_vhdl, h)
        if not compare_buffer_and_file(buf_vhdl, vhdl_file):
            error('vhdl generation error for {}'.format(f))

        # Generate SV
        buf_sv = write_buffer()
        with gconfig_scope():
            gconfig.hdl_lang = 'sv'
            print_verilog.print_verilog(buf_sv, h)
        if not compare_buffer_and_file(buf_sv, sv_file):
            error('SV generation error for {}'.format(f))

        # Generate Verilog
        buf_verilog = write_buffer()
        with gconfig_scope():
            gconfig.hdl_lang = 'verilog'
            print_verilog.print_verilog(buf_verilog, h)
        if not compare_buffer_and_file(buf_verilog, verilog_file):
            error('Verilog generation error for {}'.format(f))

        nbr_tests += 1

        if args.elaborate:
            # Elaboration tests
            top_entity = t.hdl_module_name

            # Elaborate VHDL using GHDL
            elab_vhdl(vhdl_file)

            # Elaborate SV and Verilog using Verilator
            elab_sv(sv_file, top_entity)
            elab_sv(verilog_file, top_entity)

            nbr_tests += 1

def test_hdl_library_names():
    """Test passing specific library names to generate_hdl."""
    global nbr_tests

    # Test Wishbone library name
    wb_test_name = 'features/wb-library'
    wb_lib = 'wb_lib'
    if args.verbose:
        print(f'test hdl library name: {wb_test_name} (wb_lib={wb_lib})')
    cheby_file_wb = srcdir + wb_test_name + '.cheby'
    vhdl_file_wb = srcdir + wb_test_name + '.vhdl' # Golden file

    t_wb = parse_ok(cheby_file_wb)
    layout_ok(t_wb)
    expand_hdl.expand_hdl(t_wb)
    gen_name.gen_name_memmap(t_wb)
    # Call generate_hdl with custom WB lib name, default AXI lib name
    h_wb = gen_hdl.generate_hdl(t_wb, wb_lib_name=wb_lib)

    # Generate VHDL and compare
    buf_vhdl_wb = write_buffer()
    print_vhdl.print_vhdl(buf_vhdl_wb, h_wb)
    if not compare_buffer_and_file(buf_vhdl_wb, vhdl_file_wb):
        error(f'VHDL generation error for {wb_test_name} with wb_lib_name={wb_lib}')
    nbr_tests += 1

    # Test AXI library name
    axi_test_name = 'features/axi-library'
    axi_lib = 'axi_lib'
    if args.verbose:
        print(f'test hdl library name: {axi_test_name} (axil_lib={axi_lib})')
    cheby_file_axi = srcdir + axi_test_name + '.cheby'
    vhdl_file_axi = srcdir + axi_test_name + '.vhdl' # Golden file

    t_axi = parse_ok(cheby_file_axi)
    layout_ok(t_axi)
    expand_hdl.expand_hdl(t_axi)
    gen_name.gen_name_memmap(t_axi)
    # Call generate_hdl with default WB lib name, custom AXI lib name
    h_axi = gen_hdl.generate_hdl(t_axi, axil_lib_name=axi_lib)

    # Generate VHDL and compare
    buf_vhdl_axi = write_buffer()
    print_vhdl.print_vhdl(buf_vhdl_axi, h_axi)
    if not compare_buffer_and_file(buf_vhdl_axi, vhdl_file_axi):
        error(f'VHDL generation error for {axi_test_name} with axil_lib_name={axi_lib}')
    nbr_tests += 1


def test_hdl_ref_async_rst():
    # Generate HDL with asynchronous reset and compare with a baseline
    global nbr_tests

    for f in ["features/axi4_byte", "features/axi4_word", "features/axi4_submap_wb"]:
        if args.verbose:
            print("test hdl with ref (async rst): {}".format(f))

        cheby_file = srcdir + f + ".cheby"
        vhdl_file = srcdir + f + "_async_rst.vhdl"
        sv_file = srcdir + f + "_async_rst.sv"

        with gconfig_scope():
            gconfig.rst_sync = False

            t = parse_ok(cheby_file)
            layout_ok(t)
            expand_hdl.expand_hdl(t)
            gen_name.gen_name_memmap(t)
            h = gen_hdl.generate_hdl(t)

            # Generate VHDL
            buf = write_buffer()
            print_vhdl.print_vhdl(buf, h)
            if not compare_buffer_and_file(buf, vhdl_file):
                error("vhdl generation error for {}".format(f))

            # Generate SV
            buf_sv = write_buffer()
            with gconfig_scope():
                gconfig.hdl_lang = 'sv'
                print_verilog.print_verilog(buf_sv, h)
            if not compare_buffer_and_file(buf_sv, sv_file):
                error("SV generation error for {}".format(f))

        nbr_tests += 1

def test_hdl_ref_preset_preload():
    # Generate HDL with preset preloading and compare with a baseline
    global nbr_tests

    for f in ["features/simple_reg2", "features/field_range1", "features/field_value1"]:
        if args.verbose:
            print("test hdl with ref (preset initialization): {}".format(f))

        cheby_file = srcdir + f + ".cheby"
        vhdl_file = srcdir + f + "_preset_init.vhdl"
        verilog_file = srcdir + f + "_preset_init.v"
        sv_file = srcdir + f + "_preset_init.sv"

        with gconfig_scope():
            gconfig.preload_reg_preset = True

            t = parse_ok(cheby_file)
            layout_ok(t)
            expand_hdl.expand_hdl(t)
            gen_name.gen_name_memmap(t)
            h = gen_hdl.generate_hdl(t)

            # Generate VHDL
            buf = write_buffer()
            print_vhdl.print_vhdl(buf, h)
            if not compare_buffer_and_file(buf, vhdl_file):
                error("vhdl generation error for {}".format(f))

            # Generate Verilog
            buf_verilog = write_buffer()
            with gconfig_scope():
                gconfig.hdl_lang = 'verilog'
                print_verilog.print_verilog(buf_verilog, h)
            if not compare_buffer_and_file(buf_verilog, verilog_file):
                error('Verilog generation error for {}'.format(f))

            # Generate SV
            buf_sv = write_buffer()
            with gconfig_scope():
                gconfig.hdl_lang = 'sv'
                print_verilog.print_verilog(buf_sv, h)
            if not compare_buffer_and_file(buf_sv, sv_file):
                error("SV generation error for {}".format(f))

        nbr_tests += 1

def test_verilog_ref():
    # Generate verilog and compare with a baseline.
    global nbr_tests
    for f in ['crossbar/crossbar']:
        if args.verbose:
            print('test verilog with ref: {}'.format(f))

        cheby_file = srcdir + f + '.cheby'
        vlog_file = srcdir + f + '.v'

        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        h = gen_hdl.generate_hdl(t)

        # Generate Verilog
        gconfig.hdl_lang = 'verilog'
        buf = write_buffer()
        with gconfig_scope():
            gconfig.hdl_lang = 'verilog'
            print_verilog.print_verilog(buf, h)
        if not compare_buffer_and_file(buf, vlog_file):
            error('verilog generation error for {}'.format(f))

        nbr_tests += 1

def test_sv_ref():
    # Generate SystemVerilog and compare with a baseline.
    global nbr_tests
    for f in ["crossbar/crossbar", "bug-include/pg_wb"]:
        if args.verbose:
            print("test sv with ref: {}".format(f))

        cheby_file = srcdir + f + ".cheby"
        vlog_file = srcdir + f + ".sv"

        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        h = gen_hdl.generate_hdl(t)

        # Generate SV
        buf = write_buffer()
        with gconfig_scope():
            gconfig.hdl_lang = 'sv'
            print_verilog.print_verilog(buf, h)
        if not compare_buffer_and_file(buf, vlog_file):
            error("sv generation error for {}".format(f))

        nbr_tests += 1

def test_issue84():
    global nbr_tests
    for f in ['issue84/sps200CavityControl_as']:
        if args.verbose:
            print('test hdl with ref: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '.vhdl'
        sv_file = srcdir + f + '.sv'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        h = gen_hdl.generate_hdl(t.c_address_spaces_map['bar0'])

        # Generate VHDL
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, h)
        if not compare_buffer_and_file(buf, vhdl_file):
            error('vhdl generation error for {}'.format(f))

        # Generate SV
        buf_sv = write_buffer()
        with gconfig_scope():
            gconfig.hdl_lang = 'sv'
            print_verilog.print_verilog(buf_sv, h)
        if not compare_buffer_and_file(buf_sv, sv_file):
            error('SV generation error for {}'.format(f))

        nbr_tests += 1

def test_self():
    """Auto-test"""
    def test(func, func_name):
        if args.verbose:
            print('test self: {}'.format(func_name))
        ok = False
        try:
            func()
        except TestError:
            ok = True
        if not ok:
            error("self-test error for {}".format(func_name))
    test((lambda: parse_ok(srcdir + 'error1.yaml')), "parse_ok")
    test((lambda: parse_err(srcdir + 'features/simple_reg1.cheby')), "parse_err")
    t = parse_ok(srcdir + 'layout/err_bus_name.cheby')
    test((lambda: layout_ok(t)), "layout_ok")
    t = parse_ok(srcdir + 'demo.cheby')
    test((lambda: layout_err(t)), "layout_err")


def sub_gena_compare(filename, t):
    # Test DSP map generation
    idx = filename.find('/')
    basedir = filename[:idx + 1]
    # Note: Gena fails on Regs_small, sub_reg_swap, Cregs_resize_signed,
    #   Muxed
    #   And order is different for sub_reg_one
    buf = write_buffer()
    gen_gena_dsp.gen_gena_dsp_map(buf, t, with_date=False)
    dspmapfile = srcdir + basedir + 'DSP/include/MemMapDSP_' + t.name + '.h'
    if not compare_buffer_and_file(buf, dspmapfile):
        error('gena DSP MemMap generation error for {}'.format(filename))
    # Test DSP access header generation
    buf = write_buffer()
    gen_gena_dsp.gen_gena_dsp_h(buf, t)
    dspmapfile = srcdir + basedir + 'DSP/include/vmeacc_' + t.name + '.h'
    if not compare_buffer_and_file(buf, dspmapfile):
        error('gena DSP header generation error for {}'.format(filename))
    # Test DSP access C generation
    buf = write_buffer()
    gen_gena_dsp.gen_gena_dsp_c(buf, t)
    dspmapfile = srcdir + basedir + 'DSP/vmeacc_' + t.name + '.c'
    if not compare_buffer_and_file(buf, dspmapfile):
        error('gena DSP C generation error for {}'.format(filename))


def test_gena():
    # Feature tests
    global nbr_tests
    files = ['CRegs', 'CRegs_Regs', 'CRegs_NoRMW', 'CRegs_Regs_NoRMW',
             'CRegs_internal',
             'Regs', 'Regs_Mems', 'Regs_rdstrobe', 'Regs_nodff',
             'Regs_cross_words', 'Regs_small',
             'sub_reg_swap', 'sub_reg_one', 'sub_reg_preset',
             'sub_reg_preset2',
             'Mems', 'Mems2', 'Mems_RO', 'Mems_WO',
             'Mems_nodff', 'Mems_splitaddr',
             'CRegs_Mems', 'CRegs_Regs_Mems',
             'Area_CRegs',
             'Area_CRegs_Regs_Mems', 'Area_CRegs_Regs_Mems_EmptyRoot',
             'Area_Mems', 'Area_extarea', 'Area_extarea_error',
             'Area_reserved',
             'CRegs_wrstrobe', 'CRegs_srff', 'CRegs_resize', 'CRegs_nosplit',
             'CRegs_busout', 'CRegs_extcreg', 'CRegs_extacm',
             'CRegs_nodff', 'CRegs_splitaddr', 'CRegs_library',
             'CRegs_resize_nosplit', 'CRegs_ignore', 'CRegs_Preset',
             'CRegs_Address', 'CRegs_resize_signed', 'CRegs_d8',
             'Submap', 'Submap_internal',
             'Muxed', 'Muxed2', 'Semver', 'Consts']
    for f in files:
        if args.verbose:
            print('test gena: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'gena/' + f + '.xml'
        chebfile = srcdir + 'gena/' + f + '.cheby'
        t = gena2cheby.convert(xmlfile)
        buf = write_buffer()
        pprint.pprint_cheby(buf, t)
        if not compare_buffer_and_file(buf, chebfile):
            error('gena2cheby conversion error for {}'.format(f))
        # Test parse+layout
        t = parse_ok(chebfile)
        layout_ok(t)
        # Test memmap generation
        hmemmap = gen_gena_memmap.gen_gena_memmap(t)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, hmemmap)
        memmapfile = srcdir + 'gena/HDL/' + 'MemMap_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, memmapfile):
            error('gena memmap generation error for {}'.format(f))
        # Test regctrl generation
        hregctrl = gen_gena_regctrl.gen_gena_regctrl(t, True)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, hregctrl)
        regctrlfile = srcdir + 'gena/HDL/' + 'RegCtrl_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, regctrlfile):
            error('gena regctrl generation error for {}'.format(f))
        # Test DSP map generation
        sub_gena_compare('gena/' + f, t)
        nbr_tests += 1


def test_gena_regctrl_err():
    global nbr_tests
    files = ['Muxed_name', 'Muxed_code']
    for f in files:
        if args.verbose:
            print('test gena regctrl err: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'err_gena/' + f + '.xml'
        chebfile = srcdir + 'err_gena/' + f + '.cheby'
        t = gena2cheby.convert(xmlfile)
        buf = write_buffer()
        pprint.pprint_cheby(buf, t)
        if not compare_buffer_and_file(buf, chebfile):
            error('gena2cheby conversion error for {}'.format(f))
        # Test parse+layout
        t = parse_ok(chebfile)
        layout_ok(t)
        # Test memmap generation
        gen_gena_memmap.gen_gena_memmap(t)
        # Test regctrl generation
        try:
            gen_gena_regctrl.gen_gena_regctrl(t, True)
            error('gen regctrl error expected for {}'.format(f))
        except gen_gena_regctrl.GenHDLException as e:
            assert(str(e) != '')
        nbr_tests += 1


def test_gena2cheby():
    global nbr_tests
    files = ['const_value', 'fesa_class_prop', 'root_attr', 'root_gen_include',
             'submap_desc', 'comment', 'area_attrs', 'memory_gen',
             'err_memory_width', 'memory_buffer', 'memory_bit_field',
             'regs_gen',
             'sub_reg_gen', 'sub_reg_gen_ignore',
             'bit_field_gen', 'reg_name_boolean']
    for f in files:
        if args.verbose:
            print('test gena2cheby: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'gena2cheby/' + f + '.xml'
        gena2cheby.convert(xmlfile)
        nbr_tests += 1


def test_gena2cheby_err():
    global nbr_tests
    files = ['err_memmap_acc_mode', 'err_root_attr', 'err_root_gen',
             'err_root_element', 'err_submap_child', 'err_submap_gen',
             'err_submap_attr', 'err_submap_include',
             'err_comment',
             'err_area_attrs', 'err_area_gen',
             'err_memory_gen', 'err_memory_attr', 'err_memory_child',
             'err_memory_channel_attrs', 'err_memory_channel_child',
             'err_memory_buffer_child', 'err_memory_buffer_attrs',
             'err_memory_bit_field_attrs', 'err_memory_bit_field_child',
             'err_regs_gen', 'err_regs_attrs', 'err_regs_child',
             'err_regs_bit_encoding',
             'err_sub_reg_gen', 'err_sub_reg_attrs', 'err_sub_reg_child',
             'err_bit_field_gen', 'err_bit_field_attrs', 'err_bit_field_child',
             'err_bit_field_preset']
    for f in files:
        if args.verbose:
            print('test gena2cheby err: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'gena2cheby/' + f + '.xml'
        try:
            gena2cheby.convert(xmlfile)
            error('gena2cheby error expected for {}'.format(f))
        except gena2cheby.UnknownValue:
            pass
        except gena2cheby.UnknownAttribute:
            pass
        except gena2cheby.UnknownGenAttribute:
            pass
        except gena2cheby.ErrorGenAttribute:
            pass
        except gena2cheby.UnknownTag:
            pass
        nbr_tests += 1


def test_gena2cheby_regressions():
    global nbr_tests
    files = ['issue7/code_fields',
             'issue_gena_rst/CRegs', 'issue_gena_rst/CRegs_srff',
             'issue33/testmap', 'issue33b/testmap', 'bug-xml/acqCore',
             'issue33d/preset1-preset-no',
             'issue33d/preset1-preset-always',
             'issue33d/preset1-preset-nosplit',
             'issue33d/preset2-preset-nosplit',
             'issue51/map', 'bug-unit/rfLimiter',
             'bug-note/WB3_DDR', 'bug-note/WB3_DDR-1']
    for f in files:
        if args.verbose:
            print('test gena2cheby regression: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + f + '.xml'
        chebfile = srcdir + f + '.cheby'
        if f.endswith("-preset-no"):
            gena2cheby.flag_keep_preset = "no"
        elif f.endswith("-preset-always"):
            gena2cheby.flag_keep_preset = "always"
        else:
            gena2cheby.flag_keep_preset = "no-split"
        t = gena2cheby.convert(xmlfile)
        buf = write_buffer()
        pprint.pprint_cheby(buf, t)
        if not compare_buffer_and_file(buf, chebfile):
            error('gena2cheby conversion error for {}'.format(f))
        nbr_tests += 1


def test_gena_gen_regressions():
    global nbr_tests
    files = ['issue7/code_fields',
             'issue_gena_rst/CRegs', 'issue_gena_rst/CRegs_srff',
             'issue32/memmap', 'gena2cheby/submap_noinc', 'issue49/mainMap', 'issue33e/timing',
             'issue68/m1', 'issue70/m3', 'issue69/m1', 'issue73/yesno2', 'issue102/mainMap']
    for f in files:
        if args.verbose:
            print('test gena regression: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        # Test parse+layout
        t = parse_ok(chebfile)
        layout_ok(t)
        # Test memmap generation
        hmemmap = gen_gena_memmap.gen_gena_memmap(t)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, hmemmap)
        (head, _) = os.path.split(f)
        memmapfile = srcdir + head + '/MemMap_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, memmapfile):
            error('gena memmap generation error for {}'.format(f))
        # Test regctrl generation
        hregctrl = gen_gena_regctrl.gen_gena_regctrl(t, False)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, hregctrl)
        regctrlfile = srcdir + head + '/RegCtrl_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, regctrlfile):
            error('gena regctrl generation error for {}'.format(f))
        nbr_tests += 1


def test_gena_dsp_regressions():
    global nbr_tests
    files = ['issue106/m1']
    for f in files:
        if args.verbose:
            print('test gena regression: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        # Test parse+layout
        t = parse_ok(chebfile)
        layout_ok(t)
        sub_gena_compare(f, t)
        nbr_tests += 1


def test_wbgen2cheby():
    global nbr_tests
    files = ['reg1', 'reg2', 'reg_field1', 'reg_in', 'reg_noprefix', 'reg_noprefix2',
             'reg_unsigned', 'reg_signed',
             'reg_loadext', 'reg_ackread',
             'reg_rwrw_async', 'reg_rowo_async', 'reg_rwro_async',
             'reg_bit_rowo_async', 'reg_bit_rwro_async', 'reg_bit_rwrw_async',
             'reg_passthrough', 'reg_passthrough_async',
             'reg_monostable', 'reg_monostable_async', 'reg_monostable_pad',
             'reg_constant', 'reg_constant_bit',
             'fifo1', 'fifo2', 'fifo3', 'fifo_async', 'fifo_optional',
             'fifo_bclr', 'fifo_bus_count', 'fifo_bus_empty',
             'fifo_dev_empty', 'fifo_dev_count',
             'ram1', 'ram2', 'ram3',
             'ram_reg', 'ram_reg2',
             'ram_rw', 'ram_rw_bs', 'ram_pad', 'ram_async',
             'irq1', 'irq_ack', 'irq_mask',
             'description', 'comment1', 'comment_block',
             'wb_freq_multi_count_cst',
             'version',
             'svec_xloader_wb',
             '../issue28/wrc_syscon_wb']
    print_vhdl.style = 'wbgen'
    for f in files:
        if args.verbose:
            print('test wbgen2cheby: {}'.format(f))
        # Test Gena to Cheby conversion
        wbfile = srcdir + 'wbgen/' + f + '.wb'
        chebfile = srcdir + 'wbgen/' + f + '.cheby'
        buf = write_buffer()
        wbgen2cheby.convert(buf, wbfile)
        if not compare_buffer_and_file(buf, chebfile):
            error('wbgen2cheby conversion error for {}'.format(f))
        # Test parse+layout
        t = parse_ok(chebfile)
        layout_ok(t)
        # Test vhdl generation
        h = gen_wbgen_hdl.expand_hdl(t)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, h)
        hdlfile = srcdir + 'wbgen/' + f + '.vhdl'
        if not compare_buffer_and_file(buf, hdlfile):
            error('wbgen vhdl generation error for {}'.format(f))
        nbr_tests += 1
    print_vhdl.style = None


def test_consts():
    # Generate constants and compare with a baseline.
    global nbr_tests

    for f in ['demo_all', 'features/semver1', 'features/mapinfo1',
              'issue64/simple_reg1', 'issue_g2/reg', 'bug-consts/blkpfx',
              'features/enums1', 'features/enums2', 'bug-const-range/const_range',
              'features/memwide_ua', 'bug-same-label/same_label', 'issue143/map',
              'mr67/top']:
        if args.verbose:
            print('test consts: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '-consts.vhdl'
        vhdl_ohwr_file = srcdir + f + '-consts.vhdl-ohwr'
        verilog_file = srcdir + f + '-consts.v'
        systemverilog_file = srcdir + f + '-consts.sv'
        c_file = srcdir + f + '-consts.h'
        t = parse_ok(chebfile)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)

        for file, style in [(verilog_file, 'verilog'), (systemverilog_file, 'sv'),
                            (vhdl_file, 'vhdl'), (vhdl_ohwr_file, 'vhdl-ohwr'),
                            (c_file, 'h')]:
            buf = write_buffer()
            print_consts.pconsts_cheby(buf, t, style)
            if not compare_buffer_and_file(buf, file):
                error('consts {} generation error for {}'.format(style, f))

            if args.elaborate:
                # Elaboration tests

                if style == 'vhdl' or style == 'vhdl-ohwr':
                    # Elaborate VHDL using GHDL
                    elab_vhdl(file)

                # We don't test SV elaboration here because Verilator requires a top-level instance

                if style == 'h':
                    check_c_syntax(file)

        nbr_tests += 1

def test_doc():
    # Generate html and md, compare with a baseline.
    global nbr_tests
    for f in ['issue9/test', 'features/semver1', 'issue84/sps200CavityControl_as', 'issue67/repeatInRepeat']:
        if args.verbose:
            print('test doc: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        html_file = srcdir + f + '.html'
        md_file = srcdir + f + '.md'
        rst_file = srcdir + f + '.rst'
        latex_file = srcdir + f + '.tex'
        t = parse_ok(chebfile)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        layout.sort_tree(t)

        for file, pprint, style in [
                (html_file, print_html.print_html, 'html'),
                (md_file, print_markdown.print_markdown, 'md'),
                (rst_file, print_rest.print_rest, 'rst'),
                (latex_file, print_latex.print_latex, 'latex')]:
            buf = write_buffer()
            pprint(buf, t)
            if not compare_buffer_and_file(buf, file):
                error('doc {} generation error for {}'.format(style, f))
        nbr_tests += 1


def test_custom():
    global nbr_tests
    for f in ['custom/fidsErrMiss']:
        if args.verbose:
            print('test custom: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        c_file = srcdir + f + '.h'
        t = parse_ok(chebfile)
        layout_ok(t)
        buf = write_buffer()
        # We need to change working directory
        cwd = os.getcwd()
        os.chdir(srcdir + '/custom')
        gen_custom.generate_custom(buf, t, 'gen_custom.py')
        os.chdir(cwd)
        if not compare_buffer_and_file(buf, c_file):
            error('custom generation error for {}'.format(f))
        nbr_tests += 1

def test_edge3():
    global nbr_tests
    # don't test 'issue84/sps200CavityControl', too incompatible to rework
    for f in ['issue124/project', 'issue129/acdipole_ip', 'issue128/acdipole_ip']:
        if args.verbose:
            print('test edge3: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        edgefile = srcdir + f + '.csv'
        # simple test for no exceptions if no edgefile
        t = parse_ok(chebfile)
        layout_ok(t)
        buf = write_buffer()
        gen_edge3.generate_edge3(buf, t)
        if os.path.exists(edgefile):
            if args.verbose:
                print('testing with edge3 file: {}'.format(edgefile))
            if not compare_buffer_and_file(buf, edgefile):
                error('edge3 generation error for {}'.format(f))
        nbr_tests += 1

def test_silecs():
    global nbr_tests
    for f in ['silecs/fids-errmiss']:
        if args.verbose:
            print('test SILECS: {}'.format(f))
        chebfile = srcdir + f + '.cheby'
        silecsfile = srcdir + f + '.silecsdesign'
        # simple test for no exceptions
        t = parse_ok(chebfile)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_memmap(t)
        buf = write_buffer()
        gen_silecs.generate_silecs(buf, t)
        if args.verbose:
            print('testing with SILECS file: {}'.format(silecsfile))
        if not compare_buffer_and_file(buf, silecsfile):
            error('SILECS generation error for {}'.format(f))
        nbr_tests += 1

def main():
    global args

    # Crude
    aparser = argparse.ArgumentParser(description='cheby tests')
    aparser.add_argument('-v', '--verbose', action='store_true', help='Enable additional prints.')
    aparser.add_argument('-r', '--regen', action='store_true', help='Regenerate golden test files.')
    aparser.add_argument('-k', '--keep', action='store_true', help='Keep running tests after an error occured.')
    aparser.add_argument('-e', '--elaborate', action='store_true', help='Enable elaboration/compilation tests.')
    args = aparser.parse_args()

    try:
        
        test_self()
        test_parser()
        test_layout()
        test_print()
        test_gconfig_scope()
        test_genc_ref()
        test_hdl_library_names()
        test_hdl()
        test_hdl_err()
        test_hdl_ref()
        test_hdl_ref_async_rst()
        test_hdl_ref_preset_preload()
        test_verilog_ref()
        test_sv_ref()
        test_issue84()
        test_gena()
        test_gena_regctrl_err()
        test_gena2cheby()
        test_gena2cheby_err()
        test_gena2cheby_regressions()
        test_gena_gen_regressions()
        test_gena_dsp_regressions()
        test_wbgen2cheby()
        test_consts()
        test_doc()
        test_custom()
        test_edge3()
        test_silecs()
        print("Done ({} tests)!".format(nbr_tests))
    except TestError as e:
        werr(e.msg)
        sys.exit(2)


if __name__ == '__main__':
    main()
