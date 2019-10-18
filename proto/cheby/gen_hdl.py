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
import functools
from cheby.hdltree import (HDLModule, HDLPackage,
                           HDLInterface, HDLInterfaceSelect, HDLInstance,
                           HDLPort, HDLSignal,
                           HDLAssign, HDLSync, HDLComb, HDLComment,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLIfElse,
                           bit_1, bit_0, bit_x,
                           HDLAnd, HDLOr, HDLNot, HDLEq, HDLConcat,
                           HDLIndex, HDLSlice, HDLReplicate, Slice_or_Index,
                           HDLConst, HDLBinConst, HDLNumber, HDLBool, HDLParen)
import cheby.tree as tree
from cheby.layout import ilog2
from cheby.hdl.busgen import BusGen
from cheby.hdl.wbbus import WBBus
from cheby.hdl.cernbus import CERNBEBus
from cheby.hdl.srambus import SRAMBus
from cheby.hdl.axi4litebus import AXI4LiteBus
from cheby.hdl.globals import rst_sync, dirname
from cheby.hdl.ibus import Ibus, add_bus
from cheby.hdl.genreg import GenReg
from cheby.hdl.elgen import add_module_port, strobe_index, strobe_init

def add_ports_interface(root, module, n):
    # Generic submap.
    busgroup = n.get_extension('x_hdl', 'busgroup')
    n.h_busgen = name_to_busgen(n.interface)
    n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)


def add_ports_submap(root, module, n):
    if n.filename is None:
        add_ports_interface(root, module, n)
    else:
        if n.include is True:
            # Inline
            add_ports(root, module, n.c_submap)
        else:
            busgroup = n.c_submap.get_extension('x_hdl', 'busgroup')
            n.h_busgen = name_to_busgen(n.c_submap.bus)
            n.h_busgen.gen_bus_slave(root, module, n.c_name + '_', n, busgroup)


def add_ports_memory(root, module, mem):
    """Create RAM ports and wires shared by all the registers.
    :attr h_addr: the address port
    """
    if mem.interface is not None:
        mem.c_addr_bits = ilog2(mem.c_depth)
        mem.c_width = mem.c_elsize * tree.BYTE_SIZE
        add_ports_interface(root, module, mem)
        return
    # Compute width, and create address port.
    mem.h_addr_width = ilog2(mem.c_depth)
    mem.h_addr = add_module_port(
        root, module, mem.c_name + '_adr', mem.h_addr_width, 'IN')
    mem.h_addr.comment = '\n' + "RAM port for {}".format(mem.c_name)

    for c in mem.children:
        if isinstance(c, tree.Reg):
            # Ram
            add_ports_memory_reg(root, module, c)
        else:
            raise AssertionError(c)


def add_ports_memory_reg(root, module, reg):
    """Create ports and wires for a ram.
    :attr h_we: the write enable
    :attr h_rd: the read enable
    :attr h_dat: the data (either input or output)
    """
    # Create ports for external access to the RAM.
    if reg.access == 'ro':
        reg.h_wr = add_module_port(
            root, module, reg.c_name + '_we', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.c_name + '_dat', reg.c_rwidth, 'IN')
    else:
        reg.h_rd = add_module_port(
            root, module, reg.c_name + '_rd', None, 'IN')
        reg.h_dat = add_module_port(
            root, module, reg.c_name + '_dat', reg.c_rwidth, 'OUT')

    nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
    reg.h_sig_bwsel = module.new_HDLSignal(reg.c_name + '_int_bwsel', nbr_bytes)

    if reg.access == 'ro':
        # External port is WO
        reg.h_sig_dati = module.new_HDLSignal(reg.c_name + '_int_dati', reg.c_rwidth)
        reg.h_sig_dato = module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
        reg.h_dat_ign = module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
        reg.h_rreq = module.new_HDLSignal(reg.c_name + '_rreq')
        reg.h_rack = module.new_HDLSignal(reg.c_name + '_rack')
        reg.h_sig_wr = module.new_HDLSignal(reg.c_name + '_int_wr')
        reg.h_ext_rd = module.new_HDLSignal(reg.c_name + '_ext_rd')
    else:
        # External port is RO.
        reg.h_sig_dato = module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
        reg.h_dat_ign = module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
        reg.h_rreq = module.new_HDLSignal(reg.c_name + '_rreq')
        reg.h_rack = module.new_HDLSignal(reg.c_name + '_rack')
        reg.h_sig_wr = module.new_HDLSignal(reg.c_name + '_int_wr')
        reg.h_ext_wr = module.new_HDLSignal(reg.c_name + '_ext_wr')


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
        elif isinstance(n, tree.Memory):
            add_ports_memory(root, module, n)
        elif isinstance(n, tree.Reg):
            n.h_gen.gen_ports(root, module, n)
        else:
            raise AssertionError


