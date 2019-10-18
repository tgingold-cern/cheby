from cheby.hdl.buses import name_to_busgen
from cheby.hdl.geninterface import GenInterface


class GenSubmap(GenInterface):
    def gen_ports(self, root, module, n):
        busgroup = n.c_submap.get_extension('x_hdl', 'busgroup')
        n.h_busgen = name_to_busgen(n.c_submap.bus)
        n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)
