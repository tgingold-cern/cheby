from cheby.hdl.globals import dirname
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

class ElGen(object):
    def gen_port(self, root, module, name, size, dir):
        pass
    
    def gen_processes(self, root, module, ibus, n):
        pass

    def gen_read(self, root, s, n, off, ibus, rdproc):
        pass

    def gen_write(self, root, s, n, off, ibus, wrproc):
        pass


def add_module_port(root, module, name, size, dir):
    "Utility function to easily add a port to :param module:"
    if root.h_itf is None:
        return module.add_port(name + '_' + dirname[dir], size, dir=dir)
    else:
        p = root.h_itf.add_port(name, size, dir=dir)
        return HDLInterfaceSelect(root.h_ports, p)

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


def strobe_init(root, n):
    sz = n.c_size // root.c_word_size
    if sz <= 1:
        return bit_0
    else:
        return HDLReplicate(bit_0, sz)


def strobe_index(root, n, off, lhs):
    if n.c_size <= root.c_word_size:
        return lhs
    else:
        return HDLIndex(lhs, off // root.c_word_bits)


