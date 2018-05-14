from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLComponent, HDLComponentSpec,
                           HDLSignal, HDLPort, HDLParam,
                           bit_0, bit_1,
                           HDLSlice, HDLIndex,
                           HDLSub, HDLMul,
                           HDLAnd, HDLNot,
                           HDLGe, HDLLe, HDLEq,
                           HDLZext, HDLReplicate, HDLConcat,
                           HDLAssign, HDLIfElse,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLInstance, HDLComb, HDLSync,
                           HDLNumber)
from gen_gena_memmap import subsuffix
import cheby.gen_hdl as gen_hdl

READ_ACCESS = ('ro', 'rw')
WRITE_ACCESS = ('wo', 'rw')

def get_gena_gen(n, name, default=False):
    gena_gen = n.get_extension('x_gena', 'gen')
    if gena_gen is None:
        return default
    return gena_gen.get(name, default)


def gen_hdl_reg_decls(reg, pfx, root, module, isigs):
    # Generate ports
    mode = 'OUT' if reg.access in WRITE_ACCESS else 'IN'
    reg.h_port = []
    if get_gena_gen(reg, 'no-split'):
        reg.h_port = HDLPort(pfx + reg.name, size=reg.c_rwidth, dir=mode)
        module.ports.append(reg.h_port)
    elif get_gena_gen(reg, 'ext-creg'):
        if reg.access in READ_ACCESS:
            reg.h_port = HDLPort(pfx + reg.name, size=reg.c_rwidth, dir='IN')
            module.ports.append(reg.h_port)
        if reg.access in WRITE_ACCESS:
            reg.h_portsel = []
            for i in reversed(range(reg.c_nwords)):
                sig = HDLPort('{}{}_Sel{}'.format(
                    pfx, reg.name, subsuffix(i, reg.c_nwords)), dir='OUT')
                reg.h_portsel.insert(0, sig)
                module.ports.append(sig)
    else:
        for f in reg.fields:
            sz, lo = (None, None) if f.hi is None else (f.c_iowidth, f.lo)
            portname = pfx + reg.name + (('_' + f.name) if f.name is not None else '')
            port = HDLPort(portname, size=sz, lo_idx=lo, dir=mode)
            f.h_port = port
            module.ports.append(f.h_port)

    reg.h_busout = None
    if get_gena_gen(reg, 'bus-out'):
        reg.h_busout = HDLPort(pfx + reg.name, size=reg.c_rwidth, dir='OUT')
        module.ports.append(reg.h_busout)

    reg.h_wrstrobe = []
    if get_gena_gen(reg, 'write-strobe'):
        for i in reversed(range(reg.c_nwords)):
            port = HDLPort(
                pfx + reg.name + '_WrStrobe' + subsuffix(i, reg.c_nwords),
                dir='OUT')
            reg.h_wrstrobe.insert(0, port)
            module.ports.append(port)

    reg.h_SRFF = None
    reg.h_ClrSRFF = None
    srff = get_gena_gen(reg, 'srff')
    if srff:
        reg.h_SRFF = HDLPort(
            pfx + reg.name + '_SRFF', size=reg.c_rwidth, dir='OUT')
        module.ports.append(reg.h_SRFF)
        reg.h_ClrSRFF = HDLPort(pfx + reg.name + '_ClrSRFF')
        module.ports.append(reg.h_ClrSRFF)

    # Create Loc_ signal
    if get_gena_gen(reg, 'ext-creg') and reg.access == 'wo':
        reg.h_loc = None
    else:
        reg.h_loc = HDLSignal('Loc_{}{}'.format(pfx, reg.name), reg.c_rwidth)
        module.decls.append(reg.h_loc)
    # Create Loc_x_SRFF
    reg.h_loc_SRFF = None
    if srff:
        reg.h_loc_SRFF = HDLSignal('Loc_{}{}_SRFF'.format(pfx, reg.name),
                                   reg.c_rwidth)
        module.decls.append(reg.h_loc_SRFF)
    # Create Sel_ signal
    if reg.access in WRITE_ACCESS:
        reg.h_wrsel = []
        for i in reversed(range(reg.c_nwords)):
            sig = HDLSignal('WrSel_{}{}{}'.format(
                pfx, reg.name, subsuffix(i, reg.c_nwords)))
            reg.h_wrsel.insert(0, sig)
            module.decls.append(sig)

