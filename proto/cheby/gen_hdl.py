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
from cheby.hdltree import (HDLModule, HDLInterface,
                           HDLAssign, HDLComb, HDLComment, HDLConstant,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           bit_x,
                           HDLSlice, HDLReplicate,
                           HDLConst, HDLNumber)
import cheby.tree as tree
import cheby.hdlutils as hdlutils
import cheby.hdlopt as hdlopt
from cheby.layout import ilog2
from cheby.hdl.wbbus import WBBus
from cheby.hdl.ibus import Ibus
from cheby.hdl.genblock import GenBlock
from cheby.hdl.buses import name_to_busgen

def add_block_decoder(root, stmts, addr, children, hi, func, off):
    # :param hi: is the highest address bit to be decoded.
    debug = False
    if debug:
        print("add_block_decoder: hi={}, off={:08x}".format(hi, off))
        for i in children:
            print("{}: {:08x}, sz={:x}, al={:x}".format(
                i.name, i.c_abs_addr, i.c_size, i.c_align))
        print("----")
    if len(children) == 0:
        # Nothing to do
        func(stmts, None, 0)
        return
    elif len(children) == 1:
        # If there is only one child, no need to decode anymore.
        el = children[0]
        if isinstance(el, tree.Reg):
            if hi <= root.c_addr_word_bits:
                foff = off - el.c_abs_addr
                if el.c_size <= root.c_word_size:
                    # If the size of the register is smaller than the word,
                    # always reads at 0.  Word endianness doesn't matter.
                    assert foff == 0
                else:
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
    while children:
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
        while children:
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
    elif isinstance(n, (tree.Root, tree.Block, tree.AddressSpace)):
        r = []
        for e in n.children:
            r.extend(gather_leaves(e))
        return r
    else:
        raise AssertionError(n)


def add_decoder(root, stmts, addr, _n, func):
    """Call :param func: for each element of :param n:.  :param func: can also
       be called with None when a decoder is generated and could handle an
       address that has no corresponding children."""
    children = gather_leaves(root)
    children = sorted(children, key=lambda x: x.c_abs_addr)

    add_block_decoder(root, stmts, addr, children, ilog2(root.c_size), func, 0)


def add_read_mux_process(root, module, ibus):
    # Generate the read decoder.  This is a large combinational process
    # that mux the data and ack.
    # It can be combinational because the read address is stable until the
    # end of the access.
    module.stmts.append(HDLComment('Process for read requests.'))
    rd_adr = ibus.rd_adr
    rdproc = HDLComb()
    module.stmts.append(rdproc)

    # All the read are ack'ed (including the read to unassigned addresses).
    rdproc.stmts.append(HDLComment("By default ack read requests"))
    rdproc.stmts.append(HDLAssign(ibus.rd_dat,
                                  HDLReplicate(bit_x, root.c_word_bits)))

    def add_read(s, n, off):
        if n is not None:
            s.append(HDLComment("{} {}".format(n.NAME, n.c_name)))
            n.h_gen.gen_read(s, off, ibus, rdproc)
        else:
            s.append(HDLAssign(ibus.rd_ack, ibus.rd_req))

    stmts = []
    add_decoder(root, stmts, rd_adr, root, add_read)
    rdproc.stmts.extend(stmts)
    hdlutils.compute_sensitivity(rdproc)


def add_write_mux_process(root, module, ibus):
    # Generate the write decoder.  This is a large combinational process
    # that mux the acks and regenerate the requests.
    # It can be combinational because the read address is stable until the
    # end of the access.
    module.stmts.append(HDLComment('Process for write requests.'))
    wr_adr = ibus.wr_adr
    wrproc = HDLComb()
    module.stmts.append(wrproc)

    def add_write(s, n, off):
        if n is not None:
            s.append(HDLComment("{} {}".format(n.NAME, n.c_name)))
            n.h_gen.gen_write(s, off, ibus, wrproc)
        else:
            # By default, ack unknown requests.
            s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))

    stmts = []
    add_decoder(root, stmts, wr_adr, root, add_write)
    wrproc.stmts.extend(stmts)
    hdlutils.compute_sensitivity(wrproc)


def gen_hdl_header(root, ibus=None):
    # Note: also called from gen_gena_regctrl but without ibus.
    module = HDLModule()
    module.name = root.hdl_module_name

    # Create the bus
    root.h_busgen = name_to_busgen(root.bus)
    root.h_busgen.expand_bus(root, module, ibus)

    return module


def gen_enums(root, module):
    decls = module.global_decls
    for en in root.x_enums:
        decls.append(HDLComment("Enumeration {}".format(en.name)))
        for val in en.children:
            if en.width is None:
                cst = HDLConstant("C_{}_{}".format(en.name, val.name),
                                  value=HDLNumber(val.value), typ='N')
            else:
                cst = HDLConstant("C_{}_{}".format(en.name, val.name),
                                  size=en.width, value=HDLConst(val.value, en.width))
            decls.append(cst)


def generate_hdl(root):
    ibus = Ibus()

    # Force the regeneration of wb package (useful only when testing).
    WBBus.wb_pkg = None

    module = gen_hdl_header(root, ibus)

    root.h_bus['vrst'] = root.h_bus['brst']

    root.h_gen = GenBlock(root, module, root)
    root.h_gen.create_generators()

    if False:
        gen_enums(root, module)

    # Add ports
    iogroup = root.get_extension('x_hdl', 'iogroup')
    if iogroup is not None:
        root.h_itf = HDLInterface('t_' + iogroup)
        module.global_decls.append(root.h_itf)
        grp = module.add_modport(iogroup, root.h_itf, True)
        grp.comment = 'Wires and registers'
        root.h_ports = grp
    else:
        root.h_itf = None
        root.h_ports = module

    root.h_gen.gen_ports()

    if root.hdl_pipeline:
        ibus = ibus.pipeline(root, module, root.hdl_pipeline, '_d0')

    # Add internal processes + wires
    root.h_ram = None
    root.h_gen.gen_processes(ibus)

    # Address decoders and muxes.
    add_write_mux_process(root, module, ibus)
    add_read_mux_process(root, module, ibus)

    hdlopt.remove_unused(module)

    return module
