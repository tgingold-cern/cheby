from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLPackage,
                           HDLComment,
                           HDLConstant,
                           HDLHexConst, HDLBinConst)

def get_gena(n, name, default=None):
    if not hasattr(n, 'x_gena'):
        return default
    x_gena = n.x_gena
    if x_gena is None:
        return default
    return x_gena.get(name, default)

def get_note(n):
    return get_gena(n, 'note', '')

def gen_header(root, decls):
    if hasattr(root, 'x_gena'):
        cpfx = 'C_{}'.format(root.name)
        ident_code = root.x_gena.get('ident-code')
        if ident_code:
            decls.append(HDLComment('Ident Code'))
            decls.append(HDLConstant(cpfx + '_IdentCode', 16,
                         value=HDLHexConst(ident_code, 16)))

        version = root.x_gena.get('map-version')
        if version:
            decls.append(HDLComment('Memory Map Version'))
            decls.append(HDLConstant(cpfx + '_MemMapVersion', 32,
                         value=HDLHexConst(version, 32)))

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

def gen_reg_addr(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Addresses : {}'.format(name),
                             nl=False))
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(n.c_size) - word_width

    for e in n.elements:
        if isinstance(e, tree.Reg):
            addr = e.c_address // root.c_word_size
            if e.c_size > root.c_word_size:
                num = e.c_size // root.c_word_size
                for i in range(num):
                    gen_addr_cst(decls, addr + i,
                        'C_Reg_{}_{}_{}'.format(pfx, e.name, num - i - 1),
                        addr_width, word_width, word_width)
            else:
                gen_addr_cst(decls, addr, 'C_Reg_{}_{}'.format(pfx, e.name),
                    addr_width, word_width, word_width)

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
    def gen_one_mask(decls, acm, name, w, lo_idx):
        acm &= (1 << w) - 1
        cst = HDLConstant(name, w, lo_idx=lo_idx, value=HDLBinConst(acm, w))
        cst.eol_comment = ' : Value : X"{:0{}x}"'.format(acm, w / 4)
        decls.append(cst)

    word_width = root.c_word_size * tree.BYTE_SIZE
    if reg.width <= word_width:
        gen_one_mask(decls,
                     mask, '{}_{}'.format(pfx, reg.name), reg.width, 0)
    else:
        num = reg.width / word_width
        for i in reversed(range(num)):
            gen_one_mask(decls,
                         mask >> (i * word_width),
                         '{}_{}_{}'.format(pfx, reg.name, i),
                         word_width, i * word_width)

def gen_reg_acm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Auto Clear Masks : {}'.format(name)))

    mpfx = 'C_ACM_{}'.format(pfx)
    for e in n.elements:
        if isinstance(e, tree.Reg):
            acm = compute_acm(e)
            gen_mask(decls, acm, root, e, mpfx)

def gen_reg_psm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Preset Masks : {}'.format(name)))
    mpfx = 'C_PSM_{}'.format(pfx)
    for e in n.elements:
        if isinstance(e, tree.Reg):
            psm = compute_preset(e)
            gen_mask(decls, psm, root, e, mpfx)

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
            codes = get_gena(e, 'code-fields', None)
            if codes is not None:
                gen_one_cf(codes, 'C_Code_{}_{}'.format(root.name, e.name),
                           e.width, 0)
            else:
                for f in e.fields:
                    codes = get_gena(f, 'code-fields', None)
                    if codes is not None:
                        gen_one_cf(codes, 'C_Code_{}_{}_{}'.format(
                                    root.name, e.name, f.name),
                                   f.c_width, f.lo)

def gen_memory_data(n, root, decls, name, pfx):
    decls.append(HDLComment('Memory Data : {}'.format(name), nl=False))
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(n.c_size) - word_width
    for e in n.elements:
        if isinstance(e, tree.Array):
            addr = e.c_address // root.c_word_size
            gen_addr_cst(decls, addr, 'C_Mem_{}_{}_Sta'.format(pfx, e.name),
                addr_width, word_width, word_width)
            addr = (e.c_address + e.c_size - 1) // root.c_word_size
            gen_addr_cst(decls, addr, 'C_Mem_{}_{}_End'.format(pfx, e.name),
                addr_width, word_width, word_width)

def gen_submap_addr(n, root, decls, name, pfx):
    decls.append(HDLComment('Submap Addresses : {}'.format(name), nl=False))
    word_width = ilog2(root.c_word_size)
    for e in n.elements:
        if isinstance(e, tree.Block) and e.submap_file is not None:
            block_width = ilog2(e.c_size)
            addr_width = ilog2(n.c_size) - block_width
            addr = e.c_address >> block_width
            gen_addr_cst(decls, addr, 'C_Submap_{}_{}'.format(pfx, e.name),
                addr_width, block_width, word_width)

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
