"""Create HDL for a Cheby description.

   Handling of names:
   Ideally we'd like to generate an HDL design that is error free.  But in
   practice, there could be some errors due to name conflict.  We try to do
   our best...
   A user name (one that comes from the Cheby description) get always a suffix,
   so that there is no conflict with reserved words.  The suffixes are:
   _i/_o for ports
   _reg for register
   However, it is supposed that the user name is valid and unique according to
   the HDL.  So for VHDL generation, it must be unique using case insensitive
   comparaison.
   The _i/_o suffixes are also used for ports, so the ports of the bus can
   also have conflicts with user names.
"""
from cheby.hdltree import (HDLModule, HDLPackage,
                           HDLInterface, HDLInterfaceSelect, HDLInstance,
                           HDLPort, HDLSignal,
                           HDLAssign, HDLSync, HDLComb, HDLComment,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLIfElse,
                           bit_1, bit_0, bit_x,
                           HDLAnd, HDLOr, HDLNot, HDLEq, HDLConcat,
                           HDLIndex, HDLSlice, HDLReplicate, Slice_or_Index,
                           HDLConst, HDLBinConst, HDLNumber, HDLBool, HDLParen)
import cheby.tree as tree
from cheby.layout import ilog2

dirname = {'IN': 'i', 'OUT': 'o'}


class Isigs(object):
    "Internal signals"
    pass


def add_bus(root, module, bus):
    root.h_bus = {}
    for n, h in bus:
        module.ports.append(h)
        root.h_bus[n] = h


class BusGen(object):
    """The purpose of BusGen is to abstract the buses.
    Internally, there is one bus for read acces, and one bus for write access.
    TODO: the current implementation doesn't use a pulse.

    For the read access:
    inputs:
    * rd_int: a pulse indicating a read access
    * adrr: address, valid and stable during the access.
    outputs:
    * rd_ack: a pulse indicating the results are valid, and that the access is ended.
    * dato: the data, valid only when rd_ack is set.

    For the write access:
    inputs:
    * wr_int: a pulse indicating a write access
    * adrw: the address, valid and stable during the access.
    * dati: the data, valid and stable during the access.
    outputs:
    * wr_ack: a pulse indicating the access is finished.

    There can be at most one read access on fly and at most one write access on fly.
    There can be one read access in parallel to a write access.
    """

    def expand_bus(self, root, module, isigs):
        """Create bus interface for the design."""
        raise AssertionError("Not implemented")

    def gen_bus_slave(self,root, module, prefix, n, busgroup):
        """Create an interface to a slave (Add declarations)"""
        raise AssertionError("Not implemented")

    def wire_bus_slave(self, root, stmts, n):
        """Create HDL for the interface (Assignments)"""
        raise AssertionError("Not implemented")

    def write_bus_slave(self, root, stmts, n, proc, isigs):
        """Set bus slave signals to write"""
        raise AssertionError("Not implemented")

    def read_bus_slave(self, root, stmts, n, proc, isigs, rd_data):
        """Set bus slave signals to read"""
        raise AssertionError("Not implemented")


