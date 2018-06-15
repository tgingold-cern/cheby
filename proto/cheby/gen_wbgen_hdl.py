"""Create HDL from the tree"""

import cheby.tree as tree
import cheby.hdltree as hdltree
from cheby.hdltree import (HDLPort, HDLSignal, HDLParam,
                           HDLGenIf, HDLAssign, HDLInstance, HDLComb,
                           HDLComment, HDLConst, HDLNumber,
                           HDLSlice, HDLIndex, Slice_or_Index,
                           HDLIfElse,
                           HDLAnd, HDLEq, HDLNot, HDLParen,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLReplicate, HDLBool, bit_0, bit_1, bit_x)
import cheby.gen_hdl
import cheby.layout
from cheby.layout import ilog2

mode_suffix_map = {'IN': '_i', 'OUT': '_o'}

def get_wbgen(n, name, default=None):
    return n.get_extension('x_wbgen', name, default)

def get_hdl_prefix(n):
    return get_wbgen(n, 'hdl_prefix', n.name.lower() if n.name is not None else None)

def is_wbgen_fifo(n):
    return get_wbgen(n, 'kind', None) == 'fifo'

def is_wbgen_fifocs(n):
    return isinstance(n, tree.Reg) and get_wbgen(n, 'kind', None) == 'fifocs'

def is_wbgen_fiforeg(n):
    return isinstance(n, tree.Reg) and is_wbgen_fifo(n._parent)

def is_wbgen_ram(n):
    return get_wbgen(n, 'kind', None) == 'ram'

def is_wbgen_irq(n):
    return get_wbgen(n, 'kind', None) == 'irq'

def is_wbgen_irqreg(n):
    return isinstance(n, tree.Reg) and is_wbgen_irq(n._parent)


def expand_field_sel(prefix, field):
    if field.hi is None or get_wbgen(field, 'type') in ['BIT', 'MONOSTABLE']:
        return HDLIndex(prefix, field.lo)
    else:
        return HDLSlice(prefix, field.lo, field.hi - field.lo + 1)


def expand_ack(stmts, isig, ack_len):
    stmts.append(HDLAssign(HDLIndex(isig['ack'], ack_len - 1), bit_1))
    stmts.append(HDLAssign(isig['ackprg'], bit_1))


def expand_ack0(stmts, isig):
    """Like expand_ack, but in reverse order..."""
    stmts.append(HDLAssign(isig['ackprg'], bit_1))
    stmts.append(HDLAssign(HDLIndex(isig['ack'], 0), bit_1))


def expand_ack_default(choices, isig):
    cdef = HDLChoiceDefault()
    choices.append(cdef)
    cdef.stmts.append(HDLComment(
        "prevent the slave from hanging the bus on invalid address"))
    expand_ack0(cdef.stmts, isig)


class Code(object):
    def __init__(self):
        self.ports = []
        self.signals = []
        self.rst_code = []
        self.write_code = []
        self.read_code = []
        self.inack_code = []
        self.acked_code = []
        self.asgn_code = []
        self.ack_len = 1


def gen_async_pulse(clk, rst, out, inp, sync0, sync1, sync2):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(out, bit_0))
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.rst_stmts.append(HDLAssign(sync2, bit_0))
    res.sync_stmts.append(HDLAssign(sync0, inp))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    res.sync_stmts.append(HDLAssign(sync2, sync1))
    res.sync_stmts.append(HDLAssign(out,
                                    HDLAnd(sync2, HDLParen(HDLNot(sync1)))))
    return res

def gen_sync_pulse(clk, rst, out, inp, dly):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(dly, bit_0))
    res.rst_stmts.append(HDLAssign(out, bit_0))
    res.sync_stmts.append(HDLAssign(dly, inp))
    res.sync_stmts.append(HDLAssign(out, HDLAnd(inp, HDLParen(HDLNot(dly)))))
    return res


def gen_async_out(clk, rst, out, inp, sync0, sync1):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(out, bit_0))
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.sync_stmts.append(HDLAssign(sync0, inp))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    res.sync_stmts.append(HDLAssign(out, sync1))
    return res


def gen_async_inp(clk, rst, inp, sync0, sync1):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.sync_stmts.append(HDLAssign(sync0, inp))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    return res


def gen_async_lwb(clk, rst, port, isig, lwb, sync0, sync1, sync2):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.rst_stmts.append(HDLAssign(sync2, bit_0))
    res.rst_stmts.append(HDLAssign(isig, HDLConst(0, isig.size)))
    res.sync_stmts.append(HDLAssign(sync0, lwb))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    res.sync_stmts.append(HDLAssign(sync2, sync1))
    s = HDLIfElse(HDLParen(HDLAnd(HDLParen(HDLEq(sync1, bit_1)),
                                  HDLParen(HDLEq(sync2, bit_0)))))
    s.then_stmts.append(HDLAssign(isig, port))
    s.else_stmts = None
    res.sync_stmts.append(s)
    return res


def gen_async_swb(clk, rst, port, isig, swb, sync0, sync1, sync2):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.rst_stmts.append(HDLAssign(sync2, bit_0))
    res.rst_stmts.append(HDLAssign(isig, HDLConst(0, isig.size)))
    res.sync_stmts.append(HDLAssign(sync0, swb))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    res.sync_stmts.append(HDLAssign(sync2, sync1))
    s = HDLIfElse(HDLParen(HDLAnd(HDLParen(HDLEq(sync2, bit_0)),
                                  HDLParen(HDLEq(sync1, bit_1)))))
    s.then_stmts.append(HDLAssign(isig, port))
    s.else_stmts = None
    res.sync_stmts.append(s)
    return res


def gen_async_wr(clk, rst, port, inp, sync0, sync1, sync2):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(sync0, bit_0))
    res.rst_stmts.append(HDLAssign(sync1, bit_0))
    res.rst_stmts.append(HDLAssign(sync2, bit_0))
    res.sync_stmts.append(HDLAssign(sync0, inp))
    res.sync_stmts.append(HDLAssign(sync1, sync0))
    res.sync_stmts.append(HDLAssign(sync2, sync1))
    res.sync_stmts.append(HDLAssign(port, HDLAnd(sync1,
                                                 HDLParen(HDLNot(sync2)))))
    return res


def gen_async_rwrw(clk, rst, s0_sig, s1_sig, s2_sig, rd_sig, wr_sig,
                   hdl_load, hdl_port, lw_sig, sel_sig, hdl_iport):
    res = hdltree.HDLSync(clk, rst)
    res.rst_stmts.append(HDLAssign(s0_sig, bit_0))
    res.rst_stmts.append(HDLAssign(s1_sig, bit_0))
    res.rst_stmts.append(HDLAssign(s2_sig, bit_0))
    if rd_sig.size is None:
        res.rst_stmts.append(HDLAssign(rd_sig, HDLConst(0, rd_sig.size)))
        res.rst_stmts.append(HDLAssign(hdl_load, bit_0))
        res.rst_stmts.append(HDLAssign(hdl_port, HDLConst(0, hdl_port.size)))
    else:
        res.rst_stmts.append(HDLAssign(hdl_port, HDLConst(0, hdl_port.size)))
        res.rst_stmts.append(HDLAssign(hdl_load, bit_0))
        res.rst_stmts.append(HDLAssign(rd_sig, HDLConst(0, rd_sig.size)))
    res.sync_stmts.append(HDLAssign(s0_sig, lw_sig))
    res.sync_stmts.append(HDLAssign(s1_sig, s0_sig))
    res.sync_stmts.append(HDLAssign(s2_sig, s1_sig))
    s = HDLIfElse(HDLParen(HDLAnd(HDLParen(HDLEq(s2_sig, bit_0)),
                                  HDLParen(HDLEq(s1_sig, bit_1)))))
    s.else_stmts.append(HDLAssign(hdl_load, bit_0))
    res.sync_stmts.append(s)
    s1 = HDLIfElse(HDLParen(HDLEq(sel_sig, bit_1)))
    s1.then_stmts.append(HDLAssign(hdl_port, wr_sig))
    s1.then_stmts.append(HDLAssign(hdl_load, bit_1))
    s1.else_stmts.append(HDLAssign(hdl_load, bit_0))
    s1.else_stmts.append(HDLAssign(rd_sig, hdl_iport))
    s.then_stmts.append(s1)
    return res