def add_processes_memory(root, module, ibus, arr):
    module.stmts.append(HDLComment('Memory {}'.format(arr.c_name)))
    if root.h_ram is None:
        module.deps.append(('work', 'wbgen2_pkg'))
        root.h_ram = True

    if ibus.wr_adr != ibus.rd_adr and any([r.access in ['wo', 'rw'] for r in arr.children]):
        # Read request and Write request.  Priority for the write.
        arr.h_wr = module.new_HDLSignal(arr.c_name + '_wr')
        arr.h_rr = module.new_HDLSignal(arr.c_name + '_rr')
        # Any write request
        arr.h_wreq = module.new_HDLSignal(arr.c_name + '_wreq')
        arr.h_adr_int = module.new_HDLSignal(arr.c_name + '_adr_int',
                                             arr.h_addr_width)
                                            
        # Create a mux for the ram address
        proc = HDLComb()
        proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, arr.h_wr])
        if_stmt = HDLIfElse(HDLEq(arr.h_wr, bit_1))
        if_stmt.then_stmts.append(HDLAssign(arr.h_adr_int,
            HDLSlice(ibus.wr_adr, root.c_addr_word_bits, arr.h_addr_width)))
        if_stmt.else_stmts.append(HDLAssign(arr.h_adr_int,
            HDLSlice(ibus.rd_adr, root.c_addr_word_bits, arr.h_addr_width)))
        proc.stmts.append(if_stmt)
        module.stmts.append(proc)

        # Handle R & W accesses (priority to W)
        module.stmts.append(HDLAssign(arr.h_wreq,
            functools.reduce(HDLOr, [r.h_sig_wr for r in arr.children])))
        rreq = functools.reduce(HDLOr, [r.h_rreq for r in arr.children])
        module.stmts.append(HDLAssign(arr.h_rr,
            HDLAnd(rreq, HDLNot(arr.h_wreq))))
        module.stmts.append(HDLAssign(arr.h_wr, arr.h_wreq))
    else:
        arr.h_adr_int = None


