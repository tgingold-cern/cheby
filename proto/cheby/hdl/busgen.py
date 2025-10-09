from cheby.hdltree import HDLInterfaceSelect
from cheby.gen_name import concat

class BusGen(object):
    """The purpose of BusGen is to abstract the buses.
    Internally, there is one bus for read acces, and one bus for write access.
    TODO: the current implementation doesn't use a pulse.

    For the read access:
    inputs:
    * rd_req: a pulse indicating a read access
    * adrr: address, valid and stable during the access.
    outputs:
    * rd_ack: a pulse indicating the results are valid,
    and that the access is ended.
    * dato: the data, valid only when rd_ack is set.

    For the write access:
    inputs:
    * wr_req: a pulse indicating a write access
    * adrw: the address, valid and stable during the access.
    * dati: the data, valid and stable during the access.
    outputs:
    * wr_ack: a pulse indicating the access is finished.

    There can be at most one read access on fly and at most one write access
    on fly.
    There can be one read access in parallel to a write access.
    """

    def __init__(self, root, module):
        self.root = root
        self.module = module

    def add_module_port(self, n, suffix_name, size=None, lo_idx=0, dir='IN'):
        "Utility function to easily add a port to :param module:"
        if self.root.h_itf is None:
            return self.module.add_port(
                n.c_name + '_' + suffix_name, size, lo_idx, dir=dir)
        else:
            p = self.root.h_itf.add_port(concat(n.c_itfname, suffix_name), size, lo_idx, dir=dir)
            return HDLInterfaceSelect(self.root.h_ports, p)

    def expand_bus(self, ibus):
        """Create bus interface for the design."""
        raise AssertionError("Not implemented")

    def gen_bus_slave(self, prefix, n, opts):
        """Create an interface to a slave (Add declarations)"""
        raise AssertionError("Not implemented")

    def wire_bus_slave(self, n, ibus):
        """Create HDL for the interface (Assignments)"""
        raise AssertionError("Not implemented")

    def write_bus_slave(self, stmts, n, proc, ibus):
        """Set bus slave signals to write"""
        raise AssertionError("Not implemented")

    def read_bus_slave(self, stmts, n, proc, ibus, rd_data):
        """Set bus slave signals to read"""
        raise AssertionError("Not implemented")