def expand_passthrough(f, reg, name, isig, bus):
    assert f.h_access in ['RW_RO', 'WO_RO']
    assert f.c_rwidth is not None
    g = Code()
    hdl_port = HDLPort(name + '_o', f.c_rwidth, dir='OUT')
    comment = "PASS_THROUGH field: '{name}' in reg: '{reg}'".format(
        name=f.description, reg=reg.description)
    clock = get_wbgen(f, 'clock')
    if clock:
        comment = "asynchronous (clock: {}) {}".format(clock, comment)
    hdl_port.comment = "Ports for " + comment
    wr_port = HDLPort(name + '_wr_o', dir='OUT')
    g.ports.extend([hdl_port, wr_port])
    g.asgn_code.append(HDLComment(
        "pass-through field: {name} in register: {reg}".format(
            name=f.description, reg=reg.description), False))
    g.asgn_code.append(HDLAssign(hdl_port,
                       expand_field_sel(isig['wrdata'], f)))
    if clock:
        wr_int = HDLSignal(name + '_wr_int')
        wr_dly = HDLSignal(name + '_wr_int_delay')
        hdl_s0 = HDLSignal(name + '_wr_sync0')
        hdl_s1 = HDLSignal(name + '_wr_sync1')
        hdl_s2 = HDLSignal(name + '_wr_sync2')
        g.signals.extend([wr_int, wr_dly, hdl_s0, hdl_s1, hdl_s2])
        g.rst_code.append(HDLAssign(wr_int, bit_0))
        g.rst_code.append(HDLAssign(wr_dly, bit_0))
        g.inack_code.append(HDLAssign(wr_int, wr_dly))
        g.inack_code.append(HDLAssign(wr_dly, bit_0))
        g.write_code.append(HDLAssign(wr_int, bit_1))
        g.write_code.append(HDLAssign(wr_dly, bit_1))
        g.asgn_code.append(gen_async_wr(isig[clock], bus['rst'], wr_port,
                           wr_int, hdl_s0, hdl_s1, hdl_s2))
        g.asgn_code.append(HDLComment(None))
        g.asgn_code.append(HDLComment(None))
        g.ack_len = 4
    else:
        g.rst_code.append(HDLAssign(wr_port, bit_0))
        g.acked_code.append(HDLAssign(wr_port, bit_0))
        g.inack_code.append(HDLAssign(wr_port, bit_0))
        g.write_code.append(HDLAssign(wr_port, bit_1))
    return g


def expand_constant(f, reg, name, isig, bus):
    g = Code()
    if f.c_rwidth is None or f.c_rwidth == 1:
        targ = HDLIndex(isig['rddata'], f.lo)
        size = None
    else:
        targ = HDLSlice(isig['rddata'], f.lo, f.c_rwidth)
        size = f.c_rwidth
    g.read_code.append(HDLAssign(targ, HDLConst(f.preset, size)))
    return g


def expand_reg_choice(root, addr):
    wd = root.h_reg_bits - root.c_addr_word_bits
    return HDLChoiceExpr(HDLConst(addr >> root.c_addr_word_bits,
                                  wd if wd > 1 else None))


def expand_reg_rw(root, bus):
    s = HDLIfElse(HDLParen(HDLEq(bus['we'], bit_1)))
    s.else_stmts = None
    return ([s], s.then_stmts)


def expand_fiforeg(periph, reg, isig, bus):
    g = Code()
    g.choice_stmts = None
    fifo = reg._parent
    prefix = get_hdl_prefix(periph) + '_' + get_hdl_prefix(reg)

    # Create a register
    (g.choice_stmts, wr_stmts) = expand_reg_rw(periph, bus)
    direction = get_wbgen(fifo, 'direction')
    if direction == 'CORE_TO_BUS' and reg.h_num == 0:
        # FIFO read request at address 0.
        stmt = HDLIfElse(HDLParen(HDLEq(fifo.req_int0, bit_0)))
        stmt.then_stmts.append(HDLAssign(fifo.req_int, HDLNot(fifo.req_int)))
        g.choice_stmts.append(stmt)
        rd_stmts = stmt.else_stmts
    else:
        rd_stmts = g.choice_stmts
    for f in reg.children:
        name = prefix
        hdl_prefix = get_hdl_prefix(f)
        if hdl_prefix:
            name += '_' + hdl_prefix

        targ = Slice_or_Index(fifo.hdl_int, f.h_fifo_offset, f.c_rwidth)
        if direction == 'BUS_TO_CORE':
            wr_stmts.append(HDLAssign(targ, expand_field_sel(isig['wrdata'], f)))
            if f.h_fifo_offset + f.c_rwidth == fifo.hdl_int.size:
                # FIFO write request at the last address.
                wr_stmts.append(HDLAssign(fifo.req_int, bit_1))
        else:
            rd_stmts.append(HDLAssign(expand_field_sel(isig['rddata'], f),
                                      targ))
    # Pad read list.  Hummm
    pad_read_stmts(periph, rd_stmts, isig)

    if direction == 'CORE_TO_BUS' and reg.h_num == 0:
        expand_ack0(rd_stmts, isig)
    else:
        expand_ack(rd_stmts, isig, 1)

    g.asgn_code.append(HDLComment(
        "extra code for reg/fifo/mem: {}".format(reg.description), False))
    if fifo.req_int0 is not None and reg.h_num == 0:
        proc = hdltree.HDLSync(bus['clk'], bus['rst'])
        proc.rst_stmts.append(HDLAssign(fifo.req_int0, bit_0))
        proc.sync_stmts.append(HDLAssign(fifo.req_int0, fifo.req_int))
        g.asgn_code.append(proc)
        g.asgn_code.append(HDLComment(None))
        g.asgn_code.append(HDLComment(None))

    return g


def expand_fifocsreg(f, r, name, isig, bus):
    g = Code()
    if get_wbgen(f, 'kind') == 'clear_bus':
        asgn = HDLIfElse(HDLParen(
            HDLEq(expand_field_sel(isig['wrdata'], f), bit_1)))
        asgn.then_stmts.append(
            HDLAssign(r._parent.flag_signals[f.name], bit_1))
        asgn.else_stmts = None
        g.write_code.append(asgn)
        asgn = HDLAssign(expand_field_sel(isig['rddata'], f), bit_0)
        g.read_code.append(asgn)
    else:
        asgn = HDLAssign(expand_field_sel(isig['rddata'], f),
                         r._parent.flag_signals[f.name])
        g.read_code.append(asgn)
    return g


def expand_monostable(f, reg, name, isig, bus):
    #assert f.access in ['WO_RO', 'RW_RO']
    assert f.c_rwidth == 1
    g = Code()
    hdl_port = HDLPort(name + '_o', dir='OUT')
    comment = "MONOSTABLE field: '{name}' in reg: '{reg}'".format(
        name=f.description, reg=reg.description)
    clock = get_wbgen(f, 'clock')
    if clock:
        comment = "asynchronous (clock: {}) {}".format(clock, comment)
    hdl_port.comment = "Port for " + comment
    g.ports.append(hdl_port)
    if clock:
        hdl_int = HDLSignal(name + '_int')
        hdl_dly = HDLSignal(name + '_int_delay')
        hdl_s0 = HDLSignal(name + '_sync0')
        hdl_s1 = HDLSignal(name + '_sync1')
        hdl_s2 = HDLSignal(name + '_sync2')
        g.signals.extend([hdl_int, hdl_dly, hdl_s0, hdl_s1, hdl_s2])
        g.rst_code.append(HDLAssign(hdl_int, bit_0))
        g.rst_code.append(HDLAssign(hdl_dly, bit_0))
        g.inack_code.append(HDLAssign(hdl_int, hdl_dly))
        g.inack_code.append(HDLAssign(hdl_dly, bit_0))
        g.write_code.append(HDLAssign(hdl_int,
                                      expand_field_sel(isig['wrdata'], f)))
        g.write_code.append(HDLAssign(hdl_dly,
                                      expand_field_sel(isig['wrdata'], f)))
        g.read_code.append(HDLAssign(expand_field_sel(isig['rddata'], f),
                                     bit_0))
        g.ack_len = 5
        g.asgn_code.append(gen_async_pulse(
            isig[clock], bus['rst'],
            hdl_port, hdl_int, hdl_s0, hdl_s1, hdl_s2))
    else:
        hdl_dly = HDLSignal(name + '_dly0')
        hdl_int = HDLSignal(name + '_int')
        g.signals.extend([hdl_dly, hdl_int])
        g.rst_code.append(HDLAssign(hdl_int, bit_0))
        g.acked_code.append(HDLAssign(hdl_int, bit_0))
        g.write_code.append(HDLAssign(hdl_int,
                                      expand_field_sel(isig['wrdata'], f)))
        g.read_code.append(HDLAssign(expand_field_sel(isig['rddata'], f),
                                     bit_0))

        g.ack_len = 3
        g.asgn_code.append(gen_sync_pulse(
            bus['clk'], bus['rst'], hdl_port, hdl_int, hdl_dly))
    g.asgn_code.append(HDLComment(None))
    g.asgn_code.append(HDLComment(None))
    return g