def gen_hdl_reg_insts(reg, pfx, root, module, isigs):
    # For SRFF.
    if get_gena_gen(reg, 'srff'):
        root.h_has_srff = True
        inst = HDLInstance('SRFF_{}{}'.format(pfx, reg.name), 'SRFFxN')
        inst.params = [('N', HDLNumber(reg.c_rwidth))]
        inst.conns = [
            ('Clk', root.h_bus['clk']),
            ('Rst', root.h_bus['rst']),
            ('Set', reg.h_loc),
            ('Clr', reg.h_ClrSRFF),
            ('Q', reg.h_loc_SRFF)]
        module.stmts.append(inst)
        return

    if reg.access not in WRITE_ACCESS:
        return
    if get_gena_gen(reg, 'ext-creg'):
        return

    # Create Register
    gena_type = reg.get_extension('x_gena', 'type')
    if gena_type == 'rmw':
        reg_tpl = 'RMWReg'
        root.h_has_rmw = True
    elif gena_type is None:
        reg_tpl = 'CtrlRegN'
        root.h_has_creg = True
    else:
        raise AssertionError
    for i in reversed(range(reg.c_nwords)):
        inst = HDLInstance('Reg_{}{}{}'.format(
                                pfx, reg.name, subsuffix(i, reg.c_nwords)),
                            reg_tpl)
        iwidth = reg.c_rwidth // reg.c_nwords
        inst.params = [('N', HDLNumber(iwidth))]
        inst.conns = [
            ('VMEWrData', HDLSlice(root.h_bus['dati'], 0,
                                   reg.c_mwidth // reg.c_nwords)),
            ('Clk', root.h_bus['clk']),
            ('Rst', root.h_bus['rst']),
            ('WriteMem', root.h_bus['wr']),
            ('CRegSel', reg.h_wrsel[i]),
            ('AutoClrMsk', reg.h_gena_acm[i]),
            ('Preset', reg.h_gena_psm[i]),
            ('CReg', HDLSlice(reg.h_loc, i * iwidth, iwidth))]
        module.stmts.append(inst)


def gen_hdl_reg_stmts(reg, pfx, root, module, isigs):
    if reg.h_SRFF:
        module.stmts.append(HDLAssign(reg.h_SRFF, reg.h_loc_SRFF))
    if get_gena_gen(reg, 'no-split'):
        if reg.access in ('ro'):
            module.stmts.append(HDLAssign(reg.h_loc, reg.h_port))
        else:
            module.stmts.append(HDLAssign(reg.h_port, reg.h_loc))
    elif get_gena_gen(reg, 'ext-creg'):
        if reg.access in READ_ACCESS:
            module.stmts.append(HDLAssign(reg.h_loc, reg.h_port))
        if reg.access in WRITE_ACCESS:
            for i in reversed(range(reg.c_nwords)):
                module.stmts.append(HDLAssign(reg.h_portsel[i], reg.h_wrsel[i]))
    else:
        if reg.h_busout is not None:
            module.stmts.append(HDLAssign(reg.h_busout, reg.h_loc))

        # Create bitlist, a list of ordered (lo + width, lo, field)
        # Fill gaps with (lo + width, lo, None)
        bitlist = []
        nbit = 0
        for f in sorted(reg.fields, key=(lambda x: x.lo)):
            if f.lo > nbit:
                bitlist.append((f.lo, nbit, None))
            nbit = f.lo + f.c_rwidth
            bitlist.append((nbit, f.lo, f))
        if nbit != reg.c_rwidth:
            bitlist.append((reg.c_rwidth, nbit, None))
        # Assign Loc_ from inputs; assign outputs from Loc_
        for hi, lo, f in reversed(bitlist):
            if hi == lo + 1:
                tgt = HDLIndex(reg.h_loc, lo)
            elif lo == 0 and hi == reg.c_rwidth:
                tgt = reg.h_loc
            else:
                tgt = HDLSlice(reg.h_loc, lo, hi - lo)
            if f is None:
                idx = lo // root.c_word_bits
                if hi == lo + 1:
                    src = HDLIndex(reg.h_gena_psm[idx], lo)
                else:
                    src = HDLSlice(reg.h_gena_psm[idx], lo, hi - lo)
            else:
                src = f.h_port
            if reg.access in ('ro'):
                if f and f.c_iowidth < f.c_rwidth:
                    src = HDLZext(src, f.c_rwidth)
                module.stmts.append(HDLAssign(tgt, src))
            else:
                if f is not None:
                    if f.c_iowidth < f.c_rwidth:
                        tgt = HDLZext(tgt, f.c_iowidth)
                    module.stmts.append(HDLAssign(src, tgt))
    if reg.h_wrstrobe:
        for i in reversed(range(reg.c_nwords)):
            module.stmts.append(HDLAssign(reg.h_wrstrobe[i],
                HDLAnd(reg.h_wrsel[i], isigs.RegWrDone)))


def gen_hdl_wrseldec(root, module, isigs, area, pfx, wrseldec):
    proc = HDLComb()
    proc.name = '{}WrSelDec'.format(pfx)
    proc.sensitivity.append(root.h_bus['adr'])
    for r in wrseldec:
        for i in reversed(range(r.c_nwords)):
            proc.stmts.append(HDLAssign(r.h_wrsel[i], bit_0))
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    if isinstance(area, tree.Block):
        stmt = gen_hdl_area_decode(root, module, area)
        stmt.then_stmts.append(sw)
        stmt.else_stmts.append(HDLAssign(isigs.Loc_CRegWrOK, bit_0))
        proc.stmts.append(stmt)
    else:
        proc.stmts.append(sw)
    for reg in wrseldec:
        for i in reversed(range(reg.c_nwords)):
            ch = HDLChoiceExpr(reg.h_gena_regaddr[i])
            ch.stmts.append(HDLAssign(reg.h_wrsel[i], bit_1))
            ch.stmts.append(HDLAssign(isigs.Loc_CRegWrOK, bit_1))
            sw.choices.append(ch)
    ch = HDLChoiceDefault()
    ch.stmts.append(HDLAssign(isigs.Loc_CRegWrOK, bit_0))
    sw.choices.append(ch)
    module.stmts.append(proc)

def gen_hdl_cregrdmux(root, module, isigs, area, pfx, wrseldec):
    proc = HDLComb()
    proc.name = '{}CRegRdMux'.format(pfx)
    proc.sensitivity.append(root.h_bus['adr'])
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    if isinstance(area, tree.Block):
        stmt = gen_hdl_area_decode(root, module, area)
        stmt.then_stmts.append(sw)
        stmt.else_stmts.append(HDLAssign(isigs.Loc_CRegRdData, HDLReplicate(bit_0, None)))
        stmt.else_stmts.append(HDLAssign(isigs.Loc_CRegRdOK, bit_0))
        proc.stmts.append(stmt)
    else:
        proc.stmts.append(sw)
    for reg in wrseldec:
        if reg.h_loc:
            # NOTE: not needed for WO registers!
            proc.sensitivity.append(reg.h_loc)
        for i in reversed(range(reg.c_nwords)):
            ch = HDLChoiceExpr(reg.h_gena_regaddr[i])
            if reg.access == 'wo':
                val = HDLReplicate(bit_0, None)
                ok = bit_0
            else:
                val = reg.h_loc
                regw = reg.c_rwidth // reg.c_nwords
                val = HDLSlice(val, i * regw, regw)
                if regw < root.c_word_bits:
                    val = HDLZext(val, root.c_word_bits)
                ok = bit_1
            ch.stmts.append(HDLAssign(isigs.Loc_CRegRdData, val))
            ch.stmts.append(HDLAssign(isigs.Loc_CRegRdOK, ok))
            sw.choices.append(ch)
    ch = HDLChoiceDefault()
    ch.stmts.append(HDLAssign(isigs.Loc_CRegRdData, HDLReplicate(bit_0, None)))
    ch.stmts.append(HDLAssign(isigs.Loc_CRegRdOK, bit_0))
    sw.choices.append(ch)
    module.stmts.append(proc)

def gen_hdl_cregrdmux_asgn(stmts, isigs):
    stmts.append(HDLAssign(isigs.CRegRdData, isigs.Loc_CRegRdData))
    stmts.append(HDLAssign(isigs.CRegRdOK, isigs.Loc_CRegRdOK))
    stmts.append(HDLAssign(isigs.CRegWrOK, isigs.Loc_CRegWrOK))

def gen_hdl_cregrdmux_dff(root, module, isigs, pfx):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = '{}CRegRdMux_DFF'.format(pfx)
    gen_hdl_cregrdmux_asgn(proc.sync_stmts, isigs)
    module.stmts.append(proc)

def gen_hdl_no_cregrdmux_dff(root, module, isigs):
    module.stmts.append(HDLAssign(isigs.Loc_CRegRdData, HDLReplicate(bit_0, None)))
    module.stmts.append(HDLAssign(isigs.Loc_CRegRdOK, bit_0))
    module.stmts.append(HDLAssign(isigs.Loc_CRegWrOK, bit_0))
    gen_hdl_cregrdmux_asgn(module.stmts, isigs)

def gen_hdl_regrdmux(root, module, isigs, area, pfx, rd_reg):
    proc = HDLComb()
    proc.name = '{}RegRdMux'.format(pfx)
    proc.sensitivity.append(root.h_bus['adr'])
    proc.sensitivity.append(isigs.CRegRdData)
    proc.sensitivity.append(isigs.CRegRdOK)
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    if isinstance(area, tree.Block):
        stmt = gen_hdl_area_decode(root, module, area)
        stmt.then_stmts.append(sw)
        stmt.else_stmts.append(HDLAssign(isigs.Loc_RegRdData, isigs.CRegRdData))
        stmt.else_stmts.append(HDLAssign(isigs.Loc_RegRdOK, isigs.CRegRdOK))
        proc.stmts.append(stmt)
    else:
        proc.stmts.append(sw)
    for reg in rd_reg:
        loc = reg.h_loc_SRFF or reg.h_loc
        proc.sensitivity.append(loc)
        for i in reversed(range(reg.c_nwords)):
            ch = HDLChoiceExpr(reg.h_gena_regaddr[i])
            val = loc
            vwidth = reg.c_rwidth // reg.c_nwords
            val = HDLSlice(val, i * root.c_word_bits, vwidth)
            if vwidth < root.c_word_bits:
                val = HDLZext(val, vwidth)
            ch.stmts.append(HDLAssign(isigs.Loc_RegRdData, val))
            ch.stmts.append(HDLAssign(isigs.Loc_RegRdOK, bit_1))
            sw.choices.append(ch)
    ch = HDLChoiceDefault()
    ch.stmts.append(HDLAssign(isigs.Loc_RegRdData, isigs.CRegRdData))
    ch.stmts.append(HDLAssign(isigs.Loc_RegRdOK, isigs.CRegRdOK))
    sw.choices.append(ch)
    module.stmts.append(proc)

def gen_hdl_regrdmux_dff(root, module, pfx, isigs):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = '{}RegRdMux_DFF'.format(pfx)
    proc.sync_stmts.append(HDLAssign(isigs.RegRdData, isigs.Loc_RegRdData))
    proc.sync_stmts.append(HDLAssign(isigs.RegRdOK, isigs.Loc_RegRdOK))
    # proc.sync_stmts.append(HDLAssign(isigs.RegWrOK, isigs.Loc_RegWrOK))
    module.stmts.append(proc)

def gen_hdl_no_regrdmux(root, module, isigs):
    module.stmts.append(HDLAssign(isigs.Loc_RegRdData, isigs.CRegRdData))
    module.stmts.append(HDLAssign(isigs.Loc_RegRdOK, isigs.CRegRdOK))

    module.stmts.append(HDLAssign(isigs.RegRdData, isigs.Loc_RegRdData))
    module.stmts.append(HDLAssign(isigs.RegRdOK, isigs.Loc_RegRdOK))

def gen_hdl_regdone(root, module, isigs, root_isigs, rd_delay, wr_delay):
    asgn = HDLAssign(isigs.RegRdDone,
                     HDLAnd(HDLIndex(root_isigs.Loc_VMERdMem, rd_delay),
                            isigs.RegRdOK))
    module.stmts.append(asgn)
    asgn = HDLAssign(isigs.RegWrDone,
                     HDLAnd(HDLIndex(root_isigs.Loc_VMEWrMem, wr_delay),
                            isigs.CRegWrOK))
    module.stmts.append(asgn)
    if root.c_buserr:
        asgn = HDLAssign(isigs.RegRdError,
                         HDLAnd(HDLIndex(root_isigs.Loc_VMERdMem, rd_delay),
                                HDLNot(isigs.RegRdOK)))
        module.stmts.append(asgn)
        asgn = HDLAssign(isigs.RegWrError,
                         HDLAnd(HDLIndex(root_isigs.Loc_VMEWrMem, wr_delay),
                                HDLNot(isigs.CRegWrOK)))
        module.stmts.append(asgn)


def gen_hdl_mem_decls(mem, pfx, root, module, isigs):
    data = mem.elements[0]
    # Generate ports
    dwidth = min(data.width, root.c_word_bits)
    mem.h_sel = HDLPort('{}{}_Sel'.format(pfx, mem.name), dir='OUT')
    adr_sz = ilog2(mem.c_size) - root.c_addr_word_bits
    adr_lo = root.c_addr_word_bits
    mem.h_addr = HDLPort('{}{}_Addr'.format(pfx, mem.name),
                         size=adr_sz, lo_idx=adr_lo, dir='OUT')
    module.ports.extend([mem.h_sel, mem.h_addr])
    if data.access in READ_ACCESS:
        mem.h_rddata = HDLPort('{}{}_RdData'.format(pfx, mem.name), size=dwidth)
        module.ports.append(mem.h_rddata)
    if data.access in WRITE_ACCESS:
        mem.h_wrdata = HDLPort('{}{}_WrData'.format(pfx, mem.name), size=dwidth, dir='OUT')
        module.ports.append(mem.h_wrdata)
    if data.access in READ_ACCESS:
        mem.h_rdmem = HDLPort('{}{}_RdMem'.format(pfx, mem.name), dir='OUT')
        module.ports.append(mem.h_rdmem)
    if data.access in WRITE_ACCESS:
        mem.h_wrmem = HDLPort('{}{}_WrMem'.format(pfx, mem.name), dir='OUT')
        module.ports.append(mem.h_wrmem)
    if data.access in READ_ACCESS:
        mem.h_rddone = HDLPort('{}{}_RdDone'.format(pfx, mem.name))
        module.ports.append(mem.h_rddone)
    if data.access in WRITE_ACCESS:
        mem.h_wrdone = HDLPort('{}{}_WrDone'.format(pfx, mem.name))
        module.ports.append(mem.h_wrdone)
    if data.access in READ_ACCESS and root.c_buserr:
        mem.h_rderror = HDLPort('{}{}_RdError'.format(pfx, mem.name), default=bit_0)
        module.ports.append(mem.h_rderror)
    if data.access in WRITE_ACCESS and root.c_buserr:
        mem.h_wrerror = HDLPort('{}{}_WrError'.format(pfx, mem.name), default=bit_0)
        module.ports.append(mem.h_wrerror)
    # Create Sel_ signal
    sig = HDLSignal('Sel_{}{}'.format(pfx, mem.name))
    mem.h_wrsel = sig
    module.decls.append(sig)

def gen_hdl_reg2locmem_rd(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.Loc_MemRdData, isigs.RegRdData))
    stmts.append (HDLAssign(isigs.Loc_MemRdDone, isigs.RegRdDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.Loc_MemRdError, isigs.RegRdError))

def gen_hdl_memrdmux(root, module, isigs, area, pfx, mems):
    proc = HDLComb()
    proc.name = pfx + 'MemRdMux'
    proc.sensitivity.extend(
        [root.h_bus['adr'], isigs.RegRdData, isigs.RegRdDone])
    if root.c_buserr:
        proc.sensitivity.append(isigs.RegRdError)

    adr_sz = ilog2(area.c_size) - root.c_addr_word_bits
    adr_lo = root.c_addr_word_bits

    first = []
    last = first
    for m in mems:
        data = m.elements[0]
        if data.access in READ_ACCESS:
            proc.sensitivity.extend([m.h_rddata, m.h_rddone])
            if root.c_buserr:
                proc.sensitivity.append(m.h_rderror)
            proc.stmts.append(HDLAssign(m.h_wrsel, bit_0))
        cond = HDLAnd(HDLGe(HDLSlice(root.h_bus['adr'], adr_lo, adr_sz),
                            m.h_gena_sta),
                      HDLLe(HDLSlice(root.h_bus['adr'], adr_lo, adr_sz),
                            m.h_gena_end))
        stmt = HDLIfElse(cond)
        if data.access in READ_ACCESS:
            stmt.then_stmts.append(HDLAssign(m.h_wrsel, bit_1))
            stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdData, m.h_rddata))
            stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdDone, m.h_rddone))
            if root.c_buserr:
                stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdError, m.h_rderror))
        else:
            stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdData,
                                             HDLReplicate(bit_0, data.width)))
            stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdDone, bit_0))
            if root.c_buserr:
                stmt.then_stmts.append(HDLAssign(isigs.Loc_MemRdError, root.h_bus['rd']))
        last.append(stmt)
        last = stmt.else_stmts
    gen_hdl_reg2locmem_rd(root, module, isigs, last)
    if isinstance(area, tree.Block):
        stmt = gen_hdl_area_decode(root, module, area)
        stmt.then_stmts.extend(first)
        gen_hdl_reg2locmem_rd(root, module, isigs, stmt.else_stmts)
        proc.stmts.append(stmt)
    else:
        proc.stmts.extend(first)
    module.stmts.append(proc)


