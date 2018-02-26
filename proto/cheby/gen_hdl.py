"""Create HDL for a Cheby description.

   Handling of names:
   Ideally we'd like to generate an HDL design that is error free.  But in
   practice, there could be some errors due to name conflict.  We try to do
   our best...
   A user name (one that comes from the Cheby description) get always a suffix,
   so that there is no conflict with reserved words.  The suffixes are:
   _i/_o for ports
   _reg for register
   However, it is supposed that the user name is valid and unique according to
   the HDL.  So for VHDL generation, it must be unique using case insensitive
   comparaison.
   The _i/_o suffixes are also used for ports, so the ports of the bus can
   also have conflicts with user names.
"""
from hdltree import (HDLModule,
                     HDLPort, HDLSignal,
                     HDLAssign, HDLSync, HDLComment,
                     HDLSwitch, HDLChoiceExpr, HDLChoiceDefault, HDLIfElse,
                     bit_1, bit_0, bit_x,
                     HDLAnd, HDLOr, HDLNot, HDLEq,
                     HDLSlice, HDLReplicate,
                     HDLConst)
import tree
from layout import ilog2


def expand_wishbone(module, root):
    """Create wishbone interface."""
    bus = [('rst',   HDLPort("rst_n_i")),
           ('clk',   HDLPort("clk_i")),
           ('adr',   HDLPort("wb_adr_i", root.c_sel_bits + root.c_blk_bits)),
           ('dati',  HDLPort("wb_dat_i", root.c_word_bits)),
           ('dato',  HDLPort("wb_dat_o", root.c_word_bits, dir='OUT')),
           ('cyc',   HDLPort("wb_cyc_i")),
           ('sel',   HDLPort("wb_sel_i", root.c_word_size)),
           ('stb',   HDLPort("wb_stb_i")),
           ('we',    HDLPort("wb_we_i")),
           ('ack',   HDLPort("wb_ack_o", dir='OUT')),
           ('stall', HDLPort("wb_stall_o", dir='OUT'))]

    root.h_bus = {}
    for n, h in bus:
        module.ports.append(h)
        root.h_bus[n] = h


def add_ports(module, prefix, node):
    """Create ports for a composite node."""
    for n in node.elements:
        if isinstance(n, tree.CompositeNode):
            add_ports(module, prefix + n.name + '_', n)
        elif isinstance(n, tree.Reg):
            if n.access in ['wo', 'rw']:
                suf = '_o'
                dr = 'OUT'
            elif n.access in ['ro']:
                suf = '_i'
                dr = 'IN'
            elif n.access in ['cst']:
                # No port needed
                continue
            else:
                assert False

            def _create_port(b, w):
                b.h_port = HDLPort(prefix + b.name + suf, w, dir=dr)
                b.h_port.comment = b.description
                module.ports.append(b.h_port)
                if dr == 'OUT':
                    b.h_reg = HDLSignal(prefix + b.name + '_reg', w)
                    module.signals.append(b.h_reg)
                else:
                    b.h_reg = None

            if n.fields:
                for f in n.fields:
                    w = None if f.c_width == 1 else f.c_width
                    _create_port(f, w)
            else:
                _create_port(n, n.c_width)
        else:
            assert False


def add_init(stmts, node):
    """Create assignment for reset values."""
    for n in node.elements:
        if isinstance(n, tree.CompositeNode):
            add_init(stmts, n)
        elif isinstance(n, tree.Reg):
            if n.access not in ['wo', 'rw']:
                # No registers.  Check h_reg instead ?
                continue
            if n.fields:
                for f in n.fields:
                    if f.preset is None:
                        v = 0
                    else:
                        v = f.preset
                    stmts.append(HDLAssign(f.h_reg, HDLConst(v, f.c_width)))
            else:
                # Preset for regs ?
                stmts.append(HDLAssign(f.h_reg, HDLConst(0, f.c_width)))
        else:
            assert False


def wire_regs(stmts, node):
    """Create assignment from register to outputs."""
    for n in node.elements:
        if isinstance(n, tree.CompositeNode):
            wire_regs(stmts, n)
        elif isinstance(n, tree.Reg):
            if n.fields:
                for f in n.fields:
                    if f.h_reg:
                        stmts.append(HDLAssign(f.h_port, f.h_reg))
            else:
                if n.h_reg:
                    stmts.append(HDLAssign(n.h_port, n.h_reg))
        else:
            assert False


