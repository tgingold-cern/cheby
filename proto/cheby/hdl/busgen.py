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

    def expand_bus(self, root, module, ibus):
        """Create bus interface for the design."""
        raise AssertionError("Not implemented")

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        """Create an interface to a slave (Add declarations)"""
        raise AssertionError("Not implemented")

    def wire_bus_slave(self, root, module, n, ibus):
        """Create HDL for the interface (Assignments)"""
        raise AssertionError("Not implemented")

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        """Set bus slave signals to write"""
        raise AssertionError("Not implemented")

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        """Set bus slave signals to read"""
        raise AssertionError("Not implemented")
