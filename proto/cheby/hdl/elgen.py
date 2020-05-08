from cheby.hdl.globals import dirname
from cheby.hdltree import HDLInterfaceSelect


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

    def gen_processes(self, ibus):
        pass

    def gen_read(self, s, off, ibus, rdproc):
        pass

    def gen_write(self, s, off, ibus, wrproc):
        pass
