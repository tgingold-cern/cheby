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
from cheby.hdltree import (HDLModule, HDLPackage,
                           HDLInterface, HDLInterfaceSelect,
                           HDLPort, HDLSignal,
                           HDLAssign, HDLSync, HDLComment,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLIfElse,
                           bit_1, bit_0, bit_x,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLReplicate, Slice_or_Index,
                           HDLConst)
import cheby.tree as tree
from cheby.layout import ilog2

# Package wishbone_pkg that contains the wishbone interface
wb_pkg = None
wb_itf = None
wb_ports = None

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
    module.decls.extend([isigs.wb_en, isigs.rd_int, isigs.wr_int,
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

def gen_wishbone_bus(build_port, addr_bits, data_bits, comment=None,
                     is_master=False):
    res = {}
    inp, out = ('IN', 'OUT') if not is_master else ('OUT', 'IN')
    res['cyc'] = build_port('cyc', None, dir=inp)
    res['cyc'].comment = comment
    res['stb'] = build_port('stb', None, dir=inp)
    if addr_bits > 0:
        res['adr'] = build_port('adr', addr_bits, dir=inp)
    res['sel'] = build_port('sel', data_bits / tree.BYTE_SIZE, dir=inp)
    res['we'] = build_port('we', None, dir=inp)
    res['dati'] = build_port('dat', data_bits, dir=inp)

    res['ack'] = build_port('ack', None, dir=out)
    res['err'] = build_port('err', None, dir=out)
    res['rty'] = build_port('rty', None, dir=out)
    res['stall'] = build_port('stall', None, dir=out)
    res['dato'] = build_port('dat', data_bits, dir=out)
    return res

def gen_wishbone(module, ports, name, addr_bits, data_bits, comment,
                 is_master, is_bus):
    if is_bus:
        if wb_pkg is None:
            gen_wishbone_pkg()
            module.deps.append(('work', 'wishbone_pkg'))
        port = ports.add_port_group(name, wb_itf, is_master)
        port.comment = comment
        res = {}
        for name, sig in wb_ports.items():
            res[name] = HDLInterfaceSelect(port, sig)
        return res
    else:
        dirname={'IN': 'i', 'OUT': 'o'}
        res = gen_wishbone_bus(
            lambda n, sz, dir: ports.add_port(
                '{}_{}_{}'.format(name, n , dirname[dir]), size=sz, dir=dir),
            addr_bits, data_bits, comment, is_master)
        return res

def gen_wishbone_pkg():
    global wb_pkg, wb_ports, wb_itf
    if wb_pkg is not None:
        return
    wb_pkg = HDLPackage('wishbone_pkg')
    wb_itf = HDLInterface('t_wishbone')
    wb_pkg.decls.append(wb_itf)
    wb_ports = gen_wishbone_bus(
        lambda n, sz, dir: wb_itf.add_port(n, size=sz, dir=dir), 32, 32, True)
    return


def expand_wishbone(root, module, isigs):
    """Create wishbone interface."""
    root.h_bus = {}
    root.h_bus['rst'] = module.add_port('rst_n_i')
    root.h_bus['clk'] = module.add_port('clk_i')

    busgroup = root.get_extension('x_hdl', 'busgroup')

    addr_bits = root.c_sel_bits + root.c_blk_bits - root.c_addr_word_bits

    root.h_bus.update(
        gen_wishbone(module, module, 'wb', addr_bits, root.c_word_bits,
                     None, False, busgroup is True))
    root.h_bussplit = False

    if isigs:
        # Bus access
        module.stmts.append(HDLComment('WB decode signals'))
        add_decode_wb(root, module, isigs)


def add_decode_cern_be_vme(root, module, isigs):
    "Generate internal signals used by decoder/processes from CERN-BE-VME bus."
    isigs.rd_int = root.h_bus['rd']
    isigs.wr_int = root.h_bus['wr']
    isigs.rd_ack = HDLSignal('rd_ack_int')    # Ack for read
    isigs.wr_ack = HDLSignal('wr_ack_int')    # Ack for write
    module.decls.extend([isigs.rd_ack, isigs.wr_ack])
    module.stmts.append(HDLAssign(root.h_bus['rack'], isigs.rd_ack))
    module.stmts.append(HDLAssign(root.h_bus['wack'], isigs.wr_ack))


def expand_cern_be_vme(root, module, isigs, buserr, split):
    """Create CERN-BE interface."""
    bus = [('clk',   HDLPort("Clk")),
           ('rst',   HDLPort("Rst"))]
    addr_width = root.c_sel_bits + root.c_blk_bits - root.c_addr_word_bits
    if split:
        bus.extend(
            [('adro',   HDLPort("VMERdAddr", addr_width, lo_idx=root.c_addr_word_bits)),
             ('adri',   HDLPort("VMEWrAddr", addr_width, lo_idx=root.c_addr_word_bits))])
    else:
        bus.extend(
            [('adr',   HDLPort("VMEAddr", addr_width, lo_idx=root.c_addr_word_bits))])
    bus.extend(
        [('dato',  HDLPort("VMERdData", root.c_word_bits, dir='OUT')),
         ('dati',  HDLPort("VMEWrData", root.c_word_bits)),
         ('rd',    HDLPort("VMERdMem")),
         ('wr',    HDLPort("VMEWrMem")),
         ('rack',  HDLPort("VMERdDone", dir='OUT')),
         ('wack',  HDLPort("VMEWrDone", dir='OUT'))])
    if buserr:
        bus.extend([('rderr', HDLPort('VMERdError', dir='OUT')),
                    ('wrerr', HDLPort('VMEWrError', dir='OUT'))])
    add_bus(root, module, bus)

    root.h_bussplit = split
    if not split:
        root.h_bus['adro'] = root.h_bus['adr']
        root.h_bus['adri'] = root.h_bus['adr']

    if isigs:
        add_decode_cern_be_vme(root, module, isigs)

def make_port_name_simple(el, suffix, di):
    if isinstance(el, tree.Field):
        return '{}_{}'.format(el._parent.name, el.name)
    else:
        return el.name

def make_port_name_prefix(el, suffix, di):
    if suffix:
        pfx = '_' + suffix
    else:
        pfx = ''
    l = el
    while l._parent is not None:
        pfx = (('_'+ l.name) if l.name else '') + pfx
        l = l._parent

    if di:
        return pfx[1:] + '_' + di
    else:
        return pfx[1:]

def add_ports_reg(root, module, n):
    for f in n.children:
        w = None if f.c_iowidth == 1 else f.c_iowidth

        # Input
        if f.hdl_type == 'wire' and n.access in ['ro', 'rw']:
            f.h_iport = root.h_ports.add_port(
                root.h_make_port_name(f, None, 'i'), w, dir='IN')
            f.h_iport.comment = f.description
        else:
            f.h_iport = None

        # Output
        if n.access in ['wo', 'rw']:
            f.h_oport = root.h_ports.add_port(
                root.h_make_port_name(f, None, 'o'), w, dir='OUT')
            f.h_oport.comment = f.description
        else:
            f.h_oport = None

        # Write strobe
        if f.hdl_write_strobe:
            f.h_wport = root.h_ports.add_port(
                root.h_make_port_name(f, 'wr', 'o'), None, dir='OUT')
        else:
            f.h_wport = None

        # Register
        if f.hdl_type == 'reg':
            f.h_reg = HDLSignal(root.h_make_port_name(f, 'reg', None), w)
            module.decls.append(f.h_reg)
        else:
            f.h_reg = None

def gen_bus_slave_wb32(root, module, decls, name, comment, busgroup):
    return gen_wishbone(module, decls, name, 32, root.c_word_bits, comment,
                        True, busgroup is True)

def wire_bus_slave_wb32(root, stmts, n):
    stmts.append(HDLComment("Assignments for submap {}".format(n.name)))
    stmts.append(HDLAssign(n.h_bus['cyc'], HDLOr(n.h_wr, n.h_rd)))
    stmts.append(HDLAssign(n.h_bus['stb'], HDLOr(n.h_wr, n.h_rd)))
    stmts.append(HDLAssign(n.h_bus['adr'], root.h_bus['adr']))
    stmts.append(HDLAssign(n.h_bus['sel'], HDLReplicate(bit_1, 4)))
    stmts.append(HDLAssign(n.h_bus['we'], n.h_wr))
    stmts.append(HDLAssign(n.h_bus['dato'], root.h_bus['dati']))

def gen_bus_slave_sram(root, prefix, n):
    name = prefix + n.name + '_addr_o'
    n.h_addr_o = root.h_ports.add_port(
        name.lower(), n.c_blk_bits - root.c_addr_word_bits, dir='OUT')
    n.h_addr_o.comment = n.description

    name = prefix + n.name + '_data_i'
    n.h_data_i = root.h_ports.add_port(name.lower(), n.c_width, dir='IN')

    name = prefix + n.name + '_data_o'
    n.h_data_o = root.h_ports.add_port(name.lower(), n.c_width, dir='OUT')

    name = prefix + n.name + '_wr_o'
    n.h_wr_o = root.h_ports.add_port(name.lower(), None, dir='OUT')

def wire_bus_slave_sram(root, stmts, n):
    stmts.append(HDLAssign(n.h_data_o, root.h_bus['dati']))
    stmts.append(HDLAssign(n.h_addr_o,
                 HDLSlice(root.h_bus['adr'],
                          root.c_addr_word_bits,
                          n.c_blk_bits - root.c_addr_word_bits)))

def gen_bus_slave(root, module, prefix, n, interface):
    busgroup = n.get_extension('x_hdl', 'busgroup')
    if interface == 'wb-32-be':
        n.h_bus = gen_bus_slave_wb32(
            root, module, module, n.name, n.description, busgroup)
        # Internal signals
        n.h_wr = HDLSignal(prefix + 'wr')
        module.decls.append(n.h_wr)
        n.h_rd = HDLSignal(prefix + 'rd')
        module.decls.append(n.h_rd)
    elif interface == 'sram':
        n.h_bus = {}
        gen_bus_slave_sram(root, prefix, n)
    else:
        raise AssertionError(interface)


def add_ports_submap(root, module, prefix, n):
    if True:
        npfx = n.name + '_'
    else:
        npfx = prefix + n.name + '_'
    if n.filename is not None and n.interface == 'include':
        # Inline
        add_ports(root, module, npfx, n.c_submap)
    else:
        gen_bus_slave(root, module, npfx, n, n.interface)


def wire_submap(root, module, n, stmts):
    if n.interface == 'wb-32-be':
        wire_bus_slave_wb32(root, stmts, n)
    elif n.interface == 'sram':
        wire_bus_slave_sram(root, stmts, n)
    else:
        raise AssertionError(n.interface)


def add_ports(root, module, prefix, node):
    """Create ports for a composite node."""
    for n in node.children:
        if isinstance(n, tree.Block):
            if n.children:
                # Recurse
                add_ports(root, module, prefix + n.name + '_', n)
        elif isinstance(n, tree.Submap):
            # Interface
            add_ports_submap(root, module, prefix, n)
        elif isinstance(n, tree.Array):
            # TODO
            raise AssertionError
        elif isinstance(n, tree.Reg):
            add_ports_reg(root, module, n)
        else:
            raise AssertionError


def wire_regs(root, module, isigs, node):
    """Create assignment from register to outputs."""
    stmts = module.stmts
    for n in node.children:
        if isinstance(n, tree.Block):
            wire_regs(root, module, isigs, n)
        elif isinstance(n, tree.Submap):
            if n.interface == 'include':
                wire_regs(root, module, isigs, n.c_submap)
            else:
                wire_submap(root, module, n, stmts)
        elif isinstance(n, tree.Array):
            pass
        elif isinstance(n, tree.Reg):
            for f in n.children:
                if f.h_reg is not None and f.h_oport is not None:
                    stmts.append(HDLAssign(f.h_oport, f.h_reg))
        else:
            raise AssertionError


def add_reg_decoder(root, stmts, addr, func, els, blk_bits):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding children."""
    # Decode directly all the children
    width = blk_bits - root.c_addr_word_bits
    if width == 0:
        # There is only one register, handle it directly
        assert len(els) <= 1
        for el in els:
            func(stmts, el, 0)
    else:
        sw = HDLSwitch(HDLSlice(addr, 0, width))
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

def gather_children(n):
    if isinstance(n, tree.Reg):
        return [n]
    elif isinstance(n, tree.Submap):
        if n.interface == 'include':
            return gather_children(n.c_submap)
        else:
            return [n]
    elif isinstance(n, (tree.Root, tree.ComplexNode)):
        r = []
        for e in n.children:
            r.extend(gather_children(e))
        return r
        return reduce((lambda x, y: x.extend(y)),
                      [gather_children(i) for i in n.children])
    else:
        raise AssertionError

def add_block_decoder(root, stmts, addr, children, hi, func):
    if False:
        print("add_block_decoder: hi={}".format(hi))
        for i in children:
            print("{}: {:08x}".format(i.name, i.c_address))
        print("----")
    if len(children) == 1:
        el = children[0]
        if isinstance(el, tree.Reg):
            add_reg_decoder(root, stmts, addr, func, children, hi)
        else:
            func(stmts, el, 0)
        return

    maxsz = max([e.c_size for e in children])
    maxszl2 = ilog2(maxsz)
    assert maxsz == 1 << maxszl2
    mask = (1 << hi) - maxsz
    assert maxszl2 < hi

    # Note: addr has a word granularity.
    sw = HDLSwitch(HDLSlice(addr, maxszl2 - root.c_addr_word_bits, hi - maxszl2))
    stmts.append(sw)

    while len(children) > 0:
        first = children[0]
        children = children[1:]
        l = [first]
        base = first.c_address & mask
        if False:
            print("hi={} szl2={} first: {:08x}, base: {:08x}, mask: {:08x}".format(
                hi, maxszl2, first.c_address, base, mask))
        while len(children) > 0:
            el = children[0]
            if (el.c_address & mask) != base:
                break
            if False:
                print(" {} c_addr={:08x}".format(el.name, el.c_address))
            l.append(el)
            children = children[1:]

        ch = HDLChoiceExpr(HDLConst(base >> maxszl2, hi - maxszl2))
        sw.choices.append(ch)
        add_block_decoder(root, ch.stmts, addr, l, maxszl2, func)


def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding children."""
    children = gather_children(root)
    children = sorted(children, key=lambda x: x.c_address)

    add_block_decoder(
        root, stmts, addr, children, root.c_sel_bits + root.c_blk_bits, func)


def field_decode(root, reg, f, off, val, dat):
    """Handle multi-word accesses.  Slice (if needed) VAL and DAT for offset
       OFF and field F or register REG."""
    # Register and value bounds
    d_lo = f.lo
    d_hi = f.lo + f.c_rwidth - 1
    v_lo = 0
    v_hi = f.c_rwidth - 1
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
        dat = Slice_or_Index(dat, d_lo, d_hi - d_lo + 1)
    if v_hi == f.c_rwidth - 1 and v_lo == 0:
        pass
    else:
        val = Slice_or_Index(val, v_lo, v_hi - v_lo + 1)
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
        for f in n.children:
            if n.access in ['wo', 'rw']:
                src = f.h_reg
            elif n.access == 'ro':
                src = f.h_iport
            elif n.access == 'cst':
                src = HDLConst(f.preset, f.c_rwidth)
            else:
                raise AssertionError
            reg, dat = field_decode(root, n, f, off, src, rd_data)
            if reg is None:
                continue
            s.append(HDLAssign(dat, reg))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.name))
                if n.access != 'wo':
                    add_read_reg(s, n, off)
            elif isinstance(n, tree.Block):
                raise AssertionError
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.name)))
                if n.interface == 'wb-32-be':
                    s.append(HDLAssign(rd_data, n.h_bus['dati']))
                    rdproc.rst_stmts.append(HDLAssign(n.h_rd, bit_0))
                    rd_if.then_stmts.append(HDLAssign(n.h_rd, bit_0))
                    s.append(HDLAssign(n.h_rd, bit_1))
                    s.append(HDLAssign(isigs.rd_ack, n.h_bus['ack']))
                    return
                elif n.interface == 'sram':
                    return
                else:
                    raise AssertionError
            else:
                s.append(HDLComment("TODO: ??"))  # Array ?
        # All the read are ack'ed (including the read to unassigned addresses).
        s.append(HDLAssign(isigs.rd_ack, bit_1))

    then_stmts = []
    add_decoder(root, then_stmts, root.h_bus.get('adr', None), root, add_read)
    rd_if.then_stmts.extend(then_stmts)


