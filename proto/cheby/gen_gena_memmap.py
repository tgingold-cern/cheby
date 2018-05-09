from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLPackage,
                           HDLComment, HDLComponent, HDLComponentSpec,
                           HDLConstant, HDLSignal, HDLPort, HDLParam,
                           bit_0, bit_1,
                           HDLSlice, HDLIndex,
                           HDLSub, HDLMul,
                           HDLAnd, HDLNot,
                           HDLZext, HDLReplicate, HDLConcat,
                           HDLAssign,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLInstance, HDLComb, HDLSync,
                           HDLHexConst, HDLBinConst, HDLNumber)
import cheby.gen_hdl as gen_hdl

def get_gena(n, name, default=None):
    return n.get_extension('x_gena', name, default)

def get_note(n):
    return get_gena(n, 'note', '')

def gen_header(root, decls):
    if hasattr(root, 'x_gena'):
        cpfx = 'C_{}'.format(root.name)
        ident_code = root.x_gena.get('ident-code')
        if ident_code:
            width = root.c_word_size * tree.BYTE_SIZE
            decls.append(HDLComment('Ident Code'))
            decls.append(HDLConstant(cpfx + '_IdentCode', width,
                         value=HDLHexConst(ident_code, width)))

        version = root.x_gena.get('map-version')
        if version:
            decls.append(HDLComment('Memory Map Version'))
            cst = HDLConstant(cpfx + '_MemMapVersion', 32,
                              value=HDLHexConst(version, 32))
            cst.eol_comment='{}'.format(version)
            decls.append(cst)

