"""Simple test program"""
import sys
import cheby.parser as parser

srcdir = '../testfiles/'


def error(msg):
    sys.stderr.write('error: {}\n'.format(msg))
    sys.exit(1)


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
              'parse_err_elem1.yaml', 'parse_err_elem2.yaml',
              'parse_err_reg1.yaml',
              'parse_err_field1.yaml', 'parse_err_field2.yaml',
              'parse_err_field3.yaml',
              'parse_err_array1.yaml', 'parse_err_array2.yaml',
              'parse_err_block1.yaml']:
        parse_err(srcdir + f)


def main():
    test_parser()


if __name__ == '__main__':
    main()
