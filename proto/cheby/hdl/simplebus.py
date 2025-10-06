from cheby.hdltree import (HDLPort,
                           HDLAssign, HDLSync, HDLComb,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLParen)
from cheby.hdl.busgen import BusGen
from cheby.hdl.globals import gconfig, dirname
from cheby.hdl.ibus import add_bus
import cheby.parser as parser


class SimpleBus(BusGen):
    def __init__(self, name, root, module):
        super().__init__(root, module)
        self.buserr = False
        self.split = False

    names = {
        'clk': 'clk',
        'rst': 'rst',
        'adr': 'adr',
        'adrr': 'adrr',
        'adrw': 'adrw',
        'dato': 'dato',
        'dati': 'dati',
        'rd': 'rd',
        'wr': 'wr',
        'rack': 'rack',
        'wack': 'wack',
        'rderr': 'rderr',
        'wrerr': 'wrerr'
    }

    busname = "simple"

    def add_decode_simple_bus(self, ibus):
        """Generate internal signals used by decoder/processes from the bus"""
        ibus.rd_req = self.root.h_bus['rd']
        ibus.wr_req = self.root.h_bus['wr']
        ibus.rd_ack = self.module.new_HDLSignal('rd_ack_int')    # Ack for read
        ibus.rd_err = self.module.new_HDLSignal('rd_err_int')    # Error for read (not supported)
        ibus.wr_ack = self.module.new_HDLSignal('wr_ack_int')    # Ack for write
        ibus.wr_err = self.module.new_HDLSignal('wr_err_int')    # Error for write (not supported)
        self.module.stmts.append(HDLAssign(self.root.h_bus['rack'], ibus.rd_ack))
        self.module.stmts.append(HDLAssign(self.root.h_bus['wack'], ibus.wr_ack))

    def gen_bus(self, build_port, addr_bits, lo_addr, data_bits,
                     force_addr, is_split, is_buserr, is_master):
        """Create bus interface."""
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        bus = []
        if force_addr or addr_bits > 0:
            if is_split:
                bus.extend(
                    [('adrr', build_port(self.names['adrr'], addr_bits,
                                         lo=lo_addr, dir=inp)),
                     ('adrw', build_port(self.names['adrw'], addr_bits,
                                         lo=lo_addr, dir=inp))])
            else:
                bus.extend(
                    [('adr', build_port(self.names['adr'], addr_bits,
                                        lo=lo_addr, dir=inp))])
        bus.extend(
            [('dato', build_port(self.names['dato'], data_bits, dir=out)),
             ('dati', build_port(self.names['dati'], data_bits, dir=inp)),
             ('rd', build_port(self.names['rd'], dir=inp)),
             ('wr', build_port(self.names['wr'], dir=inp)),
             ('rack', build_port(self.names['rack'], dir=out)),
             ('wack', build_port(self.names['wack'], dir=out))])
        if is_buserr:
            bus.extend([('rderr', build_port(self.names['rderr'], dir=out)),
                        ('wrerr', build_port(self.names['wrerr'], dir=out))])
        return bus

    def add_xilinx_attributes(self, bus, portname):
        pass

    def expand_bus(self, ibus):
        """Create bus interface."""
        if self.root.get_extension('x_hdl', 'busgroup'):
            parser.warning(self.root, "busgroup on '{}' is ignored for {}".format(
                self.root.get_path(), self.busname))
        if self.root.get_extension('x_hdl', 'bus-error'):
            parser.warning(self.root, "bus-error on '{}' is ignored for {}".format(
                self.root.get_path(), self.busname))

        bus = [('clk', HDLPort(self.names['clk'])),
               ('brst', HDLPort(self.names['rst']))]
        bus.extend(self.gen_bus(
            lambda n, sz=None, lo=0, dir='IN':
            HDLPort(n, size=sz, lo_idx=lo, dir=dir) if sz is None or sz > 0 else None,
            self.root.c_addr_bits, self.root.c_addr_word_bits, self.root.c_word_bits,
            ibus is None, self.split, self.buserr, False))
        if self.root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(bus, 'slave')
        add_bus(self.root, self.module, bus)
        self.root.h_bussplit = self.split

        # The reset port Rst is active high, while internally we use an active low reset.
        # Kludge: not reverted for gen_gena_regctrl...
        if ibus is not None:
            rstn = self.module.new_HDLSignal('rst_n')
            self.module.stmts.append(HDLAssign(rstn, HDLNot(self.root.h_bus['brst'])))
            self.root.h_bus['brst'] = rstn

        if ibus is not None:
            ibus.addr_size = self.root.c_addr_bits
            ibus.addr_low = self.root.c_addr_word_bits
            ibus.data_size = self.root.c_word_bits
            ibus.clk = self.root.h_bus['clk']
            ibus.rst = self.root.h_bus['brst']
            ibus.rd_dat = self.root.h_bus['dato']
            ibus.wr_dat = self.root.h_bus['dati']

            if self.root.c_addr_bits > 0:
                if self.split:
                    ibus.rd_adr = self.root.h_bus['adrr']
                    ibus.wr_adr = self.root.h_bus['adrw']
                else:
                    ibus.rd_adr = self.root.h_bus['adr']
                    ibus.wr_adr = self.root.h_bus['adr']

            self.add_decode_simple_bus(ibus)

    def gen_bus_slave(self, prefix, n, opts):
        """Create an interface to a slave (Add declarations)"""
        if opts.busgroup:
            parser.warning(self.root, "busgroup on '{}' is ignored for {}".format(
                self.root.get_path(), self.busname))
        ports = self.gen_bus(
            lambda name, sz=None, lo=0, dir='IN':
                 None if sz == 0 else self.module.add_port(
                    '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                    size=sz, lo_idx=lo, dir=dir),
            n.c_addr_bits, self.root.c_addr_word_bits, self.root.c_word_bits,
            False, self.split, self.buserr, True)
        if self.root.hdl_bus_attribute == 'Xilinx':
            self.add_xilinx_attributes(ports, n.c_name)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        # Add the comment.  Not that simple as the first port of the bus depends on
        # split or not split, address or no address.
        comment = "\n" + (n.comment or "{} bus {}".format(self.busname, n.name))
        if n.c_addr_bits > 0:
            first = 'adrr' if self.split else 'adr'
        else:
            first = 'dato'
        n.h_bus[first].comment = comment
        if self.root.h_bussplit:
            # Request signals
            n.h_wr = self.module.new_HDLSignal(prefix + 'wr')
            n.h_rr = self.module.new_HDLSignal(prefix + 'rr')
            # Start transactions
            n.h_ws = self.module.new_HDLSignal(prefix + 'ws')
            n.h_rs = self.module.new_HDLSignal(prefix + 'rs')
            # Enable (set by decoding logic)
            n.h_re = self.module.new_HDLSignal(prefix + 're')
            n.h_we = self.module.new_HDLSignal(prefix + 'we')
            # Transaction in progress
            n.h_wt = self.module.new_HDLSignal(prefix + 'wt')
            n.h_rt = self.module.new_HDLSignal(prefix + 'rt')

    def gen_adr_mux(self, n, ibus):
        # Mux for addresses.
        proc = HDLComb()
        proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, n.h_wt, n.h_ws])
        if_stmt = HDLIfElse(HDLEq(HDLOr(n.h_ws, n.h_wt), bit_1))
        if_stmt.then_stmts.append(
            HDLAssign(n.h_bus['adr'],
                      HDLSlice(ibus.wr_adr, self.root.c_addr_word_bits, n.c_addr_bits)))
        if_stmt.else_stmts.append(
            HDLAssign(n.h_bus['adr'],
                      HDLSlice(ibus.rd_adr, self.root.c_addr_word_bits, n.c_addr_bits)))
        proc.stmts.append(if_stmt)
        self.module.stmts.append(proc)

    def wire_bus_slave(self, n, ibus):
        stmts = self.module.stmts
        stmts.append(HDLAssign(n.h_bus['dati'], ibus.wr_dat))

        if self.root.h_bussplit:
            # Handle read requests.
            proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
            # Write requests set on WE, clear by RdDone
            proc.sync_stmts.append(
                HDLAssign(n.h_wr,
                          HDLAnd(HDLOr(n.h_wr, n.h_we), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
            # Write transaction set start W transaction, clear by WrDone
            proc.sync_stmts.append(
                HDLAssign(n.h_wt,
                          HDLAnd(HDLOr(n.h_wt, n.h_ws), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            # Read requests set on RE, clear by RdDone
            proc.sync_stmts.append(
                HDLAssign(n.h_rr,
                          HDLAnd(HDLOr(n.h_rr, n.h_re), HDLNot(n.h_bus['rack']))))
            proc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
            # Read transaction set start R transaction, clear by RdDone
            proc.sync_stmts.append(
                HDLAssign(n.h_rt,
                          HDLAnd(HDLOr(n.h_rt, n.h_rs), HDLNot(n.h_bus['rack']))))
            proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
            stmts.append(proc)
            # Start a read transaction if a read request is pending and no transactions in
            # progress, and no write request (priority to write).
            stmts.append(
                HDLAssign(n.h_rs,
                          HDLAnd(n.h_rr, HDLNot(HDLOr(n.h_wr, HDLOr(n.h_rt, n.h_wt))))))
            # Start write transaction if pending write request and no read transaction XXX.
            stmts.append(
                HDLAssign(n.h_ws,
                          HDLAnd(n.h_wr, HDLNot(HDLOr(n.h_rt, n.h_wt)))))
            # Mux for addresses.
            if ibus.rd_adr is not None:
                self.gen_adr_mux(n, ibus)
        elif ibus.rd_adr != ibus.wr_adr:
            # Asymetric pipelining: add a mux to select the address.
            n.h_ws = self.module.new_HDLSignal(n.c_name + '_ws')
            n.h_wt = self.module.new_HDLSignal(n.c_name + '_wt')
            proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
            proc.sync_stmts.append(
                HDLAssign(n.h_wt,
                          HDLAnd(HDLOr(n.h_wt, n.h_ws), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            stmts.append(proc)
            stmts.append(HDLAssign(n.h_bus['wr'], n.h_ws))
            # Mux for addresses.
            if n.c_addr_bits > 0:
                self.gen_adr_mux(n, ibus)
        else:
            if n.c_addr_bits > 0:
                stmts.append(HDLAssign(n.h_bus['adr'],
                                       HDLSlice(ibus.rd_adr, self.root.c_addr_word_bits, n.c_addr_bits)))

    def write_bus_slave(self, stmts, n, proc, ibus):
        if self.root.h_bussplit:
            # Start write transaction if WR is set and neither read nor write transaction
            proc.stmts.append(HDLAssign(n.h_we, bit_0))
            stmts.append(HDLAssign(n.h_we, ibus.wr_req))
            proc.stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
            stmts.append(HDLAssign(n.h_bus['wr'], n.h_ws))
        elif ibus.rd_adr != ibus.wr_adr:
            proc.stmts.append(HDLAssign(n.h_ws, bit_0))
            stmts.append(HDLAssign(n.h_ws, ibus.wr_req))
        else:
            proc.stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
            stmts.append(HDLAssign(n.h_bus['wr'], ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['wack']))

    def read_bus_slave(self, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_bus['rd'], bit_0))
        if self.root.h_bussplit:
            # Start read transaction if RR is set and neither read nor write transaction
            proc.stmts.append(HDLAssign(n.h_re, bit_0))
            stmts.append(HDLAssign(n.h_re, ibus.rd_req))
            stmts.append(HDLAssign(n.h_bus['rd'], n.h_rs))
        else:
            stmts.append(HDLAssign(n.h_bus['rd'], ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rack']))