def gen_addr_cst(decls, addr, name, addr_width, block_width, word_width):
    val = HDLBinConst(addr, addr_width)
    cst = HDLConstant(name, addr_width, lo_idx=block_width, value=val)
    # FIXME: Gena word address is wrong.
    cst.eol_comment = \
        ' : Word address : "{:0{}b}" & X"{:0{}x}"; Byte Address : X"{:0{}x}"'.format(
        addr >> (4 * (addr_width // 4)), (addr_width % 4),
        addr, addr_width // 4,
        (addr << word_width) & ((1 << addr_width) - 1), addr_width // 4)
    decls.append(cst)
    return cst

def gen_reg_addr(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Addresses : {}'.format(name),
                             nl=False))
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(n.c_size) - word_width

    for reg in n.elements:
        if isinstance(reg, tree.Reg):
            addr = reg.c_address // root.c_word_size
            # FIXME: Gena looks to use 1 instead of word_width
            if reg.c_size > root.c_word_size:
                num = reg.c_size // root.c_word_size
                reg.h_gena_regaddr = []
                for i in range(num):
                    cst = gen_addr_cst(decls, addr + i,
                        'C_Reg_{}_{}_{}'.format(pfx, reg.name, num - i - 1),
                        addr_width, word_width, 1)
                    reg.h_gena_regaddr.append(cst)
            else:
                cst = gen_addr_cst(decls, addr,
                        'C_Reg_{}_{}'.format(pfx, reg.name),
                        addr_width, word_width, 1)
                reg.h_gena_regaddr = cst

def compute_acm(reg):
    res = get_gena(reg, 'auto-clear', 0)
    for f in reg.fields:
        v = get_gena(f, 'auto-clear', None)
        if v is not None:
            res = (res & ~(1 << f.lo)) | (v << f.lo)
    return res

def compute_preset(reg):
    res = get_gena(reg, 'preset', 0)
    for f in reg.fields:
        v = f.preset
        if v is not None:
            res = (res & ~(1 << f.lo)) | (v << f.lo)
    return res

def gen_mask(decls, mask, root, reg, pfx):
    def gen_one_mask(acm, name, w, lo_idx):
        acm &= (1 << w) - 1
        cst = HDLConstant(name, w, lo_idx=lo_idx, value=HDLBinConst(acm, w))
        cst.eol_comment = ' : Value : X"{:0{}x}"'.format(acm, w / 4)
        return cst

    word_width = root.c_word_size * tree.BYTE_SIZE
    if reg.width <= word_width:
        reg_width = reg.width
        if get_gena(reg, 'type', None) == 'rmw':
            reg_width //= 2
        res = gen_one_mask(mask, '{}_{}'.format(pfx, reg.name), reg_width, 0)
        decls.append(res)
        return res
    else:
        num = reg.width / word_width
        res = []
        for i in reversed(range(num)):
            r = gen_one_mask(mask >> (i * word_width),
                            '{}_{}_{}'.format(pfx, reg.name, i),
                            word_width, i * word_width)
            decls.append(r)
            res.insert(0, r)
        return res

def gen_reg_acm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Auto Clear Masks : {}'.format(name)))

    mpfx = 'C_ACM_{}'.format(pfx)
    for e in n.elements:
        if isinstance(e, tree.Reg):
            acm = compute_acm(e)
            e.h_gena_acm = gen_mask(decls, acm, root, e, mpfx)

def gen_reg_psm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Preset Masks : {}'.format(name)))
    mpfx = 'C_PSM_{}'.format(pfx)
    for e in n.elements:
        if isinstance(e, tree.Reg):
            psm = compute_preset(e)
            e.h_gena_psm = gen_mask(decls, psm, root, e, mpfx)

def gen_code_fields(n, root, decls):
    decls.append(HDLComment('CODE FIELDS'))

    def gen_one_cf(codes, pfx, sz, lo_idx=0):
        for cf in codes:
            cf = cf['code-field']
            cst = HDLConstant(pfx + '_' + cf['name'], sz, lo_idx=lo_idx,
                              value=HDLBinConst(cf['code'], sz))
            decls.append(cst)

    for e in reversed(n.elements):
        if isinstance(e, tree.Reg):
            # code-fields for fields
            for f in e.fields:
                codes = get_gena(f, 'code-fields', None)
                if codes is not None:
                    gen_one_cf(codes, 'C_Code_{}_{}_{}'.format(
                                root.name, e.name, f.name),
                               f.c_width, f.lo)
            # code-fiels for registers
            codes = get_gena(e, 'code-fields', None)
            if codes is not None:
                width = max([(f.hi or f.lo) + 1 for f in e.fields])
                gen_one_cf(codes, 'C_Code_{}_{}'.format(root.name, e.name),
                           width, 0)

def gen_memory_data(n, root, decls, name, pfx):
    decls.append(HDLComment('Memory Data : {}'.format(name), nl=False))
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(n.c_size) - word_width
    for e in n.elements:
        if isinstance(e, tree.Array):
            addr = e.c_address >> word_width
            gen_addr_cst(decls, addr, 'C_Mem_{}_{}_Sta'.format(pfx, e.name),
                addr_width, word_width, 1)
            addr = (e.c_address + e.c_size - 1) >> word_width
            gen_addr_cst(decls, addr, 'C_Mem_{}_{}_End'.format(pfx, e.name),
                addr_width, word_width, 1)

def gen_submap_addr(n, root, decls, name, pfx):
    decls.append(HDLComment('Submap Addresses : {}'.format(name), nl=False))
    # word_width = ilog2(root.c_word_size)
    for e in n.elements:
        if isinstance(e, tree.Block) and e.submap_file is not None:
            block_width = ilog2(e.c_size)
            addr_width = ilog2(n.c_size) - block_width
            addr = e.c_address >> block_width
            gen_addr_cst(decls, addr, 'C_Submap_{}_{}'.format(pfx, e.name),
                addr_width, block_width, 1)

def gen_block(n, root, decls, name, pfx):
    gen_reg_addr(n, root, decls, name, pfx)
    gen_reg_acm(n, root, decls, name, pfx)
    gen_reg_psm(n, root, decls, name, pfx)
    gen_code_fields(n, root, decls)
    gen_memory_data(n, root, decls, name, pfx)
    gen_submap_addr(n, root, decls, name, pfx)

def gen_areas_address(areas, root, decls):
    # decls.append(HDLComment('Memory Areas.'))
    cpfx = 'C_Area_{}'.format(root.name)
    addr_width = ilog2(root.c_size)
    for e in areas:
        area_width = ilog2(e.c_size)
        sz = addr_width - area_width
        cst = HDLConstant(cpfx + '_' + e.name, sz, lo_idx=area_width,
                          value=HDLBinConst(e.c_address >> area_width, sz))
        #cst.eol_comment = '{} : Word Address : X"{:X}"; Byte Address : 0x{:x}'.format(
        #    get_note(e), e.c_address // root.c_word_size, e.c_address)
        decls.append(cst)

def gen_gena_memmap(root):
    res = HDLPackage()
    res.name = 'MemMap_{}'.format(root.name)
    decls = []
    gen_header(root, decls)

    areas = [e for e in root.elements
             if isinstance(e, tree.Block) and not hasattr(e, 'c_submap')] # or isinstance(e, tree.Array))]
    if areas:
        gen_areas_address(areas, root, decls)
        for e in areas:
            name = 'Area {}'.format(e.name)
            pfx = '{}_{}'.format(root.name, e.name)
            gen_block(e, root, decls, name, pfx)

    gen_block(root, root, decls, 'Memory Map', root.name)

    res.decls = decls
    return res

def gen_hdl_reg_decls(reg, pfx, root, module, isigs):
    # Generate ports
    for f in reg.fields:
        mode = 'OUT' if reg.access in ('rw', 'wo') else 'IN'
        sz = None if f.hi is None else f.c_width
        portname = reg.name + (('_' + f.name) if f.name is not None else '')
        port = HDLPort(portname, size=sz, dir=mode)
        f.h_port = port
        module.ports.append(f.h_port)
    # Create Loc_ signal
    reg.h_loc = HDLSignal('Loc_{}'.format(reg.name), reg.c_rwidth)
    module.signals.append(reg.h_loc)
    # Create Sel_ signal
    if reg.access in ('rw', 'wo'):
        reg.h_wrsel = HDLSignal('WrSel_{}'.format(reg.name))
        module.signals.append(reg.h_wrsel)
        # Create Register
        gena_type = reg.get_extension('x_gena', 'type')
        if gena_type == 'rmw':
            reg_tpl = 'RMWReg'
        elif gena_type is None:
            reg_tpl = 'CtrlRegN'
        else:
            raise AssertionError
        inst = HDLInstance('Reg_{}'.format(reg.name), reg_tpl)
        inst.params = [('N', HDLNumber(reg.c_rwidth))]
        inst.conns = [
            ('VMEWrData', HDLSlice(root.h_bus['dati'], 0, reg.c_dwidth)),
            ('Clk', root.h_bus['clk']),
            ('Rst', root.h_bus['rst']),
            ('WriteMem', root.h_bus['wr']),
            ('CRegSel', reg.h_wrsel),
            ('AutoClrMsk', reg.h_gena_acm),
            ('Preset', reg.h_gena_psm),
            ('CReg', HDLSlice(reg.h_loc, 0, reg.c_rwidth))]
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
            if hi == lo + 1:
                src = HDLIndex(reg.h_gena_psm, lo)
            else:
                src = HDLSlice(reg.h_gena_psm, lo, hi - lo)
        else:
            src = f.h_port
        if reg.access in ('ro'):
            module.stmts.append(HDLAssign(tgt, src))
        else:
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
        proc.stmts.append(HDLAssign(r.h_wrsel, bit_0))
    sw = HDLSwitch(HDLSlice(root.h_bus['adr'],
                            root.c_addr_word_bits,
                            ilog2(area.c_size) - root.c_addr_word_bits))
    proc.stmts.append(sw)
    for reg in wrseldec:
        ch = HDLChoiceExpr(reg.h_gena_regaddr)
        ch.stmts.append(HDLAssign(reg.h_wrsel, bit_1))
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
        ch = HDLChoiceExpr(reg.h_gena_regaddr)
        proc.sensitivity.append(reg.h_loc)
        if reg.access == 'wo':
            val = HDLReplicate(bit_0, None)
            ok = bit_0
        else:
            val = reg.h_loc
            val = HDLSlice(val, 0, reg.c_rwidth)
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
        ch = HDLChoiceExpr(reg.h_gena_regaddr)
        proc.sensitivity.append(reg.h_loc)
        val = reg.h_loc
        val = HDLSlice(val, 0, reg.c_rwidth)
        if reg.c_rwidth < root.c_word_bits:
            val = HDLZext(val, root.c_word_bits)
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

def gen_hdl_regdone(root, module, isigs, root_isigs):
    asgn = HDLAssign(isigs.RegRdDone,
                     HDLAnd(HDLIndex(root_isigs.Loc_VMERdMem, 2),
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
        module.signals.append(s)
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
    gen_hdl_regdone(root, module, isigs, root_isigs)

    gen_hdl_misc(root, module, isigs)

    gen_hdl_strobeseq(root, module, root_isigs)
    gen_hdl_misc_root(root, module, isigs)

def gen_hdl_components(root, module):
    if True:
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
        module.signals.insert(0, comp)
        spec = HDLComponentSpec(comp, "CommonVisual.CtrlRegN(V1)")
        module.signals.insert(1, spec)
    if True:
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
        module.signals.insert(0, comp)
        spec = HDLComponentSpec(comp, "CommonVisual.RMWReg(RMWReg)")
        module.signals.insert(1, spec)

def gen_gena_regctrl(root):
    module, isigs = gen_hdl.gen_hdl_header(root)
    module.name = 'RegCtrl_{}'.format(root.name)
    module.libraries.append('CommonVisual')
    module.deps.append('MemMap_{}'.format(root.name))
    isigs = gen_hdl.Isigs()
    isigs.Loc_VMERdMem = HDLSignal('Loc_VMERdMem', 3)
    isigs.Loc_VMEWrMem = HDLSignal('Loc_VMEWrMem', 2)
    module.signals.extend([isigs.Loc_VMERdMem, isigs.Loc_VMEWrMem])
    gen_hdl_area(root, '', root, module, isigs)
    gen_hdl_components(root, module)

    return module
