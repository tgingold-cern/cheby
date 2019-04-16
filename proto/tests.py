#! /usr/bin/env python
"""Simple test program"""
import sys
import os
import subprocess
import cheby.parser as parser
import cheby.layout as layout
import cheby.pprint as pprint
import cheby.sprint as sprint
import cheby.gen_c as gen_c
import cheby.gen_name as gen_name
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.gen_laychk as gen_laychk
import cheby.expand_hdl as expand_hdl
import cheby.gen_gena_memmap as gen_gena_memmap
import cheby.gen_gena_regctrl as gen_gena_regctrl
import cheby.gena2cheby as gena2cheby
import cheby.wbgen2cheby as wbgen2cheby
import cheby.gen_wbgen_hdl as gen_wbgen_hdl
import cheby.print_consts as print_consts
import cheby.print_html as print_html
import cheby.print_markdown as print_markdown
import cheby.gen_custom as gen_custom

srcdir = '../testfiles/'
verbose = False
nbr_tests = 0

class TestError(Exception):
    def __init__(self, msg):
        self.msg = msg


def werr(str):
    sys.stderr.write(str + '\n')


def error(msg):
    raise TestError('error: {}'.format(msg))


class write_null(object):
    """A class that could be used as a very simple write-only stream"""
    def write(self, str):
        pass


class write_buffer(object):
    """A class that could be used as a very simple write stream"""
    def __init__(self):
        self.buffer = ''

    def write(self, str):
        self.buffer += str

    def get(self):
        return self.buffer


def parse_ok(f):
    try:
        return parser.parse_yaml(f)
    except parser.ParseException:
        error('unexpected parse error for {}'.format(f))


def parse_err(f):
    try:
        parser.parse_yaml(f)
    except parser.ParseException:
        return
    error('parse error expected for {}'.format(f))


def test_parser():
    global nbr_tests
    for f in ['demo.yaml', 'simple_reg1.yaml', 'simple_reg2.yaml',
              'block1.yaml', 'submap2.yaml', 'submap3.yaml', 'block4.yaml']:
        if verbose:
            print('test parser: {}'.format(f))
        parse_ok(srcdir + f)
        nbr_tests += 1
    for f in ['no-such-file.yaml', 'error1.yaml',
              'err_name_type1.yaml', 'err_width_type1.yaml',
              'err_align_type1.yaml',
              'parse_err_elem1.yaml', 'parse_err_elem2.yaml',
              'parse_err_reg1.yaml',
              'parse_err_field1.yaml', 'parse_err_field2.yaml',
              'parse_err_field3.yaml',
              'parse_err_array1.yaml', 'parse_err_array2.yaml',
              'parse_err_block1.yaml']:
        if verbose:
            print('test parser: {}'.format(f))
        parse_err(srcdir + f)
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
    for f in ['demo.yaml', 'block1.yaml', 'array1.yaml', 'array2.yaml',
              'bug-gen-c/fids-errmiss.cheby']:
        if verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_ok(t)
        hname = t.name + '.h'
        cname = t.name + '.c'
        gen_name.gen_name_root(t)
        with open(hname, 'w') as fd:
            gen_c.gen_c_cheby(fd, t, 'neutral')
            gen_c.gen_c_cheby(fd, t, 'arm')
        with open(cname, 'w') as fd:
            gen_laychk.gen_chklayout_cheby(fd, t)
        subprocess.check_call(['gcc', '-S', cname])
        os.remove(hname)
        os.remove(cname)
        os.remove(t.name + '.s')
        nbr_tests += 1
    for f in ['err_bus_name.yaml',
              'err_reg_addr1.yaml', 'err_reg_addr2.yaml',
              'err_reg_width1.yaml',
              'err_reg_type1.yaml', 'err_reg_type2.yaml',
              'err_reg_type3.yaml',
              'err_field1.yaml', 'err_field2.yaml', 'err_field3.yaml',
              'err_field4.yaml', 'err_field5.yaml', 'err_field6.yaml',
              'err_field_name1.yaml', 'err_field_name2.yaml',
              'err_reg_name1.yaml', 'err_reg_name2.yaml',
              'err_reg_acc1.yaml', 'err_reg_acc2.yaml',
              'err_field_preset1.yaml',
              'err_noelements.yaml',
              'err_arr1.yaml', 'err_arr2.yaml',
              'err_block_size1.yaml',
              'issue14/test-err.cheby']:
        if verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_err(t)
        nbr_tests += 1