def gen_hdl_no_memrdmux(root, module, isigs):
    gen_hdl_reg2locmem_rd(root, module, isigs, module.stmts)


def gen_hdl_locmem2mem_rd(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.MemRdData, isigs.Loc_MemRdData))
    stmts.append (HDLAssign(isigs.MemRdDone, isigs.Loc_MemRdDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.MemRdError, isigs.Loc_MemRdError))


def gen_hdl_memrdmux_dff(root, module, isigs, pfx):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = pfx + 'MemRdMux_DFF'
    gen_hdl_locmem2mem_rd(root, module, isigs, proc.sync_stmts)
    module.stmts.append(proc)


def gen_hdl_no_memrdmux_dff(root, module, isigs):
    gen_hdl_locmem2mem_rd(root, module, isigs, module.stmts)


def gen_hdl_reg2locmem_wr(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.Loc_MemWrDone, isigs.RegWrDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.Loc_MemWrError, isigs.RegWrError))


def gen_hdl_memwrmux(root, module, isigs, area, pfx, mems):
    proc = HDLComb()
    proc.name = pfx + 'MemWrMux'
    proc.sensitivity.extend([root.h_bus['adr'], isigs.RegWrDone])
    if root.c_buserr:
        proc.sensitivity.append(isigs.RegWrError)

    adr_sz = ilog2(area.c_size) - root.c_addr_word_bits
    adr_lo = root.c_addr_word_bits

    first = []
    last = first
    for m in mems:
        data = m.elements[0]
        if data.access == 'wo':
            proc.stmts.append(HDLAssign(m.h_wrsel, bit_0))
        cond = HDLAnd(HDLGe(HDLSlice(root.h_bus['adr'], adr_lo, adr_sz),
                            m.h_gena_sta),
                      HDLLe(HDLSlice(root.h_bus['adr'], adr_lo, adr_sz),
                            m.h_gena_end))
        stmt = HDLIfElse(cond)
        if data.access == 'wo':
            stmt.then_stmts.append(HDLAssign(m.h_wrsel, bit_1))
        if data.access in WRITE_ACCESS:
            proc.sensitivity.append(m.h_wrdone)
            done = m.h_wrdone
        else:
            done = bit_0
        stmt.then_stmts.append(HDLAssign(isigs.Loc_MemWrDone, done))
        if root.c_buserr:
            if data.access in WRITE_ACCESS:
                proc.sensitivity.append(m.h_wrerror)
                err = m.h_wrerror
            else:
                err = root.h_bus['wr']
            stmt.then_stmts.append(HDLAssign(isigs.Loc_MemWrError, err))
        last.append(stmt)
        last = stmt.else_stmts
    gen_hdl_reg2locmem_wr(root, module, isigs, last)
    if isinstance(area, tree.Block):
        stmt = gen_hdl_area_decode(root, module, area)
        stmt.then_stmts.extend(first)
        gen_hdl_reg2locmem_wr(root, module, isigs, stmt.else_stmts)
        proc.stmts.append(stmt)
    else:
        proc.stmts.extend(first)
    module.stmts.append(proc)


