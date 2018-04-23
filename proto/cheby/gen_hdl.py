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
import expand_hdl
from layout import ilog2


class HdlError(Exception):
    def __init__(self, msg):
        self.msg = msg


class Isigs(object):
    "Internal signals"
    pass


def add_bus(root, module, bus):
    root.h_bus = {}
    for n, h in bus:
        module.ports.append(h)
        root.h_bus[n] = h


def add_decode_wb(root, module, isigs):
    "Generate internal signals used by decoder/processes from WB bus."
    isigs.rd_int = HDLSignal('rd_int')        # Read access
    isigs.wr_int = HDLSignal('wr_int')        # Write access
    isigs.rd_ack = HDLSignal('rd_ack_int')    # Ack for read
    isigs.wr_ack = HDLSignal('wr_ack_int')    # Ack for write
    # Internal signals for wb.
    isigs.wb_en = HDLSignal('wb_en')
    isigs.ack_int = HDLSignal('ack_int')      # Ack
    module.signals.extend([isigs.wb_en, isigs.rd_int, isigs.wr_int,
                           isigs.ack_int, isigs.rd_ack, isigs.wr_ack])
    module.stmts.append(
        HDLAssign(isigs.wb_en, HDLAnd(root.h_bus['cyc'], root.h_bus['stb'])))
    module.stmts.append(
        HDLAssign(isigs.rd_int, HDLAnd(isigs.wb_en, HDLNot(root.h_bus['we']))))
    module.stmts.append(
        HDLAssign(isigs.wr_int, HDLAnd(isigs.wb_en, root.h_bus['we'])))
    module.stmts.append(HDLAssign(isigs.ack_int,
                                  HDLOr(isigs.rd_ack, isigs.wr_ack)))
    module.stmts.append(HDLAssign(root.h_bus['ack'], isigs.ack_int))
    module.stmts.append(HDLAssign(root.h_bus['stall'],
                                  HDLAnd(HDLNot(isigs.ack_int), isigs.wb_en)))


def expand_wishbone(root, module, isigs):
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
    add_bus(root, module, bus)

    # Bus access
    module.stmts.append(HDLComment('WB decode signals'))
    add_decode_wb(root, module, isigs)


def add_decode_cern_be_vme(root, module, isigs):
    "Generate internal signals used by decoder/processes from CERN-BE-VME bus."
    isigs.rd_int = root.h_bus['rd']
    isigs.wr_int = root.h_bus['wr']
    isigs.rd_ack = HDLSignal('rd_ack_int')    # Ack for read
    isigs.wr_ack = HDLSignal('wr_ack_int')    # Ack for write
    module.signals.extend([isigs.rd_ack, isigs.wr_ack])
    module.stmts.append(HDLAssign(root.h_bus['rack'], isigs.rd_ack))
    module.stmts.append(HDLAssign(root.h_bus['wack'], isigs.wr_ack))


def expand_cern_be_vme(root, module, isigs):
    """Create CERN-BE interface."""
    bus = [('clk',   HDLPort("Clk")),
           ('rst',   HDLPort("Rst")),
           ('adr',   HDLPort("VMEAddr", root.c_sel_bits + root.c_blk_bits)),
           ('dato',  HDLPort("VMERdData", root.c_word_bits, dir='OUT')),
           ('dati',  HDLPort("VMEWrData", root.c_word_bits)),
           ('rd',    HDLPort("VMERdMem")),
           ('wr',    HDLPort("VMEWrMem")),
           ('rack',  HDLPort("VMERdDone")),
           ('wack',  HDLPort("VMEWrDone"))]
    add_bus(root, module, bus)

    add_decode_cern_be_vme(root, module, isigs)


