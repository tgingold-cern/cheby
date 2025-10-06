from cheby.hdltree import (
    HDLPackage,
    HDLInterface,
    HDLInterfaceSelect,
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
    HDLParen,
    HDLPort,
    HDLNode,
)
from cheby.hdl.busgen import BusGen
import cheby.tree as tree
from cheby.hdl.globals import gconfig, dirname, libname
from cheby.hdl.busparams import BusOptions
from typing import Dict

class WBBus(BusGen):
    # Package wishbone_pkg that contains the wishbone interface
    wb_pkg = None
    wb_itf = None
    wb_ports = None

    def __init__(self, name, root, module):
        super().__init__(root, module)
        assert name.startswith('wb-')

    def add_in_progress_reg(self, stb, ack, pfx):
        # The ack is not combinational, thus the strobe may stay longer
        # than one cycle.
        # Add an in progress 'wb_Xip' signal that is set on a strobe
        # and cleared on the ack.
        wb_xip = self.module.new_HDLSignal('wb_{}ip'.format(pfx))
        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'],
                       rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(wb_xip, bit_0))
        proc.sync_stmts.append(HDLAssign(
            wb_xip, HDLAnd(HDLOr(wb_xip, HDLParen(stb)), HDLNot(ack))))
        self.module.stmts.append(proc)
        return HDLAnd(stb, HDLNot(wb_xip))

    def add_decode_wb(self, ibus, opts):
        "Generate internal signals used by decoder/processes from WB bus."
        ibus.addr_size = self.root.c_addr_bits
        ibus.addr_low = self.root.c_addr_word_bits
        ibus.data_size = self.root.c_word_bits
        ibus.clk = self.root.h_bus['clk']
        ibus.rst = self.root.h_bus['brst']
        ibus.rd_dat = self.root.h_bus['dato']
        ibus.wr_dat = self.root.h_bus['dati']

        # Translate Byte-wise write mask of Wishbone bus to bit-wise write mask of ibus
        ibus.wr_sel = self.module.new_HDLSignal('wr_sel', self.root.c_word_bits)
        proc = HDLComb()
        proc.sensitivity.extend([self.root.h_bus['sel']])
        for idx in range(self.root.c_word_bits // tree.BYTE_SIZE):
            proc.stmts.append(
                HDLAssign(
                    HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                    HDLReplicate(
                        HDLSlice(self.root.h_bus['sel'], idx, None),
                        tree.BYTE_SIZE,
                        True,
                    ),
                )
            )
        self.module.stmts.append(proc)

        if ibus.addr_size > 0:
            if opts.busgroup:
                addr = self.module.new_HDLSignal('adr_int', ibus.addr_size, lo_idx=ibus.addr_low)
                self.module.stmts.append(
                    HDLAssign(addr, opts.resize_addr_in(self.root.h_bus['adr'], ibus)))
            else:
                addr = self.root.h_bus['adr']
            ibus.rd_adr = addr
            ibus.wr_adr = addr
        ibus.rd_req = self.module.new_HDLSignal('rd_req_int')    # Read access
        ibus.wr_req = self.module.new_HDLSignal('wr_req_int')    # Write access
        ibus.rd_ack = self.module.new_HDLSignal('rd_ack_int')    # Ack for read
        ibus.rd_err = self.module.new_HDLSignal('rd_err_int')    # Error for read
        ibus.wr_ack = self.module.new_HDLSignal('wr_ack_int')    # Ack for write
        ibus.wr_err = self.module.new_HDLSignal('wr_err_int')    # Error for write
        # Internal signals for wb.
        wb_en = self.module.new_HDLSignal('wb_en')
        ack_int = self.module.new_HDLSignal('ack_int')  # Ack
        err_int = self.module.new_HDLSignal('err_int')  # Err
        self.module.stmts.append(
            HDLAssign(wb_en, HDLAnd(self.root.h_bus['cyc'], self.root.h_bus['stb'])))
        self.module.stmts.append(HDLComment(None))

        # Read access
        rd_req = HDLAnd(wb_en, HDLNot(self.root.h_bus['we']))
        rd_req = self.add_in_progress_reg(rd_req,
                                          ibus.rd_ack, 'r')
        self.module.stmts.append(HDLAssign(ibus.rd_req, rd_req))
        self.module.stmts.append(HDLComment(None))

        # Write access
        wr_req = HDLAnd(wb_en, self.root.h_bus['we'])
        wr_req = self.add_in_progress_reg(wr_req,
                                          ibus.wr_ack, 'w')
        self.module.stmts.append(HDLAssign(ibus.wr_req, wr_req))
        self.module.stmts.append(HDLComment(None))

        if opts.bus_error:
            # Acknowledge or Error
            proc = HDLComb()
            proc.sensitivity.extend([ibus.rd_ack, ibus.wr_ack, ack_int, ibus.rd_err, ibus.wr_err, err_int])

            proc.stmts.append(HDLAssign(ack_int, HDLOr(ibus.rd_ack, ibus.wr_ack)))
            proc.stmts.append(HDLAssign(err_int, HDLOr(ibus.rd_err, ibus.wr_err)))
            ack_err = HDLIfElse(HDLEq(err_int, bit_0))
            ack_err.then_stmts.append(HDLAssign(self.root.h_bus['ack'], ack_int))
            ack_err.then_stmts.append(HDLAssign(self.root.h_bus['err'], bit_0))
            ack_err.else_stmts.append(HDLAssign(self.root.h_bus['ack'], bit_0))
            ack_err.else_stmts.append(HDLAssign(self.root.h_bus['err'], ack_int))
            proc.stmts.append(ack_err)

            self.module.stmts.append(proc)
        else:
            # Acknowledge
            self.module.stmts.append(HDLAssign(ack_int, HDLOr(ibus.rd_ack, ibus.wr_ack)))
            self.module.stmts.append(HDLAssign(self.root.h_bus['ack'], ack_int))

        # Stall
        self.module.stmts.append(
            HDLAssign(self.root.h_bus['stall'], HDLAnd(HDLNot(ack_int), wb_en)))

        # No retry
        self.module.stmts.append(HDLAssign(self.root.h_bus['rty'], bit_0))

        if not opts.bus_error:
            # No error
            # (maintain assignment order of original implementation (before
            #  adding the bus error feature)
            self.module.stmts.append(HDLAssign(self.root.h_bus['err'], bit_0))


    def gen_wishbone_bus(self, build_port, addr_bits, lo_addr,
                         data_bits, is_master) -> Dict[str, HDLNode]:
        # FIXME: 'dat' is used both as an input and as an output.
        #  This is not a problem in general as a suffix is appended,
        #  except for system verilog interfaces...
        res = {}
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')

        res['brst'] = build_port('rst_n', None, dir='EXT')
        res['clk'] = build_port('clk', None, dir='EXT')

        res['cyc'] = build_port('cyc', None, dir=inp)
        res['stb'] = build_port('stb', None, dir=inp)
        if addr_bits > 0:
            res['adr'] = build_port('adr', addr_bits, lo_idx=lo_addr, dir=inp)
        else:
            res['adr'] = None
        res['sel'] = build_port('sel', data_bits // tree.BYTE_SIZE, dir=inp)
        res['we'] = build_port('we', None, dir=inp)
        res['dati'] = build_port('dat', data_bits, dir=inp)

        res['ack'] = build_port('ack', None, dir=out)
        res['err'] = build_port('err', None, dir=out)
        res['rty'] = build_port('rty', None, dir=out)
        res['stall'] = build_port('stall', None, dir=out)
        res['dato'] = build_port('dat', data_bits, dir=out)
        return res

    def gen_wishbone(self, ports, name, addr_bits, lo_addr,
                     data_bits, comment, is_master, is_group, libname = libname) -> Dict[str, HDLPort]:
        assert((comment is None) or isinstance(comment, str))
        if is_group:
            if WBBus.wb_pkg is None:
                self.gen_wishbone_pkg()
                self.module.deps.append((libname, 'wishbone_pkg'))
            # Add the interface modport to the ports
            port = ports.add_modport(name, WBBus.wb_itf, is_master)
            port.comment = comment
            res = {}
            # Fill res
            for pname, sig in WBBus.wb_ports.items():
                res[pname] = HDLInterfaceSelect(port, sig)
            if data_bits < 32:
                res['dato'] = HDLSlice(res['dato'], 0, data_bits)
                res['dati'] = HDLSlice(res['dati'], 0, data_bits)
                res['sel'] = HDLSlice(res['sel'], 0, data_bits // tree.BYTE_SIZE)
            return res
        else:
            # Not an interface (ie not a group)
            # For 'EXT' ports (external ports), do not append prefix and use 'IN' direction.
            # For masters, do not add 'EXT' ports.
            res = self.gen_wishbone_bus(
                lambda n, sz, lo_idx=0, dir='IN': ports.add_port(
                    '{}_{}_{}'.format(name, n, dirname[dir]) if dir != 'EXT' else '{}_i'.format(n),
                    size=sz, lo_idx=lo_idx,
                    dir=dir if dir != 'EXT' else 'IN') if not (dir == 'EXT' and is_master) else None,
                addr_bits, lo_addr, data_bits, is_master)
            res['cyc'].comment = comment
            return res

    def gen_wishbone_pkg(self):
        """Create the wishbone_pkg package, so that interface can be
        referenced"""
        assert WBBus.wb_pkg is None
        WBBus.wb_pkg = HDLPackage('wishbone_pkg')
        WBBus.wb_itf = HDLInterface('t_wishbone')
        WBBus.wb_pkg.decls.append(WBBus.wb_itf)
        WBBus.wb_ports = self.gen_wishbone_bus(
            lambda n, sz, lo_idx=0, dir='IN':
            WBBus.wb_itf.add_port(n, size=sz, lo_idx=lo_idx, dir=dir),
            32, 0, 32, True)
        return

    def expand_bus(self, ibus, lib_name):
        """Create wishbone interface for the design."""
        self.root.h_bus = {}
        opts = BusOptions(self.root, self.root)

        self.root.h_bus.update(self.gen_wishbone(
            self.module, 'wb', self.root.c_addr_bits, self.root.c_addr_word_bits,
            self.root.c_word_bits, None, False, opts.busgroup, libname=lib_name))
        self.root.h_bussplit = False

        # Bus access
        self.module.stmts.append(HDLComment('WB decode signals'))
        self.add_decode_wb(ibus, opts)

    def gen_bus_slave(self, prefix, n, opts):
        # Create the bus for a submap or a memory
        comment = '\n' + (n.comment or 'WB bus {}'.format(n.name))
        n.h_busgroup = opts.busgroup
        n.h_bus_opts = opts
        n.h_bus = self.gen_wishbone(
            self.module, n.c_name,
            n.c_addr_bits, self.root.c_addr_word_bits, self.root.c_word_bits,
            comment, True, opts.busgroup)
        # Internal signals
        # Enable (set by decoding logic)
        n.h_re = self.module.new_HDLSignal(prefix + 're')
        n.h_we = self.module.new_HDLSignal(prefix + 'we')
        # Transaction in progress (write, read, any)
        n.h_wt = self.module.new_HDLSignal(prefix + 'wt')
        n.h_rt = self.module.new_HDLSignal(prefix + 'rt')
        n.h_tr = self.module.new_HDLSignal(prefix + 'tr')
        # Ack
        n.h_wack = self.module.new_HDLSignal(prefix + 'wack')
        n.h_rack = self.module.new_HDLSignal(prefix + 'rack')
        if self.root.h_bussplit:
            # Request signals
            n.h_wr = self.module.new_HDLSignal(prefix + 'wr')
            n.h_rr = self.module.new_HDLSignal(prefix + 'rr')

    def wire_bus_slave(self, n, ibus):
        stmts = self.module.stmts
        stmts.append(HDLAssign(n.h_tr, HDLOr(n.h_wt, n.h_rt)))
        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
        proc.rst_stmts.append(HDLAssign(n.h_wt, bit_0))
        if self.root.h_bussplit:
            # WR is set on WE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_wr,
                          HDLAnd(HDLOr(n.h_wr, n.h_we), HDLNot(n.h_wack))))
            proc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
            # WT is set on WR & ~TR and cleared by ACK
            proc.sync_stmts.append(
                HDLAssign(n.h_wt,
                          HDLAnd(HDLOr(n.h_wt, HDLParen(HDLAnd(n.h_wr, HDLNot(n.h_tr)))),
                                 HDLNot(n.h_wack))))
            proc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
            # RR is set by RE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_rr,
                          HDLAnd(HDLOr(n.h_rr, n.h_re), HDLNot(n.h_rack))))
            # RT is set by RR and cleared by ACK
            proc.sync_stmts.append(
                HDLAssign(n.h_rt,
                          HDLAnd(HDLOr(n.h_rt, HDLParen(HDLAnd(n.h_rr,
                                                               HDLNot(HDLOr(n.h_wr, n.h_tr))))),
                                 HDLNot(n.h_rack))))
        else:
            # RT is set by RE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_rt,
                          HDLAnd(HDLOr(n.h_rt, n.h_re), HDLNot(n.h_rack))))
            # WT is set by WE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_wt,
                          HDLAnd(HDLOr(n.h_wt, n.h_we), HDLNot(n.h_wack))))
        stmts.append(proc)
        stmts.append(HDLAssign(n.h_bus['cyc'], n.h_tr))
        stmts.append(HDLAssign(n.h_bus['stb'], n.h_tr))
        stmts.append(HDLAssign(n.h_wack, HDLAnd(n.h_bus['ack'], n.h_wt)))
        stmts.append(HDLAssign(n.h_rack, HDLAnd(n.h_bus['ack'], n.h_rt)))
        if n.h_bus['adr'] is not None:
            if self.root.h_bussplit:
                # WB adr mux
                proc = HDLComb()
                proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, n.h_wt])
                if_stmt = HDLIfElse(HDLEq(n.h_wt, bit_1))
                if_stmt.then_stmts.append(
                    HDLAssign(n.h_bus['adr'],
                              n.h_bus_opts.resize_addr_out_full(
                                  ibus.wr_adr, ibus)))
                if_stmt.else_stmts.append(
                    HDLAssign(n.h_bus['adr'],
                              n.h_bus_opts.resize_addr_out_full(
                                  ibus.rd_adr, ibus)))
                proc.stmts.append(if_stmt)
                stmts.append(proc)
            else:
                stmts.append(
                    HDLAssign(n.h_bus['adr'],
                              n.h_bus_opts.resize_addr_out_full(
                                  ibus.rd_adr, ibus)))

        if ibus.wr_sel is not None:
            # Translate bit-wise write mask of internal bus to Byte-wise write mask of
            # Wishbone bus
            proc = HDLComb()
            proc.sensitivity.extend([ibus.wr_sel])
            proc.stmts.append(
                HDLAssign(
                    n.h_bus['sel'],
                    HDLReplicate(bit_0, self.root.c_word_bits // tree.BYTE_SIZE),
                )
            )
            for idx in range(self.root.c_word_bits // tree.BYTE_SIZE):
                proc_if = HDLIfElse(
                    HDLNot(
                        HDLEq(
                            HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                            HDLReplicate(bit_0, tree.BYTE_SIZE, False),
                        )
                    )
                )
                proc_if.then_stmts.append(
                    HDLAssign(HDLSlice(n.h_bus['sel'], idx, None), bit_1)
                )
                proc_if.else_stmts = None
                proc.stmts.append(proc_if)
            stmts.append(proc)
        else:
            stmts.append(
                HDLAssign(
                    n.h_bus['sel'],
                    HDLReplicate(bit_1, self.root.c_word_bits // tree.BYTE_SIZE),
                )
            )

        stmts.append(HDLAssign(n.h_bus['we'], n.h_wt))
        stmts.append(HDLAssign(n.h_bus['dati'], ibus.wr_dat))

    def write_bus_slave(self, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_we, bit_0))
        stmts.append(HDLAssign(n.h_we, ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_wack))

    def read_bus_slave(self, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_re, bit_0))
        stmts.append(HDLAssign(n.h_re, ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        # Propagate ack provided it is a write transaction and only for one cycle.
        stmts.append(HDLAssign(ibus.rd_ack, n.h_rack))
