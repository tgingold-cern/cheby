from cheby.hdl.buses import name_to_busgen
from cheby.hdl.busparams import BusOptions
from cheby.hdl.geninterface import GenInterface


class GenSubmap(GenInterface):
    def gen_ports(self):
        n = self.n
        opts = BusOptions(n.c_submap, n.c_submap)
        n.h_busgen = name_to_busgen(n.c_submap.bus, self.root, self.module)
        n.h_busgen.gen_bus_slave(n.c_name + '_', n, opts)