def add_write_process(root, module, isigs):
    # Register write
    wrproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(wrproc)
    wr_if = HDLIfElse(HDLAnd(HDLEq(isigs.wr_int, bit_1),
                             HDLEq(isigs.wr_ack, bit_0)))
    wr_if.else_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write_reg(s, n, off):
        for f in n.children:
            # Reset code
            if f.h_reg is not None:
                v = 0 if f.preset is None else f.preset
                wrproc.rst_stmts.append(HDLAssign(f.h_reg, HDLConst(v, f.c_rwidth)))
            # Assign code
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
                wrproc.rst_stmts.append(HDLAssign(f.h_wport, bit_0))
                wrproc.sync_stmts.append(HDLAssign(f.h_wport, bit_0))


    def add_write(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.name))
                if n.access in ['wo', 'rw']:
                    add_write_reg(s, n, off)
            elif isinstance(n, tree.Block):
                raise AssertionError
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.name)))
                if n.interface == 'wb-32-be':
                    wrproc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
                    wr_if.then_stmts.append(HDLAssign(n.h_wr, bit_0))
                    s.append(HDLAssign(n.h_wr, bit_1))
                    s.append(HDLAssign(isigs.rd_ack, n.h_bus['ack']))
                    return
                elif n.interface == 'sram':
                    s.append(HDLAssign(n.h_wr_o, bit_1))
                    return
                else:
                    raise AssertionError
            else:
                s.append(HDLComment("TODO: ??"))  # Array ?
        # All the write are ack'ed (including the write to unassigned
        # addresses)
        s.append(HDLAssign(isigs.wr_ack, bit_1))
    then_stmts = []
    add_decoder(root, then_stmts, root.h_bus.get('adr', None), root, add_write)
    wr_if.then_stmts.extend(then_stmts)
    wrproc.sync_stmts.append(wr_if)