def add_ports_reg(module, prefix, n):
    if n.c_type is None:
        pfx = prefix + n.name + '_'
    else:
        pfx = prefix
    for f in n.fields:
        w = None if f.c_width == 1 else f.c_width

        # Input
        if f.hdl_type == 'wire' and n.access in ['ro', 'rw']:
            name = pfx + f.name + '_i'
            f.h_iport = HDLPort(name.lower(), w, dir='IN')
            f.h_iport.comment = f.description
            module.ports.append(f.h_iport)
        else:
            f.h_iport = None

        # Output
        if n.access in ['wo', 'rw']:
            name = pfx + f.name + '_o'
            f.h_oport = HDLPort(name.lower(), w, dir='OUT')
            f.h_oport.comment = f.description
            module.ports.append(f.h_oport)
        else:
            f.h_oport = None

        # Write strobe
        if f.hdl_write_strobe:
            name = pfx + f.name + '_wr_o'
            f.h_wport = HDLPort(name.lower(), None, dir='OUT')
            module.ports.append(f.h_wport)
        else:
            f.h_wport = None

        # Register
        if f.hdl_type == 'reg':
            name = pfx + f.name + '_reg'
            f.h_reg = HDLSignal(name.lower(), w)
            module.signals.append(f.h_reg)
        else:
            f.h_reg = None

def add_ports_block(root, module, prefix, n):
    assert n.interface is not None
    if n.interface == 'sram':
        name = prefix + n.name + '_addr_o'
        n.h_addr_o = HDLPort(
            name.lower(), n.c_blk_bits - root.c_addr_word_bits, dir='OUT')
        n.h_addr_o.comment = n.description
        module.ports.append(n.h_addr_o)

        name = prefix + n.name + '_data_i'
        n.h_data_i = HDLPort(name.lower(), n.c_width, dir='IN')
        module.ports.append(n.h_data_i)

        name = prefix + n.name + '_data_o'
        n.h_data_o = HDLPort(name.lower(), n.c_width, dir='OUT')
        module.ports.append(n.h_data_o)

        name = prefix + n.name + '_wr_o'
        n.h_wr_o = HDLPort(name.lower(), None, dir='OUT')
        module.ports.append(n.h_wr_o)
    else:
        raise AssertionError


def add_ports(root, module, prefix, node):
    """Create ports for a composite node."""
    for n in node.elements:
        if isinstance(n, tree.Block):
            if n.elements:
                # Recurse
                add_ports(root, module, prefix + n.name + '_', n)
            else:
                # Interface
                add_ports_block(root, module, prefix, n)
        elif isinstance(n, tree.Array):
            # TODO
            raise AssertionError
        elif isinstance(n, tree.Reg):
            add_ports_reg(module, prefix, n)
        else:
            raise AssertionError


def add_init_reg(stmts, node):
    """Create assignment for reset values."""

    for n in node.elements:
        if isinstance(n, tree.Block):
            add_init_reg(stmts, n)
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            for f in n.fields:
                if f.h_reg is not None:
                    if f.preset is None:
                        v = 0
                    else:
                        v = f.preset
                    stmts.append(HDLAssign(f.h_reg, HDLConst(v, f.c_width)))
        else:
            raise AssertionError


def add_clear_wstrobe(stmts, node):
    """Create assignment to clear the wstrobe."""

    for n in node.elements:
        if isinstance(n, tree.Block):
            if n.interface is None:
                add_clear_wstrobe(stmts, n)
            elif n.interface == 'sram':
                stmts.append(HDLAssign(n.h_wr_o, bit_0))
            else:
                raise AssertionError
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            for f in n.fields:
                if f.h_wport is not None:
                    stmts.append(HDLAssign(f.h_wport, bit_0))
        else:
            raise AssertionError


def wire_regs(root, module, isigs, node):
    """Create assignment from register to outputs."""
    stmts = module.stmts
    for n in node.elements:
        if isinstance(n, tree.Block):
            if n.interface is None:
                wire_regs(root, module, isigs, n)
            elif n.interface == 'sram':
                stmts.append(HDLAssign(n.h_data_o, root.h_bus['dati']))
                stmts.append(HDLAssign(n.h_addr_o,
                             HDLSlice(root.h_bus['adr'],
                                      root.c_addr_word_bits,
                                      n.c_blk_bits - root.c_addr_word_bits)))
                pass
            else:
                raise AssertionError
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            for f in n.fields:
                if f.h_reg is not None and f.h_oport is not None:
                    stmts.append(HDLAssign(f.h_oport, f.h_reg))
        else:
            raise AssertionError


