from cheby.hdltree import HDLAssign, HDLSync, HDLComment, HDLBinConst, bit_0
from cheby.hdl.globals import gconfig


class Ibus:
    """Internal bus.
       This bus is used internally to connect elements.
       This is a very simple bus: A pulse is sent on the *_req wire, and the transaction is finished
       when a pulse is received on the *_ack wire.  Can be combinational.  The address must be
       stable during the transaction.
    """
    def __init__(self):
        # Size
        self.data_size = None
        self.addr_size = None
        self.addr_low = None
        # Read signals (in and out)
        self.rd_req = None      # Read request
        self.rd_req_del = None  # Delayed read request
                                # (sometimes used to delay acknowledges in case of
                                #  request errors)
        self.rd_ack = None      # Read acknowledge
        self.rd_err = None      # Read error
        self.rd_adr = None      # Read address
        self.rd_dat = None      # Read data
        # Write signals (in and out)
        self.wr_req = None      # Write request
        self.wr_req_del = None  # Delayed write request
                                # (sometimes used to delay acknowledges in case of
                                #  request errors)
        self.wr_ack = None      # Write acknowledge
        self.wr_err = None      # Write error
        self.wr_adr = None      # Write address
        self.wr_dat = None      # Write data
        self.wr_sel = None      # Write mask

    def pipeline(self, root, module, conds, suffix):
        """Create a new ibus by adding registers to self according to :param conds:
           :param suffix: is used to create signals name.
        """
        if not conds:
            # No pipelining.
            return self
        res = Ibus()
        res.addr_size = self.addr_size
        res.data_size = self.data_size
        res.addr_low = self.addr_low
        names = []
        c_ri = 'rd-in' in conds
        names.extend([('rd_req', c_ri, 'i', None, None),
                      ('rd_req_del', c_ri, 'i', None, None),
                      ('rd_adr', c_ri, 'i', self.addr_size, self.addr_low)])
        c_ro = 'rd-out' in conds
        names.extend([('rd_ack', c_ro, 'o', None, None),
                      ('rd_err', c_ro, 'o', None, None),
                      ('rd_dat', c_ro, 'o', self.data_size, 0)])
        c_wi = 'wr-in' in conds
        copy_wa = (self.rd_adr == self.wr_adr) and (c_wi == c_ri)
        names.extend([('wr_req', c_wi, 'i', None, None),
                      ('wr_req_del', c_wi, 'i', None, None),
                      ('wr_adr', c_wi, 'i', self.addr_size, self.addr_low),
                      ('wr_dat', c_wi, 'i', self.data_size, 0),
                      # The write mask of the internal bus operates on a per bit level.
                      # In case of a more coarse selection at an upper interface
                      # driving the internal bus, it is supposed that the EDA tool will
                      # make the necessary optimizations to propagate the reduce mask
                      # width down to the application of it in the internal bus.
                      ('wr_sel', c_wi, 'i', self.data_size, 0)])
        c_wo = 'wr-out' in conds
        names.extend([('wr_ack', c_wo, 'o', None, None),
                      ('wr_err', c_wo, 'o', None, None)])
        module.stmts.append(HDLComment("pipelining for {}".format('+'.join(conds))))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'],
                       rst_sync=gconfig.rst_sync)
        for n, c, d, sz, lo in names:
            if n == 'wr_adr' and copy_wa:
                # If wr_adr == rd_adr in both self and future res, do not create a signal,
                # simply copy it.
                continue

            sig = getattr(self, n)
            if sig is None or sz == 0:
                # Address signals may not exist.
                w = None

            elif c:
                w = module.new_HDLSignal(n + suffix, sz, lo)

                # Reset value of pipeline
                if w.size is None:
                    cnst = bit_0
                else:
                    cnst = HDLBinConst(0, w.size)

                if d == 'i':
                    asgn = HDLAssign(w, cnst)
                else:
                    asgn = HDLAssign(sig, cnst)
                proc.rst_stmts.append(asgn)

                # Synchronous assignment of pipeline
                if d == 'i':
                    asgn = HDLAssign(w, sig)
                else:
                    asgn = HDLAssign(sig, w)
                proc.sync_stmts.append(asgn)

            else:
                w = sig

            setattr(res, n, w)

        if copy_wa:
            res.wr_adr = res.rd_adr
        module.stmts.append(proc)

        return res


def add_bus(root, module, bus):
    root.h_bus = {}
    for n, h in bus:
        if h is not None:
            module.ports.append(h)
        root.h_bus[n] = h
