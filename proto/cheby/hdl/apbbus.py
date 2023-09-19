from cheby.hdltree import (
    HDLPort,
    HDLAssign,
    HDLComment,
    HDLAnd,
    HDLOr,
    HDLNot,
    HDLIfElse,
    HDLEq,
    HDLParen,
    HDLSlice,
    HDLReplicate,
    HDLSync,
    HDLComb,
    bit_0,
    bit_1,
)
from cheby.hdl.busgen import BusGen
import cheby.tree as tree
import cheby.parser as parser
from cheby.hdl.globals import gconfig, dirname
from cheby.hdl.ibus import add_bus
from cheby.hdl.busparams import BusOptions


class APBBus(BusGen):
    def __init__(self, name):
        assert name == "apb-32"

    def gen_ports(self, build_port, addr_bits, lo_addr, data_bits, is_master=False):
        """Generates required APB ports based on the generator function build_port"""
        inp, outp = ("IN", "OUT") if not is_master else ("OUT", "IN")
        return [
            build_port("paddr", addr_bits, lo=lo_addr, dir=inp),
            build_port("psel", None, dir=inp),
            build_port("pwrite", None, dir=inp),
            build_port("penable", None, dir=inp),
            build_port("pready", None, dir=outp),
            build_port("pwdata", data_bits, dir=inp),
            build_port("pstrb", data_bits // tree.BYTE_SIZE, dir=inp),
            build_port("prdata", data_bits, dir=outp),
            build_port("pslverr", None, dir=outp),
        ]

    def expand_bus_w(self, root, module, ibus, opts):
        """Generate internal write bus and connect it with APB signals"""
        ibus.wr_req = module.new_HDLSignal("wr_req")
        ibus.wr_adr = module.new_HDLSignal(
            "wr_addr", root.c_addr_bits, lo_idx=root.c_addr_word_bits
        )
        ibus.wr_dat = module.new_HDLSignal("wr_data", root.c_word_bits)
        ibus.wr_sel = module.new_HDLSignal("wr_sel", root.c_word_bits)

        module.stmts.append(HDLComment("Write Channel"))
        # A write transfer consists of two phases, a setup and an access phase. The
        # setup phase has a duration of one clock cycle, the access phase has a duration
        # of at least one clock cycle. At the end of the access phase (i.e. at the
        # earliest with the third rising clock cycle) the written data is applied.
        #   1. The select signal, PSEL, is asserted, which means that PADDR, PWRITE, and
        #      PWDATA must be valid.
        #   2. The enable signal, PENABLE, is asserted until the completer device
        #      asserts the ready signal, PREADY.
        #   3. At the rising clock edge following the assertion of the ready signal, the
        #      written data is applied.
        # If the select signal remains asserted after a transfer, a new transfer is
        # started.
        #
        # The following logic converts an APB write request into a write request on the
        # internal bus. While the APB write request has to be kept asserted until it is
        # acknowledged, the forwarded internal write request is only active for one
        # clock cycle.
        # Without pipelining on the write side (wr-*), the write request will be
        # executed at the end of the setup phase (i.e. with the second rising clock
        # edge). This is one cycle earlier than what the standard foresees. In such a
        # case, an APB write request can be completed without the setup phase and hence,
        # in one clock cycle only.
        module.stmts.append(
            HDLAssign(
                ibus.wr_req,
                HDLAnd(
                    HDLAnd(root.h_bus["psel"], root.h_bus["pwrite"]),
                    HDLNot(root.h_bus["penable"]),
                ),
            )
        )
        module.stmts.append(HDLAssign(ibus.wr_adr, root.h_bus["paddr"]))
        module.stmts.append(HDLAssign(ibus.wr_dat, root.h_bus["pwdata"]))

        # Translate Byte-wise write mask of APB bus to bit-wise write mask of ibus
        proc = HDLComb()
        proc.sensitivity.extend([root.h_bus["pstrb"]])
        for idx in range(root.c_word_bits // tree.BYTE_SIZE):
            proc.stmts.append(
                HDLAssign(
                    HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                    HDLReplicate(
                        HDLSlice(root.h_bus["pstrb"], idx, None),
                        tree.BYTE_SIZE,
                        True,
                    ),
                )
            )
        module.stmts.append(proc)

    def expand_bus_r(self, root, module, ibus, opts):
        """Generate internal read bus and connect it with APB signals"""
        ibus.rd_req = module.new_HDLSignal("rd_req")
        ibus.rd_adr = module.new_HDLSignal(
            "rd_addr", root.c_addr_bits, lo_idx=root.c_addr_word_bits
        )
        ibus.rd_dat = module.new_HDLSignal("rd_data", root.c_word_bits)

        module.stmts.append(HDLComment("Read Channel"))
        # A read transfer consists of two phases, a setup and an access phase. The setup
        # phase has a duration of one clock cycle, the access phase has a duration of at
        # least one clock cycle. The data is read and output together with the assertion
        # of the ready signal, PREADY. The rising clock edge following the assertion of
        # the ready signal completes the access phase.
        #   1. The select signal, PSEL, is asserted, which means that PADDR, PWRITE, and
        #      PWDATA must be valid.
        #   2. The enable signal, PENABLE, is asserted until the completer device
        #      asserts the ready signal, PREADY.
        #   3. At the rising clock edge following the assertion of the ready signal, the
        #      read transfer is completed.
        # If the select signal remains asserted after a transfer, a new transfer is
        # started.
        #
        # The following logic converts an APB read request into a read request on the
        # internal bus. While the APB read request has to be kept asserted until it is
        # acknowledged, the forwarded internal read request is only active for one
        # clock cycle.
        # Since the the read data should be available as early as possible during the
        # access phase, the read request is already forwarded during the setup phase.
        # Without pipelining on the read side (rd-*), the read data might even be ready
        # during the setup phase. In that case, an APB read request can be completed
        # without the setup phase and hence, in one clock cycle only.
        module.stmts.append(
            HDLAssign(
                ibus.rd_req,
                HDLAnd(
                    HDLAnd(root.h_bus["psel"], HDLNot(root.h_bus["pwrite"])),
                    HDLNot(root.h_bus["penable"]),
                ),
            )
        )
        module.stmts.append(HDLAssign(ibus.rd_adr, root.h_bus["paddr"]))
        module.stmts.append(HDLAssign(root.h_bus["prdata"], ibus.rd_dat))

    def expand_bus_output(self, root, module, ibus, opts):
        """Generate output APB signals and connect them with internal bus"""
        ibus.wr_err = module.new_HDLSignal("wr_err")
        ibus.wr_ack = module.new_HDLSignal("wr_ack")
        ibus.rd_ack = module.new_HDLSignal("rd_ack")
        ibus.rd_err = module.new_HDLSignal("rd_err")

        module.stmts.append(
            HDLAssign(root.h_bus["pready"], HDLOr(ibus.wr_ack, ibus.rd_ack))
        )
        if opts.bus_error:
            module.stmts.append(
                HDLAssign(root.h_bus["pslverr"], HDLOr(ibus.wr_err, ibus.rd_err))
            )
        else:
            module.stmts.append(HDLAssign(root.h_bus["pslverr"], bit_0))

    def add_xilinx_attributes(self, bus, portname):
        """Add bus attributes used by Xilinx' Vivado"""
        for name, port in bus:
            if name in ("clk", "brst"):
                continue
            port.attributes[
                "X_INTERFACE_INFO"
            ] = "xilinx.com:interface:apb:1.0 {} {}".format(portname, name.upper())

    def expand_opts(self, opts):
        """Apply bus options"""
        if opts.busgroup:
            parser.warning(
                opts.bus,
                "busgroup on '{}' is ignored for apb-32".format(opts.bus.get_path()),
            )

    def expand_bus(self, root, module, ibus):
        """Create APB top level interface"""
        opts = BusOptions(root, root)
        self.expand_opts(opts)

        # Generate bus ports
        bus = [("clk", HDLPort("pclk")), ("brst", HDLPort("presetn"))]
        bus.extend(
            self.gen_ports(
                lambda n, sz, lo=0, dir="IN": (
                    n,
                    None if sz == 0 else HDLPort(n, size=sz, lo_idx=lo, dir=dir),
                ),
                opts.addr_wd,
                opts.addr_low,
                root.c_word_bits,
                False,
            )
        )

        if root.hdl_bus_attribute == "Xilinx":
            self.add_xilinx_attributes(bus, "slave")

        add_bus(root, module, bus)

        # Configure internal bus
        root.h_bussplit = True
        ibus.addr_size = root.c_addr_bits
        ibus.addr_low = root.c_addr_word_bits
        ibus.data_size = root.c_word_bits
        ibus.rst = root.h_bus["brst"]
        ibus.clk = root.h_bus["clk"]

        # Connect internal bus with APB signals
        self.expand_bus_w(root, module, ibus, opts)
        self.expand_bus_r(root, module, ibus, opts)
        self.expand_bus_output(root, module, ibus, opts)

    def gen_bus_slave(self, root, module, prefix, n, opts):
        """Create internal APB interface"""
        self.expand_opts(opts)

        ports = self.gen_ports(
            lambda name, sz=None, lo=0, dir="IN": (
                name,
                None
                if sz == 0
                else module.add_port(
                    "{}_{}_{}".format(n.c_name, name, dirname[dir]),
                    size=sz,
                    lo_idx=lo,
                    dir=dir,
                ),
            ),
            opts.addr_wd,
            opts.addr_low,
            root.c_word_bits,
            True,
        )

        if root.hdl_bus_attribute == "Xilinx":
            self.add_xilinx_attributes(ports, n.c_name)

        n.h_bus_opts = opts

        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p

        # Internal sampled signals
        #   Write Request
        n.i_wr_req = module.new_HDLSignal(prefix + "wr_req")
        n.i_wr_ack = module.new_HDLSignal(prefix + "wr_ack")
        n.h_wr = module.new_HDLSignal(prefix + "wr")
        n.h_wr_reg = module.new_HDLSignal(prefix + "wr_reg")
        #   Read Request
        n.i_rd_req = module.new_HDLSignal(prefix + "rd_req")
        n.i_rd_ack = module.new_HDLSignal(prefix + "rd_ack")
        n.h_rd = module.new_HDLSignal(prefix + "rd")
        n.h_rd_reg = module.new_HDLSignal(prefix + "rd_reg")

    def wire_bus_slave(self, root, module, n, ibus):
        """Connect internal APB interface with internal bus"""
        stmts = module.stmts

        # Internal request signal
        # Activate on incoming request, deactivate on acknowledge (prioritize)
        proc = HDLSync(root.h_bus["clk"], root.h_bus["brst"], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(n.h_wr_reg, bit_0))
        proc.rst_stmts.append(HDLAssign(n.h_rd_reg, bit_0))

        proc_ack = HDLIfElse(HDLEq(n.i_wr_ack, bit_1))
        proc_ack.then_stmts.append(HDLAssign(n.h_wr_reg, bit_0))
        proc_req = HDLIfElse(HDLEq(n.i_wr_req, bit_1))
        proc_req.then_stmts.append(HDLAssign(n.h_wr_reg, bit_1))
        proc_req.else_stmts = None
        proc_ack.else_stmts.append(proc_req)
        proc.sync_stmts.append(proc_ack)

        proc_ack = HDLIfElse(HDLEq(n.i_rd_ack, bit_1))
        proc_ack.then_stmts.append(HDLAssign(n.h_rd_reg, bit_0))
        proc_req = HDLIfElse(HDLEq(n.i_rd_req, bit_1))
        proc_req.then_stmts.append(HDLAssign(n.h_rd_reg, bit_1))
        proc_req.else_stmts = None
        proc_ack.else_stmts.append(proc_req)
        proc.sync_stmts.append(proc_ack)

        stmts.append(proc)
        stmts.append(HDLAssign(n.h_wr, HDLOr(n.h_wr_reg, n.i_wr_req)))
        stmts.append(HDLAssign(n.h_rd, HDLOr(n.h_rd_reg, n.i_rd_req)))

        stmts.append(HDLAssign(n.h_bus["psel"], HDLOr(n.h_wr, n.h_rd)))
        stmts.append(
            HDLAssign(
                n.h_bus["penable"],
                HDLOr(
                    HDLParen(HDLAnd(HDLNot(ibus.wr_req), n.h_wr)),
                    HDLParen(HDLAnd(HDLNot(ibus.rd_req), n.h_rd)),
                ),
            )
        )
        stmts.append(HDLAssign(n.h_bus["pwrite"], n.h_wr))

        if n.h_bus["paddr"] is not None:
            proc = HDLComb()
            proc.sensitivity.extend([n.h_wr, ibus.wr_adr, ibus.rd_adr])
            proc_if = HDLIfElse(HDLEq(n.h_wr, bit_1))
            proc_if.then_stmts.append(
                HDLAssign(
                    n.h_bus["paddr"],
                    n.h_bus_opts.resize_addr_out(
                        HDLSlice(ibus.wr_adr, root.c_addr_word_bits, n.c_addr_bits),
                        ibus,
                    ),
                )
            )
            proc_if.else_stmts.append(
                HDLAssign(
                    n.h_bus["paddr"],
                    n.h_bus_opts.resize_addr_out(
                        HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits),
                        ibus,
                    ),
                )
            )
            proc.stmts.append(proc_if)
            stmts.append(proc)

        stmts.append(HDLAssign(n.h_bus["pwdata"], ibus.wr_dat))

        if ibus.wr_sel is not None:
            # Translate bit-wise write mask of ibus to Byte-wise write mask of APB bus
            proc = HDLComb()
            proc.sensitivity.extend([ibus.wr_sel])
            proc.stmts.append(
                HDLAssign(
                    n.h_bus["pstrb"],
                    HDLReplicate(bit_0, root.c_word_bits // tree.BYTE_SIZE),
                )
            )
            for idx in range(root.c_word_bits // tree.BYTE_SIZE):
                proc_if = HDLIfElse(
                    HDLNot(
                        HDLEq(
                            HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                            HDLReplicate(bit_0, tree.BYTE_SIZE, False),
                        )
                    )
                )
                proc_if.then_stmts.append(
                    HDLAssign(HDLSlice(n.h_bus["pstrb"], idx, None), bit_1)
                )
                proc_if.else_stmts = None
                proc.stmts.append(proc_if)
            stmts.append(proc)
        else:
            stmts.append(
                HDLAssign(
                    n.h_bus["pstrb"],
                    HDLReplicate(bit_1, root.c_word_bits // tree.BYTE_SIZE),
                )
            )

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.i_wr_req, bit_0))
        proc.stmts.append(HDLAssign(n.i_wr_ack, bit_0))
        stmts.append(HDLAssign(n.i_wr_req, ibus.wr_req))
        stmts.append(HDLAssign(n.i_wr_ack, ibus.wr_ack))

        stmts.append(HDLAssign(ibus.wr_ack, HDLAnd(n.h_wr, n.h_bus["pready"])))
        stmts.append(HDLAssign(ibus.wr_err, HDLAnd(n.h_wr, n.h_bus["pslverr"])))

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.i_rd_req, bit_0))
        proc.stmts.append(HDLAssign(n.i_rd_ack, bit_0))
        stmts.append(HDLAssign(n.i_rd_req, ibus.rd_req))
        stmts.append(HDLAssign(n.i_rd_ack, ibus.rd_ack))

        stmts.append(HDLAssign(ibus.rd_dat, n.h_bus["prdata"]))
        stmts.append(HDLAssign(ibus.rd_ack, HDLAnd(n.h_rd, n.h_bus["pready"])))
        stmts.append(HDLAssign(ibus.rd_err, HDLAnd(n.h_rd, n.h_bus["pslverr"])))
