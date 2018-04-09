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
import parser
import tree
from layout import ilog2


class Isigs(object):
    "Internal signals"
    pass


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
        if isinstance(n, tree.Block):
            add_ports(module, prefix + n.name + '_', n)
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            if n.access in ['wo', 'rw']:
                suf = '_o'
                dr = 'OUT'
            elif n.access in ['ro', 'cst']:
                suf = '_i'
                dr = 'IN'
            else:
                raise AssertionError

            def _create_port(b, w):
                if n.access != 'cst':
                    name = pfx + b.name + suf
                    b.h_port = HDLPort(name.lower(), w, dir=dr)
                    b.h_port.comment = b.description
                    module.ports.append(b.h_port)
                if n.access in ['wo', 'rw'] and n.hdl_type == 'reg':
                    name = pfx + b.name + '_reg'
                    b.h_reg = HDLSignal(name.lower(), w)
                    module.signals.append(b.h_reg)
                else:
                    b.h_reg = None

            if n.fields:
                pfx = prefix + n.name + '_'
                for f in n.fields:
                    w = None if f.c_width == 1 else f.c_width
                    _create_port(f, w)
            else:
                pfx = prefix
                _create_port(n, n.width)
        else:
            raise AssertionError


def add_init(stmts, node):
    """Create assignment for reset values."""

    def add_init_field(f):
        if f.h_reg is not None:
            if f.preset is None:
                v = 0
            else:
                v = f.preset
            stmts.append(HDLAssign(f.h_reg, HDLConst(v, f.c_width)))

    for n in node.elements:
        if isinstance(n, tree.Block):
            add_init(stmts, n)
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            if n.fields:
                for f in n.fields:
                    add_init_field(f)
            else:
                add_init_field(n)
        else:
            raise AssertionError


def wire_regs(stmts, node):
    """Create assignment from register to outputs."""
    def wire_regs_field(f):
        if f.h_reg:
            stmts.append(HDLAssign(f.h_port, f.h_reg))

    for n in node.elements:
        if isinstance(n, tree.Block):
            wire_regs(stmts, n)
        if isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            if n.fields:
                for f in n.fields:
                    wire_regs_field(f)
            else:
                wire_regs_field(n)
        else:
            raise AssertionError


def add_reg_decoder(root, stmts, addr, func, els, blk_bits):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    # Decode directly all the elements
    width = blk_bits - root.c_addr_word_bits
    if width == 0:
        assert len(els) <= 1
        for el in els:
            func(stmts, el)
    else:
        sw = HDLSwitch(HDLSlice(addr, root.c_addr_word_bits, width))
        stmts.append(sw)
        for el in els:
            cstmts = []
            func(cstmts, el)
            if cstmts:
                # Only create the choice is there are statements.
                ch = HDLChoiceExpr(
                    HDLConst(el.c_address >> root.c_addr_word_bits, width))
                sw.choices.append(ch)
                ch.stmts = cstmts
        ch = HDLChoiceDefault()
        sw.choices.append(ch)
        func(ch.stmts, None)

def add_block_decoder(root, stmts, addr, func, n):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
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
                func(ch.stmts, el)
            elif isinstance(el[0], tree.Reg):
                # FIXME: compute the minimal subblocks_bits
                add_reg_decoder(root, ch.stmts, addr, func, el, subblocks_bits)
            else:
                raise AssertionError
    ch = HDLChoiceDefault()
    sw.choices.append(ch)
    func(ch.stmts, None)