def add_reg_decoder(root, stmts, addr, func, els, blk_bits):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    # Decode directly all the elements
    width = blk_bits - root.c_addr_word_bits
    if width == 0:
        # There is only one register, handle it directly
        assert len(els) <= 1
        for el in els:
            func(stmts, el, 0)
    else:
        sw = HDLSwitch(HDLSlice(addr, root.c_addr_word_bits, width))
        stmts.append(sw)
        for el in els:
            suboff = 0
            while suboff < el.c_size:
                cstmts = []
                if True:
                    # Big endian
                    foff = el.c_size - root.c_word_size - suboff
                else:
                    # Little endian
                    foff = suboff
                func(cstmts, el, foff * tree.BYTE_SIZE)
                if cstmts:
                    # Only create the choice is there are statements.
                    addr = el.c_address + suboff
                    ch = HDLChoiceExpr(
                        HDLConst(addr >> root.c_addr_word_bits, width))
                    sw.choices.append(ch)
                    ch.stmts = cstmts
                suboff += root.c_word_size
        ch = HDLChoiceDefault()
        sw.choices.append(ch)
        func(ch.stmts, None, 0)

def add_block_decoder(root, stmts, addr, func, n):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    # Block without elements: interface
    if not n.elements:
        func(stmts, n, 0)
        return

    if n.c_sel_bits == 0:
        # Only one selector level.
        # Either there is only one child, or only regs.
        el = n.elements[0]
        if isinstance(el, tree.Reg):
            add_reg_decoder(root, stmts, addr, func, n.elements, n.c_blk_bits)
            return
        assert len(n.elements) == 1
        if isinstance(el, tree.Array):
            func(stmts, el, 0)
        else:
            add_block_decoder(root, stmts, addr, func, n.elements[0])
        return

    # Put children into sub-blocks
    n_subblocks = 1 << n.c_sel_bits
    subblocks_bits = n.c_blk_bits
    subblocks = [None] * n_subblocks
    for i in range(n_subblocks):
        subblocks[i] = []
    for el in n.elements:
        idx = (el.c_address >> subblocks_bits) & (n_subblocks - 1)
        subblocks[idx].append(el)

    sw = HDLSwitch(HDLSlice(addr, subblocks_bits, n.c_sel_bits))
    stmts.append(sw)
    for i in range(n_subblocks):
        el = subblocks[i]
        if el:
            ch = HDLChoiceExpr(HDLConst(i, n.c_sel_bits))
            sw.choices.append(ch)
            if isinstance(el[0], tree.Block):
                assert len(el) == 1
                add_block_decoder(root, ch.stmts, addr, func, el[0])
            elif isinstance(el[0], tree.Array):
                assert len(el) == 1
                func(ch.stmts, el, 0)
            elif isinstance(el[0], tree.Reg):
                # FIXME: compute the minimal subblocks_bits
                add_reg_decoder(root, ch.stmts, addr, func, el, subblocks_bits)
            else:
                raise AssertionError
    ch = HDLChoiceDefault()
    sw.choices.append(ch)
    func(ch.stmts, None, 0)

def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    add_block_decoder(root, stmts, addr, func, n)


def field_decode(root, reg, f, off, val, dat):
    """Handle multi-word accesses.  Slice (if needed) VAL and DAT for offset
       OFF and field F or register REG."""
    # Register and value bounds
    d_lo = f.lo
    d_hi = f.lo + f.c_width - 1
    v_lo = 0
    v_hi = f.c_width - 1
    # Next field if not affected by this read.
    if d_hi < off:
        return (None, None)
    if d_lo >= off + root.c_word_bits:
        return (None, None)
    if d_lo < off:
        # Strip the part below OFF.
        delta = off - d_lo
        d_lo = off
        v_lo += delta
    # Set right boundaries
    d_lo -= off
    d_hi -= off
    if d_hi >= root.c_word_bits:
        delta = d_hi + 1 - root.c_word_bits
        d_hi = root.c_word_bits - 1
        v_hi -= delta

    if d_hi == root.c_word_bits - 1 and d_lo == 0:
        pass
    else:
        dat = HDLSlice(dat, d_lo, d_hi - d_lo + 1)
    if v_hi == f.c_width - 1 and v_lo == 0:
        pass
    else:
        val = HDLSlice(val, v_lo, v_hi - v_lo + 1)
    return (val, dat)


