#! /usr/bin/env python3
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
import cheby.print_rest as print_rest
import cheby.gen_custom as gen_custom

srcdir = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                      '../testfiles/')
verbose = False
flag_regen = False
flag_keep = False
nbr_tests = 0


class TestError(Exception):
    def __init__(self, msg):
        self.msg = msg


def werr(str):
    sys.stderr.write(str + '\n')


def error(msg):
    if flag_keep:
        werr('error: {}'.format(msg))
    else:
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
    for f in ['demo', 'features/simple_reg1', 'features/simple_reg2',
              'features/block1', 'features/submap2', 'features/submap3',
              'features/block4', 'parser/extension1']:
        f += '.cheby'
        if verbose:
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
        if verbose:
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
    for f in ['demo', 'features/block1', 'features/array1', 'features/array2',
              'bug-gen-c/fids-errmiss',
              'bug-gen-c-02/mbox_regs',
              'bug-gen-c-02/fip_urv_regs']:
        f += '.cheby'
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
        hfiles.append(hname)
        os.remove(cname)
        os.remove(t.name + '.s')
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
              'issue14/test-err',
              'issue57/m1', 'issue71/m1']:
        f += '.cheby'
        if verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_err(t)
        nbr_tests += 1


def test_print():
    global nbr_tests
    fd = write_null()
    for f in ['demo', 'features/reg_value1', 'features/reg_value2',
              'features/reg_value3', 'demo_all', 'features/semver1',
              'issue55/modulation']:
        f += '.cheby'
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
    if flag_regen:
        open(filename, 'w').write(buf)
        werr('Regenerate {}'.format(filename))
        return True
    buf_lines = buf.splitlines()
    ref_lines = ref.splitlines()
    nlines = len(buf_lines)
    if nlines != len(ref_lines):
        werr('Number of lines mismatch')
        return False
    if flag_keep:
        return False
    for i in range(nlines):
        if buf_lines[i] == ref_lines[i]:
            print('=' + buf_lines[i])
            continue
        print('>' + buf_lines[i])
        print('<' + ref_lines[i])
    return False


def test_hdl():
    # Just generate vhdl (without baseline)
    global nbr_tests
    fd = write_null()
    for f in ['features/simple_reg3', 'features/simple_reg4_ro',
              'features/reg_value1', 'features/reg_value2', 'features/reg_value3',
              'features/field_value1', 'features/field_value2',
              'features/field_range1',
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
              'issue60/busgroup-interface']:
        if verbose:
            print('test hdl: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
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


def gen_name_err(t):
    try:
        gen_name.gen_name_root(t)
    except parser.ParseException:
        return
    error('hdl error expected for {}'.format(t.name))


def test_hdl_err():
    global nbr_tests
    # Error in expand_hdl
    for f in ['issue11/test_port1_err1', 'issue11/test_port_err2',
              'access/const_err_wo', 'access/const_err_nopreset',
              'access/autoclear_err_ro',
              'access/orclr_err_ro', 'access/orclr_err_wo']:
        if verbose:
            print('test hdl error: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl_err(t)
        gen_name.gen_name_root(t)
        nbr_tests += 1
    # Error in gen_name
    for f in ['issue65/m1']:
        if verbose:
            print('test hdl error: {}'.format(f))
        t = parse_ok(srcdir + f + '.cheby')
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name_err(t)
        nbr_tests += 1


def test_hdl_ref():
    # Generate vhdl and compare with a baseline.
    global nbr_tests
    for f in ['fmc-adc01/fmc_adc_alt_trigin', 'fmc-adc01/fmc_adc_alt_trigout',
              'issue9/test', 'issue10/test',
              'issue8/simpleMap_bug', 'issue8/simpleMap_noBug',
              'issue14/test-axi', 'issue14/test-be', 'issue14/test-le',
              'issue11/test_port1_reg', 'issue11/test_port1',
              'issue11/test_port1_field',
              'issue11/test_port2_reg', 'issue11/test_port2_wire',
              'issue13/mainMap2', 'memory01/mainMap',
              'issue39/addressingMemory',
              'issue40/bugConstraints',
              'issue41/bugBlockFields',
              'issue45/test8', 'issue45/test16',
              'features/wires1', 'features/semver1', 'features/semver2',
              'features/mapinfo2',
              'features/enums1', 'features/enums2', 'features/enums3',
              'features/orclrout_rw',
              'features/blkprefix1', 'features/blkprefix2',
              'features/regprefix1', 'features/regprefix2',
              'issue52/hwInfo',
              'bug-gen_wt/m1',
              'issue59/inherit', 'issue64/simple_reg1', 'issue66/m1',
              'issue44/m1']:
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
    test((lambda: parse_err(srcdir + 'features/simple_reg1.cheby')), "parse_err")
    t = parse_ok(srcdir + 'layout/err_bus_name.cheby')
    test((lambda: layout_ok(t)), "layout_ok")
    t = parse_ok(srcdir + 'demo.cheby')
    test((lambda: layout_err(t)), "layout_err")


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
             'bit_field_gen', 'reg_name_boolean']
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
        if verbose:
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
             'issue68/m1', 'issue70/m3']
    for f in files:
        if verbose:
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
             '../issue28/wrc_syscon_wb']
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
    for f in ['demo_all', 'features/semver1', 'features/mapinfo1', 'issue64/simple_reg1']:
        if verbose:
            print('test consts: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        vhdl_file = srcdir + f + '-consts.vhdl'
        vhdl_ohwr_file = srcdir + f + '-consts.vhdl-ohwr'
        verilog_file = srcdir + f + '-consts.v'
        c_file = srcdir + f + '-consts.h'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)

        for file, style in [(verilog_file, 'verilog'),
                            (vhdl_file, 'vhdl'), (vhdl_ohwr_file, 'vhdl-ohwr'),
                            (c_file, 'h')]:
            buf = write_buffer()
            print_consts.pconsts_cheby(buf, t, style)
            if not compare_buffer_and_file(buf, file):
                error('consts {} generation error for {}'.format(style, f))
        nbr_tests += 1


def test_doc():
    # Generate html and md, compare with a baseline.
    global nbr_tests
    for f in ['issue9/test', 'features/semver1']:
        if verbose:
            print('test doc: {}'.format(f))
        cheby_file = srcdir + f + '.cheby'
        html_file = srcdir + f + '.html'
        md_file = srcdir + f + '.md'
        rst_file = srcdir + f + '.rst'
        t = parse_ok(cheby_file)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        gen_name.gen_name_root(t)

        for file, pprint, style in [
                (html_file, print_html.pprint, 'html'),
                (md_file, print_markdown.print_markdown, 'md'),
                (rst_file, print_rest.print_rest, 'rst')]:
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
    global verbose, flag_regen, flag_keep

    # Crude
    if '-v' in sys.argv[1:]:
        verbose = True
    if '--regen' in sys.argv[1:]:
        flag_regen = True
    if '-k' in sys.argv[1:]:
        flag_keep = True

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
        test_gena2cheby_regressions()
        test_gena_gen_regressions()
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