def gen_hdl_no_memwrmux(root, module, isigs):
    gen_hdl_reg2locmem_wr(root, module, isigs, module.stmts)


def gen_hdl_locmem2mem_wr(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.MemWrDone, isigs.Loc_MemWrDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.MemWrError, isigs.Loc_MemWrError))


def gen_hdl_memwrmux_dff(root, module, isigs, pfx):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = pfx + 'MemWrMux_DFF'
    gen_hdl_locmem2mem_wr(root, module, isigs, proc.sync_stmts)
    module.stmts.append(proc)


def gen_hdl_no_memwrmux_dff(root, module, isigs):
    gen_hdl_locmem2mem_wr(root, module, isigs, module.stmts)


def gen_hdl_mem_asgn(root, module, isigs, area, mems):
    for m in mems:
        data = m.elements[0]
        adr_sz = ilog2(m.c_size) - root.c_addr_word_bits
        adr_lo = root.c_addr_word_bits
        module.stmts.append(
            HDLAssign(m.h_addr, HDLSlice(root.h_bus['adr'], adr_lo, adr_sz)))
        module.stmts.append(HDLAssign(m.h_sel, m.h_wrsel))
        if data.access in READ_ACCESS:
            module.stmts.append(HDLAssign(m.h_rdmem,
                                          HDLAnd(m.h_wrsel, root.h_bus['rd'])))
        if data.access in WRITE_ACCESS:
            module.stmts.append(HDLAssign(m.h_wrmem,
                                          HDLAnd(m.h_wrsel, root.h_bus['wr'])))
            module.stmts.append(HDLAssign(m.h_wrdata, root.h_bus['dati']))