def add_read_process(root, module, isigs):
    # Register read
    rd_data = root.h_bus['dato']
    rdproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(rdproc)
    rdproc.rst_stmts.append(HDLAssign(isigs.rd_ack, bit_0))
    rdproc.rst_stmts.append(HDLAssign(rd_data,
                                      HDLReplicate(bit_x, root.c_word_bits)))
    rdproc.sync_stmts.append(HDLAssign(rd_data,
                                       HDLReplicate(bit_x, root.c_word_bits)))
    rd_if = HDLIfElse(HDLAnd(HDLEq(isigs.rd_int, bit_1),
                             HDLEq(isigs.rd_ack, bit_0)))
    rdproc.sync_stmts.append(rd_if)
    rd_if.else_stmts.append(HDLAssign(isigs.rd_ack, bit_0))

    def add_read_reg(s, n, off):
        for f in n.fields:
            if n.access in ['wo', 'rw']:
                src = f.h_reg
            elif n.access == 'ro':
                src = f.h_iport
            elif n.access == 'cst':
                src = HDLConst(f.preset, f.c_width)
            else:
                raise AssertionError
            reg, dat = field_decode(root, n, f, off, src, rd_data)
            if reg is None:
                continue
            s.append(HDLAssign(dat, reg))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                if n.access == 'wo':
                    return
                s.append(HDLComment(n.name))
                add_read_reg(s, n, off)
            elif isinstance(n, tree.Block):
                if n.interface == 'sram':
                    s.append(HDLAssign(rd_data, n.h_data_o))
                else:
                    raise AssertionError
            else:
                s.append(HDLComment("TODO"))
        # All the read are ack'ed (including the read to unassigned addresses).
        s.append(HDLAssign(isigs.rd_ack, bit_1))

    add_decoder(root, rd_if.then_stmts, root.h_bus['adr'], root, add_read)


def add_write_process(root, module, isigs):
    # Register write
    wrproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(wrproc)
    add_init_reg(wrproc.rst_stmts, root)
    add_clear_wstrobe(wrproc.rst_stmts, root)
    add_clear_wstrobe(wrproc.sync_stmts, root)
    wr_if = HDLIfElse(HDLAnd(HDLEq(isigs.wr_int, bit_1),
                             HDLEq(isigs.wr_ack, bit_0)))
    wrproc.sync_stmts.append(wr_if)
    wr_if.else_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write_sram(s, n):
        s.append(HDLAssign(n.h_wr_o, bit_1))

    def add_write_reg(s, n, off):
        for f in n.fields:
            if f.hdl_type == 'reg':
                r = f.h_reg
            elif f.hdl_type == 'wire':
                r = f.h_oport
            else:
                raise AssertionError
            reg, dat = field_decode(root, n, f, off, r, wr_data)
            if reg is None:
                continue
            s.append(HDLAssign(reg, dat))
            if f.h_wport is not None:
                s.append(HDLAssign(f.h_wport, bit_1))

    def add_write(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                if n.access in ['ro', 'cst']:
                    return
                else:
                    s.append(HDLComment(n.name))
                    add_write_reg(s, n, off)
            elif isinstance(n, tree.Block) and n.interface == 'sram':
                add_write_sram(s, n)
            else:
                s.append(HDLComment("TODO"))
        # All the write are ack'ed (including the write to unassigned
        # addresses)
        s.append(HDLAssign(isigs.wr_ack, bit_1))
    add_decoder(root, wr_if.then_stmts, root.h_bus['adr'], root, add_write)


def generate_hdl(root):
    module = HDLModule()
    module.name = root.name

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE

    isigs = Isigs()

    # Create the bus
    if root.bus == 'wb-32-be':
        expand_wishbone(root, module, isigs)
    elif root.bus == 'cern-be-vme-16':
        expand_cern_be_vme(root, module, isigs)
    else:
        raise HdlError("Unhandled bus '{}'".format(root.bus))

    # Add ports
    add_ports(root, module, root.name.lower() + '_', root)

    module.stmts.append(HDLComment('Assign outputs'))
    wire_regs(root, module, isigs, root)

    module.stmts.append(HDLComment('Process to write registers.'))
    add_write_process(root, module, isigs)

    module.stmts.append(HDLComment('Process to read registers.'))
    add_read_process(root, module, isigs)

    return module