def gen_hdl_header(root, isigs=None):
    module = HDLModule()
    module.name = root.name

    # Number of bits in the address used by a word
    root.c_addr_word_bits = ilog2(root.c_word_size)
    # Number of bits in a word
    root.c_word_bits = root.c_word_size * tree.BYTE_SIZE

    # Create the bus
    if root.bus == 'wb-32-be':
        root.h_make_port_name = make_port_name_prefix
        expand_wishbone(root, module, isigs)
    elif root.bus.startswith('cern-be-vme-'):
        names = root.bus[12:].split('-')
        err = names[0] == 'err'
        if err:
            del names[0]
        split = names[0] == 'split'
        if split:
            del names[0]
        assert len(names) == 1
        root.h_make_port_name = make_port_name_simple
        expand_cern_be_vme(root, module, isigs, err, split)
    else:
        raise HdlError("Unhandled bus '{}'".format(root.bus))

    return module


def generate_hdl(root):
    isigs = Isigs()

    module = gen_hdl_header(root, isigs)

    # Add ports
    iogroup = root.get_extension('x_hdl', 'iogroup')
    if iogroup is not None:
        grp = module.add_port_group(iogroup)
        grp.comment = 'Wires and registers'
        root.h_ports = grp
    else:
        root.h_ports = module
    add_ports(root, module, root.name.lower() + '_', root)

    module.stmts.append(HDLComment('Assign outputs'))
    wire_regs(root, module, isigs, root)

    module.stmts.append(HDLComment('Process for write requests.'))
    add_write_process(root, module, isigs)

    module.stmts.append(HDLComment('Process for read requests.'))
    add_read_process(root, module, isigs)

    return module