def gen_hdl_mem2top_rd(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.RdData, isigs.MemRdData))
    stmts.append (HDLAssign(isigs.RdDone, isigs.MemRdDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.RdError, isigs.MemRdError))


def gen_hdl_mem2top_wr(root, module, isigs, stmts):
    stmts.append (HDLAssign(isigs.WrDone, isigs.MemWrDone))
    if root.c_buserr:
        stmts.append (HDLAssign(isigs.WrError, isigs.MemWrError))


def gen_hdl_area_decode(root, module, area):
    parent_width = ilog2(area._parent.c_size)
    a_width = ilog2(area.c_size)
    cond = HDLEq(HDLSlice(root.h_bus['adr'], a_width, parent_width - a_width),
                 area.h_gena_area)
    return HDLIfElse(cond)

def gen_hdl_areardmux(root, module, isigs, area, areas):
    proc = HDLComb()
    proc.name = 'AreaRdMux'
    proc.sensitivity.extend([root.h_bus['adr'], isigs.MemRdData, isigs.MemRdDone])

    first = []
    last = first
    for a in areas:
        proc.sensitivity.extend([a.h_isigs.RdData, a.h_isigs.RdDone])
        stmt = gen_hdl_area_decode(root, module, a)
        stmt.then_stmts.append(HDLAssign(isigs.RdData, a.h_isigs.RdData))
        stmt.then_stmts.append(HDLAssign(isigs.RdDone, a.h_isigs.RdDone))
        if root.c_buserr:
            proc.sensitivity.append(a.h_isigs.RdError)
            stmt.then_stmts.append(HDLAssign(isigs.RdError, a.h_isigs.RdError))
        last.append(stmt)
        last = stmt.else_stmts
    gen_hdl_mem2top_rd(root, module, isigs, last)
    proc.stmts.extend(first)
    module.stmts.append(proc)


