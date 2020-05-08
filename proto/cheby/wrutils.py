# Very simple wrappers

def w(fd, s):
    fd.write(s)


def wln(fd, s=""):
    fd.write(s)
    fd.write('\n')


def windent(fd, indent):
    w(fd, '  ' * indent)
