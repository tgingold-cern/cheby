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
                           HDLInterface, HDLInterfaceSelect, HDLInstance,
                           HDLPort, HDLSignal,
                           HDLAssign, HDLSync, HDLComb, HDLComment,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLIfElse,
                           bit_1, bit_0, bit_x,
                           HDLAnd, HDLOr, HDLNot, HDLEq,
                           HDLSlice, HDLReplicate, Slice_or_Index,
                           HDLConst, HDLNumber, HDLBool)
import cheby.tree as tree
from cheby.layout import ilog2

dirname = {'IN': 'i', 'OUT': 'o'}

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
        lambda n, sz, dir: wb_itf.add_port(n, size=sz, dir=dir), 32, 32, None, True)
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

def add_module_port(root, module, name, size, dir):
    if root.h_itf is None:
        return module.add_port(name + '_' + dirname[dir], size, dir=dir)
    else:
        p = root.h_itf.add_port(name, size, dir=dir)
        return HDLInterfaceSelect(root.h_ports, p)

def add_ports_reg(root, module, n):
    for f in n.children:
        w = None if f.c_iowidth == 1 else f.c_iowidth

        # Input
        if f.hdl_type == 'wire' and n.access in ['ro', 'rw']:
            f.h_iport = add_module_port(root, module, f.c_name, w, dir='IN')
            f.h_iport.comment = f.description
        else:
            f.h_iport = None

        # Output
        if n.access in ['wo', 'rw']:
            f.h_oport = add_module_port(root, module, f.c_name, w, dir='OUT')
            f.h_oport.comment = f.description
        else:
            f.h_oport = None

        # Write strobe
        if f.hdl_write_strobe:
            f.h_wport = add_module_port(
                root, module, f.c_name + '_wr', None, dir='OUT')
        else:
            f.h_wport = None

        # Register
        if f.hdl_type == 'reg':
            f.h_reg = HDLSignal(f.c_name + '_reg', w)
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
    stmts.append(HDLAssign(n.h_bus['dati'], root.h_bus['dati']))

def gen_bus_slave_sram(root, prefix, n):
    name = prefix + n.name + '_addr_o'
    n.h_addr_o = root.h_ports.add_port(
        name, n.c_blk_bits - root.c_addr_word_bits, dir='OUT')
    n.h_addr_o.comment = n.description

    name = prefix + n.name + '_data_i'
    n.h_data_i = root.h_ports.add_port(name, n.c_width, dir='IN')

    name = prefix + n.name + '_data_o'
    n.h_data_o = root.h_ports.add_port(name, n.c_width, dir='OUT')

    name = prefix + n.name + '_wr_o'
    n.h_wr_o = root.h_ports.add_port(name, None, dir='OUT')

def wire_bus_slave_sram(root, stmts, n):
    stmts.append(HDLAssign(n.h_data_o, root.h_bus['dato']))
    stmts.append(HDLAssign(n.h_addr_o,
                 HDLSlice(root.h_bus['adr'],
                          root.c_addr_word_bits,
                          n.c_blk_bits - root.c_addr_word_bits)))

def gen_bus_slave(root, module, prefix, n, interface, busgroup):
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


def add_ports_submap(root, module, n):
    if n.filename is None:
        # Generic submap.
        busgroup = n.get_extension('x_hdl', 'busgroup')
        gen_bus_slave(root, module, n.c_name + '_', n, n.interface, busgroup)
    else:
        if n.interface == 'include':
            # Inline
            add_ports(root, module, n.c_submap)
        else:
            busgroup = n.c_submap.get_extension('x_hdl', 'busgroup')
            gen_bus_slave(root, module, n.c_name + '_', n, n.c_interface, busgroup)


def wire_submap(root, module, n, stmts):
    if n.c_interface == 'wb-32-be':
        wire_bus_slave_wb32(root, stmts, n)
    elif n.c_interface == 'sram':
        wire_bus_slave_sram(root, stmts, n)
    else:
        raise AssertionError(n.interface)

