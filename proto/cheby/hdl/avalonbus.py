from cheby.hdltree import (HDLPort,
                           HDLAssign, HDLSync, HDLComb,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLConcat, HDLReplicate,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLParen)
from cheby.hdl.busgen import BusGen
from cheby.hdl.globals import gconfig, dirname
from cheby.hdl.ibus import add_bus
import cheby.parser as parser
import cheby.tree as tree


class AvalonBus(BusGen):
    def __init__(self, name):
        assert name == "avalon-lite-32"

    def add_decode_avalon(self, root, module, ibus):
        """Generate internal signals used by decoder/processes from
        Avalon bus."""
        ibus.rd_req = module.new_HDLSignal('rd_req')  # Read access
        ibus.rd_ack = module.new_HDLSignal('rd_ack')  # Ack for read
        ibus.rd_err = module.new_HDLSignal('rd_err')  # Error for read (not supported)
        ibus.wr_req = module.new_HDLSignal('wr_req')  # Write access
        ibus.wr_ack = module.new_HDLSignal('wr_ack')  # Ack for write
        ibus.wr_dat = module.new_HDLSignal('wr_dat', root.c_word_bits)  # Write data
        ibus.wr_sel = module.new_HDLSignal('wr_sel', root.c_word_bits)  # Write mask
        ibus.wr_err = module.new_HDLSignal('wr_err')  # Error for write (not supported)

        # Waitrequest
        # Set on rd or wr, cleared on ack
        wait = module.new_HDLSignal('wait_int')
        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'],
                       rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(wait, bit_0))
        proc.sync_stmts.append(HDLAssign(
            wait, HDLAnd(HDLOr(wait, HDLParen(HDLOr(root.h_bus['rd'], root.h_bus['wr']))),
                         HDLNot(HDLParen(HDLOr(ibus.rd_ack, ibus.wr_ack))))))
        module.stmts.append(proc)

        # Translate Byte-wise write mask of Avalon bus to bit-wise write mask
        sel = module.new_HDLSignal('sel_int', root.c_word_bits)
        proc = HDLComb()
        proc.sensitivity.extend([root.h_bus['be']])
        for idx in range(root.c_word_bits // tree.BYTE_SIZE):
            proc.stmts.append(
                HDLAssign(
                    HDLSlice(sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                    HDLReplicate(
                        HDLSlice(root.h_bus['be'], idx, None),
                        tree.BYTE_SIZE,
                        True,
                    ),
                )
            )
        module.stmts.append(proc)

        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(ibus.rd_req, bit_0))
        proc.rst_stmts.append(HDLAssign(ibus.wr_req, bit_0))

        if ibus.addr_size > 0:
            addr = module.new_HDLSignal(
                'adr', root.c_addr_bits, lo_idx=root.c_addr_word_bits
            )

            # address: saved on 'read' or 'write' when wait request is not set.
            if_stmt = HDLIfElse(
                HDLEq(
                    HDLAnd(
                        HDLParen(HDLOr(root.h_bus['rd'], root.h_bus['wr'])),
                        HDLNot(wait),
                    ),
                    bit_1,
                )
            )
            if_stmt.then_stmts.append(HDLAssign(addr, root.h_bus['adr']))
            proc.sync_stmts.append(if_stmt)

            ibus.rd_adr = addr
            ibus.wr_adr = addr

        # write mask, write data: saved on 'write' when wait request is not set.
        if_stmt = HDLIfElse(HDLEq(HDLAnd(root.h_bus['wr'], HDLNot(wait)), bit_1))
        if_stmt.then_stmts.append(HDLAssign(ibus.wr_sel, sel))
        if_stmt.then_stmts.append(HDLAssign(ibus.wr_dat, root.h_bus['dati']))
        proc.sync_stmts.append(if_stmt)

        # read request, write request: hold one cycle when wait request is not set.
        proc.sync_stmts.append(
            HDLAssign(ibus.rd_req, HDLAnd(root.h_bus['rd'], HDLNot(wait)))
        )
        proc.sync_stmts.append(
            HDLAssign(ibus.wr_req, HDLAnd(root.h_bus['wr'], HDLNot(wait)))
        )

        module.stmts.append(proc)

        module.stmts.append(HDLAssign(root.h_bus['rack'], ibus.rd_ack))
        module.stmts.append(HDLAssign(root.h_bus['wait'], wait))

    def gen_avalon_bus(self, build_port, addr_bits, lo_addr, data_bits, is_master):
        """Create Avalon interface."""
        inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
        bus = [
            ('adr', build_port("address", addr_bits,
                               lo=lo_addr, dir=inp)),
            ('dato', build_port("readdata", data_bits, dir=out)),
            ('dati', build_port("writedata", data_bits, dir=inp)),
            ('be', build_port("byteenable", data_bits // tree.BYTE_SIZE, dir=inp)),
            ('rd', build_port("read", dir=inp)),
            ('wr', build_port("write", dir=inp)),
            ('rack', build_port("readdatavalid", dir=out)),
            ('wait', build_port("waitrequest", dir=out))]
        return bus

    def expand_bus(self, root, module, ibus):
        """Create Avalon interface."""
        if root.get_extension('x_hdl', 'busgroup'):
            parser.warning(root, "busgroup on '{}' is ignored for avalon-lite".format(
                root.get_path()))
        if root.get_extension('x_hdl', 'bus-error'):
            parser.warning(root, "bus-error on '{}' is ignored for avalon-lite".format(
                root.get_path()))

        bus = [('clk', HDLPort("clk")),
               ('brst', HDLPort("reset"))]
        bus.extend(self.gen_avalon_bus(
            lambda n, sz=None, lo=0, dir='IN':
            HDLPort(n, size=sz, lo_idx=lo, dir=dir) if sz is None or sz > 0 else None,
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, False))
        add_bus(root, module, bus)
        root.h_bussplit = False

        # The reset port Rst is active high, while internally we use an active low reset.
        rstn = module.new_HDLSignal('rst_n')
        module.stmts.append(HDLAssign(rstn, HDLNot(root.h_bus['brst'])))
        root.h_bus['brst'] = rstn

        ibus.addr_size = root.c_addr_bits
        ibus.addr_low = root.c_addr_word_bits
        ibus.data_size = root.c_word_bits
        ibus.clk = root.h_bus['clk']
        ibus.rst = root.h_bus['brst']
        ibus.rd_dat = root.h_bus['dato']
        ibus.wr_dat = root.h_bus['dati']

        ibus.rd_adr = root.h_bus['adr']
        ibus.wr_adr = root.h_bus['adr']

        self.add_decode_avalon(root, module, ibus)

    def gen_bus_slave(self, root, module, prefix, n, opts):
        """Create an interface to a slave (Add declarations)"""
        if opts.busgroup:
            parser.warning(root, "busgroup on '{}' is ignored for avalon".format(
                root.get_path()))
        if opts.bus_error:
            parser.warning(root, "bus-error on '{}' is ignored for avalon".format(
                root.get_path()))

        n.h_busgroup = opts.busgroup
        ports = self.gen_avalon_bus(
            lambda name, sz=None, lo=0, dir='IN':
                 None if sz == 0 else module.add_port(
                    '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                    size=sz, lo_idx=lo, dir=dir),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, True)
        n.h_bus = {}
        for name, p in ports:
            n.h_bus[name] = p
        # Add the comment.  Not that simple as the first port of the bus depends on
        # split or not split, address or no address.
        comment = '\n' + (n.comment or n.description or 'Avalon bus {}'.format(n.name))
        first = 'adr'
        if n.h_bus[first] is None:
            first = 'dato'
        n.h_bus[first].comment = comment
        # Internal signals
        # Request (set by decoding logic)
        n.h_re = module.new_HDLSignal(prefix + 're')
        n.h_we = module.new_HDLSignal(prefix + 'we')
        # Request signals
        n.h_rr = module.new_HDLSignal(prefix + 'rr')
        n.h_wr = module.new_HDLSignal(prefix + 'wr')
        if root.h_bussplit:
            # Read waiting for ack.
            n.h_rt = module.new_HDLSignal(prefix + 'rt')
            # Pending signals
            n.h_wp = module.new_HDLSignal(prefix + 'wp')
            n.h_rp = module.new_HDLSignal(prefix + 'rp')

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
            res = HDLConcat(res,
                            HDLReplicate(bit_0, root.c_addr_word_bits, False))
        return res

    def wire_bus_slave(self, root, module, n, ibus):
        stmts = module.stmts
        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(n.h_rr, bit_0))
        proc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
        if root.h_bussplit:
            # Write state machine (note: write has priority over read)
            #    /----> IDLE
            #    |   <--/   \--->
            #    WRITE         PENDING
            #        <----------/
            # IDLE -> WRITE:
            #   When WE is set and the read FSM is idle (RR=0 and RT=0)
            # IDLE -> PENDING
            #   When WE is set and the read FSM is in request or waiting
            # PENDING -> WRITE   (PENDING state is wp)
            #   When the FSM is idle
            # WRITE -> IDLE      (WRITE state is wr)
            #   When waitrequest = 0
            # WR is set on WE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_wr,
                          HDLOr(HDLParen(HDLAnd(n.h_wr, n.h_bus['wait'])),
                                HDLParen(HDLAnd(HDLParen(HDLOr(n.h_we, n.h_wp)),
                                                HDLNot(HDLParen(HDLOr(n.h_rr, n.h_rt))))))))
            # WP: write request pending.  Set on WR when RT is set.
            proc.rst_stmts.append(HDLAssign(n.h_wp, bit_0))
            proc.sync_stmts.append(
                HDLAssign(n.h_wp,
                          HDLAnd(HDLParen(HDLOr(n.h_wp, n.h_we)), HDLParen(HDLOr(n.h_rr, n.h_rt)))))
            # Read state machine
            #          /-------+----> IDLE
            #         |        |  <---/   \--->
            #       WAIT  <--- READ          PENDING
            #                      <----------/
            # IDLE -> READ
            #   When RE and the write FSM is idle (WE=0, WR=0 and WP=0)
            # IDLE -> PENDING
            #   When RE and the write FSM is not idle
            # PENDING -> READ  (PENDING state is wp)
            #   When the write FSM is idle
            # READ -> IDLE     (READ state is rr)
            #   When readdatavalid=1
            # READ -> WAIT
            #   When readdatavalid=0 and waitrequest=0
            # WAIT -> IDLE     (WAIT state is rt)
            #   When readdatavalid=1
            # RR is set by RE and cleared by ACK.
            proc.sync_stmts.append(
                HDLAssign(n.h_rr,
                        HDLOr(HDLParen(HDLAnd(HDLParen(HDLOr(n.h_re, n.h_rp)),
                                              HDLNot(HDLOr(n.h_we, HDLOr(n.h_wr, n.h_wp))))),
                              HDLParen(HDLAnd(n.h_rr, HDLAnd(HDLNot(n.h_bus['rack']), n.h_bus['wait']))))))
            # RP is set by RE if WE or WR or WP.
            proc.rst_stmts.append(HDLAssign(n.h_rp, bit_0))
            proc.sync_stmts.append(
                HDLAssign(n.h_rp,
                          HDLAnd(HDLParen(HDLOr(n.h_re, n.h_rp)),
                                 HDLParen(HDLOr(n.h_we, HDLOr(n.h_wr, n.h_wp))))))
            # RT is set by RR and cleared by ACK
            proc.rst_stmts.append(HDLAssign(n.h_rt, bit_0))
            proc.sync_stmts.append(
                HDLAssign(n.h_rt,
                          HDLOr(HDLParen(HDLAnd(n.h_rr, HDLNot(HDLOr(n.h_bus['rack'], n.h_bus['wait'])))),
                                HDLParen(HDLAnd(n.h_rt, HDLNot(n.h_bus['rack']))))))
        else:
            # RR is set by RE and maintained by WAIT.
            proc.sync_stmts.append(
                HDLAssign(n.h_rr, HDLOr(HDLParen(HDLAnd(n.h_rr, n.h_bus['wait'])), n.h_re)))
            # WT is set by WE and maintained by WAIT
            proc.sync_stmts.append(
                HDLAssign(n.h_wr, HDLOr(HDLParen(HDLAnd(n.h_wr, n.h_bus['wait'])), n.h_we)))
        stmts.append(proc)
        if n.h_bus['adr'] is not None:
            if root.h_bussplit:
                # WB adr mux
                proc = HDLComb()
                proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, n.h_wr])
                if_stmt = HDLIfElse(HDLEq(n.h_wr, bit_1))
                if_stmt.then_stmts.append(HDLAssign(n.h_bus['adr'],
                                                    self.slice_addr(ibus.wr_adr, root, n)))
                if_stmt.else_stmts.append(HDLAssign(n.h_bus['adr'],
                                                    self.slice_addr(ibus.rd_adr, root, n)))
                proc.stmts.append(if_stmt)
                stmts.append(proc)
            else:
                stmts.append(HDLAssign(n.h_bus['adr'],
                                       self.slice_addr(ibus.rd_adr, root, n)))

        if ibus.wr_sel is not None:
            # Translate bit-wise write mask of ibus to Byte-wise write mask of Avalon bus
            proc = HDLComb()
            proc.sensitivity.extend([ibus.wr_sel])
            proc.stmts.append(
                HDLAssign(
                    n.h_bus['be'],
                    HDLReplicate(bit_0, root.c_word_bits // tree.BYTE_SIZE),
                )
            )
            for idx in range(root.c_word_bits // tree.BYTE_SIZE):
                if_stmt = HDLIfElse(
                HDLNot(
                    HDLEq(
                        HDLSlice(ibus.wr_sel, idx * tree.BYTE_SIZE, tree.BYTE_SIZE),
                        HDLReplicate(bit_0, tree.BYTE_SIZE, False),
                        )
                    )
                )
                if_stmt.then_stmts.append(
                    HDLAssign(HDLSlice(n.h_bus['be'], idx, None), bit_1)
                )
                if_stmt.else_stmts = None
                proc.stmts.append(if_stmt)
            module.stmts.append(proc)
        else:
            stmts.append(
                HDLAssign(
                    n.h_bus['be'],
                    HDLReplicate(bit_1, root.c_word_bits // tree.BYTE_SIZE),
                )
            )

        stmts.append(HDLAssign(n.h_bus['wr'], n.h_wr))
        stmts.append(HDLAssign(n.h_bus['rd'], n.h_rr))
        stmts.append(HDLAssign(n.h_bus['dati'], ibus.wr_dat))

    def write_bus_slave(self, root, stmts, n, proc, ibus):
        proc.stmts.append(HDLAssign(n.h_we, bit_0))
        stmts.append(HDLAssign(n.h_we, ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, HDLAnd(n.h_wr, HDLNot(n.h_bus['wait']))))

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_re, bit_0))
        stmts.append(HDLAssign(n.h_re, ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        # Propagate ack provided it is a write transaction and only for one cycle.
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rack']))
