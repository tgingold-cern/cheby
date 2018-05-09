from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLComponent, HDLComponentSpec,
                           HDLSignal, HDLPort, HDLParam,
                           bit_0, bit_1,
                           HDLSlice, HDLIndex,
                           HDLSub, HDLMul,
                           HDLAnd, HDLNot,
                           HDLZext, HDLReplicate, HDLConcat,
                           HDLAssign,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLInstance, HDLComb, HDLSync,
                           HDLNumber)
from gen_gena_memmap import subsuffix
import cheby.gen_hdl as gen_hdl

def gen_hdl_reg_decls(reg, pfx, root, module, isigs):
    # Generate ports
    for f in reg.fields:
        mode = 'OUT' if reg.access in ('rw', 'wo') else 'IN'
        sz, lo = (None, None) if f.hi is None else (f.c_width, f.lo)
        portname = reg.name + (('_' + f.name) if f.name is not None else '')
        port = HDLPort(portname, size=sz, lo_idx=lo, dir=mode)
        f.h_port = port
        module.ports.append(f.h_port)
    # Create Loc_ signal
    reg.h_loc = HDLSignal('Loc_{}'.format(reg.name), reg.c_rwidth)
    module.decls.append(reg.h_loc)
    # Create Sel_ signal
    if reg.access in ('rw', 'wo'):
        reg.h_wrsel = []
        for i in reversed(range(reg.c_nwords)):
            sig = HDLSignal('WrSel_{}{}'.format(
                reg.name, subsuffix(i, reg.c_nwords)))
            reg.h_wrsel.insert(0, sig)
            module.decls.append(sig)
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
            inst = HDLInstance(
                'Reg_{}{}'.format(reg.name, subsuffix(i, reg.c_nwords)),
                reg_tpl)
            iwidth = reg.c_rwidth // reg.c_nwords
            inst.params = [('N', HDLNumber(iwidth))]
            inst.conns = [
                ('VMEWrData', HDLSlice(root.h_bus['dati'], 0,
                                       reg.c_dwidth // reg.c_nwords)),
                ('Clk', root.h_bus['clk']),
                ('Rst', root.h_bus['rst']),
                ('WriteMem', root.h_bus['wr']),
                ('CRegSel', reg.h_wrsel[i]),
                ('AutoClrMsk', reg.h_gena_acm[i]),
                ('Preset', reg.h_gena_psm[i]),
                ('CReg', HDLSlice(reg.h_loc, i * iwidth, iwidth))]
            module.stmts.append(inst)

def gen_hdl_reg_stmts(reg, pfx, root, module, isigs, wr_reg, rd_reg):
    # Create bitlist, a list of ordered (lo + width, lo, field)
    # Fill gaps with (lo + width, lo, None)
    bitlist = []
    nbit = 0
    for f in sorted(reg.fields, key=(lambda x: x.lo)):
        if f.lo > nbit:
            bitlist.append((f.lo, nbit, None))
        nbit = f.lo + f.c_width
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
            module.stmts.append(HDLAssign(tgt, src))
        else:
            if f is not None:
                module.stmts.append(HDLAssign(src, tgt))
    if reg.access in ('rw', 'wo'):
        wr_reg.append(reg)
    if reg.access in ('ro'):
        rd_reg.append(reg)

def gen_hdl_wrseldec(root, module, isigs, area, wrseldec):
    proc = HDLComb()
    proc.name = 'WrSelDec'
    proc.sensitivity.append(root.h_bus['adr'])
    for r in wrseldec:
        for i in reversed(range(r.c_nwords)):
            proc.stmts.append(HDLAssign(r.h_wrsel[i], bit_0))
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
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

def gen_hdl_cregrdmux(root, module, isigs, area, wrseldec):
    proc = HDLComb()
    proc.name = 'CRegRdMux'
    proc.sensitivity.append(root.h_bus['adr'])
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    proc.stmts.append(sw)
    for reg in wrseldec:
        proc.sensitivity.append(reg.h_loc)
        for i in reversed(range(reg.c_nwords)):
            ch = HDLChoiceExpr(reg.h_gena_regaddr[i])
            if reg.access == 'wo':
                val = HDLReplicate(bit_0, None)
                ok = bit_0
            else:
                val = reg.h_loc
                val = HDLSlice(val, i * root.c_word_bits,
                               reg.c_rwidth // reg.c_nwords)
                if reg.c_rwidth < root.c_word_bits:
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

def gen_hdl_cregrdmux_dff(root, module, isigs):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = 'CRegRdMux_DFF'
    proc.sync_stmts.append(HDLAssign(isigs.CRegRdData, isigs.Loc_CRegRdData))
    proc.sync_stmts.append(HDLAssign(isigs.CRegRdOK, isigs.Loc_CRegRdOK))
    proc.sync_stmts.append(HDLAssign(isigs.CRegWrOK, isigs.Loc_CRegWrOK))
    module.stmts.append(proc)

def gen_hdl_regrdmux(root, module, isigs, area, rd_reg):
    proc = HDLComb()
    proc.name = 'RegRdMux'
    proc.sensitivity.append(root.h_bus['adr'])
    proc.sensitivity.append(isigs.CRegRdData)
    proc.sensitivity.append(isigs.CRegRdOK)
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    proc.stmts.append(sw)
    for reg in rd_reg:
        proc.sensitivity.append(reg.h_loc)
        for i in reversed(range(reg.c_nwords)):
            ch = HDLChoiceExpr(reg.h_gena_regaddr[i])
            val = reg.h_loc
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

def gen_hdl_regrdmux_dff(root, module, isigs):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = 'RegRdMux_DFF'
    proc.sync_stmts.append(HDLAssign(isigs.RegRdData, isigs.Loc_RegRdData))
    proc.sync_stmts.append(HDLAssign(isigs.RegRdOK, isigs.Loc_RegRdOK))
    # proc.sync_stmts.append(HDLAssign(isigs.RegWrOK, isigs.Loc_RegWrOK))
    module.stmts.append(proc)

def gen_hdl_no_regrdmux(root, module, isigs):
    module.stmts.append(HDLAssign(isigs.Loc_RegRdData, isigs.CRegRdData))
    module.stmts.append(HDLAssign(isigs.Loc_RegRdOK, isigs.CRegRdOK))

    module.stmts.append(HDLAssign(isigs.RegRdData, isigs.Loc_RegRdData))
    module.stmts.append(HDLAssign(isigs.RegRdOK, isigs.Loc_RegRdOK))

def gen_hdl_regdone(root, module, isigs, root_isigs, rd_delay):
    asgn = HDLAssign(isigs.RegRdDone,
                     HDLAnd(HDLIndex(root_isigs.Loc_VMERdMem, rd_delay),
                            isigs.RegRdOK))
    module.stmts.append(asgn)
    asgn = HDLAssign(isigs.RegWrDone,
                     HDLAnd(HDLIndex(root_isigs.Loc_VMEWrMem, 1),
                            isigs.CRegWrOK))
    module.stmts.append(asgn)
    if root.c_buserr:
        asgn = HDLAssign(isigs.RegRdError,
                         HDLAnd(HDLIndex(root_isigs.Loc_VMERdMem, 2),
                                HDLNot(isigs.RegRdOK)))
        module.stmts.append(asgn)
        asgn = HDLAssign(isigs.RegWrError,
                         HDLAnd(HDLIndex(root_isigs.Loc_VMEWrMem, 1),
                                HDLNot(isigs.CRegWrOK)))
        module.stmts.append(asgn)


def gen_hdl_misc(root, module, isigs):
    module.stmts.append (HDLAssign(isigs.Loc_MemRdData, isigs.RegRdData))
    module.stmts.append (HDLAssign(isigs.Loc_MemRdDone, isigs.RegRdDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.Loc_MemRdError, isigs.RegRdError))

    module.stmts.append (HDLAssign(isigs.MemRdData, isigs.Loc_MemRdData))
    module.stmts.append (HDLAssign(isigs.MemRdDone, isigs.Loc_MemRdDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.MemRdError, isigs.Loc_MemRdError))

    module.stmts.append (HDLAssign(isigs.Loc_MemWrDone, isigs.RegWrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.Loc_MemWrError, isigs.RegWrError))

    module.stmts.append (HDLAssign(isigs.MemWrDone, isigs.Loc_MemWrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.MemWrError, isigs.Loc_MemWrError))

    module.stmts.append (HDLAssign(isigs.RdData, isigs.MemRdData))
    module.stmts.append (HDLAssign(isigs.RdDone, isigs.MemRdDone))
    module.stmts.append (HDLAssign(isigs.WrDone, isigs.MemWrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(isigs.RdError, isigs.MemRdError))
        module.stmts.append (HDLAssign(isigs.WrError, isigs.MemWrError))

def gen_hdl_strobeseq(root, module, isigs):
    proc = HDLSync(root.h_bus['clk'], None)
    proc.name = 'StrobeSeq'
    proc.sync_stmts.append(HDLAssign(
        isigs.Loc_VMERdMem,
        HDLConcat(HDLSlice(isigs.Loc_VMERdMem, 0, 2), root.h_bus['rd'])))
    proc.sync_stmts.append(HDLAssign(
        isigs.Loc_VMEWrMem,
        HDLConcat(HDLSlice(isigs.Loc_VMEWrMem, 0, 1), root.h_bus['wr'])))
    module.stmts.append(proc)

def gen_hdl_misc_root(root, module, isigs):
    module.stmts.append (HDLAssign(root.h_bus['dato'], isigs.RdData))
    module.stmts.append (HDLAssign(root.h_bus['rack'], isigs.RdDone))
    module.stmts.append (HDLAssign(root.h_bus['wack'], isigs.WrDone))
    if root.c_buserr:
        module.stmts.append (HDLAssign(root.h_bus['rderr'], isigs.RdError))
        module.stmts.append (HDLAssign(root.h_bus['wrerr'], isigs.WrError))

def gen_hdl_area(area, pfx, root, module, root_isigs):
    isigs = gen_hdl.Isigs()
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
    for el in area.elements:
        npfx = '_'.join([pfx, el.name])
        if isinstance(el, tree.Reg):
            gen_hdl_reg_decls(el, npfx, root, module, isigs)
        else:
            raise AssertionError

    wr_reg = []
    rd_reg = []
    for el in area.elements:
        npfx = '_'.join([pfx, el.name])
        if isinstance(el, tree.Reg):
            gen_hdl_reg_stmts(el, npfx, root, module, isigs, wr_reg, rd_reg)
        else:
            raise AssertionError

    if wr_reg:
        gen_hdl_wrseldec(root, module, isigs, area, wr_reg)
        gen_hdl_cregrdmux(root, module, isigs, area, wr_reg)
        gen_hdl_cregrdmux_dff(root, module, isigs)
    if rd_reg:
        gen_hdl_regrdmux(root, module, isigs, area, rd_reg)
        gen_hdl_regrdmux_dff(root, module, isigs)
        rd_delay = 2
    else:
        gen_hdl_no_regrdmux(root, module, isigs)
        rd_delay = 1

    gen_hdl_regdone(root, module, isigs, root_isigs, rd_delay)

    gen_hdl_misc(root, module, isigs)

    gen_hdl_strobeseq(root, module, root_isigs)
    gen_hdl_misc_root(root, module, isigs)

def gen_hdl_components(root, module):
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

def gen_gena_regctrl(root):
    module, isigs = gen_hdl.gen_hdl_header(root)
    module.name = 'RegCtrl_{}'.format(root.name)
    module.libraries.append('CommonVisual')
    module.deps.append('MemMap_{}'.format(root.name))
    isigs = gen_hdl.Isigs()
    isigs.Loc_VMERdMem = HDLSignal('Loc_VMERdMem', 3)
    isigs.Loc_VMEWrMem = HDLSignal('Loc_VMEWrMem', 2)
    module.decls.extend([isigs.Loc_VMERdMem, isigs.Loc_VMEWrMem])
    root.h_has_rmw = False
    root.h_has_creg = False
    gen_hdl_area(root, '', root, module, isigs)
    gen_hdl_components(root, module)

    return module