def add_ports_array_reg(root, module, reg):
    # Compute width
    # Create ports
    reg.h_addr_width = ilog2(reg._parent.repeat)
    reg.h_addr = add_module_port(
        root, module, reg.name + '_adr', reg.h_addr_width, 'IN')
    reg.h_addr.comment = "RAM port for {}".format(reg.name)
    if reg.access == 'ro':
        reg.h_we = add_module_port(
            root, module, reg.name + '_we', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.name + '_dat', reg.c_rwidth, 'IN')
    else:
        reg.h_rd = add_module_port(
            root, module, reg.name + '_rd', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.name + '_dat', reg.c_rwidth, 'OUT')

def wire_array_reg(root, module, reg):
    if root.h_ram is None:
        module.deps.append(('work', 'wbgen2_pkg'))
        root.h_ram = True
        root.h_ram_wr_dly = HDLSignal("wr_dly_int")
        module.decls.append(root.h_ram_wr_dly)
    inst = HDLInstance(reg.name + "_raminst", "wbgen2_dpssram")
    module.stmts.append(inst)
    inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
    inst.params.append(("g_size", HDLNumber(1 << reg.h_addr_width)))
    inst.params.append(("g_addr_width", HDLNumber(reg.h_addr_width)))
    inst.params.append(("g_dual_clock", HDLBool(False)))
    inst.params.append(("g_use_bwsel", HDLBool(False)))
    inst.conns.append(("clk_a_i", root.h_bus['clk']))
    inst.conns.append(("clk_b_i", root.h_bus['clk']))
    inst.conns.append(("addr_a_i",
                       HDLSlice(root.h_bus['adr'], 0, reg.h_addr_width)))
    inst.conns.append(("addr_b_i", reg.h_addr))

    nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
    reg.h_sig_bwsel = HDLSignal(reg.name + '_int_bwsel', nbr_bytes)
    module.decls.append(reg.h_sig_bwsel)
    inst.conns.append(("bwsel_b_i", reg.h_sig_bwsel))
    inst.conns.append(("bwsel_a_i", reg.h_sig_bwsel))

    if reg.access == 'ro':
        raise AssertionError # TODO
        inst.conns.append(("data_a_o", reg.h_dat))
        inst.conns.append(("rd_a_i", rd_sig))
    else:
        # External port is RO.
        reg.h_sig_dato = HDLSignal(reg.name + '_int_dato', reg.c_rwidth)
        module.decls.append(reg.h_sig_dato)
        reg.h_dat_ign = HDLSignal(reg.name + '_ext_dat', reg.c_rwidth)
        module.decls.append(reg.h_dat_ign)
        reg.h_sig_rd = HDLSignal(reg.name + '_int_rd')
        module.decls.append(reg.h_sig_rd)
        reg.h_sig_wr = HDLSignal(reg.name + '_int_wr')
        module.decls.append(reg.h_sig_wr)
        reg.h_ext_wr = HDLSignal(reg.name + '_ext_wr')
        module.decls.append(reg.h_ext_wr)
        module.stmts.append(HDLAssign(reg.h_ext_wr, bit_0))

        inst.conns.append(("data_a_i", root.h_bus['dati']))
        inst.conns.append(("data_a_o", reg.h_sig_dato))
        inst.conns.append(("rd_a_i", reg.h_sig_rd))
        inst.conns.append(("wr_a_i", reg.h_sig_wr))

        inst.conns.append(("data_b_i", reg.h_dat_ign))
        inst.conns.append(("data_b_o", reg.h_dat))
        inst.conns.append(("rd_b_i", reg.h_rd))
        inst.conns.append(("wr_b_i", reg.h_ext_wr))

    module.stmts.append(HDLAssign(reg.h_sig_bwsel,
                                  HDLReplicate(bit_1, nbr_bytes)))

def add_ports(root, module, node):
    """Create ports for a composite node."""
    for n in node.children:
        if isinstance(n, tree.Block):
            if n.children:
                # Recurse
                add_ports(root, module, n)
        elif isinstance(n, tree.Submap):
            # Interface
            add_ports_submap(root, module, n)
        elif isinstance(n, tree.Array):
            for c in n.children:
                if isinstance(c, tree.Reg):
                    # Ram
                    add_ports_array_reg(root, module, c)
                else:
                    raise AssertionError(c)
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
            for c in n.children:
                if isinstance(c, tree.Reg):
                    # Ram
                    wire_array_reg(root, module, c)
                else:
                    raise AssertionError(c)
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
    elif isinstance(n, tree.Array):
        return [n]
    elif isinstance(n, (tree.Root, tree.Block)):
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

    sw.choices.append(HDLChoiceDefault())


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