def expand_bit(f, reg, name, isig, bus):
    g = Code()
    if f.h_access in ('WO_RO', 'RW_RO', 'RW_RW'):
        dir = 'OUT'
    else:
        dir = 'IN'
    port_name = name + mode_suffix_map[dir]
    typ = get_wbgen(f, 'type')
    clock = get_wbgen(f, 'clock')
    load = get_wbgen(f, 'load')
    if typ == 'BIT':
        size = None
    else:
        size = f.c_rwidth
    port_type = {'SLV': 'L', 'BIT': 'L', 'UNSIGNED': 'U'}.get(typ, 'L')
    type_name = {'SLV': 'std_logic_vector',
                 'UNSIGNED': 'unsigned'}.get(typ, typ)
    if typ == 'BIT' and f.h_access == 'RW_RW' and clock:
        typ_str = "RW/RW BIT"
    else:
        typ_str = type_name
    comment = "{typ} field: '{field}' in reg: '{reg}'".format(
        typ=typ_str, field=f.description, reg=reg.description)
    if clock:
        comment = "asynchronous (clock: {}) {}".format(clock, comment)
    if f.h_access not in ['WO_RO']:
        hdl_port = HDLPort(port_name, size, typ=port_type, dir=dir)
        if load == 'LOAD_EXT' \
           and ((clock and typ == 'SLV') or typ == 'BIT'):
            hdl_port.comment = "Ports for " + comment
        elif is_wbgen_fiforeg(reg):
            # No comments for fifo
            pass
        else:
            hdl_port.comment = "Port for " + comment
        g.ports.append(hdl_port)
        read_sig = hdl_port

    if load == 'LOAD_EXT' and dir == 'OUT':
        hdl_iport = HDLPort(name + '_i', typ=port_type, dir='IN', size=size)
        hdl_load = HDLPort(name + '_load_o', dir='OUT')
        g.ports.extend([hdl_iport, hdl_load])
        read_sig = hdl_iport
    else:
        hdl_load = None

    # Internal signal for OUT ports.
    if dir == 'OUT' and load != 'LOAD_EXT' and f.h_access not in ['WO_RO']:
        hdl_sig = HDLSignal(name + '_int', size=size)
        g.signals.append(hdl_sig)
        asgn = HDLAssign(hdl_sig, HDLConst(f.preset or 0, hdl_sig.size))
        g.rst_code.append(asgn)
        read_sig = hdl_sig

    if clock:
        if f.h_access in ['RW_RW']:
            rd_sig = HDLSignal(name + '_int_read', size=size)
            wr_sig = HDLSignal(name + '_int_write', size=size)
            lw_sig = HDLSignal(name + '_lw')
            dly_sig = HDLSignal(name + '_lw_delay')
            prg_sig = HDLSignal(name + '_lw_read_in_progress')
            s0_sig = HDLSignal(name + '_lw_s0')
            s1_sig = HDLSignal(name + '_lw_s1')
            s2_sig = HDLSignal(name + '_lw_s2')
            sel_sig = HDLSignal(name + '_rwsel')
            g.signals.extend([rd_sig, wr_sig, lw_sig, dly_sig, prg_sig,
                              s0_sig, s1_sig, s2_sig, sel_sig])
            g.rst_code.append(HDLAssign(lw_sig, bit_0))
            g.rst_code.append(HDLAssign(dly_sig, bit_0))
            g.rst_code.append(HDLAssign(prg_sig, bit_0))
            g.rst_code.append(HDLAssign(sel_sig, bit_0))
            g.rst_code.append(HDLAssign(wr_sig, HDLConst(0, size)))
            g.inack_code.append(HDLAssign(lw_sig, dly_sig))
            g.inack_code.append(HDLAssign(dly_sig, bit_0))
            s = HDLIfElse(HDLParen(
                HDLAnd(HDLParen(HDLEq(HDLIndex(isig['ack'], 1), bit_1)),
                       HDLParen(HDLEq(prg_sig, bit_1)))))
            s.then_stmts.append(HDLAssign(expand_field_sel(isig['rddata'], f),
                                          rd_sig))
            s.then_stmts.append(HDLAssign(prg_sig, bit_0))
            s.else_stmts = None
            g.inack_code.append(s)
            g.write_code.append(HDLAssign(wr_sig,
                                          expand_field_sel(isig['wrdata'], f)))
            g.write_code.append(HDLAssign(lw_sig, bit_1))
            g.write_code.append(HDLAssign(dly_sig, bit_1))
            g.write_code.append(HDLAssign(prg_sig, bit_0))
            g.write_code.append(HDLAssign(sel_sig, bit_1))
            s = HDLIfElse(HDLParen(HDLEq(bus['we'], bit_0)))
            if typ == 'BIT':
                s.then_stmts.append(HDLAssign(
                    expand_field_sel(isig['rddata'], f), bit_x))
            s.then_stmts.append(HDLAssign(lw_sig, bit_1))
            s.then_stmts.append(HDLAssign(dly_sig, bit_1))
            s.then_stmts.append(HDLAssign(prg_sig, bit_1))
            s.then_stmts.append(HDLAssign(sel_sig, bit_0))
            s.else_stmts = None
            g.read_code.append(s)
            g.asgn_code.append(HDLComment(
                "asynchronous {} register : {} "
                "(type RW/WO, {} <-> {})".format(
                    type_name, f.description, clock, bus['clk'].name), False))
            g.asgn_code.append(gen_async_rwrw(
                isig[clock], bus['rst'], s0_sig, s1_sig, s2_sig,
                rd_sig, wr_sig, hdl_load, hdl_port, lw_sig, sel_sig,
                hdl_iport))
            g.asgn_code.append(HDLComment(None))
            g.asgn_code.append(HDLComment(None))
            g.ack_len = 6
            read_sig = bit_x
        elif typ == 'BIT':
            if f.h_access == 'RO_WO':
                sync0_sig = HDLSignal(name + '_sync0', size=size)
                sync1_sig = HDLSignal(name + '_sync1', size=size)
                g.signals.extend([sync0_sig, sync1_sig])
                read_sig = sync1_sig
                g.asgn_code.append(HDLComment(
                    "synchronizer chain for field : {} "
                    "(type RO/WO, {} -> {})".format(
                        f.description, clock, bus['clk'].name), False))
                g.asgn_code.append(gen_async_inp(
                    isig[clock], bus['rst'], hdl_port, sync0_sig, sync1_sig))
            elif f.h_access in ['RW_RO']:
                sync0_sig = HDLSignal(name + '_sync0', size=size)
                sync1_sig = HDLSignal(name + '_sync1', size=size)
                g.signals.extend([sync0_sig, sync1_sig])
                g.ack_len = 4
                g.write_code.append(HDLAssign(
                    hdl_sig, expand_field_sel(isig['wrdata'], f)))
                g.asgn_code.append(HDLComment(
                    "synchronizer chain for field : {} "
                    "(type RW/RO, {} <-> {})".format(
                        f.description, bus['clk'].name, clock), False))
                g.asgn_code.append(gen_async_out(
                    isig[clock], bus['rst'],
                    hdl_port, hdl_sig, sync0_sig, sync1_sig))
            else:
                assert False, "unhandled async bit access {} " \
                    "for field {}".format(f.access, f.name)
            g.asgn_code.append(HDLComment(None))
            g.asgn_code.append(HDLComment(None))
        elif f.h_access in ['RO_WO']:
            hdl_sig = HDLSignal(name + '_int', size=size)
            lwb_sig = HDLSignal(name + '_lwb')
            dly_sig = HDLSignal(name + '_lwb_delay')
            prg_sig = HDLSignal(name + '_lwb_in_progress')
            sync0_sig = HDLSignal(name + '_lwb_s0')
            sync1_sig = HDLSignal(name + '_lwb_s1')
            sync2_sig = HDLSignal(name + '_lwb_s2')
            g.signals.extend([hdl_sig, lwb_sig, dly_sig, prg_sig,
                              sync0_sig, sync1_sig, sync2_sig])
            g.rst_code.append(HDLAssign(lwb_sig, bit_0))
            g.rst_code.append(HDLAssign(dly_sig, bit_0))
            g.rst_code.append(HDLAssign(prg_sig, bit_0))
            g.inack_code.append(HDLAssign(lwb_sig, dly_sig))
            g.inack_code.append(HDLAssign(dly_sig, bit_0))
            s = HDLIfElse(HDLParen(
                HDLAnd(HDLParen(HDLEq(HDLIndex(isig['ack'], 1), bit_1)),
                       HDLParen(HDLEq(prg_sig, bit_1)))))
            s.then_stmts.append(HDLAssign(expand_field_sel(isig['rddata'], f),
                                          hdl_sig))
            s.then_stmts.append(HDLAssign(prg_sig, bit_0))
            s.else_stmts = None
            g.inack_code.append(s)
            s = HDLIfElse(HDLParen(HDLEq(bus['we'], bit_0)))
            s.then_stmts.append(HDLAssign(lwb_sig, bit_1))
            s.then_stmts.append(HDLAssign(dly_sig, bit_1))
            s.then_stmts.append(HDLAssign(prg_sig, bit_1))
            s.else_stmts = None
            g.read_code.append(s)
            g.asgn_code.append(HDLComment(
                "asynchronous std_logic_vector register : {} "
                "(type RO/WO, {} <-> {})".format(
                    f.description, clock, bus['clk'].name), False))
            g.asgn_code.append(gen_async_lwb(
                isig[clock], bus['rst'], hdl_port, hdl_sig, lwb_sig,
                sync0_sig, sync1_sig, sync2_sig))
            g.asgn_code.append(HDLComment(None))
            g.asgn_code.append(HDLComment(None))
            g.ack_len = 6
            read_sig = bit_x
        elif f.h_access in ['RW_RO']:
            swb_sig = HDLSignal(name + '_swb')
            dly_sig = HDLSignal(name + '_swb_delay')
            sync0_sig = HDLSignal(name + '_swb_s0')
            sync1_sig = HDLSignal(name + '_swb_s1')
            sync2_sig = HDLSignal(name + '_swb_s2')
            g.signals.extend([swb_sig, dly_sig,
                              sync0_sig, sync1_sig, sync2_sig])
            g.rst_code.append(HDLAssign(swb_sig, bit_0))
            g.rst_code.append(HDLAssign(dly_sig, bit_0))
            g.inack_code.append(HDLAssign(swb_sig, dly_sig))
            g.inack_code.append(HDLAssign(dly_sig, bit_0))
            g.write_code.append(HDLAssign(hdl_sig,
                                          expand_field_sel(isig['wrdata'], f)))
            g.write_code.append(HDLAssign(swb_sig, bit_1))
            g.write_code.append(HDLAssign(dly_sig, bit_1))
            g.asgn_code.append(HDLComment(
                "asynchronous std_logic_vector register : {} "
                "(type RW/RO, {} <-> {})".format(
                    f.description, clock, bus['clk'].name), False))
            g.asgn_code.append(gen_async_swb(
                isig[clock], bus['rst'], hdl_sig, hdl_port, swb_sig,
                sync0_sig, sync1_sig, sync2_sig))
            g.asgn_code.append(HDLComment(None))
            g.asgn_code.append(HDLComment(None))
            g.ack_len = 4
        else:
            assert False, "unhandled access {} for clocked reg".format(
                f.h_access)
    ack_read = get_wbgen(f, 'ack_read')
    if ack_read:
        hdl_ack = HDLPort(ack_read, dir='OUT')
        g.ports.append(hdl_ack)
        g.rst_code.append(HDLAssign(hdl_ack, bit_0))
        g.acked_code.append(HDLAssign(hdl_ack, bit_0))

    # Read
    if f.h_access not in ['WO_RO']:
        asgn = HDLAssign(expand_field_sel(isig['rddata'], f), read_sig)
        g.read_code.append(asgn)

    if clock:
        pass
    elif hdl_load:  # f.load == 'LOAD_EXT':
        g.rst_code.append(HDLAssign(hdl_load, bit_0))
        g.acked_code.append(HDLAssign(hdl_load, bit_0))
        g.inack_code.append(HDLAssign(hdl_load, bit_0))
        g.write_code.append(HDLAssign(hdl_load, bit_1))
        g.asgn_code.append(HDLAssign(hdl_port,
                                     expand_field_sel(isig['wrdata'], f)))
    elif f.h_access in ['RW_RO']:
        asgn = HDLAssign(hdl_sig, expand_field_sel(isig['wrdata'], f))
        g.write_code.append(asgn)
        asgn = HDLAssign(hdl_port, hdl_sig)
        g.asgn_code.append(asgn)

    if ack_read:
        g.read_code.append(HDLAssign(hdl_ack, bit_1))

    return g


