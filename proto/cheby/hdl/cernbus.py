from cheby.hdltree import (HDLPort,
                           HDLAssign, HDLSync, HDLComb,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLParen)
from cheby.hdl.busgen import BusGen
from cheby.hdl.globals import gconfig, dirname
from cheby.hdl.ibus import add_bus


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

    def add_decode_cern_be_vme(self, root, module, ibus):
        """Generate internal signals used by decoder/processes from
        CERN-BE-VME bus."""
        ibus.rd_req = root.h_bus['rd']
        ibus.wr_req = root.h_bus['wr']
        ibus.rd_ack = module.new_HDLSignal('rd_ack_int')    # Ack for read
        ibus.wr_ack = module.new_HDLSignal('wr_ack_int')    # Ack for write
        module.stmts.append(HDLAssign(root.h_bus['rack'], ibus.rd_ack))
        module.stmts.append(HDLAssign(root.h_bus['wack'], ibus.wr_ack))

    def gen_cern_bus(self, build_port, addr_bits, lo_addr, data_bits,
                     is_split, is_buserr, is_master):
        """Create CERN-BE interface."""
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        bus = []
        if is_split:
            bus.extend(
                [('adrr', build_port("VMERdAddr", addr_bits,
                                     lo=lo_addr, dir=inp)),
                 ('adrw', build_port("VMEWrAddr", addr_bits,
                                     lo=lo_addr, dir=inp))])
        else:
            bus.extend(
                [('adr', build_port("VMEAddr", addr_bits,
                                    lo=lo_addr, dir=inp))])
        bus.extend(
            [('dato', build_port("VMERdData", data_bits, dir=out)),
             ('dati', build_port("VMEWrData", data_bits, dir=inp)),
             ('rd', build_port("VMERdMem", dir=inp)),
             ('wr', build_port("VMEWrMem", dir=inp)),
             ('rack', build_port("VMERdDone", dir=out)),
             ('wack', build_port("VMEWrDone", dir=out))])
        if is_buserr:
            bus.extend([('rderr', build_port('VMERdError', dir=out)),
                        ('wrerr', build_port('VMEWrError', dir=out))])
        return bus

    def expand_bus(self, root, module, ibus):
        """Create CERN-BE interface."""
        bus = [('clk', HDLPort("Clk")),
               ('rst', HDLPort("Rst"))]
        bus.extend(self.gen_cern_bus(
            lambda n, sz=None, lo=0, dir='IN': HDLPort(n, size=sz, lo_idx=lo, dir=dir) if sz is None or sz > 0 else None,
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            self.split, self.buserr, False))
        add_bus(root, module, bus)
        root.h_bussplit = self.split

        # The reset port Rst is active high, while internally we use an active low reset.
        # Kludge: not reverted for gen_gena_regctrl...
        if ibus is not None:
            rstn = module.new_HDLSignal('rst_n')
            module.stmts.append(HDLAssign(rstn, HDLNot(root.h_bus['rst'])))
            root.h_bus['rst'] = rstn

        if ibus is not None:
            ibus.addr_size = root.c_addr_bits
            ibus.addr_low = root.c_addr_word_bits
            ibus.data_size = root.c_word_bits
            ibus.clk = root.h_bus['clk']
            ibus.rst = root.h_bus['rst']
            ibus.rd_dat = root.h_bus['dato']
            ibus.wr_dat = root.h_bus['dati']

            if self.split:
                ibus.rd_adr = root.h_bus['adrr']
                ibus.wr_adr = root.h_bus['adrw']
            else:
                ibus.rd_adr = root.h_bus['adr']
                ibus.wr_adr = root.h_bus['adr']

            self.add_decode_cern_be_vme(root, module, ibus)

    def gen_bus_slave(self, root, module, prefix, n, busgroup):
        """Create an interface to a slave (Add declarations)"""
        ports = self.gen_cern_bus(
            lambda name, sz=None, lo=0, dir='IN': module.add_port(
                '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                size=sz, lo_idx=lo, dir=dir),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            self.split, self.buserr, True)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        comment = '\n' + (n.comment or n.description or 'CERN-BE bus {}'.format(n.name))
        n.h_bus['adrr' if self.split else 'adr'].comment = comment
        if root.h_bussplit:
            # Request signals
            n.h_wr = module.new_HDLSignal(prefix + 'wr')
            n.h_rr = module.new_HDLSignal(prefix + 'rr')
            # Start transactions
            n.h_ws = module.new_HDLSignal(prefix + 'ws')
            n.h_rs = module.new_HDLSignal(prefix + 'rs')
            # Enable (set by decoding logic)
            n.h_re = module.new_HDLSignal(prefix + 're')
            n.h_we = module.new_HDLSignal(prefix + 'we')
            # Transaction in progress
            n.h_wt = module.new_HDLSignal(prefix + 'wt')
            n.h_rt = module.new_HDLSignal(prefix + 'rt')

    def gen_adr_mux(self, root, module, n, ibus):
        # Mux for addresses.
        proc = HDLComb()
        proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, n.h_wt, n.h_ws])
        if_stmt = HDLIfElse(HDLEq(HDLOr(n.h_ws, n.h_wt), bit_1))
        if_stmt.then_stmts.append(
            HDLAssign(n.h_bus['adr'],
                      HDLSlice(ibus.wr_adr, root.c_addr_word_bits, n.c_addr_bits)))
        if_stmt.else_stmts.append(
            HDLAssign(n.h_bus['adr'],
                      HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits)))
        proc.stmts.append(if_stmt)
        module.stmts.append(proc)

    def wire_bus_slave(self, root, module, n, ibus):
        stmts = module.stmts
        stmts.append(HDLAssign(n.h_bus['dati'], ibus.wr_dat))

        if root.h_bussplit:
            # Handle read requests.
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
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
            self.gen_adr_mux(root, module, n, ibus)
        elif ibus.rd_adr != ibus.wr_adr:
            # Asymetric pipelining: add a mux to select the address.
            n.h_ws = module.new_HDLSignal(n.c_name + '_ws')
            n.h_wt = module.new_HDLSignal(n.c_name + '_wt')
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
            proc.sync_stmts.append(
                HDLAssign(n.h_wt,
                          HDLAnd(HDLOr(n.h_wt, n.h_ws), HDLNot(n.h_bus['wack']))))
            proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
            stmts.append(proc)
            module.stmts.append(
                HDLAssign(n.h_ws,
                          HDLOr(ibus.wr_req, HDLParen(HDLAnd(n.h_wt, HDLNot(ibus.rd_req))))))
            # Mux for addresses.
            self.gen_adr_mux(root, module, n, ibus)
        else:
            stmts.append(HDLAssign(n.h_bus['adr'],
                                   HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits)))

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
        if root.h_bussplit:
            # Start write transaction if WR is set and neither read nor write transaction
            proc.stmts.append(HDLAssign(n.h_we, bit_0))
            stmts.append(HDLAssign(n.h_we, ibus.wr_req))
            stmts.append(HDLAssign(n.h_bus['wr'], n.h_ws))
        else:
            stmts.append(HDLAssign(n.h_bus['wr'], ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['wack']))

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_bus['rd'], bit_0))
        if root.h_bussplit:
            # Start read transaction if RR is set and neither read nor write transaction
            proc.stmts.append(HDLAssign(n.h_re, bit_0))
            stmts.append(HDLAssign(n.h_re, ibus.rd_req))
            stmts.append(HDLAssign(n.h_bus['rd'], n.h_rs))
        else:
            stmts.append(HDLAssign(n.h_bus['rd'], ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rack']))