class WBBus(BusGen):
    # Package wishbone_pkg that contains the wishbone interface
    wb_pkg = None
    wb_itf = None
    wb_ports = None

    def __init__(self, name):
        assert name == 'wb-32-be'

    def add_in_progress_reg(self, root, module, stb, ack, pfx):
        if root.h_pipeline:
            # The ack is not combinational, thus the strobe may stay longer
            # than one cycle.
            # Add an in progress 'wb_Xip' signal that is set on a strobe
            # and cleared on the ack.
            wb_xip = module.new_HDLSignal('wb_{}ip'.format(pfx))
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
            proc.rst_stmts.append(HDLAssign(wb_xip, bit_0))
            proc.sync_stmts.append(HDLAssign(
                wb_xip, HDLAnd(HDLOr(wb_xip, HDLParen(stb)), HDLNot(ack))))
            module.stmts.append(proc)
            return HDLAnd(stb, HDLNot(wb_xip))
        else:
            return stb

    def add_decode_wb(self, root, module, isigs):
        "Generate internal signals used by decoder/processes from WB bus."
        isigs.rd_int = module.new_HDLSignal('rd_int')        # Read access
        isigs.wr_int = module.new_HDLSignal('wr_int')        # Write access
        isigs.rd_ack = module.new_HDLSignal('rd_ack_int')    # Ack for read
        isigs.wr_ack = module.new_HDLSignal('wr_ack_int')    # Ack for write
        # Internal signals for wb.
        isigs.wb_en = module.new_HDLSignal('wb_en')
        isigs.ack_int = module.new_HDLSignal('ack_int')      # Ack
        module.stmts.append(
            HDLAssign(isigs.wb_en,
                      HDLAnd(root.h_bus['cyc'], root.h_bus['stb'])))
        module.stmts.append(HDLComment(None))

        # Read access
        rd_int = HDLAnd(isigs.wb_en, HDLNot(root.h_bus['we']))
        rd_int = self.add_in_progress_reg(root, module, rd_int, isigs.rd_ack, 'r')
        module.stmts.append(HDLAssign(isigs.rd_int, rd_int))
        module.stmts.append(HDLComment(None))

        # Write access
        wr_int = HDLAnd(isigs.wb_en, root.h_bus['we'])
        wr_int = self.add_in_progress_reg(root, module, wr_int, isigs.wr_ack, 'w')
        module.stmts.append(HDLAssign(isigs.wr_int, wr_int))
        module.stmts.append(HDLComment(None))

        # Ack
        module.stmts.append(HDLAssign(isigs.ack_int,
                                      HDLOr(isigs.rd_ack, isigs.wr_ack)))
        module.stmts.append(HDLAssign(root.h_bus['ack'], isigs.ack_int))

        # Stall
        module.stmts.append(
            HDLAssign(root.h_bus['stall'],
                      HDLAnd(HDLNot(isigs.ack_int), isigs.wb_en)))
        # No retry, no errors.
        module.stmts.append(HDLAssign(root.h_bus['rty'], bit_0))
        module.stmts.append(HDLAssign(root.h_bus['err'], bit_0))

    def gen_wishbone_bus(self, build_port, addr_bits, lo_addr,
                         data_bits, is_master):
        res = {}
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        res['cyc'] = build_port('cyc', None, dir=inp)
        res['stb'] = build_port('stb', None, dir=inp)
        if addr_bits > 0:
            res['adr'] = build_port('adr', addr_bits, lo_idx=lo_addr, dir=inp)
        res['sel'] = build_port('sel', data_bits // tree.BYTE_SIZE, dir=inp)
        res['we'] = build_port('we', None, dir=inp)
        res['dati'] = build_port('dat', data_bits, dir=inp)

        res['ack'] = build_port('ack', None, dir=out)
        res['err'] = build_port('err', None, dir=out)
        res['rty'] = build_port('rty', None, dir=out)
        res['stall'] = build_port('stall', None, dir=out)
        res['dato'] = build_port('dat', data_bits, dir=out)
        return res

    def gen_wishbone(self, module, ports, name, addr_bits, lo_addr,
                     data_bits, comment, is_master, is_bus):
        if is_bus:
            if WBBus.wb_pkg is None:
                self.gen_wishbone_pkg()
                module.deps.append(('work', 'wishbone_pkg'))
            port = ports.add_port_group(name, WBBus.wb_itf, is_master)
            port.comment = comment
            res = {}
            for name, sig in WBBus.wb_ports.items():
                res[name] = HDLInterfaceSelect(port, sig)
            return res
        else:
            res = self.gen_wishbone_bus(
                lambda n, sz, lo_idx=0, dir='IN': ports.add_port(
                    '{}_{}_{}'.format(name, n, dirname[dir]),
                    size=sz, lo_idx=lo_idx, dir=dir),
                addr_bits, lo_addr, data_bits, is_master)
            res['cyc'].comment = comment
            return res

    def gen_wishbone_pkg(self):
        """Create the wishbone_pkg package, so that interface can be
        referenced"""
        if WBBus.wb_pkg is not None:
            return
        WBBus.wb_pkg = HDLPackage('wishbone_pkg')
        WBBus.wb_itf = HDLInterface('t_wishbone')
        WBBus.wb_pkg.decls.append(WBBus.wb_itf)
        WBBus.wb_ports = self.gen_wishbone_bus(
            lambda n, sz, lo_idx=0, dir='IN':
                WBBus.wb_itf.add_port(n, size=sz, lo_idx=lo_idx, dir=dir),
            32, 0, 32, True)
        return

    def expand_bus(self, root, module, isigs):
        """Create wishbone interface for the design."""
        root.h_bus = {}
        root.h_bus['rst'] = module.add_port('rst_n_i')
        root.h_bus['clk'] = module.add_port('clk_i')

        busgroup = root.get_extension('x_hdl', 'busgroup')

        root.h_bus.update(self.gen_wishbone(
            module, module, 'wb', root.c_addr_bits, root.c_addr_word_bits,
            root.c_word_bits, None, False, busgroup is True))
        root.h_bussplit = False
        if root.c_addr_bits > 0:
            root.h_bus['adrr'] = root.h_bus['adr']
            root.h_bus['adrw'] = root.h_bus['adr']

        if isigs:
            # Bus access
            module.stmts.append(HDLComment('WB decode signals'))
            self.add_decode_wb(root, module, isigs)

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        n.h_busgroup = busgroup
        n.h_bus = self.gen_wishbone(
            module, module, n.name,
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            n.description, True, busgroup is True)
        # Internal signals
        # Read enable (set by decoding logic)
        n.h_re = module.new_HDLSignal(prefix + 're')
        # Transaction in progress (write, read, any)
        n.h_wt = module.new_HDLSignal(prefix + 'wt')
        n.h_rt = module.new_HDLSignal(prefix + 'rt')
        n.h_tr = module.new_HDLSignal(prefix + 'tr')
        # Ack
        n.h_wack = module.new_HDLSignal(prefix + 'wack')
        n.h_rack = module.new_HDLSignal(prefix + 'rack')
        if root.h_bussplit:
            # Request signals
            n.h_wr = module.new_HDLSignal(prefix + 'wr')
            n.h_rr = module.new_HDLSignal(prefix + 'rr')

    def slice_addr(self, addr, root, n):
        """Slice the input :param addr: (from the root bus) so that is can be
        assigned to the slave.  Take care of various sizes."""
        res = HDLSlice(addr, root.c_addr_word_bits, n.c_addr_bits)
        if not n.h_busgroup:
            return res
        if n.c_addr_bits < 32:
            res = HDLConcat(HDLReplicate(
                bit_0, 32 - root.c_addr_word_bits - n.c_addr_bits, False), res)
        if root.c_addr_word_bits > 0:
            res = HDLConcat(res, HDLReplicate(bit_0, root.c_addr_word_bits, False))
        return res

    def wire_bus_slave(self, root, stmts, n):
        stmts.append(HDLComment("Assignments for submap {}".format(n.name)))
        stmts.append(HDLAssign(n.h_tr, HDLOr(n.h_wt, n.h_rt)))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
        proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
        if root.h_bussplit:
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            proc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
            proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
            proc.sync_stmts.append(HDLAssign(n.h_wt,
                HDLAnd(HDLOr(n.h_wt, HDLParen(HDLAnd(n.h_wr, HDLNot(n.h_tr)))),
                    HDLNot(n.h_wack))))
            # RR is set by RD and cleared by ACK.
            proc.sync_stmts.append(HDLAssign(n.h_rr,
                HDLAnd(HDLOr(n.h_rr, n.h_re), HDLNot(n.h_rack))))
            # RT is set by RR and cleared by ACK
            proc.sync_stmts.append(HDLAssign(n.h_rt,
                HDLAnd(HDLOr(n.h_rt, HDLParen(HDLAnd(n.h_rr, HDLNot(HDLOr(n.h_wr, n.h_tr))))),
                    HDLNot(n.h_rack))))
        else:
            # RT is set by RD and cleared by ACK.
            proc.sync_stmts.append(HDLAssign(n.h_rt,
                HDLAnd(HDLOr(n.h_rt, n.h_re), HDLNot(n.h_rack))))
        stmts.append(proc)
        stmts.append(HDLAssign(n.h_bus['cyc'], n.h_tr))
        stmts.append(HDLAssign(n.h_bus['stb'], n.h_tr))
        stmts.append(HDLAssign(n.h_wack, HDLAnd(n.h_bus['ack'], n.h_wt)))
        stmts.append(HDLAssign(n.h_rack, HDLAnd(n.h_bus['ack'], n.h_rt)))
        if root.h_bussplit:
            proc = HDLComb()
            proc.sensitivity.extend([root.h_bus['adrr'], root.h_bus['adrw'], n.h_wt])
            if_stmt = HDLIfElse(HDLEq(n.h_wt, bit_1))
            if_stmt.then_stmts.append(HDLAssign(n.h_bus['adr'],
                                      self.slice_addr(root.h_bus['adrw'], root, n)))
            if_stmt.else_stmts.append(HDLAssign(n.h_bus['adr'],
                                      self.slice_addr(root.h_bus['adrr'], root, n)))
            proc.stmts.append(if_stmt)
            stmts.append(proc)
        else:
            stmts.append(HDLAssign(n.h_bus['adr'],
                                      self.slice_addr(root.h_bus['adr'], root, n)))
        stmts.append(HDLAssign(n.h_bus['sel'], HDLReplicate(bit_1, 4)))
        stmts.append(HDLAssign(n.h_bus['we'], n.h_wt))
        stmts.append(HDLAssign(n.h_bus['dati'], root.h_bus['dati']))

    def write_bus_slave(self, root, stmts, n, proc, isigs):
        if root.h_bussplit:
            proc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
            proc.sync_stmts.append(HDLAssign(n.h_wr, bit_0))
            # Set on WR, cleared by ACK.
            stmts.append(HDLAssign(n.h_wr,
                HDLAnd(HDLOr(n.h_wr, isigs.wr_int), HDLNot(n.h_wack))))
        else:
            # WT is set by WR and cleared by ACK.
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            proc.sync_stmts.append(HDLAssign(n.h_wt, bit_0))
            stmts.append(HDLAssign(n.h_wt,
                HDLAnd(HDLOr(n.h_wt, isigs.wr_int), HDLNot(n.h_wack))))
        stmts.append(HDLAssign(isigs.wr_ack, n.h_wack))

    def read_bus_slave(self, root, stmts, n, proc, isigs, rd_data):
        proc.stmts.append(HDLAssign(n.h_re, bit_0))
        stmts.append(HDLAssign(n.h_re, isigs.rd_int))
        proc.sensitivity.append(isigs.rd_int)
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        # Propagate ack provided it is a write transaction and only for one cycle.
        stmts.append(HDLAssign(isigs.rd_ack, n.h_rack))
        proc.sensitivity.extend([n.h_bus['dato'], n.h_rack, n.h_rt])


class AXI4LiteBus(BusGen):
    def __init__(self, name):
        assert name == 'axi4-lite-32'

    def gen_axi4lite_bus(self, build_port, addr_bits, lo_addr,
                         data_bits, is_master=False):
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        return [
            build_port("awvalid", None, dir=inp),
            build_port("awready", None, dir=out),
            build_port("awaddr", addr_bits, lo=lo_addr, dir=inp),
            build_port("awprot", 3, dir=inp),

            build_port("wvalid", None, dir=inp),
            build_port("wready", None, dir=out),
            build_port("wdata", data_bits, dir=inp),
            build_port("wstrb", data_bits // tree.BYTE_SIZE, dir=inp),

            build_port("bvalid", None, dir=out),
            build_port("bready", None, dir=inp),
            build_port("bresp", 2, dir=out),

            build_port("arvalid", None, dir=inp),
            build_port("arready", None, dir=out),
            build_port("araddr", addr_bits, lo=lo_addr, dir=inp),
            build_port("arprot", 3, dir=inp),

            build_port("rvalid", None, dir=out),
            build_port("rready", None, dir=inp),
            build_port("rdata", data_bits, dir=out),
            build_port("rresp", 2, dir=out)]

    def expand_bus(self, root, module, isigs):
        """Create AXI4-Lite interface for the design."""
        bus = [('clk',   HDLPort("aclk")),
               ('rst',   HDLPort("areset_n"))]
        bus.extend(self.gen_axi4lite_bus(
            lambda n, sz, lo=0, dir='IN': (n, HDLPort(n, size=sz,
                                                      lo_idx=lo, dir=dir)),
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, False))
        add_bus(root, module, bus)
        root.h_bussplit = True

        if isigs:
            # The most important points about AXI4 are in A3.2.1:
            # * A source is not permitted to wait until READY is asserted
            #   before asserting VALID.
            # * Once VALID is asserted it must remain assert until the handshake
            #   occurs
            #
            # All the replies must be registered, because they may not be acknowledged
            # immediately, and they must be 'sent' after the request has be
            # acknowledged.  This concerns RVALID, RDATA, BVALID.

            # Internal signals and bus protocol
            isigs.rd_int = module.new_HDLSignal('rd_int')       # Read access
            isigs.wr_int = module.new_HDLSignal('wr_int')       # Write access
            isigs.rd_ack = module.new_HDLSignal('rd_ack_int')   # Ack for read
            isigs.wr_ack = module.new_HDLSignal('wr_ack_int')   # Ack for write
            root.h_bus['dati'] = root.h_bus['wdata']
            root.h_bus['dato'] = module.new_HDLSignal('dato', root.c_word_bits)
            root.h_bus['adrw'] = root.h_bus['awaddr']
            root.h_bus['adrr'] = root.h_bus['araddr']

            # For the write accesses:
            # The W and AW channels are handled together: the write strobe is
            # generated when both AWVALID and WVALID are set.  
            # AWREADY and WREADY are asserted when the read ack is enabled, and
            # then BVALID is asserted until BREADY is set.
            module.stmts.append(HDLComment("AW, W and B channels"))
            axi_wip = module.new_HDLSignal('axi_wip')
            axi_wdone = module.new_HDLSignal('axi_wdone')
            w_start = HDLAnd(root.h_bus['awvalid'], root.h_bus['wvalid'])
            module.stmts.append(HDLAssign(isigs.wr_int,
                    HDLAnd(w_start, HDLNot(axi_wip))))
            module.stmts.append(HDLAssign(root.h_bus['awready'],
                    HDLAnd(axi_wip, isigs.wr_ack)))
            module.stmts.append(HDLAssign(root.h_bus['wready'],
                    HDLAnd(axi_wip, isigs.wr_ack)))
            module.stmts.append(HDLAssign(root.h_bus['bvalid'], axi_wdone))
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
            proc.rst_stmts.append(HDLAssign(axi_wip, bit_0))
            proc.rst_stmts.append(HDLAssign(axi_wdone, bit_0))
            proc.sync_stmts.append(HDLAssign(axi_wip,
                    HDLAnd(w_start, HDLNot(axi_wdone))))
            # Set on ack, cleared on bready.
            proc.sync_stmts.append(HDLAssign(axi_wdone,
                    HDLOr(isigs.wr_ack, HDLParen(HDLAnd(axi_wdone, HDLNot(root.h_bus['bready']))))))
            module.stmts.append(proc)
            module.stmts.append(HDLAssign(root.h_bus['bresp'], HDLConst(0, 2)))

            # For the read accesses:
            # The read strobe is generated when ARVALID is set.
            # ARREADY is asserted on the ack.
            # RVALID is asserted the next cycle, until RREADY is asserted.
            # As RDATA must be stable until RREADY is asserted, they are registered.
            module.stmts.append(HDLComment("AR and R channels"))
            axi_rip = module.new_HDLSignal('axi_rip')
            axi_rdone = module.new_HDLSignal('axi_rdone')
            r_start = root.h_bus['arvalid']
            module.stmts.append(HDLAssign(isigs.rd_int,
                    HDLAnd(r_start, HDLNot(axi_rip))))
            module.stmts.append(HDLAssign(root.h_bus['arready'],
                    HDLAnd(axi_rip, isigs.rd_ack)))
            module.stmts.append(HDLAssign(root.h_bus['rvalid'], axi_rdone))
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
            proc.rst_stmts.append(HDLAssign(axi_rip, bit_0))
            proc.rst_stmts.append(HDLAssign(axi_rdone, bit_0))
            proc.rst_stmts.append(HDLAssign(root.h_bus['rdata'],
                    HDLReplicate(bit_0, root.c_addr_bits)))
            proc.sync_stmts.append(HDLAssign(axi_rip,
                    HDLAnd(r_start, HDLNot(axi_rdone))))
            proc_if = HDLIfElse(HDLEq(isigs.rd_ack, bit_1))
            proc_if.then_stmts.append(HDLAssign(root.h_bus['rdata'],
                    root.h_bus['dato']))
            proc_if.else_stmts = None
            proc.sync_stmts.append(proc_if)
            # Set on ack, cleared on rready.
            proc.sync_stmts.append(HDLAssign(axi_rdone,
                    HDLOr(isigs.rd_ack, HDLParen(HDLAnd(axi_rdone, HDLNot(root.h_bus['rready']))))))
            module.stmts.append(proc)
            module.stmts.append(HDLAssign(root.h_bus['rresp'], HDLConst(0, 2)))

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        ports = self.gen_axi4lite_bus(
            lambda name, sz=None, lo=0, dir='IN': (name, module.add_port(
                '{}_{}_{}'.format(n.name, name, dirname[dir]),
                size=sz, lo_idx=lo, dir=dir)),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, True)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        n.h_bus['awvalid'].comment = n.description
        # Internal signals: valid signals.
        n.h_aw_val = module.new_HDLSignal(prefix + 'aw_val')
        n.h_w_val = module.new_HDLSignal(prefix + 'w_val')
        n.h_rd = module.new_HDLSignal(prefix + 'rd')

    def wire_bus_slave(self, root, stmts, n):
        stmts.append(HDLComment("Assignments for submap {}".format(n.name)))
        stmts.append(HDLAssign(n.h_bus['awvalid'], n.h_aw_val))
        stmts.append(HDLAssign(
            n.h_bus['awaddr'],
            HDLSlice(root.h_bus['adrw'],
                     root.c_addr_word_bits, n.c_addr_bits)))
        stmts.append(HDLAssign(n.h_bus['awprot'], HDLBinConst(0, 3)))
        stmts.append(HDLAssign(n.h_bus['wvalid'], n.h_w_val))
        stmts.append(HDLAssign(n.h_bus['wdata'], root.h_bus['dati']))
        stmts.append(HDLAssign(n.h_bus['wstrb'], HDLBinConst(0xf, 4)))
        stmts.append(HDLAssign(n.h_bus['bready'], bit_1))

        stmts.append(HDLAssign(n.h_bus['arvalid'], n.h_rd))
        stmts.append(HDLAssign(
            n.h_bus['araddr'],
            HDLSlice(root.h_bus['adrr'],
                     root.c_addr_word_bits, n.c_addr_bits)))
        stmts.append(HDLAssign(n.h_bus['arprot'], HDLBinConst(0, 3)))

        # FIXME: rready only available with axi4 root.
        stmts.append(HDLAssign(n.h_bus['rready'],
                               root.h_bus.get('rready', bit_1)))

    def write_bus_slave(self, root, stmts, n, proc, isigs):
        # Machine state for valid/ready AW and W channels
        # Set valid on request, clear valid on ready.
        # Set done on ready, clear done on ack.
        for x_val, ready in [
                (n.h_aw_val, n.h_bus['awready']),
                (n.h_w_val, n.h_bus['wready'])]:
            proc.rst_stmts.append(HDLAssign(x_val, bit_0))
            proc.sync_stmts.append(HDLAssign(x_val, bit_0))
            # VALID is set on WR, cleared by READY.
            stmts.append(HDLAssign(x_val,
                HDLOr(isigs.wr_int, HDLParen(HDLAnd(x_val, HDLNot(ready))))))
        stmts.append(HDLAssign(isigs.wr_ack, n.h_bus['bvalid']))

    def read_bus_slave(self, root, stmts, n, proc, isigs, rd_data):
        proc.stmts.append(HDLAssign(n.h_rd, bit_0))
        stmts.append(HDLAssign(n.h_rd, isigs.rd_int))
        proc.sensitivity.append(isigs.rd_int)
        stmts.append(HDLAssign(rd_data, n.h_bus['rdata']))
        stmts.append(HDLAssign(isigs.rd_ack, n.h_bus['rvalid']))
        proc.sensitivity.extend([n.h_bus['rdata'], n.h_bus['rvalid']])


class CERNBEBus(BusGen):
    def __init__(self, name):
        names = name[12:].split('-')
        self.buserr = names[0] == 'err'
        if self.buserr:
            del names[0]
        self.split = names[0] == 'split'
        if self.split:
            del names[0]
        assert len(names) == 1

    def add_decode_cern_be_vme(self, root, module, isigs):
        """Generate internal signals used by decoder/processes from
        CERN-BE-VME bus."""
        isigs.rd_int = root.h_bus['rd']
        isigs.wr_int = root.h_bus['wr']
        isigs.rd_ack = HDLSignal('rd_ack_int')    # Ack for read
        isigs.wr_ack = HDLSignal('wr_ack_int')    # Ack for write
        module.decls.extend([isigs.rd_ack, isigs.wr_ack])
        module.stmts.append(HDLAssign(root.h_bus['rack'], isigs.rd_ack))
        module.stmts.append(HDLAssign(root.h_bus['wack'], isigs.wr_ack))

    def gen_cern_bus(self, build_port, addr_bits, lo_addr, data_bits,
                     is_split, is_buserr, is_master):
        """Create CERN-BE interface."""
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        bus = []
        if is_split:
            bus.extend(
                [('adrr',   build_port("VMERdAddr", addr_bits,
                                       lo=lo_addr, dir=inp)),
                 ('adrw',   build_port("VMEWrAddr", addr_bits,
                                       lo=lo_addr, dir=inp))])
        else:
            bus.extend(
                [('adr',   build_port("VMEAddr", addr_bits,
                                     lo=lo_addr, dir=inp))])
        bus.extend(
            [('dato',  build_port("VMERdData", data_bits, dir=out)),
             ('dati',  build_port("VMEWrData", data_bits, dir=inp)),
             ('rd',    build_port("VMERdMem", dir=inp)),
             ('wr',    build_port("VMEWrMem", dir=inp)),
             ('rack',  build_port("VMERdDone", dir=out)),
             ('wack',  build_port("VMEWrDone", dir=out))])
        if is_buserr:
            bus.extend([('rderr', build_port('VMERdError', dir=out)),
                        ('wrerr', build_port('VMEWrError', dir=out))])
        return bus

    def expand_bus(self, root, module, isigs):
        """Create CERN-BE interface."""
        bus = [('clk',   HDLPort("Clk")),
               ('rst',   HDLPort("Rst"))]
        bus.extend(self.gen_cern_bus(
            lambda n, sz=None, lo=0, dir='IN': HDLPort(n, size=sz, lo_idx=lo, dir=dir),
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            self.split, self.buserr, False))
        add_bus(root, module, bus)
        root.h_bussplit = self.split

        if not self.split:
            root.h_bus['adrr'] = root.h_bus['adr']
            root.h_bus['adrw'] = root.h_bus['adr']

        if isigs:
            self.add_decode_cern_be_vme(root, module, isigs)

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        """Create an interface to a slave (Add declarations)"""
        ports = self.gen_cern_bus(
            lambda name, sz=None, lo=0, dir='IN': module.add_port(
                '{}_{}_{}'.format(n.name, name, dirname[dir]),
                size=sz, lo_idx=lo, dir=dir),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            self.split, self.buserr, True)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        n.h_bus['adrr' if self.split else 'adr'].comment = n.description
        if root.h_bussplit:
            # Request signals
            n.h_wr = module.new_HDLSignal(prefix + 'wr')
            n.h_rr = module.new_HDLSignal(prefix + 'rr')
            # Start transactions
            n.h_ws = module.new_HDLSignal(prefix + 'ws')
            n.h_rs = module.new_HDLSignal(prefix + 'rs')
            # Read enable (set by decoding logic)
            n.h_re = module.new_HDLSignal(prefix + 're')
            # Transaction in progress
            n.h_wt = module.new_HDLSignal(prefix + 'wt')
            n.h_rt = module.new_HDLSignal(prefix + 'rt')

    def wire_bus_slave(self, root, stmts, n):
        stmts.append(HDLComment("Assignments for submap {}".format(n.name)))
        stmts.append(HDLAssign(n.h_bus['dati'], root.h_bus['dati']))

        if root.h_bussplit:
            # Mux for addresses.
            proc = HDLComb()
            proc.sensitivity.extend([root.h_bus['adrr'], root.h_bus['adrw'], n.h_wt])
            if_stmt = HDLIfElse(HDLEq(n.h_wt, bit_1))
            if_stmt.then_stmts.append(HDLAssign(n.h_bus['adr'],
                               HDLSlice(root.h_bus['adrw'],
                                        root.c_addr_word_bits, n.c_addr_bits)))
            if_stmt.else_stmts.append(HDLAssign(n.h_bus['adr'],
                               HDLSlice(root.h_bus['adrr'],
                                        root.c_addr_word_bits, n.c_addr_bits)))
            proc.stmts.append(if_stmt)
            stmts.append(proc)
            # Handle read requests.
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
            # Read requests set on RD, clear by RdDone
            proc.sync_stmts.append(HDLAssign(n.h_rr,
                HDLAnd(HDLOr(n.h_re, n.h_rr), HDLNot(n.h_bus['rack']))))
            proc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
            # Read transaction set start R transaction, clear by RdDone
            proc.sync_stmts.append(HDLAssign(n.h_rt,
                HDLAnd(HDLOr(n.h_rt, n.h_rs), HDLNot(n.h_bus['rack']))))
            proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
            # Write transaction set start W transaction, clear by WrDone
            proc.sync_stmts.append(HDLAssign(n.h_wt,
                HDLAnd(HDLOr(n.h_wt, n.h_ws), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            stmts.append(proc)
            # Start a read transaction if a read request is pending and no transactions in
            # progress, and no write request (priority to write).
            stmts.append(HDLAssign(n.h_rs,
                HDLAnd(n.h_rr, HDLNot(HDLOr(n.h_wr, HDLOr(n.h_rt, n.h_wt))))))
            # Start write transaction if pending write request and no read transaction XXX.
            stmts.append(HDLAssign(n.h_ws,
                HDLAnd(n.h_wr, HDLNot(HDLOr(n.h_rt, n.h_wt)))))
        else:
            stmts.append(HDLAssign(n.h_bus['adr'],
                                   HDLSlice(root.h_bus['adr'],
                                            root.c_addr_word_bits, n.c_addr_bits)))

    def write_bus_slave(self, root, stmts, n, proc, isigs):
        proc.rst_stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
        proc.sync_stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
        if root.h_bussplit:
            # Write request set on WR, clear by WrDone
            stmts.append(HDLAssign(n.h_wr,
                HDLAnd(HDLOr(isigs.wr_int, n.h_wr), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
            proc.sync_stmts.append(HDLAssign(n.h_wr, bit_0))
            # WR set on WS
            stmts.append(HDLAssign(n.h_bus['wr'], n.h_ws))
        else:
            stmts.append(HDLAssign(n.h_bus['wr'], isigs.wr_int))
        stmts.append(HDLAssign(isigs.wr_ack, n.h_bus['wack']))

    def read_bus_slave(self, root, stmts, n, proc, isigs, rd_data):
        proc.stmts.append(HDLAssign(n.h_bus['rd'], bit_0))
        if root.h_bussplit:
            # Start read transaction if RR is set and neither read nor write transaction
            proc.stmts.append(HDLAssign(n.h_re, bit_0))
            stmts.append(HDLAssign(n.h_re, isigs.rd_int))
            stmts.append(HDLAssign(n.h_bus['rd'], n.h_rs))
            proc.sensitivity.extend([n.h_rs])
        else:
            stmts.append(HDLAssign(n.h_bus['rd'], isigs.rd_int))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        stmts.append(HDLAssign(isigs.rd_ack, n.h_bus['rack']))
        proc.sensitivity.extend([isigs.rd_int, n.h_bus['dato'], n.h_bus['rack']])


class SRAMBus(BusGen):
    def __init__(self, name):
        assert name == 'sram'

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        n.h_bus = {}
        n.h_bus['adr'] = root.h_ports.add_port(
            prefix + 'addr_o', n.c_addr_bits,
            lo_idx=root.c_addr_word_bits, dir='OUT')
        n.h_bus['adr'].comment = n.description

        n.h_bus['dati'] = root.h_ports.add_port(
            prefix + 'data_i', n.c_width, dir='IN')

        n.h_bus['dato'] = root.h_ports.add_port(
            prefix + 'data_o', n.c_width, dir='OUT')
        n.h_bus['wr'] = root.h_ports.add_port(
            prefix + 'wr_o', dir='OUT')

        # Internal signals
        n.h_bus['rack'] = module.new_HDLSignal(prefix + 'rack')
        n.h_bus['re'] = module.new_HDLSignal(prefix + 're')

    def wire_bus_slave(self, root, stmts, n):
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
        proc.rst_stmts.append(HDLAssign(n.h_bus['rack'], bit_0))
        proc.sync_stmts.append(HDLAssign(n.h_bus['rack'],
                HDLAnd(n.h_bus['re'], HDLNot(n.h_bus['rack']))))
        stmts.append(proc)
        stmts.append(HDLAssign(n.h_bus['dato'], root.h_bus['dati']))
        stmts.append(HDLAssign(n.h_bus['adr'],
                     HDLSlice(root.h_bus['adr'],
                              root.c_addr_word_bits, n.c_addr_bits)))

    def write_bus_slave(self, root, stmts, n, proc, isigs):
        proc.rst_stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
        proc.sync_stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
        stmts.append(HDLAssign(n.h_bus['wr'], isigs.wr_int))
        stmts.append(HDLAssign(isigs.wr_ack, isigs.wr_int))

    def read_bus_slave(self, root, stmts, n, proc, isigs, rd_data):
        stmts.append(HDLAssign(rd_data, n.h_bus['dati']))
        stmts.append(HDLAssign(isigs.rd_ack, n.h_bus['rack']))
        proc.stmts.append(HDLAssign(n.h_bus['re'], bit_0))
        stmts.append(HDLAssign(n.h_bus['re'], isigs.rd_int))
        proc.sensitivity.extend([isigs.rd_int, n.h_bus['dati'], n.h_bus['rack']])


def add_module_port(root, module, name, size, dir):
    if root.h_itf is None:
        return module.add_port(name + '_' + dirname[dir], size, dir=dir)
    else:
        p = root.h_itf.add_port(name, size, dir=dir)
        return HDLInterfaceSelect(root.h_ports, p)


def add_ports_reg(root, module, n):
    """Add ports and wires for register :param n:
       :field h_reg: the register.
       :field h_iport: the input port.
       :field h_oport: the output port.
       :field h_wstrobe: the write strobe port.
       :field h_rstrobe: the read strobe port.
       :field h_rack_port: the read ack port.
       :field h_wack_port: the write ack port.
    """
    iport = None
    oport = None

    for f in n.children:
        w = None if f.c_iowidth == 1 else f.c_iowidth

        # Create the register
        if f.hdl_type == 'reg':
            f.h_reg = HDLSignal(f.c_name + '_reg', w)
            module.decls.append(f.h_reg)
        else:
            f.h_reg = None
 
        # Input
        if f.hdl_type == 'wire' and n.access in ['ro', 'rw']:
            if n.hdl_port == 'reg':
                # One port used for all fields.
                if iport is None:
                    iport = add_module_port(root, module, n.c_name, n.width, dir='IN')
                    iport.comment = n.description
                f.h_iport = Slice_or_Index(iport, f.lo, w)
            else:
                # One port per field.
                f.h_iport = add_module_port(root, module, f.c_name, w, dir='IN')
                f.h_iport.comment = f.description
        else:
            f.h_iport = None

        # Output
        if n.access in ['wo', 'rw']:
            if n.hdl_port == 'reg':
                # One port used for all fields.
                if oport is None:
                    oport = add_module_port(root, module, n.c_name, n.width, dir='OUT')
                    oport.comment = n.description
                f.h_oport = Slice_or_Index(oport, f.lo, w)
            else:
                # One port per field.
                f.h_oport = add_module_port(root, module, f.c_name, w, dir='OUT')
                f.h_oport.comment = f.description
        else:
            f.h_oport = None

    # Strobe size.  There is one strobe signal per word, so create a vector if
    # the register is longer than a word.
    if n.c_size <= root.c_word_size:
        sz = None
    else:
        sz = n.c_size // root.c_word_size

    # Write strobe
    if n.hdl_write_strobe:
        n.h_wstrobe = add_module_port(
            root, module, n.c_name + '_wr', size=sz, dir='OUT')
    else:
        n.h_wstrobe = None

    # Read strobe
    if n.hdl_read_strobe:
        n.h_rstrobe = add_module_port(
            root, module, n.c_name + '_rd', size=sz, dir='OUT')
    else:
        n.h_rstrobe = None

    # Write ack
    if n.hdl_write_ack:
        n.h_wack_port = add_module_port(
            root, module, n.c_name + '_wack', size=sz, dir='IN')
    else:
        n.h_wack_port = None

    # Read ack
    if n.hdl_read_ack:
        n.h_rack_port = add_module_port(
            root, module, n.c_name + '_rack', size=sz, dir='IN')
    else:
        n.h_rack_port = None


def add_ports_submap(root, module, n):
    if n.filename is None:
        # Generic submap.
        busgroup = n.get_extension('x_hdl', 'busgroup')
        n.h_busgen = name_to_busgen(n.interface)
        n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)
    else:
        if n.interface == 'include':
            # Inline
            add_ports(root, module, n.c_submap)
        else:
            busgroup = n.c_submap.get_extension('x_hdl', 'busgroup')
            n.h_busgen = name_to_busgen(n.c_submap.bus)
            n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)


def add_ports_array(root, module, arr):
    """Create RAM ports and wires shared by all the registers.
    :attr h_addr: the address port
    """
    # Compute width, and create address port.
    arr.h_addr_width = ilog2(arr.repeat_val)
    arr.h_addr = add_module_port(
        root, module, arr.c_name + '_adr', arr.h_addr_width, 'IN')
    arr.h_addr.comment = "RAM port for {}".format(arr.c_name)


def add_ports_array_reg(root, module, reg):
    """Create ports and wires for a ram.
    :attr h_we: the write enable
    :attr h_rd: the read enable
    :attr h_dat: the data (either input or output)
    """
    # Create ports
    if reg.access == 'ro':
        reg.h_we = add_module_port(
            root, module, reg.c_name + '_we', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.c_name + '_dat', reg.c_rwidth, 'IN')
    else:
        reg.h_rd = add_module_port(
            root, module, reg.c_name + '_rd', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.c_name + '_dat', reg.c_rwidth, 'OUT')


def wire_array(root, module, isigs, arr):
    if root.h_ram is None:
        module.deps.append(('work', 'wbgen2_pkg'))
        root.h_ram = True
    if root.h_bussplit:
        # Read request and Write request.  Priority for the write.
        arr.h_wr = module.new_HDLSignal(arr.c_name + '_wr')
        arr.h_rr = module.new_HDLSignal(arr.c_name + '_rr')
        arr.h_adr_int = module.new_HDLSignal(arr.c_name + '_adr_int',
                arr.h_addr_width)

        # Create a mux for the ram address
        proc = HDLComb()
        proc.sensitivity.extend([root.h_bus['adrr'], root.h_bus['adrw'],
                                 isigs.wr_int])
        if_stmt = HDLIfElse(HDLEq(arr.h_wr, bit_1))
        if_stmt.then_stmts.append(HDLAssign(arr.h_adr_int,
            HDLSlice(root.h_bus['adrw'],
                     root.c_addr_word_bits, arr.h_addr_width)))
        if_stmt.else_stmts.append(HDLAssign(arr.h_adr_int,
            HDLSlice(root.h_bus['adrr'],
                     root.c_addr_word_bits, arr.h_addr_width)))
        proc.stmts.append(if_stmt)
        module.stmts.append(proc)

def wire_array_reg(root, module, isigs, reg):
    arr = reg._parent
    # Instantiate the ram.
    inst = HDLInstance(reg.c_name + "_raminst", "wbgen2_dpssram")
    module.stmts.append(inst)
    inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
    inst.params.append(("g_size", HDLNumber(1 << arr.h_addr_width)))
    inst.params.append(("g_addr_width", HDLNumber(arr.h_addr_width)))
    inst.params.append(("g_dual_clock", HDLBool(False)))
    inst.params.append(("g_use_bwsel", HDLBool(False)))
    inst.conns.append(("clk_a_i", root.h_bus['clk']))
    inst.conns.append(("clk_b_i", root.h_bus['clk']))
    if root.h_bussplit:
        adr_int = arr.h_adr_int
    else:
        adr_int = HDLSlice(root.h_bus['adr'],
                           root.c_addr_word_bits, arr.h_addr_width)
    inst.conns.append(("addr_a_i", adr_int))

    # Always write words to RAM (no byte select)
    nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
    reg.h_sig_bwsel = HDLSignal(reg.c_name + '_int_bwsel', nbr_bytes)
    module.decls.append(reg.h_sig_bwsel)
    inst.conns.append(("bwsel_b_i", reg.h_sig_bwsel))
    inst.conns.append(("bwsel_a_i", reg.h_sig_bwsel))

    if reg.access == 'ro':
        raise AssertionError  # TODO
        # inst.conns.append(("data_a_o", reg.h_dat))
        # inst.conns.append(("rd_a_i", rd_sig))
    else:
        # External port is RO.
        reg.h_sig_dato = HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
        module.decls.append(reg.h_sig_dato)
        reg.h_dat_ign = HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
        module.decls.append(reg.h_dat_ign)
        reg.h_sig_rd = HDLSignal(reg.c_name + '_int_rd')
        module.decls.append(reg.h_sig_rd)
        reg.h_sig_wr = HDLSignal(reg.c_name + '_int_wr')
        module.decls.append(reg.h_sig_wr)
        reg.h_ext_wr = HDLSignal(reg.c_name + '_ext_wr')
        module.decls.append(reg.h_ext_wr)
        module.stmts.append(HDLAssign(reg.h_ext_wr, bit_0))

        inst.conns.append(("data_a_i", root.h_bus['dati']))
        inst.conns.append(("data_a_o", reg.h_sig_dato))
        inst.conns.append(("rd_a_i", reg.h_sig_rd))
        inst.conns.append(("wr_a_i", reg.h_sig_wr))

        inst.conns.append(("addr_b_i", arr.h_addr))
        inst.conns.append(("data_b_i", reg.h_dat_ign))
        inst.conns.append(("data_b_o", reg.h_dat))
        inst.conns.append(("rd_b_i", reg.h_rd))
        inst.conns.append(("wr_b_i", reg.h_ext_wr))

    module.stmts.append(HDLAssign(reg.h_sig_bwsel,
                                  HDLReplicate(bit_1, nbr_bytes)))


def add_ports(root, module, node):
    """Create ports for a composite node."""
    for n in node.children:
        if isinstance(n, tree.Block):
            if n.children:
                # Recurse
                add_ports(root, module, n)
        elif isinstance(n, tree.Submap):
            # Interface
            add_ports_submap(root, module, n)
        elif isinstance(n, tree.Array):
            add_ports_array(root, module, n)
            for c in n.children:
                if isinstance(c, tree.Reg):
                    # Ram
                    add_ports_array_reg(root, module, c)
                else:
                    raise AssertionError(c)
        elif isinstance(n, tree.Reg):
            add_ports_reg(root, module, n)
        else:
            raise AssertionError


def wire_regs(root, module, isigs, node):
    """Create assignment from register to outputs."""
    stmts = module.stmts
    for n in node.children:
        if isinstance(n, tree.Block):
            wire_regs(root, module, isigs, n)
        elif isinstance(n, tree.Submap):
            if n.interface == 'include':
                wire_regs(root, module, isigs, n.c_submap)
            else:
                n.h_busgen.wire_bus_slave(root, stmts, n)
        elif isinstance(n, tree.Array):
            wire_array(root, module, isigs, n)
            for c in n.children:
                if isinstance(c, tree.Reg):
                    # Ram
                    wire_array_reg(root, module, isigs, c)
                else:
                    raise AssertionError(c)
        elif isinstance(n, tree.Reg):
            for f in n.children:
                if f.h_reg is not None and f.h_oport is not None:
                    stmts.append(HDLAssign(f.h_oport, f.h_reg))
        else:
            raise AssertionError


def add_block_decoder(root, stmts, addr, children, hi, func, off):
    debug = False
    if debug:
        print("add_block_decoder: hi={}, off={:08x}".format(hi, off))
        for i in children:
            print("{}: {:08x}, sz={:x}, al={:x}".format(
                i.name, i.c_abs_addr, i.c_size, i.c_align))
        print("----")
    if len(children) == 1:
        # If there is only one child, no need to decode anymore.
        el = children[0]
        if isinstance(el, tree.Reg):
            if hi == root.c_addr_word_bits:
                foff = off & (el.c_size - 1)
                if root.c_word_endian == 'big':
                    # Big endian
                    foff = el.c_size - root.c_word_size - foff
                else:
                    # Little endian
                    foff = foff
                func(stmts, el, foff * tree.BYTE_SIZE)
                return
            else:
                # Multi-word register - to be split, so decode more.
                maxsz = 1 << root.c_addr_word_bits
        else:
            func(stmts, el, 0)
            return
    else:
        maxsz = max([e.c_align for e in children])

    maxszl2 = ilog2(maxsz)
    assert maxsz == 1 << maxszl2
    mask = ~(maxsz - 1)
    assert maxszl2 < hi

    # Add a decoder.
    # Note: addr has a word granularity.
    sw = HDLSwitch(HDLSlice(addr, maxszl2, hi - maxszl2))
    stmts.append(sw)

    next_base = off
    while len(children) > 0:
        # Extract the first child.
        first = children.pop(0)
        l = [first]
        base = max(next_base, first.c_abs_addr & mask)
        next_base = base + maxsz
        if debug:
            print("hi={} szl2={} first: {:08x}, base: {:08x}, mask: {:08x}".
                  format(hi, maxszl2, first.c_abs_addr, base, mask))

        # Create a branch.
        ch = HDLChoiceExpr(HDLConst(base >> maxszl2, hi - maxszl2))
        sw.choices.append(ch)

        # Gather other children that are decoded in the same branch (same
        # base address)
        last = first
        while len(children) > 0:
            el = children[0]
            if (el.c_abs_addr & mask) != base:
                break
            if debug:
                print(" {} @ {:08x}".format(el.name, el.c_abs_addr))
            last = el
            l.append(el)
            children.pop(0)

        if ((last.c_abs_addr + last.c_size - 1) & mask) != base:
            children.insert(0, last)

        add_block_decoder(root, ch.stmts, addr, l, maxszl2, func, base)

    ch = HDLChoiceDefault()
    sw.choices.append(ch)
    func(ch.stmts, None, 0)


def gather_leaves(n):
    if isinstance(n, tree.Reg):
        return [n]
    elif isinstance(n, tree.Submap):
        if n.interface == 'include':
            return gather_leaves(n.c_submap)
        else:
            return [n]
    elif isinstance(n, tree.Array):
        return [n]
    elif isinstance(n, (tree.Root, tree.Block)):
        r = []
        for e in n.children:
            r.extend(gather_leaves(e))
        return r
    else:
        raise AssertionError


def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding children."""
    children = gather_leaves(root)
    children = sorted(children, key=lambda x: x.c_abs_addr)

    add_block_decoder(
        root, stmts, addr, children, root.c_sel_bits + root.c_blk_bits, func, 0)


def field_decode(root, reg, f, off, val, dat):
    """Handle multi-word accesses.  Slice (if needed) VAL and DAT for offset
       OFF and field F or register REG."""
    # Register and value bounds
    d_lo = f.lo
    d_hi = f.lo + f.c_rwidth - 1
    v_lo = 0
    v_hi = f.c_rwidth - 1
    # Next field if not affected by this read.
    if d_hi < off:
        return (None, None)
    if d_lo >= off + root.c_word_bits:
        return (None, None)
    if d_lo < off:
        # Strip the part below OFF.
        delta = off - d_lo
        d_lo = off
        v_lo += delta
    # Set right boundaries
    d_lo -= off
    d_hi -= off
    if d_hi >= root.c_word_bits:
        delta = d_hi + 1 - root.c_word_bits
        d_hi = root.c_word_bits - 1
        v_hi -= delta

    if d_hi == root.c_word_bits - 1 and d_lo == 0:
        pass
    else:
        dat = Slice_or_Index(dat, d_lo, d_hi - d_lo + 1)
    if v_hi == f.c_rwidth - 1 and v_lo == 0:
        pass
    else:
        val = Slice_or_Index(val, v_lo, v_hi - v_lo + 1)
    return (val, dat)


def strobe_init(root, n):
    sz = n.c_size // root.c_word_size
    if sz <= 1:
        return bit_0
    else:
        return HDLReplicate(bit_0, sz)


def strobe_index(root, n, off, lhs):
    if n.c_size <= root.c_word_size:
        return lhs
    else:
        return HDLIndex(lhs, off // root.c_word_bits)


def add_read_reg_process(root, module, isigs):
    # Register read
    rd_data = root.h_reg_rdat_int
    rd_ack = root.h_rd_ack1_int
    rdproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(rdproc)
    rdproc.rst_stmts.append(HDLAssign(rd_ack, bit_0))
    rdproc.rst_stmts.append(HDLAssign(rd_data,
                                      HDLReplicate(bit_x, root.c_word_bits)))
    # Be sure all unused bits are read as 0.
    rdproc.sync_stmts.append(HDLAssign(rd_data,
                                       HDLReplicate(bit_0, root.c_word_bits)))

    def add_read_reg(s, n, off):
        for f in n.children:
            if f.h_reg is not None and n.access in ['wo', 'rw']:
                src = f.h_reg
            elif f.h_iport is not None:
                src = f.h_iport
            elif f.hdl_type == 'const':
                src = HDLConst(f.preset, f.c_rwidth)
            else:
                raise AssertionError
            reg, dat = field_decode(root, n, f, off, src, rd_data)
            if reg is None:
                continue
            s.append(HDLAssign(dat, reg))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.c_name))
                if n.access != 'wo':
                    add_read_reg(s, n, off)
                if n.h_rstrobe is not None:
                    s.append(HDLAssign(strobe_index(root, n, off, n.h_rstrobe),
                                       bit_1))
                    if off == 0:
                        # Default values for the strobe.
                        v = strobe_init(root, n)
                        rdproc.rst_stmts.append(HDLAssign(n.h_rstrobe, v))
                        rdproc.sync_stmts.insert(0, HDLAssign(n.h_rstrobe, v))
                if n.h_rack_port is not None:
                    rack = strobe_index(root, n, off, n.h_rack_port)
                else:
                    rack = isigs.rd_int
                s.append(HDLAssign(rd_ack, rack))
            elif isinstance(n, tree.Submap):
                pass
            elif isinstance(n, tree.Array):
                s.append(HDLComment("RAM {}".format(n.c_name)))
                if root.h_bussplit:
                    rdproc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
                    rdproc.sync_stmts.append(HDLAssign(n.h_rr, bit_0))
                    s.append(HDLAssign(n.h_rr,
                        HDLAnd(HDLOr(n.h_rr, isigs.rd_int), isigs.wr_int)))
                    s.append(HDLAssign(rd_ack,
                        HDLAnd(HDLOr(isigs.rd_int, isigs.rd_int),
                               HDLNot(isigs.wr_int))))
                else:
                    s.append(HDLAssign(rd_ack, isigs.rd_int))
            else:
                # Blocks have been handled.
                raise AssertionError
        else:
            s.append(HDLAssign(rd_ack, isigs.rd_int))

    stmts = []
    add_decoder(root, stmts, root.h_bus.get('adrr', None), root, add_read)
    rdproc.sync_stmts.extend(stmts)


def add_read_process(root, module, isigs):
    # Generate the read decoder.  This is a large combinational process
    # that mux the data and ack.
    # It can be combinational because the read address is stable until the
    # end of the access.
    module.stmts.append(HDLComment('Process for read requests.'))
    rd_data = root.h_bus['dato']
    rd_ack = isigs.rd_ack
    rd_adr = root.h_bus.get('adrr', None)
    rdproc = HDLComb()
    if rd_adr is not None:
        rdproc.sensitivity.append(rd_adr)
    if root.h_pipeline:
        rdproc.sensitivity.extend([root.h_reg_rdat_int, root.h_rd_ack1_int,
                                   isigs.rd_int])
    module.stmts.append(rdproc)

    # All the read are ack'ed (including the read to unassigned addresses).
    rdproc.stmts.append(HDLComment("By default ack read requests"))
    rdproc.stmts.append(HDLAssign(rd_data,
                                  HDLReplicate(bit_0, root.c_word_bits)))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.c_name))
                s.append(HDLAssign(rd_data, root.h_reg_rdat_int))
                s.append(HDLAssign(rd_ack, root.h_rd_ack1_int))
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.c_name)))
                n.h_busgen.read_bus_slave(root, s, n, rdproc, isigs, rd_data)
                return
            elif isinstance(n, tree.Array):
                s.append(HDLComment("RAM {}".format(n.c_name)))
                # TODO: handle list of registers!
                r = n.children[0]
                rdproc.sensitivity.append(r.h_sig_dato)
                # Output ram data
                s.append(HDLAssign(rd_data, r.h_sig_dato))
                # Set rd signal to ram: read when there is not WR request,
                # and either a read request or a pending read request.
                if root.h_bussplit:
                    rd_sig = HDLAnd(HDLOr(isigs.rd_int, n.h_rr),
                                    HDLNot(n.h_wr))
                else:
                    rd_sig = isigs.rd_int
                s.append(HDLAssign(r.h_sig_rd, rd_sig))
                # But set it to 0 when the ram is not selected.
                rdproc.stmts.append(HDLAssign(r.h_sig_rd, bit_0))
                # Use delayed ack as ack.
                s.append(HDLAssign(rd_ack, root.h_rd_ack1_int))
                return
            else:
                # Blocks have been handled.
                raise AssertionError
        else:
            s.append(HDLAssign(rd_ack, isigs.rd_int))

    stmts = []
    add_decoder(root, stmts, rd_adr, root, add_read)
    rdproc.stmts.extend(stmts)


def add_write_process(root, module, isigs):
    # Register write
    module.stmts.append(HDLComment('Process for write requests.'))
    wrproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(wrproc)
    wrproc.rst_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wrproc.sync_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write_reg(s, n, off):
        # Write strobe
        if n.h_wstrobe is not None:
            s.append(HDLAssign(strobe_index(root, n, off, n.h_wstrobe), isigs.wr_int))
            if off == 0:
                # Default values for the strobe
                v = strobe_init(root, n)
                wrproc.rst_stmts.append(HDLAssign(n.h_wstrobe, v))
                wrproc.sync_stmts.append(HDLAssign(n.h_wstrobe, v))

        wr_if = HDLIfElse(HDLEq(isigs.wr_int, bit_1))
        wr_if.else_stmts = None
        for f in n.children:
            # Reset code
            if f.h_reg is not None and off == 0:
                v = 0 if f.preset is None else f.preset
                cst = HDLConst(v, f.c_iowidth if f.c_iowidth != 1 else None)
                wrproc.rst_stmts.append(HDLAssign(f.h_reg, cst))
            # Assign code
            if f.hdl_type == 'reg':
                r = f.h_reg
            elif f.hdl_type == 'wire':
                r = f.h_oport
            else:
                raise AssertionError
            reg, dat = field_decode(root, n, f, off, r, wr_data)
            if reg is None:
                continue
            wr_if.then_stmts.append(HDLAssign(reg, dat))
        s.append(wr_if)
        if n.h_wack_port is not None:
            wack = strobe_index(root, n, off, n.h_wack_port)
        else:
            wack = isigs.wr_int
        s.append(HDLAssign(isigs.wr_ack, wack))

    def add_write(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment("Register {}".format(n.c_name)))
                if n.access in ['wo', 'rw']:
                    add_write_reg(s, n, off)
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.c_name)))
                n.h_busgen.write_bus_slave(root, s, n, wrproc, isigs)
                return
            elif isinstance(n, tree.Array):
                s.append(HDLComment("Memory {}".format(n.c_name)))
                # TODO: handle list of registers!
                r = n.children[0]
                wrproc.rst_stmts.append(HDLAssign(r.h_sig_wr, bit_0))
                wrproc.sync_stmts.append(HDLAssign(r.h_sig_wr, bit_0))
                if root.h_bussplit:
                    wrproc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
                    wrproc.sync_stmts.append(HDLAssign(n.h_wr, bit_0))
                    s.append(HDLAssign(n.h_wr, isigs.wr_int))
                    s.append(HDLAssign(isigs.wr_ack, n.h_wr))
                else:
                    s.append(HDLAssign(isigs.wr_ack, isigs.wr_int))
                s.append(HDLAssign(r.h_sig_wr, isigs.wr_int))
                    
                return
            else:
                # Including blocks.
                raise AssertionError
        else:
            # All the write are ack'ed (including the write to unassigned
            # addresses)
            s.append(HDLAssign(isigs.wr_ack, isigs.wr_int))
    then_stmts = []
    add_decoder(
        root, then_stmts, root.h_bus.get('adrw', None), root, add_write)
    wrproc.sync_stmts.extend(then_stmts)


def name_to_busgen(name):
    if name == 'wb-32-be':
        return WBBus(name)
    elif name == 'axi4-lite-32':
        return AXI4LiteBus(name)
    elif name.startswith('cern-be-vme-'):
        return CERNBEBus(name)
    elif name == 'sram':
        return SRAMBus(name)
    else:
        raise AssertionError("Unhandled bus '{}'".format(name))


def gen_hdl_header(root, isigs=None):
    module = HDLModule()
    module.name = root.name

    # Create the bus
    root.h_busgen = name_to_busgen(root.bus)
    root.h_busgen.expand_bus(root, module, isigs)

    return module


def has_pipeline(n):
    """True if the decoder may include a pipeline register"""
    if isinstance(n, tree.Reg):
        return False
    elif isinstance(n, tree.Submap):
        if n.interface == 'include':
            return has_pipeline(n.c_submap)
        else:
            # Always allow pipeline
            return True
    elif isinstance(n, tree.Array):
        return True
    elif isinstance(n, tree.Block) or isinstance(n, tree.Root):
        return any([has_pipeline(c) for c in n.children])
    else:
        raise AssertionError(n)


def generate_hdl(root):
    isigs = Isigs()

    # Force the regeneration of wb package (useful only when testing).
    WBBus.wb_pkg = None

    root.h_pipeline = has_pipeline(root) or True

    module = gen_hdl_header(root, isigs)

    # Add ports
    iogroup = root.get_extension('x_hdl', 'iogroup')
    if iogroup is not None:
        root.h_itf = HDLInterface('t_' + iogroup)
        module.global_decls.append(root.h_itf)
        grp = module.add_port_group(iogroup, root.h_itf, True)
        grp.comment = 'Wires and registers'
        root.h_ports = grp
    else:
        root.h_itf = None
        root.h_ports = module
    add_ports(root, module, root)

    module.stmts.append(HDLComment('Assign outputs'))
    root.h_ram = None
    wire_regs(root, module, isigs, root)

    add_write_process(root, module, isigs)

    if root.h_pipeline:
        root.h_reg_rdat_int = HDLSignal('reg_rdat_int', root.c_word_bits)
        module.decls.append(root.h_reg_rdat_int)
        root.h_rd_ack1_int = HDLSignal('rd_ack1_int')
        module.decls.append(root.h_rd_ack1_int)
        module.stmts.append(HDLComment('Process for registers read.'))
        add_read_reg_process(root, module, isigs)

    add_read_process(root, module, isigs)

    return module