def pad_read_stmts(root, rd_stmts, isig):
    # Pad read list.  Hummm
    nstmts = []
    sset = [False for i in range(root.c_word_bits)]

    for s in rd_stmts:
        nstmts.append(s)
        if not isinstance(s, HDLAssign):
            pass
        elif (isinstance(s.target, HDLIndex)
              and s.target.prefix == isig['rddata']):
            sset[s.target.index] = True
            if s.expr == bit_x:
                # Discard
                nstmts.pop()
        elif (isinstance(s.target, HDLSlice)
              and s.target.prefix == isig['rddata']):
            for i in range(s.target.index, s.target.index + s.target.size):
                sset[i] = True
            if s.expr == bit_x:
                # Discard
                nstmts.pop()
    for i in range(len(sset)):
        if not sset[i]:
            nstmts.append(HDLAssign(HDLIndex(isig['rddata'], i), bit_x))

    # In place replace list.
    del rd_stmts[:]
    rd_stmts.extend(nstmts)


def expand_reg(root, r, isig, bus):
    gr = Code()
    gr.choice_stmts = None
    prefix = get_hdl_prefix(root) + '_' + get_hdl_prefix(r)

    (gr.choice_stmts, wr_stmts) = expand_reg_rw(root, bus)
    rd_stmts = gr.choice_stmts
    ack_len = 1
    force_pad = 0
    for f in r.children:
        name = prefix
        hdl_prefix = get_hdl_prefix(f)
        if hdl_prefix:
            name += '_' + hdl_prefix

        if is_wbgen_fifocs(r):
            g = expand_fifocsreg(f, r, name, isig, bus)
            typ = 'FIFOCS'
        else:
            typ = get_wbgen(f, 'type', 'SLV')
            if typ == 'PASS_THROUGH':
                g = expand_passthrough(f, r, name, isig, bus)
            elif typ in ['BIT', 'SLV', 'UNSIGNED']:
                g = expand_bit(f, r, name, isig, bus)
            elif typ == 'MONOSTABLE':
                g = expand_monostable(f, r, name, isig, bus)
            elif typ == 'CONSTANT':
                g = expand_constant(f, r, name, isig, bus)
            else:
                assert False, "unhandled type {}".format(typ)

        if typ == 'MONOSTABLE' and force_pad >= 0 \
           and get_wbgen(f, 'access_bus') is None \
           and get_wbgen(f, 'access_dev') is None:
            force_pad += 1
        else:
            force_pad = -1

        gr.ports.extend(g.ports)
        gr.signals.extend(g.signals)
        gr.rst_code.extend(g.rst_code)
        if not (typ == 'CONSTANT'
                or (typ in ['SLV'] and f.h_access in ['WO_RO'])
                or is_wbgen_fiforeg(r)
                or is_wbgen_fifocs(r)):
            gr.asgn_code.append(HDLComment(f.description, False))
        gr.asgn_code.extend(g.asgn_code)
        wr_stmts.extend(g.write_code)
        rd_stmts.extend(g.read_code)
        gr.inack_code.extend(g.inack_code)
        gr.acked_code.extend(g.acked_code)
        ack_len = max(ack_len, g.ack_len)

    # Pad read list.  Hummm
    if force_pad > 0:
        for i in range(root.c_word_bits):
            rd_stmts.append(HDLAssign(HDLIndex(isig['rddata'], i), bit_x))
    else:
        pad_read_stmts(root, rd_stmts, isig)

    expand_ack(rd_stmts, isig, ack_len)
    return gr


