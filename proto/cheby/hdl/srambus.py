from cheby.hdltree import (HDLAssign, HDLSync, HDLComb,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice)
from cheby.hdl.busgen import BusGen
from cheby.hdl.globals import gconfig
import cheby.tree as tree


class SRAMBus(BusGen):
    def __init__(self, name):
        assert name == 'sram'

    def gen_bus_slave(self, root, module, prefix, n, opts):
        n.h_bus = {}
        n.h_bus['adr'] = root.h_ports.add_port(
            prefix + 'addr_o', n.c_addr_bits,
            lo_idx=root.c_addr_word_bits, dir='OUT')
        n.h_bus['adr'].comment = '\n' + (n.comment or 'SRAM bus {}'.format(n.name))

        if n.c_bus_access in ('ro', 'rw'):
            n.h_bus['dati'] = root.h_ports.add_port(
                prefix + 'data_i', n.c_width, dir='IN')
            # Internal signal
            n.h_re = module.new_HDLSignal(prefix + 're')

        if n.c_bus_access in ('wo', 'rw'):
            n.h_bus['dato'] = root.h_ports.add_port(
                prefix + 'data_o', n.c_width, dir='OUT')
            n.h_bus['wr'] = root.h_ports.add_port(
                prefix + 'wr_o', dir='OUT')

        # Internal signals
        n.h_rack = module.new_HDLSignal(prefix + 'rack')
        n.h_re = module.new_HDLSignal(prefix + 're')

    def gen_slice(self, root, dat, wd):
        if wd < root.c_word_size * tree.BYTE_SIZE:
            dat = HDLSlice(dat, 0, wd)
        return dat

    def wire_bus_slave(self, root, module, n, ibus):
        stmts = module.stmts
        if n.c_bus_access in ('ro', 'rw'):
            # Acknowledge: delay rack by one cycle.
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
            proc.rst_stmts.append(HDLAssign(n.h_rack, bit_0))
            proc.sync_stmts.append(HDLAssign(n.h_rack, HDLAnd(n.h_re, HDLNot(n.h_rack))))
            stmts.append(proc)
        if n.c_bus_access in ('wo', 'rw'):
            stmts.append(HDLAssign(n.h_bus['dato'], self.gen_slice(root, ibus.wr_dat, n.c_width)))
        if n.c_bus_access == 'rw' and ibus.rd_adr != ibus.wr_adr:
            # Asymetric pipelining: add a mux to select the address.
            n.h_wp = module.new_HDLSignal(n.c_name + '_wp')
            n.h_we = module.new_HDLSignal(n.c_name + '_we')
            proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=gconfig.rst_sync)
            proc.sync_stmts.append(
                HDLAssign(n.h_wp,
                          HDLAnd(HDLOr(ibus.wr_req, n.h_wp), ibus.rd_req)))
            proc.rst_stmts.append(HDLAssign(n.h_wp, bit_0))
            module.stmts.append(proc)
            # Write enable.
            stmts.append(HDLAssign(n.h_we,
                                   HDLAnd(HDLOr(ibus.wr_req, n.h_wp), HDLNot(ibus.rd_req))))
            # Mux for addresses.
            proc = HDLComb()
            proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, n.h_re])
            if_stmt = HDLIfElse(HDLEq(n.h_re, bit_1))
            if_stmt.then_stmts.append(
                HDLAssign(n.h_bus['adr'],
                          HDLSlice(ibus.rd_adr, root.c_addr_word_bits, n.c_addr_bits)))
            if_stmt.else_stmts.append(
                HDLAssign(n.h_bus['adr'],
                          HDLSlice(ibus.wr_adr, root.c_addr_word_bits, n.c_addr_bits)))
            proc.stmts.append(if_stmt)
            module.stmts.append(proc)
        else:
            if n.c_bus_access in ('ro', 'rw'):
                adr = ibus.rd_adr
            else:
                assert n.c_bus_access == 'wo'
                adr = ibus.wr_adr
            stmts.append(HDLAssign(n.h_bus['adr'],
                                   HDLSlice(adr, root.c_addr_word_bits, n.c_addr_bits)))

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        if n.c_bus_access in ('wo', 'rw'):
            # Immediately ack WR.
            proc.stmts.append(HDLAssign(n.h_bus['wr'], bit_0))
            if ibus.rd_adr != ibus.wr_adr:
                wr = n.h_we
            else:
                wr = ibus.wr_req
            stmts.append(HDLAssign(n.h_bus['wr'], wr))
            stmts.append(HDLAssign(ibus.wr_ack, wr))
            proc.sensitivity.append(wr)

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        if n.c_bus_access in ('ro', 'rw'):
            stmts.append(HDLAssign(self.gen_slice(root, rd_data, n.c_width), n.h_bus['dati']))
            stmts.append(HDLAssign(ibus.rd_ack, n.h_rack))
            proc.stmts.append(HDLAssign(n.h_re, bit_0))
            stmts.append(HDLAssign(n.h_re, ibus.rd_req))
            proc.sensitivity.extend([ibus.rd_req, n.h_bus['dati'], n.h_rack])
