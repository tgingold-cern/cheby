from cheby.hdltree import (HDLPort,
                           HDLAssign, HDLSync, HDLComment,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLReplicate,
                           HDLConst, HDLBinConst, HDLParen)
from cheby.hdl.busgen import BusGen
import cheby.tree as tree
from cheby.hdl.globals import rst_sync, dirname
from cheby.hdl.ibus import add_bus


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

    def expand_bus(self, root, module, ibus):
        """Create AXI4-Lite interface for the design."""
        bus = [('clk', HDLPort("aclk")),
               ('rst', HDLPort("areset_n"))]
        bus.extend(self.gen_axi4lite_bus(
            lambda n, sz, lo=0, dir='IN': (n, HDLPort(n, size=sz,
                                                      lo_idx=lo, dir=dir)),
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, False))
        add_bus(root, module, bus)
        root.h_bussplit = True
        ibus.addr_size = root.c_addr_bits
        ibus.addr_low = root.c_addr_word_bits
        ibus.data_size = root.c_word_bits
        ibus.rst = root.h_bus['rst']
        ibus.clk = root.h_bus['clk']

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
        ibus.rd_req = module.new_HDLSignal('rd_req')       # Read access
        ibus.wr_req = module.new_HDLSignal('wr_req')       # Write access
        ibus.rd_ack = module.new_HDLSignal('rd_ack_int')   # Ack for read
        ibus.wr_ack = module.new_HDLSignal('wr_ack_int')   # Ack for write
        ibus.wr_dat = root.h_bus['wdata']
        ibus.rd_dat = module.new_HDLSignal('dato', root.c_word_bits)
        ibus.wr_adr = root.h_bus['awaddr']
        ibus.rd_adr = root.h_bus['araddr']
        # For the write accesses:
        # The W and AW channels are handled together: the write strobe is
        # generated when both AWVALID and WVALID are set.
        # AWREADY and WREADY are asserted when the read ack is enabled, and
        # then BVALID is asserted until BREADY is set.
        module.stmts.append(HDLComment("AW, W and B channels"))
        axi_wip = module.new_HDLSignal('axi_wip')
        axi_wdone = module.new_HDLSignal('axi_wdone')
        w_start = HDLAnd(root.h_bus['awvalid'], root.h_bus['wvalid'])
        module.stmts.append(
            HDLAssign(ibus.wr_req, HDLAnd(w_start, HDLNot(axi_wip))))
        module.stmts.append(HDLAssign(root.h_bus['awready'], axi_wdone))
        module.stmts.append(
            HDLAssign(root.h_bus['wready'], HDLAnd(axi_wip, ibus.wr_ack)))
        module.stmts.append(HDLAssign(root.h_bus['bvalid'], axi_wdone))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
        proc.rst_stmts.append(HDLAssign(axi_wip, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_wdone, bit_0))
        proc.sync_stmts.append(
            HDLAssign(axi_wip, HDLAnd(w_start, HDLNot(axi_wdone))))
        # Set on ack, cleared on bready.
        proc.sync_stmts.append(
            HDLAssign(axi_wdone,
                      HDLOr(ibus.wr_ack,
                            HDLParen(HDLAnd(axi_wdone, HDLNot(root.h_bus['bready']))))))
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
        module.stmts.append(
            HDLAssign(ibus.rd_req,
                      HDLAnd(r_start, HDLNot(axi_rip))))
        module.stmts.append(HDLAssign(root.h_bus['arready'], axi_rdone))
        module.stmts.append(HDLAssign(root.h_bus['rvalid'], axi_rdone))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
        proc.rst_stmts.append(HDLAssign(axi_rip, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_rdone, bit_0))
        proc.rst_stmts.append(
            HDLAssign(root.h_bus['rdata'],
                      HDLReplicate(bit_0, root.c_addr_bits)))
        proc.sync_stmts.append(
            HDLAssign(axi_rip, HDLAnd(r_start, HDLNot(axi_rdone))))
        proc_if = HDLIfElse(HDLEq(ibus.rd_ack, bit_1))
        proc_if.then_stmts.append(HDLAssign(root.h_bus['rdata'], ibus.rd_dat))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        # Set on ack, cleared on rready.
        proc.sync_stmts.append(
            HDLAssign(axi_rdone,
                      HDLOr(ibus.rd_ack, HDLParen(HDLAnd(axi_rdone, HDLNot(root.h_bus['rready']))))))
        module.stmts.append(proc)
        module.stmts.append(HDLAssign(root.h_bus['rresp'], HDLConst(0, 2)))

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        ports = self.gen_axi4lite_bus(
            lambda name, sz=None, lo=0, dir='IN': (name, module.add_port(
                '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                size=sz, lo_idx=lo, dir=dir)),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, True)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        comment = '\n' + (n.comment or n.description or 'AXI-4 lite bus {}'.format(n.name))
        n.h_bus['awvalid'].comment = comment
        # Internal signals: valid signals.
        n.h_aw_val = module.new_HDLSignal(prefix + 'aw_val')
        n.h_w_val = module.new_HDLSignal(prefix + 'w_val')
        # Internal request signals from address decoders
        n.h_rd = module.new_HDLSignal(prefix + 'rd')
        n.h_wr = module.new_HDLSignal(prefix + 'wr')

    def wire_bus_slave(self, root, module, n, ibus):
        stmts = module.stmts
        stmts.append(HDLAssign(n.h_bus['awvalid'], n.h_aw_val))
        stmts.append(HDLAssign(
            n.h_bus['awaddr'],
            HDLSlice(ibus.wr_adr, root.c_addr_word_bits, n.c_addr_bits)))
        stmts.append(HDLAssign(n.h_bus['awprot'], HDLBinConst(0, 3)))
        stmts.append(HDLAssign(n.h_bus['wvalid'], n.h_w_val))
        stmts.append(HDLAssign(n.h_bus['wdata'], ibus.wr_dat))
        stmts.append(HDLAssign(n.h_bus['wstrb'], HDLBinConst(0xf, 4)))
        stmts.append(HDLAssign(n.h_bus['bready'], bit_1))

        stmts.append(HDLAssign(n.h_bus['arvalid'], n.h_rd))
        stmts.append(HDLAssign(
            n.h_bus['araddr'],
            HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits)))
        stmts.append(HDLAssign(n.h_bus['arprot'], HDLBinConst(0, 3)))

        # FIXME: rready only available with axi4 root.
        stmts.append(HDLAssign(n.h_bus['rready'],
                               root.h_bus.get('rready', bit_1)))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
        # Machine state for valid/ready AW and W channels
        # Set valid on request, clear valid on ready.
        # Set done on ready, clear done on ack.
        for x_val, ready in [
                (n.h_aw_val, n.h_bus['awready']),
                (n.h_w_val, n.h_bus['wready'])]:
            proc.rst_stmts.append(HDLAssign(x_val, bit_0))
            proc.sync_stmts.append(HDLAssign(x_val, bit_0))
            # VALID is set on WR, cleared by READY.
            proc.sync_stmts.append(
                HDLAssign(x_val,
                          HDLOr(n.h_wr, HDLParen(HDLAnd(x_val, HDLNot(ready))))))
        stmts.append(proc)

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_wr, bit_0))
        stmts.append(HDLAssign(n.h_wr, ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['bvalid']))
        proc.sensitivity.extend([n.h_bus['bvalid']])

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_rd, bit_0))
        stmts.append(HDLAssign(n.h_rd, ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['rdata']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rvalid']))
        proc.sensitivity.extend([n.h_bus['rdata'], n.h_bus['rvalid']])