def test_print():
    global nbr_tests
    fd = write_null()
    for f in ['demo.yaml', 'reg_value1.yaml', 'reg_value2.yaml',
              'reg_value3.yaml', 'demo_all.cheby']:
        t = parse_ok(srcdir + f)
        layout_ok(t)
        pprint.pprint_cheby(fd, t)
        sprint.sprint_cheby(fd, t)
        gen_name.gen_name_root(t)
        gen_c.gen_c_cheby(fd, t, 'neutral')
        nbr_tests += 1

def compare_buffer_and_file(buf, filename):
    # Well, there is certainly a python diff module...
    buf = buf.buffer
    ref = open(filename, 'r').read()
    if ref == buf:
        return True

    buf_lines = buf.splitlines()
    ref_lines = ref.splitlines()
    nlines = len(buf_lines)
    if nlines != len(ref_lines):
        werr('Number of lines mismatch')
        return
    for i in range(nlines):
        if buf_lines[i] == ref_lines[i]:
            print('=' + buf_lines[i])
            continue
        print('>' + buf_lines[i])
        print('<' + ref_lines[i])
    return False


def test_hdl():
    global nbr_tests
    fd = write_null()
    for f in ['simple_reg3.yaml', 'simple_reg4_ro.yaml',
              'reg_value1.yaml', 'reg_value2.yaml', 'reg_value3.yaml',
              'field_value1.yaml', 'field_value2.yaml',
              'wb_slave_vic.cheby',
              '../examples/svec-leds/leds.cheby',
              'inter-mt/mt_cpu_xb.cheby',
              'inter-mt/mt_cpu_xb-include.cheby',
              'inter-mt/mt_cpu_xb-extern.cheby',
              'inter-mt/mt_cpu_xb-busgroup.cheby',
              'inter-mt/mt_cpu_xb-busgroup2.cheby',
              'inter-mt/mt_cpu_lr-busgroup.cheby',
              'demo_all.cheby']:
        if verbose:
            print('test hdl: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)
        h = gen_hdl.generate_hdl(t)
        print_vhdl.print_vhdl(fd, h)
        nbr_tests += 1


def expand_hdl_err(t):
    try:
        expand_hdl.expand_hdl(t)
    except parser.ParseException:
        return
    error('hdl error expected for {}'.format(t.name))


def test_hdl_err():
    global nbr_tests
    fd = write_null()
    for f in ['issue11/test_port1_err1', 'issue11/test_port_err2']:
        if verbose:
            print('test hdl error: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl_err(t)
        gen_name.gen_name_root(t)
        nbr_tests += 1


def test_hdl_ref():
    # Generate vhdl and compare with a baseline.
    global nbr_tests
    for f in ['fmc_adc_alt_trigin', 'fmc_adc_alt_trigout',
              'issue9/test', 'issue10/test',
              'issue8/simpleMap_bug', 'issue8/simpleMap_noBug',
              'issue14/test-axi', 'issue14/test-be', 'issue14/test-le',
              'issue11/test_port1_reg', 'issue11/test_port1',
              'issue11/test_port1_field',
              'issue11/test_port2_reg', 'issue11/test_port2_wire',
              'issue13/mainMap2',
              'wires1']:
        if verbose:
            print('test hdl with ref: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '.vhdl'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)
        h = gen_hdl.generate_hdl(t)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, h)
        if not compare_buffer_and_file(buf, vhdl_file):
            error('vhdl generation error for {}'.format(f))
        nbr_tests += 1

def test_self():
    """Auto-test"""
    def test(func, func_name):
        if verbose:
            print('test self: {}'.format(func_name))
        ok = False
        try:
            func()
        except TestError:
            ok = True
        if not ok:
            error("self-test error for {}".format(func_name))
    test((lambda: parse_ok(srcdir + 'error1.yaml')), "parse_ok")
    test((lambda: parse_err(srcdir + 'simple_reg1.yaml')), "parse_err")
    t = parse_ok(srcdir + 'err_bus_name.yaml')
    test((lambda: layout_ok(t)), "layout_ok")
    t = parse_ok(srcdir + 'demo.yaml')
    test((lambda: layout_err(t)), "layout_err")


def test_gena():
    # Feature tests
    global nbr_tests
    files = ['CRegs', 'CRegs_Regs', 'CRegs_NoRMW', 'CRegs_Regs_NoRMW',
             'Regs', 'Regs_Mems', 'Regs_rdstrobe', 'Regs_nodff',
             'Regs_cross_words', 'Regs_small',
             'sub_reg_swap', 'sub_reg_one', 'sub_reg_preset',
             'sub_reg_preset2',
             'Mems', 'Mems2', 'Mems_RO', 'Mems_WO',
             'Mems_nodff', 'Mems_splitaddr',
             'CRegs_Mems', 'CRegs_Regs_Mems',
             'Area_CRegs_Regs_Mems', 'Area_CRegs_Regs_Mems_EmptyRoot',
             'Area_Mems', 'Area_extarea', 'Area_extarea_error',
             'Area_reserved',
             'CRegs_wrstrobe', 'CRegs_srff', 'CRegs_resize', 'CRegs_nosplit',
             'CRegs_busout', 'CRegs_extcreg', 'CRegs_extacm',
             'CRegs_nodff', 'CRegs_splitaddr', 'CRegs_library',
             'CRegs_resize_nosplit', 'CRegs_ignore', 'CRegs_Preset',
             'CRegs_Address', 'CRegs_resize_signed', 'CRegs_d8',
             'Submap', 'Submap_internal',
             'Muxed', 'Muxed2']
    for f in files:
        if verbose:
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
        nbr_tests += 1

def test_gena_regctrl_err():
    global nbr_tests
    files = ['Muxed_name', 'Muxed_code']
    for f in files:
        if verbose:
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
             'bit_field_gen']
    for f in files:
        if verbose:
            print('test gena2cheby: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'gena2cheby/' + f + '.xml'
        gena2cheby.convert(xmlfile)
        nbr_tests += 1

def test_gena2cheby_err():
    global nbr_tests
    files = ['err_memmap_acc_mode', 'err_root_attr', 'err_root_gen',
             'err_root_element', 'err_submap_child', 'err_submap_gen',
             'err_submap_attr', 'err_submap_include', 'err_comment',
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
        if verbose:
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
        except gena2cheby.UnknownTag:
            pass
        nbr_tests += 1

def test_gena_regressions():
    global nbr_tests
    files = ['issue7/code_fields']
    for f in files:
        if verbose:
            print('test gena regression: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + f + '.xml'
        chebfile = srcdir + f + '.cheby'
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
        (head, tail) = os.path.split(f)
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

def test_wbgen2cheby():
    global nbr_tests
    files = ['reg1', 'reg_field1', 'reg_in', 'reg_noprefix',
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
             'wb_freq_multi_count_cst']
    print_vhdl.style = 'wbgen'
    for f in files:
        if verbose:
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
    for f in ['demo_all']:
        if verbose:
            print('test consts: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '-consts.vhdl'
        verilog_file = srcdir + f + '-consts.v'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)

        for file, style in [(verilog_file, 'verilog'), (vhdl_file, 'vhdl')]:
            buf = write_buffer()
            print_consts.pconsts_cheby(buf, t, style)
            if not compare_buffer_and_file(buf, file):
                error('consts {} generation error for {}'.format(style, f))
        nbr_tests += 1

def test_doc():
    # Generate html and md, compare with a baseline.
    global nbr_tests
    for f in ['issue9/test']:
        if verbose:
            print('test doc: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        html_file = srcdir + f + '.html'
        md_file = srcdir + f + '.md'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)

        for file, pprint, style in [
                (html_file, print_html.pprint, 'html'),
                (md_file, print_markdown.print_markdown, 'md')]:
            buf = write_buffer()
            pprint(buf, t)
            if not compare_buffer_and_file(buf, file):
                error('doc {} generation error for {}'.format(style, f))
        nbr_tests += 1

def test_custom():
    global nbr_tests
    for f in ['custom/fidsErrMiss']:
        if verbose:
            print('test custom: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        c_file = srcdir + f + '.h'
        t = parse_ok(cheby_file)
        layout_ok(t)
        buf = write_buffer()
        # We need to change working directory
        cwd = os.getcwd()
        os.chdir(srcdir + '/custom')
        gen_custom.generate_custom(buf, t)
        os.chdir(cwd)
        if not compare_buffer_and_file(buf, c_file):
            error('custom generation error for {}'.format(f))
        nbr_tests += 1


def main():
    global verbose

    # Crude
    if '-v' in sys.argv[1:]:
        verbose = True

    try:
        test_self()
        test_parser()
        test_layout()
        test_print()
        test_hdl()
        test_hdl_err()
        test_hdl_ref()
        test_gena()
        test_gena_regctrl_err()
        test_gena2cheby()
        test_gena2cheby_err()
        test_gena_regressions()
        test_wbgen2cheby()
        test_consts()
        test_doc()
        test_custom()
        print("Done ({} tests)!".format(nbr_tests))
    except TestError as e:
        werr(e.msg)
        sys.exit(2)


if __name__ == '__main__':
    main()