def gen_hdl_areawrmux(root, module, isigs, area, areas):
    proc = HDLComb()
    proc.name = 'AreaWrMux'
    proc.sensitivity.extend([root.h_bus['adr'], isigs.MemWrDone])

    first = []
    last = first
    for a in areas:
        proc.sensitivity.append(a.h_isigs.WrDone)
        stmt = gen_hdl_area_decode(root, module, a)
        stmt.then_stmts.append(HDLAssign(isigs.WrDone, a.h_isigs.WrDone))
        if root.c_buserr:
            proc.sensitivity.append(a.h_isigs.WrError)
            stmt.then_stmts.append(HDLAssign(isigs.WrError, a.h_isigs.WrError))
        last.append(stmt)
        last = stmt.else_stmts
    gen_hdl_mem2top_wr(root, module, isigs, last)
    proc.stmts.extend(first)
    module.stmts.append(proc)

def gen_hdl_no_area(root, module, isigs):
    module.stmts.append (HDLAssign(isigs.RdData, isigs.MemRdData))
    module.stmts.append (HDLAssign(isigs.RdDone, isigs.MemRdDone))
    module.stmts.append (HDLAssign(isigs.WrDone, isigs.MemWrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.RdError, isigs.MemRdError))
        module.stmts.append (HDLAssign(isigs.WrError, isigs.MemWrError))