def add_read_reg_process(root, module, isigs):
    # Register read
    rd_data = root.h_reg_rdat_int
    rd_ack = root.h_rd_ack1_int
    rdproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(rdproc)
    rdproc.rst_stmts.append(HDLAssign(rd_ack, bit_0))
    rdproc.rst_stmts.append(HDLAssign(rd_data,
                                      HDLReplicate(bit_x, root.c_word_bits)))
    rdproc.sync_stmts.append(HDLAssign(rd_data,
                                       HDLReplicate(bit_x, root.c_word_bits)))
    rd_if = HDLIfElse(HDLAnd(HDLEq(isigs.rd_int, bit_1),
                             HDLEq(rd_ack, bit_0)))
    rdproc.sync_stmts.append(rd_if)
    rd_if.then_stmts.append(HDLAssign(rd_ack, bit_1))
    rd_if.else_stmts.append(HDLAssign(rd_ack, bit_0))

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
            elif isinstance(n, tree.Submap):
                pass
            elif isinstance(n, tree.Array):
                s.append(HDLComment("RAM {}".format(n.name)))
            else:
                # Blocks have been handled.
                raise AssertionError

    then_stmts = []
    add_decoder(root, then_stmts, root.h_bus.get('adr', None), root, add_read)
    rd_if.then_stmts.extend(then_stmts)


def add_read_process(root, module, isigs):
    # Register read
    rd_data = root.h_bus['dato']
    rd_ack = isigs.rd_ack
    rd_adr = root.h_bus.get('adr', None)
    rdproc = HDLComb()
    if rd_adr is not None:
        rdproc.sensitivity.append(rd_adr)
    if root.h_max_delay >= 1:
        rdproc.sensitivity.extend([root.h_reg_rdat_int, root.h_rd_ack1_int,
                                   isigs.rd_int])
    module.stmts.append(rdproc)

    # All the read are ack'ed (including the read to unassigned addresses).
    rdproc.stmts.append(HDLComment("By default ack read requests"))
    rdproc.stmts.append(HDLAssign(rd_data,
                                  HDLReplicate(bit_0, root.c_word_bits)))
    rdproc.stmts.append(HDLAssign(rd_ack, bit_1))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.name))
                s.append(HDLAssign(rd_data, root.h_reg_rdat_int))
                s.append(HDLAssign(rd_ack, root.h_rd_ack1_int))
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.name)))
                if n.c_interface == 'wb-32-be':
                    s.append(HDLAssign(rd_data, n.h_bus['dato']))
                    rdproc.stmts.append(HDLAssign(n.h_rd, bit_0))
                    s.append(HDLAssign(n.h_rd, isigs.rd_int))
                    s.append(HDLAssign(isigs.rd_ack, n.h_bus['ack']))
                    return
                elif n.c_interface == 'sram':
                    return
                else:
                    raise AssertionError
            elif isinstance(n, tree.Array):
                s.append(HDLComment("RAM {}".format(n.name)))
                # TODO: handle list of registers!
                r = n.children[0]
                rdproc.sensitivity.append(r.h_sig_dato)
                # Output ram data
                s.append(HDLAssign(rd_data, r.h_sig_dato))
                # Set rd signal to ram
                s.append(HDLAssign(r.h_sig_rd, isigs.rd_int))
                # But set it to 0 when the ram is not selected.
                rdproc.stmts.append(HDLAssign(r.h_sig_rd, bit_0))
                # Use delayed ack as ack.
                s.append(HDLAssign(rd_ack, root.h_rd_ack1_int))
                return
            else:
                # Blocks have been handled.
                raise AssertionError

    stmts = []
    add_decoder(root, stmts, rd_adr, root, add_read)
    rdproc.stmts.extend(stmts)