def add_processes_memory_reg(root, module, ibus, reg):
    arr = reg._parent
    # Instantiate the ram.
    inst = HDLInstance(reg.c_name + "_raminst", "wbgen2_dpssram")
    module.stmts.append(inst)
    inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
    inst.params.append(("g_size", HDLNumber(1 << arr.h_addr_width)))
    inst.params.append(("g_addr_width", HDLNumber(arr.h_addr_width)))
    inst.params.append(("g_dual_clock", HDLBool(False)))
    inst.params.append(("g_use_bwsel", HDLBool(False)))
    inst.conns.append(("clk_a_i", root.h_bus['clk']))
    inst.conns.append(("clk_b_i", root.h_bus['clk']))
    if arr.h_adr_int is not None:
        adr_int = arr.h_adr_int
    else:
        adr_int = HDLSlice(ibus.rd_adr, root.c_addr_word_bits, arr.h_addr_width)
    inst.conns.append(("addr_a_i", adr_int))

    # Always write words to RAM (no byte select)
    inst.conns.append(("bwsel_b_i", reg.h_sig_bwsel))
    inst.conns.append(("bwsel_a_i", reg.h_sig_bwsel))

    proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
    proc.rst_stmts.append(HDLAssign(reg.h_rack, bit_0))
    if root.h_bussplit and reg.access in ['rw', 'wo']:
        # Arbiter: the RAM has only one address bus on port A.
        rack = HDLAnd(HDLAnd(reg.h_rreq, HDLNot(arr.h_wreq)),
                      HDLNot(reg.h_rack))
    else:
        rack = reg.h_rreq
    proc.sync_stmts.append(HDLAssign(reg.h_rack, rack))
    module.stmts.append(proc)

    if reg.access == 'ro':
        # Internal port (RO)
        inst.conns.append(("data_a_i", reg.h_sig_dati))  # Unused.
        inst.conns.append(("data_a_o", reg.h_sig_dato))
        inst.conns.append(("rd_a_i", reg.h_rreq))
        inst.conns.append(("wr_a_i", reg.h_sig_wr))

        module.stmts.append(HDLAssign(reg.h_sig_wr, bit_0))
        module.stmts.append(HDLAssign(reg.h_sig_dati, HDLReplicate(bit_x, reg.c_rwidth)))

        # External port (WO)
        module.stmts.append(HDLAssign(reg.h_ext_rd, bit_0))

        inst.conns.append(("addr_b_i", arr.h_addr))
        inst.conns.append(("data_b_i", reg.h_dat))
        inst.conns.append(("data_b_o", reg.h_dat_ign))
        inst.conns.append(("rd_b_i", reg.h_ext_rd))
        inst.conns.append(("wr_b_i", reg.h_wr))
    else:
        # Internal port (RW)
        inst.conns.append(("data_a_i", ibus.wr_dat))
        inst.conns.append(("data_a_o", reg.h_sig_dato))
        inst.conns.append(("rd_a_i", reg.h_rreq))
        inst.conns.append(("wr_a_i", reg.h_sig_wr))

        # External port (RO)
        module.stmts.append(HDLAssign(reg.h_ext_wr, bit_0))

        inst.conns.append(("addr_b_i", arr.h_addr))
        inst.conns.append(("data_b_i", reg.h_dat_ign))
        inst.conns.append(("data_b_o", reg.h_dat))
        inst.conns.append(("rd_b_i", reg.h_rd))
        inst.conns.append(("wr_b_i", reg.h_ext_wr))

    nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
    module.stmts.append(HDLAssign(reg.h_sig_bwsel,
                                  HDLReplicate(bit_1, nbr_bytes)))


def add_process_interface(root, module, ibus, n):
    module.stmts.append(HDLComment('Interface {}'.format(n.c_name)))
    n.h_busgen.wire_bus_slave(root, module, n, ibus)


def add_processes(root, module, ibus, node):
    """Create assignment from register to outputs."""
    for n in node.children:
        if isinstance(n, tree.Block):
            add_processes(root, module, ibus, n)
        elif isinstance(n, tree.Submap):
            if n.include is True:
                add_processes(root, module, ibus, n.c_submap)
            else:
                add_process_interface(root, module, ibus, n)
        elif isinstance(n, tree.Memory):
            if n.interface is not None:
                add_process_interface(root, module, ibus, n)
            else:
                add_processes_memory(root, module, ibus, n)
                for c in n.children:
                    if isinstance(c, tree.Reg):
                        # Ram
                        add_processes_memory_reg(root, module, ibus, c)
                    else:
                        raise AssertionError(c)
        elif isinstance(n, tree.Reg):
            n.h_gen.gen_processes(root, module, ibus, n)
        else:
            raise AssertionError