def gen_hdl_area_decls(area, pfx, root, module, isigs):
    area.h_isigs = isigs

    sigs = [('{}CRegRdData', root.c_word_bits),
            ('{}CRegRdOK', None),
            ('{}CRegWrOK', None),
            ('Loc_{}CRegRdData', root.c_word_bits),
            ('Loc_{}CRegRdOK', None),
            ('Loc_{}CRegWrOK', None),
            ('{}RegRdDone', None),
            ('{}RegWrDone', None),
            ('{}RegRdData', root.c_word_bits),
            ('{}RegRdOK', None),
            ('Loc_{}RegRdData', root.c_word_bits),
            ('Loc_{}RegRdOK', None),
            ('{}MemRdData', root.c_word_bits),
            ('{}MemRdDone', None),
            ('{}MemWrDone', None),
            ('Loc_{}MemRdData', root.c_word_bits),
            ('Loc_{}MemRdDone', None),
            ('Loc_{}MemWrDone', None),
            ('{}RdData', root.c_word_bits),
            ('{}RdDone', None),
            ('{}WrDone', None)]
    if root.c_buserr:
        sigs.extend([('{}RegRdError', None),
                     ('{}RegWrError', None),
                     ('{}MemRdError', None),
                     ('{}MemWrError', None),
                     ('Loc_{}MemRdError', None),
                     ('Loc_{}MemWrError', None),
                     ('{}RdError', None),
                     ('{}WrError', None),])
    for tpl, size in sigs:
        name = tpl.format(pfx)
        s = HDLSignal(name, size)
        setattr(isigs, tpl.format(''), s)
        module.decls.append(s)


def gen_hdl_area(area, pfx, root, module, root_isigs):
    isigs = area.h_isigs

    regs = []
    mems = []
    blks = []
    for el in area.elements:
        if isinstance(el, tree.Reg):
            regs.append(el)
        elif isinstance(el, tree.Array):
            mems.append(el)
        elif isinstance(el, tree.Block):
            if el.submap_file is not None:
                include = get_gena_gen(el, 'include', None)
            else:
                # A regular area.
                include = True
            if include is not None:
                blks.append(el)
        else:
            raise AssertionError

    for el in regs:
        gen_hdl_reg_decls(el, pfx, root, module, isigs)
        gen_hdl_reg_insts(el, pfx, root, module, isigs)

    wr_reg = []
    rd_reg = []
    for reg in regs:
        gen_hdl_reg_stmts(reg, pfx, root, module, isigs)
        if reg.access in WRITE_ACCESS:
            wr_reg.append(reg)
        else:
            rd_reg.append(reg)
    if wr_reg:
        gen_hdl_wrseldec(root, module, isigs, area, pfx, wr_reg)
        gen_hdl_cregrdmux(root, module, isigs, area, pfx, wr_reg)
        gen_hdl_cregrdmux_dff(root, module, isigs, pfx)
        wr_delay = 1
    else:
        gen_hdl_no_cregrdmux_dff(root, module, isigs)
        wr_delay = 0
    if rd_reg:
        gen_hdl_regrdmux(root, module, isigs, area, pfx, rd_reg)
        gen_hdl_regrdmux_dff(root, module, pfx, isigs)
        rd_delay = wr_delay + 1
    else:
        gen_hdl_no_regrdmux(root, module, isigs)
        rd_delay = wr_delay

    gen_hdl_regdone(root, module, isigs, root_isigs, rd_delay, wr_delay)

    if mems:
        for el in mems:
            gen_hdl_mem_decls(el, pfx, root, module, isigs)
        gen_hdl_memrdmux(root, module, isigs, area, pfx, mems)
        gen_hdl_memrdmux_dff(root, module, isigs, pfx)
        gen_hdl_memwrmux(root, module, isigs, area, pfx, mems)
        gen_hdl_memwrmux_dff(root, module, isigs, pfx)
        gen_hdl_mem_asgn(root, module, isigs, area, mems)
    else:
        gen_hdl_no_memrdmux(root, module, isigs)
        gen_hdl_no_memrdmux_dff(root, module, isigs)
        gen_hdl_no_memwrmux(root, module, isigs)
        gen_hdl_no_memwrmux_dff(root, module, isigs)

    if blks:
        for el in blks:
            el_isigs = gen_hdl.Isigs()
            npfx = pfx + el.name + '_'
            gen_hdl_area_decls(el, npfx, root, module, el_isigs)
        gen_hdl_areardmux(root, module, isigs, area, blks)
        gen_hdl_areawrmux(root, module, isigs, area, blks)
        for el in blks:
            npfx = pfx + el.name + '_'
            gen_hdl_area(el, npfx, root, module, root_isigs)
    else:
        gen_hdl_no_area(root, module, isigs)

