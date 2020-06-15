from cheby.hdltree import (HDLPort,
                           HDLAssign, HDLSync, HDLComment,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLReplicate,
                           HDLConst, HDLBinConst, HDLParen)
from cheby.hdl.busgen import BusGen
import cheby.tree as tree
import cheby.parser as parser
from cheby.hdl.globals import gconfig, dirname
from cheby.hdl.ibus import add_bus
from cheby.hdl.busparams import BusOptions


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

    def expand_bus_w(self, root, module, ibus, opts):
        """Sub-routine of expand_bus: the write part"""
        ibus.wr_req = module.new_HDLSignal('wr_req')       # Write access
        ibus.wr_ack = module.new_HDLSignal('wr_ack_int')   # Ack for write
        ibus.wr_dat = module.new_HDLSignal('wr_wdata', root.c_word_bits)
        ibus.wr_sel = module.new_HDLSignal('wr_wstrb', root.c_word_bits // tree.BYTE_SIZE)
        ibus.wr_adr = module.new_HDLSignal('wr_awaddr', root.c_addr_bits,
                                           lo_idx=root.c_addr_word_bits)
        # For the write accesses:
        # The W and AW channels are handled together: the write strobe is
        # generated when both AWVALID and WVALID are set.
        # AWREADY and WREADY are asserted on the ack.
        # BVALID is asserted the next cycle, until BREADY is asserted.
        module.stmts.append(HDLComment("AW, W and B channels"))
        axi_wset = module.new_HDLSignal('axi_wset')
        axi_awset = module.new_HDLSignal('axi_awset')
        axi_wdone = module.new_HDLSignal('axi_wdone')
        module.stmts.append(HDLAssign(root.h_bus['bvalid'], axi_wdone))
        module.stmts.append(HDLAssign(root.h_bus['wready'], HDLNot(axi_wset)))
        module.stmts.append(HDLAssign(root.h_bus['awready'], HDLNot(axi_awset)))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(axi_wset, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_awset, bit_0))
        proc.rst_stmts.append(HDLAssign(ibus.wr_req, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_wdone, bit_0))
        proc.sync_stmts.append(HDLAssign(ibus.wr_req, bit_0))
        # Load wdata+wsel (and acknowledge the W request)
        proc_if = HDLIfElse(HDLAnd(HDLEq(root.h_bus['wvalid'], bit_1),
                                   HDLEq(axi_wset, bit_0)))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_dat, root.h_bus['wdata']))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_sel, root.h_bus['wstrb']))
        proc_if.then_stmts.append(HDLAssign(axi_wset, bit_1))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_req, axi_awset))  # Start if AW already set
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        # Load awaddr (and acknowledge the AW request)
        proc_if = HDLIfElse(HDLAnd(HDLEq(root.h_bus['awvalid'], bit_1),
                                   HDLEq(axi_awset, bit_0)))
        if root.h_bus['awaddr'] is not None:
            proc_if.then_stmts.append(HDLAssign(ibus.wr_adr,
                                                opts.resize_addr_in(root.h_bus['awaddr'], ibus)))
        proc_if.then_stmts.append(HDLAssign(axi_awset, bit_1))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_req,
                                            HDLOr(axi_wset, root.h_bus['wvalid'])))  # Start if W
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        # Clear 'set' bits at the end of the transaction
        proc_if = HDLIfElse(HDLEq(HDLParen(HDLAnd(axi_wdone, root.h_bus['bready'])), bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_wset, bit_0))
        proc_if.then_stmts.append(HDLAssign(axi_awset, bit_0))
        proc_if.then_stmts.append(HDLAssign(axi_wdone, bit_0))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        # WDONE indicates that the write is done on the slave part (so waiting to
        # be acknowledged by the master.)
        # WDONE is set on ack, cleared on BREADY.
        proc_if = HDLIfElse(HDLEq(ibus.wr_ack, bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_wdone, bit_1))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        #
        module.stmts.append(proc)
        module.stmts.append(HDLAssign(root.h_bus['bresp'], HDLConst(0, 2)))

    def expand_bus_r(self, root, module, ibus, opts):
        """Sub-routine of expand_bus: the read part"""
        module.stmts.append(HDLComment("AR and R channels"))
        ibus.rd_req = module.new_HDLSignal('rd_req')       # Read access
        ibus.rd_ack = module.new_HDLSignal('rd_ack_int')   # Ack for read
        ibus.rd_dat = module.new_HDLSignal('dato', root.c_word_bits)
        if root.h_bus['araddr'] is not None:
            ibus.rd_adr = opts.new_resizer_addr_in(module, root.h_bus['araddr'], ibus, 'rd_addr')

        # For the read accesses:
        # The read strobe is generated when ARVALID is set.
        # ARREADY is asserted on the ack.
        # RVALID is asserted the next cycle, until RREADY is asserted.
        # As RDATA must be stable until RREADY is asserted, they are registered.
        axi_rip = module.new_HDLSignal('axi_rip')
        axi_rdone = module.new_HDLSignal('axi_rdone')
        r_start = root.h_bus['arvalid']
        # Send a pulse to the slave at the start of a transaction.
        module.stmts.append(
            HDLAssign(ibus.rd_req, HDLAnd(r_start, HDLNot(axi_rip))))
        module.stmts.append(
            HDLAssign(root.h_bus['arready'], ibus.rd_ack))
        module.stmts.append(HDLAssign(root.h_bus['rvalid'], axi_rdone))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(axi_rip, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_rdone, bit_0))
        proc.rst_stmts.append(
            HDLAssign(root.h_bus['rdata'],
                      HDLReplicate(bit_0, root.c_addr_bits)))
        # Read In Progress is set during the whole read transaction.
        proc.sync_stmts.append(
            HDLAssign(axi_rip, HDLAnd(r_start, HDLNot(axi_rdone))))
        proc_if = HDLIfElse(HDLEq(ibus.rd_ack, bit_1))
        proc_if.then_stmts.append(HDLAssign(root.h_bus['rdata'], ibus.rd_dat))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)
        # Set on ack, cleared on rready.
        proc.sync_stmts.append(
            HDLAssign(axi_rdone,
                      HDLOr(ibus.rd_ack, HDLParen(HDLAnd(axi_rdone,
                                                         HDLNot(root.h_bus['rready']))))))
        module.stmts.append(proc)
        module.stmts.append(HDLAssign(root.h_bus['rresp'], HDLConst(0, 2)))

    def add_xilinx_attributes(self, bus, portname):
        for name, port in bus:
            if name in ('clk', 'rst'):
                continue
            port.attributes['X_INTERFACE_INFO'] = "xilinx.com:interface:aximm:1.0 {} {}".format(
                portname, name.upper())

    def expand_opts(self, opts):
        if opts.busgroup:
            parser.warning(opts.bus, "busgroup on '{}' is ignored for axi4-lite".format(
                opts.bus.get_path()))

    def expand_bus(self, root, module, ibus):
        """Create AXI4-Lite interface for the design."""
        opts = BusOptions(root, root)
        self.expand_opts(opts)
        bus = [('clk', HDLPort("aclk")),
               ('rst', HDLPort("areset_n"))]
        bus.extend(self.gen_axi4lite_bus(
            lambda n, sz, lo=0, dir='IN':
                (n, None if sz == 0 else HDLPort(n, size=sz,lo_idx=lo, dir=dir)),
            opts.addr_wd, opts.addr_low, root.c_word_bits, False))
        if root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(bus, 'slave')
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
        self.expand_bus_w(root, module, ibus, opts)
        self.expand_bus_r(root, module, ibus, opts)

    def gen_bus_slave(self, root, module, prefix, n, opts):
        self.expand_opts(opts)
        ports = self.gen_axi4lite_bus(
            lambda name, sz=None, lo=0, dir='IN':
                (name, None if sz == 0 else module.add_port(
                    '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                    size=sz, lo_idx=lo, dir=dir)),
            opts.addr_wd, opts.addr_low, root.c_word_bits, True)
        if root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(ports, n.c_name)
        n.h_bus_opts = opts
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        comment = '\n' + (n.comment or n.description or 'AXI-4 lite bus {}'.format(n.name))
        n.h_bus['awvalid'].comment = comment
        # Internal signals: valid signals.
        n.h_aw_val = module.new_HDLSignal(prefix + 'aw_val')
        n.h_w_val = module.new_HDLSignal(prefix + 'w_val')
        n.h_ar_val = module.new_HDLSignal(prefix + 'ar_val')
        # Internal request signals from address decoders
        n.h_rd = module.new_HDLSignal(prefix + 'rd')
        n.h_wr = module.new_HDLSignal(prefix + 'wr')

    def wire_bus_slave(self, root, module, n, ibus):
        stmts = module.stmts
        stmts.append(HDLAssign(n.h_bus['awvalid'], n.h_aw_val))
        if n.h_bus['awaddr'] is not None:
            stmts.append(HDLAssign(
                n.h_bus['awaddr'],
                n.h_bus_opts.resize_addr_out(
                    HDLSlice(ibus.wr_adr, root.c_addr_word_bits, n.c_addr_bits), ibus)))
        stmts.append(HDLAssign(n.h_bus['awprot'], HDLBinConst(0, 3)))
        stmts.append(HDLAssign(n.h_bus['wvalid'], n.h_w_val))
        stmts.append(HDLAssign(n.h_bus['wdata'], ibus.wr_dat))
        stmts.append(HDLAssign(n.h_bus['wstrb'], ibus.wr_sel or HDLReplicate(bit_1, 4)))
        stmts.append(HDLAssign(n.h_bus['bready'], bit_1))

        stmts.append(HDLAssign(n.h_bus['arvalid'], n.h_ar_val))
        if n.h_bus['araddr'] is not None:
            stmts.append(HDLAssign(
                n.h_bus['araddr'],
                n.h_bus_opts.resize_addr_out(
                    HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits), ibus)))
        stmts.append(HDLAssign(n.h_bus['arprot'], HDLBinConst(0, 3)))

        # FIXME: rready only available with axi4 root.
        stmts.append(HDLAssign(n.h_bus['rready'],
                               root.h_bus.get('rready', bit_1)))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
        # Machine state for valid/ready AW and W channels
        # Set valid on request, clear valid on ready.
        # Set done on ready, clear done on ack.
        for x_val, req, ready in [
                (n.h_aw_val, n.h_wr, n.h_bus['awready']),
                (n.h_w_val, n.h_wr, n.h_bus['wready']),
                (n.h_ar_val, n.h_rd, n.h_bus['arready'])]:
            proc.rst_stmts.append(HDLAssign(x_val, bit_0))
            proc.sync_stmts.append(HDLAssign(x_val, bit_0))
            # VALID is set on WR, cleared by READY.
            proc.sync_stmts.append(
                HDLAssign(x_val, HDLOr(req, HDLParen(HDLAnd(x_val, HDLNot(ready))))))
        stmts.append(proc)

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_wr, bit_0))
        stmts.append(HDLAssign(n.h_wr, ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['bvalid']))

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_rd, bit_0))
        stmts.append(HDLAssign(n.h_rd, ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['rdata']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rvalid']))
