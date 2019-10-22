from cheby.hdl.globals import dirname
from cheby.hdltree import (HDLInterfaceSelect,
                           bit_0,
                           HDLIndex, HDLReplicate, Slice_or_Index)


class ElGen(object):
    def gen_port(self, root, module, name, size, dir):
        pass

    def gen_processes(self, root, module, ibus, n):
        pass

    def gen_read(self, root, s, n, off, ibus, rdproc):
        pass

    def gen_write(self, root, s, n, off, ibus, wrproc):
        pass


def add_module_port(root, module, name, size, dir):
    "Utility function to easily add a port to :param module:"
    if root.h_itf is None:
        return module.add_port(name + '_' + dirname[dir], size, dir=dir)
    else:
        p = root.h_itf.add_port(name, size, dir=dir)
        return HDLInterfaceSelect(root.h_ports, p)