def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding elements."""
    if n.c_sel_bits == 0:
        add_reg_decoder(root, stmts, addr, func, n.elements, n.c_blk_bits)
    else:
        add_block_decoder(root, stmts, addr, func, n)


def add_decode_wb(root, module, isigs):
    "Generate internal signals used by decoder/processes from WB bus."
    isigs.wb_en = HDLSignal('wb_en')
    isigs.rd_int = HDLSignal('rd_int')        # Read access
    isigs.wr_int = HDLSignal('wr_int')        # Write access
    isigs.ack_int = HDLSignal('ack_int')      # Ack
    isigs.rd_ack = HDLSignal('rd_ack_int')    # Ack for read
    isigs.wr_ack = HDLSignal('wr_ack_int')    # Ack for write
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


def add_read_process(root, module, isigs):
    # Register read
    rd_data = root.h_bus['dato']
    rdproc = HDLSync(root.h_bus['rst'], root.h_bus['clk'])
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

    def add_read_reg(s, n):
        def sel_input(t):
            "Where to read data from."
            if n.access in ['wo', 'rw']:
                return t.h_reg
            elif n.access == 'ro':
                return t.h_port
            elif n.access == 'cst':
                return HDLConst(t.preset, t.c_width)
            else:
                raise AssertionError
        if n.fields:
            for f in n.fields:
                src = sel_input(f)
                assert src is not None
                s.append(HDLAssign(
                    HDLSlice(rd_data, f.lo, f.c_width), src))
        else:
            src = sel_input(n)
            if n.width == root.c_word_bits:
                dat = rd_data
            else:
                dat = HDLSlice(rd_data, 0, n.width)
            s.append(HDLAssign(dat, src))
    def add_read(s, n):
        if n is not None:
            if isinstance(n, tree.Reg):
                if n.access == 'wo':
                    return
                else:
                    s.append(HDLComment(n.name))
                    add_read_reg(s, n)
            else:
                s.append(HDLComment("TODO"))
        # All the read are ack'ed (including the read to unassigned addresses).
        s.append(HDLAssign(isigs.rd_ack, bit_1))

    add_decoder(root, rd_if.then_stmts, root.h_bus['adr'], root, add_read)


def add_write_process(root, module, isigs):
    # Register write
    wrproc = HDLSync(root.h_bus['rst'], root.h_bus['clk'])
    module.stmts.append(wrproc)
    add_init(wrproc.rst_stmts, root)
    wr_if = HDLIfElse(HDLAnd(HDLEq(isigs.wr_int, bit_1),
                             HDLEq(isigs.wr_ack, bit_0)))
    wrproc.sync_stmts.append(wr_if)
    wr_if.else_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write_reg(s, n):
        if n.fields:
            for f in n.fields:
                if f.hdl_type == 'reg':
                    r = f.h_reg
                elif f.hdl_type == 'wire':
                    r = f.h_port
                else:
                    raise AssertionError
                s.append(HDLAssign(r, HDLSlice(wr_data, f.lo, f.c_width)))
        else:
            if n.hdl_type == 'reg':
                r = n.h_reg
            elif n.hdl_type == 'wire':
                r = n.h_port
            else:
                raise AssertionError
            if n.width == root.c_word_bits:
                dat = wr_data
            else:
                dat = HDLSlice(wr_data, 0, n.width)
            s.append(HDLAssign(r, dat))

    def add_write(s, n):
        if n is not None:
            if isinstance(n, tree.Reg):
                if n.access in ['ro', 'cst']:
                    return
                else:
                    s.append(HDLComment(n.name))
                    add_write_reg(s, n)
            else:
                s.append(HDLComment("TODO"))
        # All the write are ack'ed (including the write to unassigned
        # addresses)
        s.append(HDLAssign(isigs.wr_ack, bit_1))
    add_decoder(root, wr_if.then_stmts, root.h_bus['adr'], root, add_write)


def expand_x_hdl(n):
    "Decode x-hdl extensions"
    x_hdl = getattr(n, 'x_hdl', {})
    if isinstance(n, tree.Reg) or isinstance(n, tree.Field):
        # Default values
        n.hdl_type = 'reg'
        n.hdl_write_strobe = False

        for k, v in x_hdl.iteritems():
            if k == 'type':
                n.hdl_type = parser.read_text(n, k, v)
            elif k == 'write-strobe':
                n.hdl_write_strobe = parser.read_bool(n, k, v)
            else:
                parser.error("unhandled '{}' in x-hdl of {}".format(
                      k, n.get_path()))
    # Visite children
    if isinstance(n, tree.CompositeNode):
        for el in n.elements:
            expand_x_hdl(el)
    elif isinstance(n, tree.Reg):
        for f in n.fields:
            expand_x_hdl(f)


def generate_hdl(root):
    module = HDLModule()
    module.name = root.name

    # Decode x-hdl
    expand_x_hdl(root)

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE

    # Create the bus
    if root.bus == 'wb-32-be':
        expand_wishbone(module, root)
    else:
        raise AssertionError
    # Add ports
    add_ports(module=module, prefix=root.name.lower() + '_', node=root)

    isigs = Isigs()

    # Bus access
    module.stmts.append(HDLComment('WB decode signals'))
    add_decode_wb(root, module, isigs)

    module.stmts.append(HDLComment('Assign outputs'))
    wire_regs(module.stmts, root)

    module.stmts.append(HDLComment('Process to write registers.'))
    add_write_process(root, module, isigs)

    module.stmts.append(HDLComment('Process to read registers.'))
    add_read_process(root, module, isigs)

    return module