def add_block_decoder(root, stmts, addr, children, hi, func, off):
    # :param hi: is the highest address bit to be decoded.
    debug = False
    if debug:
        print("add_block_decoder: hi={}, off={:08x}".format(hi, off))
        for i in children:
            print("{}: {:08x}, sz={:x}, al={:x}".format(
                i.name, i.c_abs_addr, i.c_size, i.c_align))
        print("----")
    if len(children) == 1:
        # If there is only one child, no need to decode anymore.
        el = children[0]
        if isinstance(el, tree.Reg):
            if hi == root.c_addr_word_bits:
                foff = off & (el.c_size - 1)
                if root.c_word_endian == 'big':
                    # Big endian
                    foff = el.c_size - root.c_word_size - foff
                else:
                    # Little endian
                    foff = foff
                func(stmts, el, foff * tree.BYTE_SIZE)
                return
            else:
                # Multi-word register - to be split, so decode more.
                maxsz = 1 << root.c_addr_word_bits
        else:
            func(stmts, el, 0)
            return
    else:
        # Will add a decoder for the maximum aligned child.
        maxsz = max([e.c_align for e in children])

    maxszl2 = ilog2(maxsz)
    assert maxsz == 1 << maxszl2
    mask = ~(maxsz - 1)
    assert maxszl2 < hi

    # Add a decoder.
    # Note: addr has a word granularity.
    sw = HDLSwitch(HDLSlice(addr, maxszl2, hi - maxszl2))
    stmts.append(sw)

    next_base = off
    while len(children) > 0:
        # Extract the first child.
        first = children.pop(0)
        l = [first]
        # Skip holes in address to be decoded.
        base = max(next_base, first.c_abs_addr & mask)
        next_base = base + maxsz
        if debug:
            print("hi={} szl2={} first: {:08x}, base: {:08x}, mask: {:08x}".
                  format(hi, maxszl2, first.c_abs_addr, base, mask))

        # Create a branch.
        ch = HDLChoiceExpr(HDLConst(base >> maxszl2, hi - maxszl2))
        sw.choices.append(ch)

        # Gather other children that are decoded in the same branch (same
        # base address)
        last = first
        while len(children) > 0:
            el = children[0]
            if (el.c_abs_addr & mask) != base:
                break
            if debug:
                print(" {} @ {:08x}".format(el.name, el.c_abs_addr))
            last = el
            l.append(el)
            children.pop(0)

        # If the block is larger than its alignment, re-decode it again.
        if ((last.c_abs_addr + last.c_size - 1) & mask) != base:
            children.insert(0, last)

        # Sub-decode gathered children.
        add_block_decoder(root, ch.stmts, addr, l, maxszl2, func, base)

    ch = HDLChoiceDefault()
    sw.choices.append(ch)
    func(ch.stmts, None, 0)


def gather_leaves(n):
    # Gather all elements that need to be decoded.
    if isinstance(n, tree.Reg):
        return [n]
    elif isinstance(n, tree.Submap):
        if n.include is True:
            return gather_leaves(n.c_submap)
        else:
            return [n]
    elif isinstance(n, tree.Memory):
        return [n]
    elif isinstance(n, (tree.Root, tree.Block)):
        r = []
        for e in n.children:
            r.extend(gather_leaves(e))
        return r
    else:
        raise AssertionError