def gen_hdl_components(root, module):
    if root.h_has_srff:
        comp = HDLComponent('SRFFxN')
        param_n = HDLParam('N', typ='P', value=HDLNumber(16))
        comp.params.append(param_n)
        comp.ports.extend([HDLPort('Clk'),
                           HDLPort('Rst', default=bit_0),
                           HDLPort('Set', HDLSub(param_n, HDLNumber(1))),
                           HDLPort('Clr', default=bit_0),
                           HDLPort('Q', HDLSub(param_n, HDLNumber(1)), dir='OUT')])
        module.decls.insert(0, comp)
        spec = HDLComponentSpec(comp, "CommonVisual.SRFFxN(V1)")
        module.decls.insert(1, spec)
    if root.h_has_creg:
        comp = HDLComponent('CtrlRegN')
        param_n = HDLParam('N', typ='I', value=HDLNumber(16))
        comp.params.append(param_n)
        comp.ports.extend([HDLPort('Clk'),
                           HDLPort('Rst'),
                           HDLPort('CRegSel'),
                           HDLPort('WriteMem'),
                           HDLPort('VMEWrData', HDLSub(param_n, HDLNumber(1))),
                           HDLPort('AutoClrMsk', HDLSub(param_n, HDLNumber(1))),
                           HDLPort('CReg',
                                   HDLSub(param_n, HDLNumber(1)), dir='OUT'),
                           HDLPort('Preset', HDLSub(param_n, HDLNumber(1)))])
        module.decls.insert(0, comp)
        spec = HDLComponentSpec(comp, "CommonVisual.CtrlRegN(V1)")
        module.decls.insert(1, spec)
    if root.h_has_rmw:
        comp = HDLComponent('RMWReg')
        param_n = HDLParam('N', typ='N', value=HDLNumber(8))
        comp.params.append(param_n)
        comp.ports.extend([HDLPort('VMEWrData',
                                   HDLSub(HDLMul(HDLNumber(2), param_n),
                                          HDLNumber(1))),
                           HDLPort('Clk'),
                           HDLPort('AutoClrMsk', HDLSub(param_n, HDLNumber(1))),
                           HDLPort('Rst'),
                           HDLPort('CRegSel'),
                           HDLPort('CReg',
                                   HDLSub(param_n, HDLNumber(1)), dir='OUT'),
                           HDLPort('WriteMem'),
                           HDLPort('Preset', HDLSub(param_n, HDLNumber(1)))])
        module.decls.insert(0, comp)
        spec = HDLComponentSpec(comp, "CommonVisual.RMWReg(RMWReg)")
        module.decls.insert(1, spec)

def gen_hdl_strobeseq(root, module, isigs):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = 'StrobeSeq'
    proc.sync_stmts.append(HDLAssign(
        isigs.Loc_VMERdMem,
        HDLConcat(HDLSlice(isigs.Loc_VMERdMem, 0, 2), root.h_bus['rd'])))
    proc.sync_stmts.append(HDLAssign(
        isigs.Loc_VMEWrMem,
        HDLConcat(HDLSlice(isigs.Loc_VMEWrMem, 0, None), root.h_bus['wr'])))
    module.stmts.append(proc)


def gen_hdl_misc_root(root, module, isigs):
    module.stmts.append (HDLAssign(root.h_bus['dato'], isigs.RdData))
    module.stmts.append (HDLAssign(root.h_bus['rack'], isigs.RdDone))
    module.stmts.append (HDLAssign(root.h_bus['wack'], isigs.WrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(root.h_bus['rderr'], isigs.RdError))
        module.stmts.append (HDLAssign(root.h_bus['wrerr'], isigs.WrError))

def gen_gena_regctrl(root):
    module, isigs = gen_hdl.gen_hdl_header(root)
    module.name = 'RegCtrl_{}'.format(root.name)
    module.libraries.append('CommonVisual')
    lib = get_gena_gen(root, 'vhdl-library')
    if lib:
        module.libraries.append(lib)
    else:
        lib = 'work'
    module.deps.append((lib, 'MemMap_{}'.format(root.name)))
    isigs = gen_hdl.Isigs()
    isigs.Loc_VMERdMem = HDLSignal('Loc_VMERdMem', 3)
    isigs.Loc_VMEWrMem = HDLSignal('Loc_VMEWrMem', 2)
    module.decls.extend([isigs.Loc_VMERdMem, isigs.Loc_VMEWrMem])
    root.h_has_rmw = False
    root.h_has_creg = False
    root.h_has_srff = False
    gen_hdl_area_decls(root, '', root, module, isigs)
    gen_hdl_area(root, '', root, module, isigs)

    gen_hdl_strobeseq(root, module, isigs)
    gen_hdl_misc_root(root, module, isigs)

    gen_hdl_components(root, module)

    return module
