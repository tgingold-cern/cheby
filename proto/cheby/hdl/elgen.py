from cheby.hdl.globals import dirname
from cheby.hdltree import (HDLInterfaceSelect,
                           bit_0,
                           HDLIndex, HDLReplicate, Slice_or_Index)


class ElGen(object):
    def __init__(self, root, module, n):
        self.root = root
        self.module = module
        self.n = n

    def add_module_port(self, name, size, dir):
        "Utility function to easily add a port to :param module:"
        if self.root.h_itf is None:
            return self.module.add_port(name + '_' + dirname[dir], size, dir=dir)
        else:
            p = self.root.h_itf.add_port(name, size, dir=dir)
            return HDLInterfaceSelect(self.root.h_ports, p)

    def create_generators(self):
        """Add the object to generate hdl"""
        pass
    
    def gen_port(self, root, module, name, size, dir):
        pass

    def gen_processes(self, root, module, ibus, n):
        pass

    def gen_read(self, root, s, n, off, ibus, rdproc):
        pass

    def gen_write(self, root, s, n, off, ibus, wrproc):
        pass