def add_decoder(root, stmts, addr, n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding children."""
    children = gather_leaves(root)
    children = sorted(children, key=lambda x: x.c_abs_addr)

    add_block_decoder(root, stmts, addr, children, ilog2(root.c_size), func, 0)


def add_read_interface(root, s, n, off, ibus, rdproc):
    n.h_busgen.read_bus_slave(root, s, n, rdproc, ibus, ibus.rd_dat)


def add_read_memory(root, s, n, off, ibus, rdproc):
    if n.interface is not None:
        add_read_interface(root, s, n, off, ibus, rdproc)
        return
    # TODO: handle list of registers!
    r = n.children[0]
    rdproc.sensitivity.append(r.h_sig_dato)
    # Output ram data
    s.append(HDLAssign(ibus.rd_dat, r.h_sig_dato))
    # Set rd signal to ram: read when there is not WR request,
    # and either a read request or a pending read request.
    if root.h_bussplit and r.access in ['wo', 'rw']:
        rd_sig = HDLAnd(ibus.rd_req, HDLNot(n.h_wreq))
        rdproc.sensitivity.extend([n.h_wreq])
    else:
        rd_sig = ibus.rd_req
    s.append(HDLAssign(r.h_rreq, rd_sig))
    # But set it to 0 when the ram is not selected.
    rdproc.stmts.append(HDLAssign(r.h_rreq, bit_0))
    # Use delayed ack as ack.
    s.append(HDLAssign(ibus.rd_ack, r.h_rack))
    rdproc.sensitivity.append(r.h_rack)


def add_read_mux_process(root, module, ibus):
    # Generate the read decoder.  This is a large combinational process
    # that mux the data and ack.
    # It can be combinational because the read address is stable until the
    # end of the access.
    module.stmts.append(HDLComment('Process for read requests.'))
    rd_adr = ibus.rd_adr
    rdproc = HDLComb()
    if rd_adr is not None:
        rdproc.sensitivity.append(rd_adr)
    rdproc.sensitivity.extend([ibus.rd_req])
    module.stmts.append(rdproc)

    # All the read are ack'ed (including the read to unassigned addresses).
    rdproc.stmts.append(HDLComment("By default ack read requests"))
    rdproc.stmts.append(HDLAssign(ibus.rd_dat,
                                  HDLReplicate(bit_x, root.c_word_bits)))

    def add_read(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.c_name))
                n.h_gen.gen_read(root, s, n, off, ibus, rdproc)
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.c_name)))
                add_read_interface(root, s, n, off, ibus, rdproc)
            elif isinstance(n, tree.Memory):
                s.append(HDLComment("RAM {}".format(n.c_name)))
                add_read_memory(root, s, n, off, ibus, rdproc)
            else:
                # Blocks have been handled.
                raise AssertionError
        else:
            s.append(HDLAssign(ibus.rd_ack, ibus.rd_req))

    stmts = []
    add_decoder(root, stmts, rd_adr, root, add_read)
    rdproc.stmts.extend(stmts)


def add_write_interface(root, s, n, off, ibus, wrproc):
    n.h_busgen.write_bus_slave(root, s, n, wrproc, ibus)


def add_write_memory(root, s, n, off, ibus, wrproc):
    if n.interface is not None:
        add_write_interface(root, s, n, off, ibus, wrproc)
        return
    # TODO: handle list of registers!
    r = n.children[0]
    if r.access in ['rw', 'wo']:
        wrproc.stmts.append(HDLAssign(r.h_sig_wr, bit_0))
        s.append(HDLAssign(r.h_sig_wr, ibus.wr_req))
        s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))


def add_write_mux_process(root, module, ibus):
    # Generate the write decoder.  This is a large combinational process
    # that mux the acks and regenerate the requests.
    # It can be combinational because the read address is stable until the
    # end of the access.
    module.stmts.append(HDLComment('Process for write requests.'))
    wr_adr = ibus.wr_adr
    wrproc = HDLComb()
    if wr_adr is not None:
        wrproc.sensitivity.append(wr_adr)
    wrproc.sensitivity.extend([ibus.wr_req])
    module.stmts.append(wrproc)

    def add_write(s, n, off):
        if n is not None:
            if isinstance(n, tree.Reg):
                s.append(HDLComment(n.c_name))
                n.h_gen.gen_write(root, s, n, off, ibus, wrproc)
            elif isinstance(n, tree.Submap):
                s.append(HDLComment("Submap {}".format(n.c_name)))
                add_write_interface(root, s, n, off, ibus, wrproc)
            elif isinstance(n, tree.Memory):
                s.append(HDLComment("RAM {}".format(n.c_name)))
                add_write_memory(root, s, n, off, ibus, wrproc)
            else:
                # Blocks have been handled.
                raise AssertionError
        else:
            # By default, ack unknown requests.
            s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))

    stmts = []
    add_decoder(root, stmts, wr_adr, root, add_write)
    wrproc.stmts.extend(stmts)


def set_gen(root, node):
    """Add the object to generate hdl"""
    for n in node.children:
        if isinstance(n, tree.Block):
            if n.children:
                # Recurse
                set_gen(root, n)
        elif isinstance(n, tree.Submap):
            if n.include is True:
                # Inline
                set_gen(root, n.c_submap)
        elif isinstance(n, tree.Memory):
            pass
        elif isinstance(n, tree.Reg):
            n.h_gen = GenReg()
            pass
        else:
            raise AssertionError

def name_to_busgen(name):
    if name == 'wb-32-be':
        return WBBus(name)
    elif name == 'axi4-lite-32':
        return AXI4LiteBus(name)
    elif name.startswith('cern-be-vme-'):
        return CERNBEBus(name)
    elif name == 'sram':
        return SRAMBus(name)
    else:
        raise AssertionError("Unhandled bus '{}'".format(name))


def gen_hdl_header(root, ibus=None):
    # Note: also called from gen_gena_regctrl but without ibus.
    module = HDLModule()
    module.name = root.name

    # Create the bus
    root.h_busgen = name_to_busgen(root.bus)
    root.h_busgen.expand_bus(root, module, ibus)

    return module


def generate_hdl(root):
    ibus = Ibus()

    # Force the regeneration of wb package (useful only when testing).
    WBBus.wb_pkg = None

    module = gen_hdl_header(root, ibus)

    set_gen(root, root)

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

    if root.hdl_pipeline:
        ibus = ibus.pipeline(root, module, root.hdl_pipeline, '_d0')

    # Add internal processes + wires
    root.h_ram = None
    add_processes(root, module, ibus, root)

    # Address decoders and muxes.
    add_write_mux_process(root, module, ibus)
    add_read_mux_process(root, module, ibus)

    return module