def add_write_process(root, module, isigs):
    # Register write
    wrproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'])
    module.stmts.append(wrproc)
    if root.h_ram_wr_dly is not None:
        wrproc.rst_stmts.append(HDLAssign(root.h_ram_wr_dly, bit_0))
    wr_if = HDLIfElse(HDLAnd(HDLEq(isigs.wr_int, bit_1),
                             HDLEq(isigs.wr_ack, bit_0)))
    wr_if.else_stmts.append(HDLAssign(isigs.wr_ack, bit_0))
    wr_data = root.h_bus['dati']

    def add_write_reg(s, n, off):
        for f in n.children:
            # Reset code
            if f.h_reg is not None:
                v = 0 if f.preset is None else f.preset
                cst = HDLConst(v, f.c_iowidth if f.c_iowidth != 1 else None)
                wrproc.rst_stmts.append(HDLAssign(f.h_reg, cst))
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
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.name)))
                if n.c_interface == 'wb-32-be':
                    wrproc.rst_stmts.append(HDLAssign(n.h_wr, bit_0))
                    wr_if.then_stmts.append(HDLAssign(n.h_wr, bit_0))
                    s.append(HDLAssign(n.h_wr, bit_1))
                    s.append(HDLAssign(isigs.wr_ack, n.h_bus['ack']))
                    return
                elif n.c_interface == 'sram':
                    s.append(HDLAssign(n.h_wr_o, bit_1))
                    return
                else:
                    raise AssertionError
            elif isinstance(n, tree.Array):
                # TODO: handle list of registers!
                r = n.children[0]
                wrproc.rst_stmts.append(HDLAssign(r.h_sig_wr, bit_0))
                wr_if.else_stmts.append(HDLAssign(r.h_sig_wr, bit_0))
                s2 = HDLIfElse(HDLEq(root.h_ram_wr_dly, bit_0))
                s.append(s2)
                s2.then_stmts.append(HDLAssign(r.h_sig_wr, bit_1))
                s2.then_stmts.append(HDLAssign(root.h_ram_wr_dly, bit_1))
                s2.else_stmts.append(HDLAssign(root.h_ram_wr_dly, bit_0))
                s2.else_stmts.append(HDLAssign(isigs.wr_ack, bit_1))
                return
            else:
                # Including blocks.
                raise AssertionError
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
        expand_cern_be_vme(root, module, isigs, err, split)
    else:
        raise HdlError("Unhandled bus '{}'".format(root.bus))

    return module


def compute_max_delay(n):
    if isinstance(n, tree.Reg):
        return 1
    elif isinstance(n, tree.Submap):
        if n.interface == 'include':
            return compute_max_delay(n.c_submap)
        else:
            return 0
    elif isinstance(n, tree.Array):
        return 0
    elif isinstance(n, tree.Block) or isinstance(n, tree.Root):
        return max([compute_max_delay(c) for c in n.children])
    else:
        raise AssertionError(n)

def generate_hdl(root):
    isigs = Isigs()

    root.h_max_delay = compute_max_delay(root)

    module = gen_hdl_header(root, isigs)

    # Add ports
    iogroup = root.get_extension('x_hdl', 'iogroup')
    if iogroup is not None:
        root.h_itf = HDLInterface('t_' + iogroup)
        module.global_decls.append(root.h_itf)
        grp = module.add_port_group(iogroup, root.h_itf, True)
        grp.comment = 'Wires and registers'
        root.h_ports = grp
    else:
        root.h_itf = None
        root.h_ports = module
    add_ports(root, module, root)

    module.stmts.append(HDLComment('Assign outputs'))
    root.h_ram = None
    root.h_ram_wr_dly = None
    wire_regs(root, module, isigs, root)

    module.stmts.append(HDLComment('Process for write requests.'))
    add_write_process(root, module, isigs)

    if root.h_max_delay >= 1:
        root.h_reg_rdat_int = HDLSignal('reg_rdat_int', root.c_word_bits)
        module.decls.append(root.h_reg_rdat_int)
        root.h_rd_ack1_int = HDLSignal('rd_ack1_int')
        module.decls.append(root.h_rd_ack1_int)
        module.stmts.append(HDLComment('Process for registers read.'))
        add_read_reg_process(root, module, isigs)

    module.stmts.append(HDLComment('Process for read requests.'))
    add_read_process(root, module, isigs)

    return module
