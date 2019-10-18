from cheby.hdl.elgen import ElGen
from cheby.hdltree import (HDLComment)
from cheby.hdl.buses import name_to_busgen

class GenInterface(ElGen):
    def gen_ports(self, root, module, n):
        # Generic submap.
        busgroup = n.get_extension('x_hdl', 'busgroup')
        n.h_busgen = name_to_busgen(n.interface)
        n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)

    def gen_processes(self, root, module, ibus, n):
        module.stmts.append(HDLComment('Interface {}'.format(n.c_name)))
        n.h_busgen.wire_bus_slave(root, module, n, ibus)

    def gen_read(self, root, s, n, off, ibus, rdproc):
        n.h_busgen.read_bus_slave(root, s, n, rdproc, ibus, ibus.rd_dat)

    def gen_write(self, root, s, n, off, ibus, wrproc):
        n.h_busgen.write_bus_slave(root, s, n, wrproc, ibus)


