from cheby.hdl.elgen import ElGen
from cheby.hdltree import (HDLComment)
from cheby.hdl.buses import name_to_busgen
from cheby.hdl.busparams import BusOptions


class GenInterface(ElGen):
    def gen_ports(self):
        # Generic submap.
        n = self.n
        opts = BusOptions(n, self.root)
        n.h_busgen = name_to_busgen(n.interface, self.root, self.module)
        n.h_busgen.gen_bus_slave(n.c_name + '_', n, opts)

    def gen_processes(self, ibus):
        n = self.n
        self.module.stmts.append(HDLComment('Interface {}'.format(n.c_name)))
        n.h_busgen.wire_bus_slave(n, ibus)

    def gen_read(self, s, off, ibus, rdproc):
        n = self.n
        n.h_busgen.read_bus_slave(s, n, rdproc, ibus, ibus.rd_dat)

    def gen_write(self, s, off, ibus, wrproc):
        n = self.n
        n.h_busgen.write_bus_slave(s, n, wrproc, ibus)
