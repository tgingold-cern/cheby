#!/usr/bin/env python
import sys
import parser
import pprint


def main():
    if len(sys.argv) == 1:
        print("error: no input file")
        sys.exit(2)
    else:
        for f in sys.argv[1:]:
            try:
                t = parser.parse_yaml(f)
            except parser.ParseException as e:
                sys.stderr.write("{}: {}\n".format(f, e.msg))
                sys.exit(2)
            pprint.pprint_cheby(sys.stdout, t)


if __name__ == '__main__':
    main()
