from cheby.hdltree import (
    HDLNode,
    HDLPort,
    HDLAssign,
    HDLSync,
    HDLComb,
    HDLComment,
    HDLIfElse,
    bit_1,
    bit_0,
    HDLAnd,
    HDLOr,
    HDLNot,
    HDLEq,
    HDLSlice,
    HDLReplicate,
    HDLBinConst,
    HDLParen,
    HDLPackage,
    HDLInterface,
    HDLInterfaceSelect,
)
from cheby.hdl.busgen import BusGen
import cheby.tree as tree
from cheby.hdl.globals import gconfig, dirname, libname
from cheby.hdl.ibus import add_bus
from cheby.hdl.busparams import BusOptions
from typing import List, Tuple

# AXI Lite response codes (BRESP, RRESP)
RESP_OKAY = HDLBinConst(0, 2)
RESP_SLVERR = HDLBinConst(2, 2)


class AXI4LiteBus(BusGen):
    # Package axi4lite_pkg that contains the interface
    axi4l_pkg = None
    axi4l_itf = None
    axi4l_ports = None

    def __init__(self, name, root, module):
        super().__init__(root, module)
        assert name == 'axi4-lite-32'

    def gen_axi4lite_bus(self, ports, name, build_port,
                         addr_bits, lo_addr, data_bits, comment,
                         is_master=False, is_group=False, libname = libname) -> \
                         List[Tuple[str, HDLNode]]:
        if is_group:
            if AXI4LiteBus.axi4l_pkg is None:
                self.gen_axi4l_pkg(ports, name, comment, data_bits)
                self.module.deps.append((libname, 'axi4lite_pkg'))
            # Add the interface modport to the ports
            port = ports.add_modport(name, AXI4LiteBus.axi4l_itf, is_master)
            port.comment = comment
            res = []
            # Fill res
            for p in AXI4LiteBus.axi4l_ports:
                res.append((p.name, HDLInterfaceSelect(port, p)))
            return res
        else:
            # Not an interface (ie not a busgroup)
            inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
            res = [
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
            return res

    def gen_axi4l_pkg(self, ports, name, comment, data_bits) -> None:
        """Create the axi4lite_pkg package, so that interface can be
        referenced"""
        assert AXI4LiteBus.axi4l_pkg is None
        AXI4LiteBus.axi4l_pkg = HDLPackage('axi4lite_pkg')
        AXI4LiteBus.axi4l_itf = HDLInterface('t_axi4lite')
        AXI4LiteBus.axi4l_pkg.decls.append(AXI4LiteBus.axi4l_itf)
        AXI4LiteBus.axi4l_ports = self.gen_axi4lite_bus(ports, name,
            lambda n, sz, lo=0, dir='IN':
            AXI4LiteBus.axi4l_itf.add_port(n, size=sz, lo_idx=lo, dir=dir),
            data_bits, 0, data_bits, comment, True, False)
        return

    def expand_bus_w(self, ibus, opts):
        """Sub-routine of expand_bus: the write part"""
        ibus.wr_req = self.module.new_HDLSignal('wr_req')  # Write access
        ibus.wr_ack = self.module.new_HDLSignal('wr_ack')  # Ack for write
        ibus.wr_err = self.module.new_HDLSignal('wr_err')  # Error for write
        ibus.wr_adr = self.module.new_HDLSignal('wr_addr', self.root.c_addr_bits,
                                           lo_idx=self.root.c_addr_word_bits)
        ibus.wr_dat = self.module.new_HDLSignal('wr_data', self.root.c_word_bits)
        ibus.wr_sel = self.module.new_HDLSignal('wr_sel', self.root.c_word_bits)
        # For the write accesses:
        # AWREADY and WREADY default to asserted and are deasserted one cycle after AWVALID and
        # WVALID are set, respectively. AWADDR, WDATA and WSEL are registred at the same time.
        # The write strobe is generated when both channels received a transaction.
        # BVALID is asserted on ack, until BREADY is asserted.
        self.module.stmts.append(HDLComment("AW, W and B channels"))
        axi_awset = self.module.new_HDLSignal('axi_awset')
        axi_wset = self.module.new_HDLSignal('axi_wset')
        axi_wdone = self.module.new_HDLSignal('axi_wdone')
        axi_werr = self.module.new_HDLSignal('axi_werr', 2)
        self.module.stmts.append(HDLAssign(self.root.h_bus['awready'], HDLNot(axi_awset)))
        self.module.stmts.append(HDLAssign(self.root.h_bus['wready'], HDLNot(axi_wset)))
        self.module.stmts.append(HDLAssign(self.root.h_bus['bvalid'], axi_wdone))

        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(ibus.wr_req, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_awset, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_wset, bit_0))
        if opts.bus_error:
            # During reset, all handshaking signals are set in a way to accept
            # all handshakes while returning an error on the BRESP signal.
            # This allows the bus to remain accessible despite being in reset
            # and without stalling the bus.
            proc.rst_stmts.append(HDLComment(
                "During reset, accept all handshakes and return error"))
            proc.rst_stmts.append(HDLAssign(axi_wdone, bit_1))
            proc.rst_stmts.append(HDLAssign(axi_werr, RESP_SLVERR))
        else:
            # Without bus error, use behaviour of original implementation
            proc.rst_stmts.append(HDLAssign(axi_wdone, bit_0))

            self.module.stmts.append(HDLAssign(axi_werr, RESP_OKAY))

        proc.sync_stmts.append(HDLAssign(ibus.wr_req, bit_0))
        if opts.bus_error:
            # Stop accepting handshake as soon as reset is over
            proc.sync_stmts.append(HDLAssign(axi_wdone, bit_0))
            # Reset BRESP signal
            proc.sync_stmts.append(HDLAssign(axi_werr, RESP_OKAY))

        # Load AWADDR (and acknowledge the AW request)
        proc_if = HDLIfElse(HDLAnd(HDLEq(self.root.h_bus['awvalid'], bit_1),
                                   HDLEq(axi_awset, bit_0)))
        if self.root.h_bus['awaddr'] is not None:
            proc_if.then_stmts.append(HDLAssign(opts.resize_addr_lhs(ibus.wr_adr, ibus),
                                                opts.resize_addr_in(self.root.h_bus['awaddr'], ibus)))
        proc_if.then_stmts.append(HDLAssign(axi_awset, bit_1))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_req, axi_wset))  # Start if W already set
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        # Load WDATA and WSEL (and acknowledge the W request)
        proc_if = HDLIfElse(HDLAnd(HDLEq(self.root.h_bus['wvalid'], bit_1),
                                   HDLEq(axi_wset, bit_0)))
        proc_if.then_stmts.append(HDLAssign(ibus.wr_dat, self.root.h_bus['wdata']))

        #   Translate Byte-wise write mask of AXI4Lite bus to bit-wise write mask of
        #   internal bus
        for idx in range(self.root.c_word_bits // tree.BYTE_SIZE):
            proc_if.then_stmts.append(
                HDLAssign(
                    HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                    HDLReplicate(
                        HDLSlice(self.root.h_bus['wstrb'], idx, None),
                        tree.BYTE_SIZE,
                        True,
                    ),
                )
            )

        proc_if.then_stmts.append(HDLAssign(axi_wset, bit_1))
        proc_if.then_stmts.append(
            HDLAssign(ibus.wr_req, HDLOr(axi_awset, self.root.h_bus['awvalid'])))  # Start if AW
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        # Clear 'set' bits at the end of the transaction
        proc_if = HDLIfElse(HDLEq(HDLParen(HDLAnd(axi_wdone, self.root.h_bus['bready'])), bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_wset, bit_0))
        proc_if.then_stmts.append(HDLAssign(axi_awset, bit_0))
        if not opts.bus_error:
            proc_if.then_stmts.append(HDLAssign(axi_wdone, bit_0))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        # WDONE indicates that the write is done on the slave part (so waiting to
        # be acknowledged by the master). WDONE is set on ack, cleared on BREADY.
        proc_if = HDLIfElse(HDLEq(ibus.wr_ack, bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_wdone, bit_1))

        if opts.bus_error:
            # Set BRESP signal indicating possible address error by returning
            # SLVERR (0b10) in case of an error
            proc_if_err = HDLIfElse(HDLEq(ibus.wr_err, bit_0))
            proc_if_err.then_stmts.append(HDLAssign(axi_werr, RESP_OKAY))
            proc_if_err.else_stmts.append(HDLAssign(axi_werr, RESP_SLVERR))
            proc_if.then_stmts.append(proc_if_err)

        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        self.module.stmts.append(proc)

        # Maintain assignment order of original implementation (before adding
        # the bus error feature)
        if opts.bus_error:
            bresp = axi_werr
        else:
            bresp = RESP_OKAY
        self.module.stmts.append(HDLAssign(self.root.h_bus['bresp'], bresp))

    def expand_bus_r(self, ibus, opts):
        """Sub-routine of expand_bus: the read part"""
        ibus.rd_req = self.module.new_HDLSignal('rd_req')  # Read access
        ibus.rd_ack = self.module.new_HDLSignal('rd_ack')  # Ack for read
        ibus.rd_err = self.module.new_HDLSignal('rd_err')  # Error for read
        ibus.rd_adr = self.module.new_HDLSignal('rd_addr', self.root.c_addr_bits,
                                           lo_idx=self.root.c_addr_word_bits)
        ibus.rd_dat = self.module.new_HDLSignal('rd_data', self.root.c_word_bits)
        # For the read accesses:
        # ARREADY defaults to asserted and is deasserted one cycle after ARVALID is set.
        # ARADDR is registred at the same time and the read strobe is generated.
        # RVALID is asserted on ack, until RREADY is asserted.
        # As RDATA must be stable until RREADY is asserted, it is registered.
        self.module.stmts.append(HDLComment("AR and R channels"))
        axi_arset = self.module.new_HDLSignal('axi_arset')
        axi_rdone = self.module.new_HDLSignal('axi_rdone')
        axi_rerr = self.module.new_HDLSignal('axi_rerr', 2)
        self.module.stmts.append(HDLAssign(self.root.h_bus['arready'], HDLNot(axi_arset)))
        self.module.stmts.append(HDLAssign(self.root.h_bus['rvalid'], axi_rdone))

        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(ibus.rd_req, bit_0))
        proc.rst_stmts.append(HDLAssign(axi_arset, bit_0))
        if opts.bus_error:
            # During reset, all handshaking signals are set in a way to accept
            # all handshakes while returning an error on the BRESP signal.
            # This allows the bus to remain accessible despite being in reset
            # and without stalling the bus.
            proc.rst_stmts.append(HDLComment(
                "During reset, accept all handshakes and return error"))
            proc.rst_stmts.append(HDLAssign(axi_rdone, bit_1))
            proc.rst_stmts.append(HDLAssign(axi_rerr, RESP_SLVERR))
        else:
            # Without bus error, use behaviour of original implementation
            proc.rst_stmts.append(HDLAssign(axi_rdone, bit_0))

            self.module.stmts.append(HDLAssign(axi_rerr, RESP_OKAY))
        proc.rst_stmts.append(
            HDLAssign(self.root.h_bus['rdata'], HDLReplicate(bit_0, self.root.c_word_bits)))

        proc.sync_stmts.append(HDLAssign(ibus.rd_req, bit_0))
        if opts.bus_error:
            # Stop accepting handshake as soon as reset is over
            proc.sync_stmts.append(HDLAssign(axi_rdone, bit_0))
            # Reset RRESP signal
            proc.sync_stmts.append(HDLAssign(axi_rerr, RESP_OKAY))

        # Load ARADDR (and acknowledge the AR request)
        proc_if = HDLIfElse(HDLAnd(HDLEq(self.root.h_bus['arvalid'], bit_1),
                                   HDLEq(axi_arset, bit_0)))
        if self.root.h_bus['araddr'] is not None:
            proc_if.then_stmts.append(HDLAssign(opts.resize_addr_lhs(ibus.rd_adr, ibus),
                                                opts.resize_addr_in(self.root.h_bus['araddr'], ibus)))
        proc_if.then_stmts.append(HDLAssign(axi_arset, bit_1))
        proc_if.then_stmts.append(HDLAssign(ibus.rd_req, bit_1))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        # Clear 'set' bit at the end of the transaction
        proc_if = HDLIfElse(HDLEq(HDLParen(HDLAnd(axi_rdone, self.root.h_bus['rready'])), bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_arset, bit_0))
        if not opts.bus_error:
            proc_if.then_stmts.append(HDLAssign(axi_rdone, bit_0))
        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        # RDONE indicates that the read is done on the slave part (so waiting to
        # be acknowledged by the master). RDONE is set on ack, cleared on RREADY.
        proc_if = HDLIfElse(HDLEq(ibus.rd_ack, bit_1))
        proc_if.then_stmts.append(HDLAssign(axi_rdone, bit_1))
        proc_if.then_stmts.append(HDLAssign(self.root.h_bus['rdata'], ibus.rd_dat))

        if opts.bus_error:
            # Set RRESP signal indicating possible address error by returning
            # SLVERR (0b10) in case of an error
            proc_if_err = HDLIfElse(HDLEq(ibus.rd_err, bit_0))
            proc_if_err.then_stmts.append(HDLAssign(axi_rerr, RESP_OKAY))
            proc_if_err.else_stmts.append(HDLAssign(axi_rerr, RESP_SLVERR))
            proc_if.then_stmts.append(proc_if_err)

        proc_if.else_stmts = None
        proc.sync_stmts.append(proc_if)

        self.module.stmts.append(proc)

        # Maintain assignment order of original implementation (before adding
        # the bus error feature)
        if opts.bus_error:
            rresp = axi_rerr
        else:
            rresp = RESP_OKAY
        self.module.stmts.append(HDLAssign(self.root.h_bus['rresp'], rresp))

    def add_xilinx_attributes(self, bus, portname):
        for name, port in bus:
            if name in ('clk', 'brst'):
                continue
            if isinstance(port, HDLInterfaceSelect):
                continue
            port.attributes['X_INTERFACE_INFO'] = "xilinx.com:interface:aximm:1.0 {} {}".format(
                portname, name.upper())

    def expand_bus(self, ibus, lib_name):
        """Create AXI4-Lite interface for the design."""
        opts = BusOptions(self.root, self.root)
        bus = [('clk', HDLPort("aclk")),
               ('brst', HDLPort("areset_n"))]
        bus.extend(self.gen_axi4lite_bus(self.module, 'axi4l',
            lambda n, sz, lo=0, dir='IN':
                (n, None if sz == 0 else HDLPort(n, size=sz,lo_idx=lo, dir=dir)),
                opts.addr_wd, opts.addr_low, self.root.c_word_bits, None, False, opts.busgroup, libname=lib_name))
        if self.root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(bus, 'slave')
        add_bus(self.root, self.module, bus)
        self.root.h_bussplit = True
        ibus.addr_size = self.root.c_addr_bits
        ibus.addr_low = self.root.c_addr_word_bits
        ibus.data_size = self.root.c_word_bits
        ibus.rst = self.root.h_bus['brst']
        ibus.clk = self.root.h_bus['clk']

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
        self.expand_bus_w(ibus, opts)
        self.expand_bus_r(ibus, opts)

    def gen_bus_slave(self, prefix, n, opts):
        comment = "\n" + (n.comment or "AXI-4 lite bus {}".format(n.name))
        ports = self.gen_axi4lite_bus(self.module, n.c_name,
            lambda name, sz=None, lo=0, dir='IN':
                (name, None if sz == 0 else self.module.add_port(
                    '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                    size=sz, lo_idx=lo, dir=dir)),
                    opts.addr_wd, opts.addr_low, self.root.c_word_bits, comment,
                    True, opts.busgroup)
        if self.root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(ports, n.c_name)
        n.h_bus_opts = opts
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        n.h_bus['awvalid'].comment = comment
        # Internal signals: valid signals.
        n.h_aw_val = self.module.new_HDLSignal(prefix + 'aw_val')
        n.h_w_val = self.module.new_HDLSignal(prefix + 'w_val')
        n.h_ar_val = self.module.new_HDLSignal(prefix + 'ar_val')
        # Internal request signals from address decoders
        n.h_rd = self.module.new_HDLSignal(prefix + 'rd')
        n.h_wr = self.module.new_HDLSignal(prefix + 'wr')

    def wire_bus_slave(self, n, ibus):
        stmts = self.module.stmts
        stmts.append(HDLAssign(n.h_bus['awvalid'], n.h_aw_val))
        if n.h_bus['awaddr'] is not None:
            stmts.append(HDLAssign(
                n.h_bus['awaddr'],
                n.h_bus_opts.resize_addr_out_full(ibus.wr_adr, ibus)))
        stmts.append(HDLAssign(n.h_bus['awprot'], HDLBinConst(0, 3)))
        stmts.append(HDLAssign(n.h_bus['wvalid'], n.h_w_val))
        stmts.append(HDLAssign(n.h_bus['wdata'], ibus.wr_dat))

        if ibus.wr_sel is not None:
            # Translate bit-wise write mask of internal bus to Byte-wise write mask of
            # AXI4Lite bus
            proc = HDLComb()
            proc.sensitivity.extend([ibus.wr_sel])
            proc.stmts.append(
                HDLAssign(
                    n.h_bus['wstrb'],
                    HDLReplicate(bit_0, self.root.c_word_bits // tree.BYTE_SIZE),
                )
            )
            for idx in range(self.root.c_word_bits // tree.BYTE_SIZE):
                if_stmt = HDLIfElse(
                    HDLNot(
                        HDLEq(
                            HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                            HDLReplicate(bit_0, tree.BYTE_SIZE, False),
                        )
                    )
                )
                if_stmt.then_stmts.append(
                    HDLAssign(HDLSlice(n.h_bus['wstrb'], idx, None), bit_1)
                )
                if_stmt.else_stmts = None
                proc.stmts.append(if_stmt)
            stmts.append(proc)
        else:
            stmts.append(
                HDLAssign(
                    n.h_bus['wstrb'],
                    HDLReplicate(bit_1, self.root.c_word_bits // tree.BYTE_SIZE),
                )
            )

        stmts.append(HDLAssign(n.h_bus['bready'], bit_1))

        stmts.append(HDLAssign(n.h_bus['arvalid'], n.h_ar_val))
        if n.h_bus['araddr'] is not None:
            stmts.append(HDLAssign(
                n.h_bus['araddr'],
                n.h_bus_opts.resize_addr_out_full(ibus.rd_adr, ibus)))
        stmts.append(HDLAssign(n.h_bus['arprot'], HDLBinConst(0, 3)))
        stmts.append(HDLAssign(n.h_bus['rready'], bit_1))

        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        # Machine state for valid/ready AW and W channels
        # Set valid on request, clear valid on ready.
        # Set done on ready, clear done on ack.
        for x_val, req, ready in [
                (n.h_aw_val, n.h_wr, n.h_bus['awready']),
                (n.h_w_val, n.h_wr, n.h_bus['wready']),
                (n.h_ar_val, n.h_rd, n.h_bus['arready'])]:
            proc.rst_stmts.append(HDLAssign(x_val, bit_0))
            # VALID is set on REQ, cleared by READY.
            proc.sync_stmts.append(
                HDLAssign(x_val, HDLOr(req, HDLParen(HDLAnd(x_val, HDLNot(ready))))))
        stmts.append(proc)

    def write_bus_slave(self, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_wr, bit_0))
        stmts.append(HDLAssign(n.h_wr, ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['bvalid']))

    def read_bus_slave(self, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_rd, bit_0))
        stmts.append(HDLAssign(n.h_rd, ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['rdata']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rvalid']))