def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    if n.c_sel_bits == 0:
        # Decode directly all the elements
        width = n.c_blk_bits - root.c_addr_word_bits
        if width == 0:
            for el in n.elements:
                func(stmts, el)
        else:
            sw = HDLSwitch(HDLSlice(addr, root.c_addr_word_bits, width))
            stmts.append(sw)
            for el in n.elements:
                ch = HDLChoiceExpr(
                    HDLConst(el.c_address >> root.c_addr_word_bits, width))
                sw.choices.append(ch)
                func(ch.stmts, el)
            ch = HDLChoiceDefault()
            sw.choices.append(ch)
            func(ch.stmts, None)
    else:
        # TODO
        assert False


class Params(object):
    pass


def generate_hdl(root):
    res = HDLModule()
    res.name = root.name

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE

    # Create the bus
    if root.bus == 'wb-32-be':
        expand_wishbone(res, root)
    else:
        assert False
    # Add ports
    add_ports(module=res, prefix='', node=root)
    # Bus access
    res.stmts.append(HDLComment('WB decode signals'))
    wb_en = HDLSignal('wb_en')
    rd_int = HDLSignal('rd_int')
    wr_int = HDLSignal('wr_int')
    ack_int = HDLSignal('ack_int')
    rd_ack = HDLSignal('rd_ack_int')
    wr_ack = HDLSignal('wr_ack_int')
    res.signals.extend([wb_en, rd_int, wr_int, ack_int, rd_ack, wr_ack])
    res.stmts.append(HDLAssign(wb_en,
                               HDLAnd(root.h_bus['cyc'], root.h_bus['stb'])))
    res.stmts.append(HDLAssign(rd_int,
                               HDLAnd(wb_en, HDLNot(root.h_bus['we']))))
    res.stmts.append(HDLAssign(wr_int,
                               HDLAnd(wb_en, root.h_bus['we'])))
    res.stmts.append(HDLAssign(ack_int, HDLOr(rd_ack, wr_ack)))
    res.stmts.append(HDLAssign(root.h_bus['ack'], ack_int))
    res.stmts.append(HDLAssign(root.h_bus['stall'],
                               HDLAnd(HDLNot(ack_int), wb_en)))

    res.stmts.append(HDLComment('Assign outputs'))
    wire_regs(res.stmts, root)

    # Register write
    res.stmts.append(HDLComment('Process to write registers.'))
    wrproc = HDLSync(root.h_bus['rst'], root.h_bus['clk'])
    res.stmts.append(wrproc)
    add_init(wrproc.rst_stmts, root)
    wr_if = HDLIfElse(HDLAnd(HDLEq(wr_int, bit_1), HDLEq(wr_ack, bit_0)))
    wrproc.sync_stmts.append(wr_if)
    wr_if.else_stmts.append(HDLAssign(wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write(s, n):
        if n is not None:
            if n.fields:
                for f in n.fields:
                    if f.h_reg is not None:
                        s.append(HDLAssign(f.h_reg, HDLSlice(wr_data,
                                                             f.lo, f.c_width)))
            else:
                if n.h_reg is not None:
                    s.append(HDLAssign(n.h_reg, wr_data))
        # All the write are ack'ed (including the write to unassigned
        # addresses)
        s.append(HDLAssign(wr_ack, bit_1))
    add_decoder(root, wr_if.then_stmts, root.h_bus['adr'], root, add_write)

    # Register read
    res.stmts.append(HDLComment('Process to read registers.'))
    wr_data = root.h_bus['dato']
    rdproc = HDLSync(root.h_bus['rst'], root.h_bus['clk'])
    res.stmts.append(rdproc)
    rdproc.rst_stmts.append(HDLAssign(rd_ack, bit_0))
    rdproc.rst_stmts.append(HDLAssign(wr_data,
                                      HDLReplicate(bit_x, root.c_word_bits)))
    rdproc.sync_stmts.append(HDLAssign(wr_data,
                                       HDLReplicate(bit_x, root.c_word_bits)))
    rd_if = HDLIfElse(HDLAnd(HDLEq(rd_int, bit_1), HDLEq(rd_ack, bit_0)))
    rdproc.sync_stmts.append(rd_if)
    rd_if.else_stmts.append(HDLAssign(rd_ack, bit_0))

    def add_read(s, n):
        if n is not None:
            if n.fields:
                for f in n.fields:
                    if f.h_reg is not None:
                        s.append(HDLAssign(HDLSlice(wr_data, f.lo, f.c_width),
                                           f.h_reg))
            else:
                if n.h_reg is not None:
                    s.append(HDLAssign(wr_data, n.h_reg))
        # All the read are ack'ed (including the read to unassigned addresses).
        s.append(HDLAssign(rd_ack, bit_1))

    add_decoder(root, rd_if.then_stmts, root.h_bus['adr'], root, add_read)

    # Generate ACK

    return res
