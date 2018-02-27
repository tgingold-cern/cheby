"""Simple test program"""
import sys
import cheby.parser as parser
import cheby.layout as layout
import cheby.pprint as pprint
import cheby.sprint as sprint
import cheby.cprint as cprint
import cheby.gen_hdl as gen_hdl
import cheby.print_vhdl as print_vhdl

srcdir = '../testfiles/'


class TestError(Exception):
    def __init__(self, msg):
        self.msg = msg


def error(msg):
    raise TestError('error: {}\n'.format(msg))


class write_null(object):
    """A class that could be used as a very simple write-only stream"""
    def write(self, str):
        pass


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
    for f in ['demo.yaml', 'array1.yaml', 'array2.yaml']:
        t = parse_ok(srcdir + f)
        layout_ok(t)
    for f in ['err_bus_name.yaml',
              'err_reg_addr1.yaml', 'err_reg_addr2.yaml',
              'err_reg_width1.yaml',
              'err_reg_type1.yaml', 'err_reg_type2.yaml',
              'err_field1.yaml', 'err_field2.yaml', 'err_field3.yaml',
              'err_field4.yaml', 'err_field5.yaml',
              'err_noelements.yaml',
              'err_arr1.yaml']:
        t = parse_ok(srcdir + f)
        layout_err(t)


def test_print():
    fd = write_null()
    for f in ['demo.yaml']:
        t = parse_ok(srcdir + f)
        layout_ok(t)
        pprint.pprint_cheby(fd, t)
        sprint.sprint_cheby(fd, t)
        cprint.cprint_cheby(fd, t)


def test_hdl():
    fd = write_null()
    for f in ['simple_reg3.yaml', 'simple_reg4_ro.yaml']:
        t = parse_ok(srcdir + f)
        layout_ok(t)
        h = gen_hdl.generate_hdl(t)
        print_vhdl.print_vhdl(fd, h)


def test_self():
    """Auto-test"""
    def test(func, func_name):
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



def main():
    try:
        test_self()
        test_parser()
        test_layout()
        test_print()
        test_hdl()
        print("Done!")
    except TestError as e:
        sys.stderr.write(e.msg)
        sys.exit(2)

if __name__ == '__main__':
    main()
