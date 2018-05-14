#! /usr/bin/env python
"""Simple test program"""
import sys
import os
import subprocess
import cheby.parser as parser
import cheby.layout as layout
import cheby.pprint as pprint
import cheby.sprint as sprint
import cheby.cprint as cprint
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl
import cheby.gen_laychk as gen_laychk
import cheby.expand_hdl as expand_hdl
import cheby.gen_gena_memmap as gen_gena_memmap
import cheby.gen_gena_regctrl as gen_gena_regctrl
import gena2cheby

srcdir = '../testfiles/'
verbose = False

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
    for f in ['demo.yaml', 'simple_reg1.yaml', 'simple_reg2.yaml',
              'block1.yaml', 'block2.yaml', 'block3.yaml', 'block4.yaml']:
        parse_ok(srcdir + f)
    for f in ['no-such-file.yaml', 'error1.yaml',
              'err_name_type1.yaml', 'err_width_type1.yaml',
              'err_align_type1.yaml',
              'parse_err_elem1.yaml', 'parse_err_elem2.yaml',
              'parse_err_reg1.yaml',
              'parse_err_field1.yaml', 'parse_err_field2.yaml',
              'parse_err_field3.yaml',
              'parse_err_array1.yaml', 'parse_err_array2.yaml',
              'parse_err_block1.yaml']:
        parse_err(srcdir + f)


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
    for f in ['demo.yaml', 'block1.yaml', 'array1.yaml', 'array2.yaml']:
        if verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_ok(t)
        hname = t.name + '.h'
        cname = t.name + '.c'
        with open(hname, 'w') as fd:
            cprint.cprint_cheby(fd, t)
        with open(cname, 'w') as fd:
            gen_laychk.gen_chklayout_cheby(fd, t)
        subprocess.check_call(['gcc', '-S', cname])
        os.remove(hname)
        os.remove(cname)
        os.remove(t.name + '.s')
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
              'err_block_size1.yaml']:
        if verbose:
            print('test layout: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_err(t)


def test_print():
    fd = write_null()
    for f in ['demo.yaml', 'reg_value1.yaml', 'reg_value2.yaml',
              'reg_value3.yaml']:
        t = parse_ok(srcdir + f)
        layout_ok(t)
        pprint.pprint_cheby(fd, t)
        sprint.sprint_cheby(fd, t)
        cprint.cprint_cheby(fd, t)


def test_hdl():
    fd = write_null()
    for f in ['simple_reg3.yaml', 'simple_reg4_ro.yaml',
              'reg_value1.yaml', 'reg_value2.yaml', 'reg_value3.yaml',
              'field_value1.yaml', 'field_value2.yaml',
              'wb_slave_vic.cheby']:
        if verbose:
            print('test hdl: {}'.format(f))
        t = parse_ok(srcdir + f)
        layout_ok(t)
        expand_hdl.expand_hdl(t)
        h = gen_hdl.generate_hdl(t)
        print_vhdl.print_vhdl(fd, h)


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
    test((lambda : parse_ok(srcdir + 'error1.yaml')), "parse_ok")
    test((lambda : parse_err(srcdir + 'simple_reg1.yaml')), "parse_err")
    t = parse_ok(srcdir + 'err_bus_name.yaml')
    test((lambda : layout_ok(t)), "layout_ok")
    t = parse_ok(srcdir + 'demo.yaml')
    test((lambda : layout_err(t)), "layout_err")


def compare_buffer_and_file(buf, filename):
    buf = buf.buffer
    ref = open(filename, 'r').read()
    if ref == buf:
        return True

    buf_lines = buf.splitlines()
    ref_lines = ref.splitlines()
    nlines = len(buf_lines)
    if nlines != len(ref_lines):
        werr('Number of lines mismatch')
    for i in range(nlines):
        if buf_lines[i] == ref_lines[i]:
            continue
        print('>' + buf_lines[i])
        print('<' + ref_lines[i])
    return False


def test_gena():
    files=['CRegs', 'CRegs_Regs', 'CRegs_NoRMW', 'CRegs_Regs_NoRMW',
           'Regs', 'Regs_Mems',
           'Mems', 'Mems2', 'CRegs_Mems', 'CRegs_Regs_Mems',
           'Area_CRegs_Regs_Mems', 'Area_CRegs_Regs_Mems_EmptyRoot',
           'Area_Mems',
           'CRegs_wrstrobe', 'CRegs_srff', 'CRegs_resize', 'CRegs_nosplit',
           'CRegs_busout']
    for f in files:
        if verbose:
            print('test gena: {}'.format(f))
        # Test Gena to Cheby conversion
        xmlfile = srcdir + 'gena/' + f + '.xml'
        chebfile = srcdir + 'gena/' + f + '.cheby'
        t = gena2cheby.convert(xmlfile)
        buf = write_buffer ()
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
        memmapfile = srcdir + 'gena/' + 'MemMap_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, memmapfile):
            error('gena memmap generation error for {}'.format(f))
        # Test regctrl generation
        hregctrl = gen_gena_regctrl.gen_gena_regctrl(t)
        buf = write_buffer()
        print_vhdl.print_vhdl(buf, hregctrl)
        regctrlfile = srcdir + 'gena/' + 'RegCtrl_' + t.name + '.vhd'
        if not compare_buffer_and_file(buf, regctrlfile):
            error('gena regctrl generation error for {}'.format(f))

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
        test_gena()
        print("Done!")
    except TestError as e:
        werr(e.msg)
        sys.exit(2)

if __name__ == '__main__':
    main()
