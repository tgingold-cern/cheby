from cheby.hdltree import (HDLPort,
                           HDLComment,
                           HDLAssign, HDLSync, HDLComb,
                           HDLIfElse,
                           bit_1, bit_0,
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

    def add_in_progress_reg(self, root, module, stb, ack, name):
        # The ack is not combinational, thus the strobe may stay longer
        # than one cycle.
        # Add an in progress 'avmm_Xip' signal that is set on a strobe
        # and cleared on the ack.
        xip = module.new_HDLSignal(name)
        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'],
                       rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(xip, bit_0))
        proc.sync_stmts.append(HDLAssign(
            xip, HDLAnd(HDLOr(xip, stb), HDLNot(ack))))
        module.stmts.append(proc)
        return HDLAnd(stb, HDLNot(xip))

    def add_decode_avalon(self, root, module, ibus):
        """Generate internal signals used by decoder/processes from
        Avalon bus."""
        ibus.rd_ack = module.new_HDLSignal('rd_ack_int')    # Ack for read
        ibus.wr_ack = module.new_HDLSignal('wr_ack_int')    # Ack for write
        ibus.rd_req = module.new_HDLSignal('rd_req_int')    # Read access
        ibus.wr_req = module.new_HDLSignal('wr_req_int')    # Write access

        # Read access
        # Avalon 'read' is a state, while ibus 'rd' is a pulse
        rd_req = root.h_bus['rd']
        rd_req = self.add_in_progress_reg(root, module, rd_req,
                                          ibus.rd_ack, 'rd_rqip_int')
        module.stmts.append(HDLAssign(ibus.rd_req, rd_req))
        module.stmts.append(HDLComment(None))

        # Write access
        # Avalon 'write' is a state, while ibus 'wr' is a pulse
        wr_req = root.h_bus['wr']
        wr_req = self.add_in_progress_reg(root, module, wr_req,
                                          ibus.wr_ack, 'wr_rqip_int')
        module.stmts.append(HDLAssign(ibus.wr_req, wr_req))
        module.stmts.append(HDLComment(None))

        # Waitrequest
        # Set on rd or wr, cleared on ack
        wreq_r = module.new_HDLSignal('wreq_int_r')
        wreq = module.new_HDLSignal('wreq_int')
        module.stmts.append(HDLAssign(wreq,
            HDLAnd(wreq_r, HDLNot(HDLParen(HDLOr(ibus.rd_ack, ibus.wr_ack))))))
        proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'],
                       rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(wreq_r, bit_0))
        proc.sync_stmts.append(HDLAssign(
            wreq_r, HDLOr(HDLParen(HDLOr(root.h_bus['rd'], root.h_bus['wr'])), wreq)))
        module.stmts.append(proc)

        module.stmts.append(HDLAssign(root.h_bus['rack'], ibus.rd_ack))
        module.stmts.append(HDLAssign(root.h_bus['wreq'], wreq))

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
             ('wreq', build_port("waitrequest", dir=out))]
        return bus

    def expand_bus(self, root, module, ibus):
        """Create Avalon interface."""
        if root.get_extension('x_hdl', 'busgroup'):
            parser.warning(root, "busgroup on '{}' is ignored for avalon-lite".format(
                root.get_path()))
        bus = [('clk', HDLPort("clk")),
               ('brst', HDLPort("reset"))]
        bus.extend(self.gen_avalon_bus(
            lambda n, sz=None, lo=0, dir='IN':
            HDLPort(n, size=sz, lo_idx=lo, dir=dir) if sz is None or sz > 0 else None,
            root.c_addr_bits, root.c_addr_word_bits, root.c_word_bits, False))
        add_bus(root, module, bus)

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
        ports = self.gen_avalon_bus(
            lambda name, sz=None, lo=0, dir='IN':
                 None if sz == 0 else module.add_port(
                    '{}_{}_{}'.format(n.c_name, name, dirname[dir]),
                    size=sz, lo_idx=lo, dir=dir),
            n.c_addr_bits, root.c_addr_word_bits, root.c_word_bits,
            self.split, self.buserr, True)
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

        if ibus.rd_adr != ibus.wr_adr:
            # Asymetric pipelining: add a mux to select the address.
            n.h_ws = module.new_HDLSignal(n.c_name + '_ws')
            n.h_wt = module.new_HDLSignal(n.c_name + '_wt')
            proc = HDLSync(root.h_bus['clk'], root.h_bus['brst'], rst_sync=gconfig.rst_sync)
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
        stmts.append(HDLAssign(n.h_bus['wr'], ibus.wr_req))
        stmts.append(HDLAssign(ibus.wr_ack, n.h_bus['wack']))

    def read_bus_slave(self, root, stmts, n, proc, ibus, rd_data):
        proc.stmts.append(HDLAssign(n.h_bus['rd'], bit_0))
        stmts.append(HDLAssign(n.h_bus['rd'], ibus.rd_req))
        stmts.append(HDLAssign(rd_data, n.h_bus['dato']))
        stmts.append(HDLAssign(ibus.rd_ack, n.h_bus['rack']))