def expand_irqs(root, module, bus, isig):
    g = Code()
    g.choices = []
    g.inpvec_sig = None
    irqs = []
    for r in root.children:
        if is_wbgen_irq(r):
            for el in get_wbgen(r, 'irqs'):
                irqs.append(el['irq'])
    nbr_irqs = len(irqs)
    if nbr_irqs == 0:
        return g
    level = [{'LEVEL_1': 3,
              'LEVEL_0': 2,
              'EDGE_FALLING': 1,
              'EDGE_RISING': 0}[irq.get('trigger', 'EDGE_RISING')]
             for irq in irqs]

    module.deps = [('work', "wbgen2_pkg")]
    int_port = HDLPort('wb_int_o', dir='OUT')
    g.ports.append(int_port)

    idr_sig = HDLSignal("eic_idr_int", nbr_irqs)
    idrw_sig = HDLSignal("eic_idr_write_int")
    g.signals.extend([idr_sig, idrw_sig])
    ier_sig = HDLSignal("eic_ier_int", nbr_irqs)
    ierw_sig = HDLSignal("eic_ier_write_int")
    g.signals.extend([ier_sig, ierw_sig])
    imr_sig = HDLSignal("eic_imr_int", nbr_irqs)
    isrc_sig = HDLSignal("eic_isr_clear_int", nbr_irqs)
    isrs_sig = HDLSignal("eic_isr_status_int", nbr_irqs)
    g.signals.extend([imr_sig, isrc_sig, isrs_sig])
    ack_sig = HDLSignal("eic_irq_ack_int", nbr_irqs)
    isrw_sig = HDLSignal("eic_isr_write_int")
    inp_vec = HDLSignal("irq_inputs_vector_int", nbr_irqs)
    g.signals.extend([ack_sig, isrw_sig])
    g.inpvec_sig = inp_vec
    g.rst_code.append(HDLAssign(idrw_sig, bit_0))
    g.rst_code.append(HDLAssign(ierw_sig, bit_0))
    g.rst_code.append(HDLAssign(isrw_sig, bit_0))
    g.acked_code.append(HDLAssign(idrw_sig, bit_0))
    g.acked_code.append(HDLAssign(ierw_sig, bit_0))
    g.acked_code.append(HDLAssign(isrw_sig, bit_0))

    # Read/Write registers
    def _assign(wr, rd, int_sig, r):
        if wr:
            wr_stmts.append(HDLAssign(wr, bit_1))
        if rd:
            rd_stmts.append(HDLAssign(
                Slice_or_Index(isig['rddata'], 0, nbr_irqs),
                Slice_or_Index(rd, 0, nbr_irqs)))
        if int_sig:
            g.asgn_code.append(HDLComment(
                "extra code for reg/fifo/mem: {}".format(r.description), False))
            g.asgn_code.append(HDLAssign(
                Slice_or_Index(int_sig, 0, nbr_irqs),
                Slice_or_Index(isig['wrdata'], 0, nbr_irqs)))
    for b in root.children:
        if is_wbgen_irq(b):
            for r in r.children:
                (choice_stmts, wr_stmts) = expand_reg_rw(root, root.h_bus)
                rd_stmts = choice_stmts
                g.choices.append((r, choice_stmts))
                if r.name == 'eic_idr':
                    _assign(idrw_sig, None, idr_sig, r)
                elif r.name == 'eic_ier':
                    _assign(ierw_sig, None, ier_sig, r)
                elif r.name == 'eic_imr':
                    _assign(None, imr_sig, None, r)
                elif r.name == 'eic_isr':
                    _assign(isrw_sig, isrs_sig, isrc_sig, r)
                else:
                    assert False, "unhandled eic register {}".format(r.name)
                pad_read_stmts(root, rd_stmts, isig)
                expand_ack(rd_stmts, isig, 1)
    # EIC controller.
    g.asgn_code.append(HDLComment(
        "extra code for reg/fifo/mem: IRQ_CONTROLLER", False))
    ctrl = HDLInstance("eic_irq_controller_inst", "wbgen2_eic")
    ctrl.params.append(('g_num_interrupts', HDLNumber(nbr_irqs)))
    for i in range(root.c_word_bits):
        ctrl.params.append(("g_irq{:02x}_mode".format(i),
                            HDLNumber(level[i] if i < len(level) else 0)))
    ctrl.conns.append(("clk_i", bus['clk']))
    ctrl.conns.append(("rst_n_i", bus['rst']))
    ctrl.conns.append(("irq_i", inp_vec))
    ctrl.conns.append(("irq_ack_o", ack_sig))
    ctrl.conns.append(("reg_imr_o", imr_sig))
    ctrl.conns.append(("reg_ier_i", ier_sig))
    ctrl.conns.append(("reg_ier_wr_stb_i", ierw_sig))
    ctrl.conns.append(("reg_idr_i", idr_sig))
    ctrl.conns.append(("reg_idr_wr_stb_i", idrw_sig))
    ctrl.conns.append(("reg_isr_o", isrs_sig))
    ctrl.conns.append(("reg_isr_i", isrc_sig))
    ctrl.conns.append(("reg_isr_wr_stb_i", isrw_sig))
    ctrl.conns.append(("wb_irq_o", int_port))
    g.asgn_code.append(ctrl)
    # Irq lines
    idx = 0
    for irq in irqs:
        gi = Code()
        pfx = irq['name'].lower()
        p = HDLPort("irq_{}_i".format(pfx))
        gi.ports.append(p)
        g.asgn_code.append(HDLAssign(HDLIndex(inp_vec, idx), p))
        if 'ack_line' in irq:
            ack = HDLPort("irq_{}_ack_o".format(pfx), dir='OUT')
            gi.ports.append(ack)
            g.asgn_code.append(HDLAssign(ack, HDLIndex(ack_sig, idx)))
        if irq.get('mask_line', False):
            msk = HDLPort("irq_{}_mask_o".format(pfx), dir='OUT')
            gi.ports.append(msk)
            g.asgn_code.append(HDLAssign(msk, HDLIndex(imr_sig, idx)))
        irq['code'] = gi
        idx += 1
    return g


def expand_sel_select(root, sig):
    lo = root.c_blk_bits - root.c_addr_word_bits
    if root.c_sel_bits > 1:
        return HDLSlice(sig, lo, root.c_sel_bits)
    else:
        return HDLIndex(sig, lo)


def expand_sel_choice(root, num):
    if root.c_sel_bits == 1:
        v = HDLConst(num, size=None)
    else:
        v = HDLConst(num, size=root.c_sel_bits)
    return v


def expand_rams(root, module, bus, isig):
    periph = root # TODO
    g = Code()
    g.sel_choices = []
    g.out_choices = []
    g.decode_stmts = []

    rams = []
    for r in root.children:
        if is_wbgen_ram(r):
            rams.append(r)

    if len(rams) == 0:
        return g

    comb = HDLComb()
    comb.sensitivity.extend([bus['adr'], isig['rd'], isig['wr']])

    num = 1 if root.h_reg_bits > 0 else 0
    for r in rams:
        reg = r.children[0]
        r.code = Code()
        r.code.clock_port = None
        prefix = get_hdl_prefix(root) + '_' + get_hdl_prefix(r)
        addr = HDLPort(prefix + '_addr_i', r.c_sel_bits, dir='IN')
        addr.comment = "Ports for RAM: {}".format(r.description)
        dato = HDLPort(prefix + '_data_o', reg.width, dir='OUT')
        dato.comment = "Read data output"
        rd_sig = HDLPort(prefix + '_rd_i', dir='IN')
        rd_sig.comment = "Read strobe input (active high)"
        r.code.ports = [addr, dato, rd_sig]
        access_dev = get_wbgen(r, 'access_dev')
        if access_dev in ['READ_WRITE']:
            dati = HDLPort(prefix + '_data_i', reg.width, dir='IN')
            dati.comment = "Write data input"
            wr_sig = HDLPort(prefix + '_wr_i', dir='IN')
            wr_sig.comment = "Write strobe (active high)"
            r.code.ports.extend([dati, wr_sig])
            byte_select = get_wbgen(r, 'byte_select')
            if byte_select:
                bwsel_sig = HDLPort(prefix + '_bwsel_i', reg.width // 8)
                bwsel_sig.comment = "Byte select input (active high)"
                r.code.ports.append(bwsel_sig)
        g.ports.extend(r.code.ports)
        rdat_int = HDLSignal(prefix + '_rddata_int', reg.width)
        rd_int = HDLSignal(prefix + '_rd_int')
        wr_int = HDLSignal(prefix + '_wr_int')
        g.signals.extend([rdat_int, rd_int, wr_int])

        ch = HDLChoiceExpr(expand_sel_choice(root, num))
        g.sel_choices.append(ch)
        s = HDLIfElse(HDLParen(HDLEq(isig['rd'], bit_1)))
        s.then_stmts.append(HDLAssign(HDLIndex(isig['ack'], 0), bit_1))
        s.else_stmts.append(HDLAssign(HDLIndex(isig['ack'], 0), bit_1))
        ch.stmts.append(s)
        ch.stmts.append(HDLAssign(isig['ackprg'], bit_1))

        # The mux for data_o
        ch = HDLChoiceExpr(expand_sel_choice(periph, num))
        g.out_choices.append(ch)
        s = HDLAssign(HDLSlice(bus['dato'], 0, reg.c_rwidth), rdat_int)
        ch.stmts.append(s)
        if reg.c_rwidth < root.c_word_size * tree.BYTE_SIZE:
            # Pad
            w = root.c_word_size * tree.BYTE_SIZE - reg.c_rwidth
            s = HDLAssign(HDLSlice(bus['dato'], reg.c_rwidth, w),
                          HDLConst(0, w))
            ch.stmts.append(s)

        # R/W lines decoder
        s = HDLIfElse(HDLParen(HDLEq(expand_sel_select(periph, bus['adr']),
                                     expand_sel_choice(periph, num))))
        comb.stmts.append(s)
        s.then_stmts.append(HDLAssign(rd_int, isig['rd']))
        s.then_stmts.append(HDLAssign(wr_int, isig['wr']))
        s.else_stmts.append(HDLAssign(wr_int, bit_0))
        s.else_stmts.append(HDLAssign(rd_int, bit_0))

        # Instance
        addr_bits = ilog2(r.repeat)
        clock = get_wbgen(r, 'clock')
        bwsel = get_wbgen(r, 'byte_select')
        g.asgn_code.append(HDLComment(
            "extra code for reg/fifo/mem: {}".format(r.description), False))
        g.asgn_code.append(HDLComment(
            "RAM block instantiation for memory: {}".format(r.description),
            False))
        inst = HDLInstance(prefix + "_raminst", "wbgen2_dpssram")
        inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
        inst.params.append(("g_size", HDLNumber(r.repeat)))
        inst.params.append(("g_addr_width", HDLNumber(addr_bits)))
        inst.params.append(("g_dual_clock", HDLBool(clock is not None)))
        inst.params.append(("g_use_bwsel", HDLBool(bwsel)))
        inst.conns.append(("clk_a_i", bus['clk']))
        inst.conns.append(
            ("clk_b_i", bus['clk'] if clock is None else isig[clock]))
        inst.conns.append(("addr_b_i", addr))
        inst.conns.append(("addr_a_i",
                           HDLSlice(isig['rwaddr'], 0, addr_bits)))
        inst.conns.append(("data_b_o", dato))
        inst.conns.append(("rd_b_i", rd_sig))
        if bwsel:
            bwsel_val = bwsel_sig
        else:
            bwsel_val = HDLSlice(isig['all1'], 0, reg.c_rwidth // 8)
        if get_wbgen(r, 'access_dev') in ['READ_WRITE']:
            inst.conns.append(("data_b_i", dati))
            inst.conns.append(("wr_b_i", wr_sig))
            inst.conns.append(("bwsel_b_i", bwsel_val))
        else:
            inst.conns.append(("bwsel_b_i", bwsel_val))
            inst.conns.append(("data_b_i",
                               HDLSlice(isig['all0'], 0, reg.c_rwidth)))
            inst.conns.append(("wr_b_i", HDLIndex(isig['all0'], 0)))
        inst.conns.append(("data_a_o",
                           HDLSlice(rdat_int, 0, reg.c_rwidth)))
        inst.conns.append(("rd_a_i", rd_int))
        inst.conns.append(("data_a_i",
                           HDLSlice(isig['wrdata'], 0, reg.c_rwidth)))
        inst.conns.append(("wr_a_i", wr_int))
        if bwsel:
            bwsel_val = isig['bwsel']
        else:
            bwsel_val = isig['all1']
        inst.conns.append(("bwsel_a_i",
                           HDLSlice(bwsel_val, 0, reg.c_rwidth // 8)))
        g.asgn_code.append(inst)

        if clock is not None:
            r.code.clock_port = isig[clock]
        num += 1

    g.decode_stmts.append(comb)

    if g.ports:
        module.deps = [('work', 'wbgen2_pkg')]
    return g


def expand_fifo(module, periph, fifo, isig, bus):
    g = Code()
    g.flag_signals = []
    g.inst_code = []
    g.params = []

    opt = get_wbgen(fifo, 'optional')
    if opt is not None:
        opt = HDLParam(opt, typ='I', value=HDLNumber(1))
        g.params.append(opt)
    prefix = get_hdl_prefix(periph) + '_' + get_hdl_prefix(fifo)
    fifo.signals = {}
    fifo.flag_signals = {}
    rst = HDLSignal(prefix + '_rst_n')
    g.signals.append(rst)

    fifo_width = 0
    cs_reg = None
    fields = []
    for reg in fifo.children:
        if is_wbgen_fifocs(reg):
            cs_reg = reg
        else:
            fields.extend(reg.children)
            for f in reg.children:
                f.h_fifo_offset = fifo_width
                fifo_width += f.c_rwidth

    in_int = HDLSignal(prefix + '_in_int', size=fifo_width)
    g.signals.append(in_int)
    out_int = HDLSignal(prefix + '_out_int', size=fifo_width)
    g.signals.append(out_int)
    breq_int0 = None
    direction = get_wbgen(fifo, 'direction')
    if direction == 'BUS_TO_CORE':
        flag_prefix = prefix + '_rd'
        mode = 'OUT'
        bus_req = HDLPort(prefix + '_rd_req_i', dir='IN')
        bus_req.comment = "FIFO read request"
        breq_int = HDLSignal(prefix + '_wrreq_int')
        g.acked_code.append(HDLAssign(breq_int, bit_0))
        fifo.hdl_int = in_int
        g.signals.append(breq_int)
    elif direction == 'CORE_TO_BUS':
        flag_prefix = prefix + '_wr'
        mode = 'IN'
        bus_req = HDLPort(prefix + '_wr_req_i', dir='IN')
        bus_req.comment = "FIFO write request"
        breq_int = HDLSignal(prefix + '_rdreq_int')
        breq_int0 = HDLSignal(prefix + '_rdreq_int_d0')
        fifo.hdl_int = out_int
        g.signals.extend([breq_int, breq_int0])
    g.ports.append(bus_req)
    fifo.req_int = breq_int
    fifo.req_int0 = breq_int0

    depth = get_wbgen(fifo, 'depth')
    log2_depth = ilog2(depth)

    field_full = None
    field_clear = None
    field_count = None
    field_empty = None
    for f in cs_reg.children:
        kind = get_wbgen(f, 'kind')
        if kind == 'full':
            field_full = f
        elif kind == 'clear_bus':
            field_clear = f
        elif kind == 'count':
            field_count = f
        elif kind in ('empty', ):
            field_empty = f
        else:
            raise AssertionError("unhandled fifo kind '{}'".format(kind))

    if get_wbgen(fifo, 'wire_full'):
        rd_full = HDLPort(flag_prefix + '_full_o', dir='OUT')
        rd_full.comment = "FIFO full flag"
        g.ports.append(rd_full)
    else:
        rd_full = None
    if field_full is not None:
        full_int = HDLSignal(prefix + '_full_int')
        fifo.flag_signals['full'] = full_int
        g.flag_signals.append(full_int)
    else:
        full_int = None
    if get_wbgen(fifo, 'wire_empty'):
        rd_empty = HDLPort(flag_prefix + '_empty_o', dir='OUT')
        rd_empty.comment = "FIFO empty flag"
        g.ports.append(rd_empty)
    else:
        rd_empty = None
    if field_empty is not None:
        empty_int = HDLSignal(prefix + '_empty_int')
        fifo.flag_signals['empty'] = empty_int
        g.flag_signals.append(empty_int)
    else:
        empty_int = None

    if field_clear is not None:
        clear_int = HDLSignal(prefix + '_clear_bus_int')
        fifo.flag_signals['clear_bus'] = clear_int
        g.flag_signals.append(clear_int)
        g.acked_code.append(HDLAssign(clear_int, bit_0))
        g.rst_code.append(HDLAssign(clear_int, bit_0))
    else:
        clear_int = None

    if get_wbgen(fifo, 'wire_count'):
        rd_usedw = HDLPort(flag_prefix + '_usedw_o',
                           size=log2_depth, dir='OUT')
        rd_usedw.comment = "FIFO number of used words"
        g.ports.append(rd_usedw)
    else:
        rd_usedw = None
    if field_count is not None:
        usedw_int = HDLSignal(prefix + '_usedw_int', log2_depth)
        fifo.flag_signals['count'] = usedw_int
        g.flag_signals.append(usedw_int)
    else:
        usedw_int = None

    g.rst_code.append(HDLAssign(breq_int, bit_0))

    g.inst_code.append(HDLComment(
        "extra code for reg/fifo/mem: {}".format(fifo.description), False))
    for reg in fifo.children:
        if is_wbgen_fifocs(reg):
            continue
        for f in reg.children:
            prt_name = "{}_{}{}".format(
                prefix, get_hdl_prefix(f), mode_suffix_map[mode])
            wd = f.c_rwidth
            prt = HDLPort(prt_name, size=(wd if wd > 1 else None), dir=mode)
            g.ports.append(prt)
            if direction == 'BUS_TO_CORE':
                d, s = (prt, Slice_or_Index(out_int, f.h_fifo_offset, f.c_rwidth))
            else:
                d, s = (Slice_or_Index(in_int, f.h_fifo_offset, f.c_rwidth), prt)
            g.inst_code.append(HDLAssign(d, s))

    rst_val = bus['rst']
    if clear_int:
        rst_val = HDLAnd(rst_val, HDLParen(HDLNot(clear_int)))
    g.inst_code.append(HDLAssign(rst, rst_val))

    clock = get_wbgen(fifo, 'clock')
    if clock is None:
        inst = HDLInstance(prefix + "_INST", "wbgen2_fifo_sync")
    else:
        inst = HDLInstance(prefix + "_INST", "wbgen2_fifo_async")
    g.inst_code.append(inst)
    inst.params.append(("g_size", HDLNumber(depth)))
    inst.params.append(("g_width", HDLNumber(fifo_width)))
    inst.params.append(("g_usedw_size", HDLNumber(log2_depth)))
    if direction == 'BUS_TO_CORE':
        bus_port, dev_port = ("rd_", "wr_")
    else:
        bus_port, dev_port = ("wr_", "rd_")
    inst.conns.append((bus_port + "req_i", bus_req))
    if rd_full:
        inst.conns.append((bus_port + "full_o", rd_full))
    if rd_empty:
        inst.conns.append((bus_port + "empty_o", rd_empty))
    if rd_usedw:
        inst.conns.append((bus_port + "usedw_o", rd_usedw))
    if full_int:
        inst.conns.append((dev_port + "full_o", full_int))
    if empty_int:
        inst.conns.append((dev_port + "empty_o", empty_int))
    if usedw_int:
        inst.conns.append((dev_port + "usedw_o", usedw_int))
    inst.conns.append((dev_port + "req_i", breq_int))
    inst.conns.append(("rst_n_i", rst))
    if clock is None:
        inst.conns.append(("clk_i", bus['clk']))
    else:
        inst.conns.append((bus_port + "clk_i", isig[clock]))
        inst.conns.append((dev_port + "clk_i", bus['clk']))
    inst.conns.append(("wr_data_i", in_int))
    inst.conns.append(("rd_data_o", out_int))

    # Wrap inside a generate block.
    if opt:
        cond_stmt = HDLGenIf(HDLNot(HDLEq(opt, HDLNumber(0))))
        cond_stmt.stmts = g.inst_code
        g.inst_code = [cond_stmt]

    module.deps = [('work', 'wbgen2_pkg')]
    return g

def compute_access(field):
    """Compute the abbreviated access from access_bus and access_dev"""
    bus_acc = get_wbgen(field, 'access_bus')
    dev_acc = get_wbgen(field, 'access_dev')
    abbrev = {'READ_WRITE': 'RW', 'READ_ONLY': 'RO', 'WRITE_ONLY': 'WO'}
    typ = get_wbgen(field, 'type')
    if bus_acc is None:
        bus_acc = {'PASS_THROUGH': 'WO', 'MONOSTABLE': 'WO',
                   'CONSTANT': 'RO'}.get(typ, 'RW')
    else:
        bus_acc = abbrev.get(bus_acc)
    if dev_acc is None:
        dev_acc = {'CONSTANT': 'WO'}.get(typ, 'RO')
    else:
        dev_acc = abbrev.get(dev_acc)
    field.h_access = '{}_{}'.format(bus_acc, dev_acc)

def build_ordered_regs(root):
    """Create ordered list of regs."""
    # Ordered regs: regular regs, interrupt, fifo regs, ram
    res = [r for r in root.children if (isinstance(r, tree.Reg)
                                        or is_wbgen_irq(r)
                                        or is_wbgen_fifo(r))]
    for r in root.children:
        if is_wbgen_irq(r):
            res.extend(r.children)
    for r in root.children:
        if is_wbgen_fifo(r):
            res.extend(r.children)
    res.extend([r for r in root.children if is_wbgen_ram(r)])
    root.h_ordered_regs = res

def layout_wbgen(root):
    build_ordered_regs(root)

    # The registers (that includes Fifos as they have been expanded)
    reg_len = 0  # in bytes
    for r in root.children:
        if isinstance(r, tree.Reg):
            reg_len = max(reg_len, r.address + r.c_rwidth // tree.BYTE_SIZE)
        elif is_wbgen_irq(r) or is_wbgen_fifo(r):
            for r1 in r.children:
                reg_len = max(reg_len, r.c_address + r1.c_address + r1.c_rwidth // tree.BYTE_SIZE)

    # The rams
    max_ram_size = 0 # in bytes
    nbr_rams = 0
    for r in root.children:
        if is_wbgen_ram(r):
            reg = r.children[0]
            bsz = reg.c_rwidth // tree.BYTE_SIZE
            assert bsz <= root.c_word_size
            r.h_ram_size = r.repeat * bsz
            max_ram_size = max(max_ram_size, r.h_ram_size)
            nbr_rams += 1

    # Split the address space into blocks (of equal length). One block
    # for registers (if any) and one block per ram
    nbr_blocks = nbr_rams + (1 if reg_len > 0 else 0)
    block_size = max(reg_len, max_ram_size)
    assert block_size > 0, "there must be at least one reg or one ram"
    # Round to a power of 2.
    root.h_blk_bits = ilog2(block_size)
    root.h_sel_bits = ilog2(nbr_blocks)
    root.h_reg_bits = 0 if reg_len == 0 else ilog2(reg_len)
    block_size = 1 << root.h_blk_bits

    # Assign ram addresses
    ram_off = block_size if reg_len > 0 else 0
    for r in root.children:
        if is_wbgen_ram(r):
            r.h_addr_base = ram_off
            r.h_addr_len = r.h_ram_size
            ram_off += block_size

def expand_hdl(root):
    assert isinstance(root, tree.Root)
    layout_wbgen(root)
    m = cheby.gen_hdl.gen_hdl_header(root)
    m.name = get_wbgen(root, 'hdl_entity', root.name)
    #bus = expand_wishbone(m, periph)

    # Patch clk name
    root.h_bus['clk'].name = 'clk_sys_i'

    # Internal signals
    addr_width = root.c_blk_bits + root.c_sel_bits - root.c_addr_word_bits
    isig = {}
    isig['ack'] = HDLSignal("ack_sreg", size=10)
    isig['rddata'] = HDLSignal("rddata_reg", size=root.c_word_bits)
    isig['wrdata'] = HDLSignal("wrdata_reg", size=root.c_word_bits)
    isig['bwsel'] = HDLSignal("bwsel_reg", size=root.c_word_bits // tree.BYTE_SIZE)
    isig['rwaddr'] = HDLSignal("rwaddr_reg", size=addr_width or 1)
    isig['ackprg'] = HDLSignal("ack_in_progress")
    isig['wr'] = HDLSignal("wr_int")
    isig['rd'] = HDLSignal("rd_int")
    isig['all1'] = HDLSignal("allones", size=root.c_word_bits)
    isig['all0'] = HDLSignal("allzeros", size=root.c_word_bits)

    # Compute access, adjust registers with no fields
    for r in root.children:
        if isinstance(r, tree.Reg):
            if len(r.children) == 1 and r.children[0].name is None:
                f = r.children[0]
                if hasattr(r, 'x_wbgen'):
                    # Copy x-wbgen attributes.
                    f.x_wbgen = r.x_wbgen
                    f.comment = get_wbgen(r, 'field_comment')
                    f.description = get_wbgen(r, 'field_description')
            for f in r.children:
                compute_access(f)

    # Gather clocks from fields and rams
    clk_sigs = []
    for r in root.children:
        if isinstance(r, tree.Reg):
            for f in r.children:
                clk = get_wbgen(f, 'clock')
                if clk and clk not in clk_sigs:
                    clk_sigs.append(clk)
        elif is_wbgen_ram(r) or is_wbgen_fifo(r):
            clk = get_wbgen(r, 'clock')
            if clk and clk not in clk_sigs:
                clk_sigs.append(clk)

    for c in clk_sigs:
        clk = HDLPort(c, dir='IN')
        isig[c] = clk

    # Create irq
    irq_code = expand_irqs(root, m, root.h_bus, isig)

    # Create rams
    rams_code = expand_rams(root, m, root.h_bus, isig)

    # Create regs
    for r in root.c_sorted_children:
        if isinstance(r, tree.Reg):
            g = expand_reg(root, r, isig, root.h_bus)
            r.ports = g.ports
        elif is_wbgen_fifo(r):
            g = expand_fifo(m, root, r, isig, root.h_bus)
            r.ports = g.ports
            num = 0
            for fr in r.children:
                if is_wbgen_fifocs(fr):
                    fr.code = expand_reg(root, fr, isig, root.h_bus)
                elif is_wbgen_fiforeg(fr):
                    fr.h_num = num
                    num += 1
                    fr.code = expand_fiforeg(root, fr, isig, root.h_bus)
                else:
                    raise AssertionError
        else:
            continue
        r.code = g

    # Params
    for r in root.children:
        if is_wbgen_fifo(r):
            m.params.extend(r.code.params)

    # Ports: first bus (already done), then:
    # * bus interrupt (if any)
    # * clocks
    if irq_code.ports:
        # Insert wb int_o port
        bus_int = irq_code.ports.pop(0)
        m.ports.append(bus_int)
        #root.bus_ports.append(bus_int)
    # Add clock ports
    for c in clk_sigs:
        m.ports.append(isig[c])
    # Regs
    for r in root.children:
        if isinstance(r, tree.Reg) \
           or is_wbgen_fifocs(r):
            m.ports.extend(r.code.ports)
        elif is_wbgen_fifo(r):
            m.ports.extend(r.code.ports)
        elif is_wbgen_irq(r):
            for irq in get_wbgen(r, 'irqs'):
                m.ports.extend(irq['irq']['code'].ports)
        elif is_wbgen_ram(r):
            m.ports.extend(rams_code.ports)
            rams_code.ports = []

    # Signals.
    for r in root.children:
        if isinstance(r, tree.Reg) \
           or is_wbgen_fifocs(r):
            m.decls.extend(r.code.signals)
        elif is_wbgen_fifo(r):
            m.decls.extend(r.code.signals)
        elif is_wbgen_ram(r):
            m.decls.extend(rams_code.signals)
            rams_code.signals = []
    for r in root.children:
        if is_wbgen_irq(r):
            m.decls.extend(irq_code.signals)
            irq_code.signals = []
    for r in root.children:
        if is_wbgen_fifo(r):
            m.decls.extend(r.code.flag_signals)
    if irq_code.inpvec_sig:
        m.decls.append(irq_code.inpvec_sig)
    m.decls.extend([isig['ack'], isig['rddata'], isig['wrdata'],
                    isig['bwsel'],
                    isig['rwaddr'], isig['ackprg'], isig['wr'], isig['rd'],
                    isig['all1'], isig['all0']])

    # Create the decoder/register.
    ff = hdltree.HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    ff.rst_stmts.append(HDLAssign(isig['ack'], HDLConst(0, isig['ack'].size)))
    ff.rst_stmts.append(HDLAssign(isig['ackprg'], bit_0))
    ff.rst_stmts.append(HDLAssign(isig['rddata'],
                                  HDLConst(0, isig['rddata'].size)))

    ff.sync_stmts.append(HDLComment(
        "advance the ACK generator shift register"))
    ff.sync_stmts.append(HDLAssign(HDLSlice(isig['ack'], 0, 9),
                                   HDLSlice(isig['ack'], 1, 9)))
    ff.sync_stmts.append(HDLAssign(HDLIndex(isig['ack'], 9), bit_0))
    s1 = HDLIfElse(HDLParen(HDLEq(isig['ackprg'], bit_1)))
    ff.sync_stmts.append(s1)
    s_ack = HDLIfElse(HDLParen(HDLEq(HDLIndex(isig['ack'], 0), bit_1)))
    s1.then_stmts.append(s_ack)

    # The select condition: true for the read or the write cycle.
    s2 = HDLIfElse(HDLParen(
        HDLAnd(HDLParen(HDLEq(root.h_bus['cyc'], bit_1)),
               HDLParen(HDLEq(root.h_bus['stb'], bit_1)))))
    s1.else_stmts.append(s2)
    s2.else_stmts = None

    if False:
        print("sel_bits: {}, blk_bits: {}, reg_bits: {}".format(
            root.c_sel_bits, root.c_blk_bits, root.h_reg_bits))

    # Create the switch decoder.  Will be placed later...
    if root.c_sel_bits > 0:
        sel_sw = HDLSwitch(expand_sel_select(root, isig['rwaddr']))
        s2.then_stmts.append(sel_sw)
    else:
        sel_sw = None
    if root.h_reg_bits > root.c_addr_word_bits:
        blk_sw = HDLSwitch(Slice_or_Index(
            isig['rwaddr'], 0, root.h_reg_bits - root.c_addr_word_bits))
        if sel_sw:
            ch = HDLChoiceExpr(expand_sel_choice(root, 0))
            sel_sw.choices.append(ch)
            ch.stmts.append(blk_sw)
        else:
            s2.then_stmts.append(blk_sw)
    else:
        blk_sw = None

    #  FF rst, reg decode, inack, acked code.
    for r in root.h_ordered_regs:
        if is_wbgen_fiforeg(r):
            ch = expand_reg_choice(root, r.c_address + r._parent.c_address)
            ch.stmts.extend(r.code.choice_stmts)
            blk_sw.choices.append(ch)
        elif is_wbgen_irqreg(r):
            for r1, stmts in irq_code.choices:
                ch = expand_reg_choice(root, r1.c_address + r1._parent.c_address)
                ch.stmts.extend(stmts)
                blk_sw.choices.append(ch)
            irq_code.choices = []
        elif isinstance(r, tree.Reg) or is_wbgen_fifocs(r):
            reg_code = r.code
            ff.rst_stmts.extend(reg_code.rst_code)
            if blk_sw is None and sel_sw is None:
                s2.then_stmts.extend(reg_code.choice_stmts)
            else:
                sw = blk_sw if blk_sw is not None else sel_sw
                ch = expand_reg_choice(root, r.c_address + r._parent.c_address)
                ch.stmts.extend(reg_code.choice_stmts)
                sw.choices.append(ch)
            s_ack.else_stmts.extend(reg_code.inack_code)
            s_ack.then_stmts.extend(reg_code.acked_code)

    ff.rst_stmts.extend(irq_code.rst_code)
    s_ack.then_stmts.extend(irq_code.acked_code)
    for r in root.children:
        if is_wbgen_fifo(r):
            ff.rst_stmts.extend(r.code.rst_code)
            s_ack.then_stmts.extend(r.code.acked_code)

    s_ack.then_stmts.append(HDLAssign(isig['ackprg'], bit_0))

    # Ack for non-existing register.
    if blk_sw:
        expand_ack_default(blk_sw.choices, isig)
    if sel_sw:
        sel_sw.choices.extend(rams_code.sel_choices)
        expand_ack_default(sel_sw.choices, isig)

    # Concurrent statements
    # * Internal assignments.
    m.stmts.append(HDLComment(
        "Some internal signals assignments. "
        "For (foreseen) compatibility with other bus standards.", False))
    m.stmts.append(HDLAssign(isig['wrdata'], root.h_bus['dati']))
    m.stmts.append(HDLAssign(isig['bwsel'], root.h_bus['sel']))
    m.stmts.append(HDLAssign(isig['rd'],
                   HDLAnd(root.h_bus['cyc'],
                          HDLAnd(root.h_bus['stb'],
                                 HDLParen(HDLNot(root.h_bus['we']))))))
    m.stmts.append(HDLAssign(isig['wr'],
                   HDLAnd(root.h_bus['cyc'],
                          HDLAnd(root.h_bus['stb'], root.h_bus['we']))))
    m.stmts.append(HDLAssign(isig['all1'],
                             HDLReplicate(bit_1, root.c_word_bits)))
    m.stmts.append(HDLAssign(isig['all0'],
                             HDLReplicate(bit_0, root.c_word_bits)))

    m.stmts.append(HDLComment("", False))
    m.stmts.append(HDLComment("Main register bank access process.", False))

    # * Registers.
    m.stmts.append(ff)

    # * Muxes
    m.stmts.append(HDLComment(None))
    if sel_sw:
        m.stmts.append(HDLComment("Data output multiplexer process"))
        dato_stmt = HDLComb()
        m.stmts.append(dato_stmt)
        dato_stmt.sensitivity.extend([isig['rddata'], isig['rwaddr']])
        sw = HDLSwitch(expand_sel_select(root, isig['rwaddr']))
        dato_stmt.stmts.append(sw)
        sw.choices.extend(rams_code.out_choices)
        for c in rams_code.out_choices:
            dato_stmt.sensitivity.append(c.stmts[0].expr)
        c = HDLChoiceDefault()
        c.stmts.append(HDLAssign(root.h_bus['dato'], isig['rddata']))
        sw.choices.append(c)
        dato_stmt.sensitivity.append(root.h_bus['adr'])  # FIXME: why

        m.stmts.append(HDLComment(None))
        m.stmts.append(HDLComment("Read & write lines decoder for RAMs"))
        m.stmts.extend(rams_code.decode_stmts)
        m.stmts.append(HDLComment(None))
        m.stmts.append(HDLComment(None))
    else:
        m.stmts.append(HDLComment("Drive the data output bus"))
        m.stmts.append(HDLAssign(root.h_bus['dato'], isig['rddata']))

    for r in root.children:
        if isinstance(r, tree.Reg):
            m.stmts.extend(r.code.asgn_code)
        elif is_wbgen_fifo(r):
            m.stmts.extend(r.code.inst_code)
        elif is_wbgen_ram(r):
            m.stmts.extend(rams_code.asgn_code)
            rams_code.asgn_code = []

    m.stmts.extend(irq_code.asgn_code)
    for r in root.children:
        if is_wbgen_fifo(r):
            m.stmts.extend(r.code.asgn_code)
            for r1 in r.children:
                if is_wbgen_fiforeg(r1):
                    m.stmts.extend(r1.code.asgn_code)

    adr = root.h_bus.get('adr', HDLReplicate(bit_0, 1))
    m.stmts.append(HDLAssign(isig['rwaddr'], adr))
    m.stmts.append(HDLAssign(root.h_bus['stall'],
                             HDLAnd(HDLParen(HDLNot(HDLIndex(isig['ack'], 0))),
                                    HDLAnd(root.h_bus['stb'],
                                           root.h_bus['cyc']))))
    m.stmts.append(HDLComment(
        "ACK signal generation. Just pass the LSB of ACK counter.", False))
    m.stmts.append(HDLAssign(root.h_bus['ack'], HDLIndex(isig['ack'], 0)))

    return m
