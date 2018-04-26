from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLPackage,
                           HDLComment,
                           HDLConstant,
                           HDLHexConst, HDLBinConst)

def gen_gena_memmap(root):
    res = HDLPackage()
    res.name = 'MemMap_{}'.format(root.name)
    cpfx = 'C_{}'.format(root.name)
    decls = []
    if hasattr(root, 'x_gena'):
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

    decls.append(HDLComment('Register Addresses : Memory Map'))
    cpfx = 'C_Reg_{}'.format(root.name)
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(root.c_size) - word_width
    for e in root.elements:
        if isinstance(e, tree.Reg):
            val = HDLBinConst(e.c_address >> word_width, addr_width)
            cst = HDLConstant(cpfx + '_' + e.name, addr_width,
                              lo_idx=word_width, value=val)
            cst.eol_comment = \
                ': Word address : "{:0{}b}" & X"{:0{}X}"; Byte Address : X"{:x}"'.format(
                    e.c_address >> word_width, addr_width,
                    e.c_address >> word_width, (addr_width + 3) // 4,
                    e.c_address)
            decls.append(cst)

    decls.append(HDLComment('Register Auto Clear Masks : Memory Map'))
    cpfx = 'C_ACM_{}'.format(root.name)
    word_size = 8 * root.c_word_size
    for e in root.elements:
        if isinstance(e, tree.Reg):
            acm = 0
            cst = HDLConstant(cpfx + '_' + e.name, word_size,
                              value=HDLBinConst(acm, word_size))
            cst.eol_comment = ' : Value : X"{:0{}X}"'.format(
                acm, word_size / 4)
            decls.append(cst)

    decls.append(HDLComment('Register Preset Masks : Memory Map'))
    cpfx = 'C_PSM_{}'.format(root.name)
    word_size = 8 * root.c_word_size
    for e in root.elements:
        if isinstance(e, tree.Reg):
            psm = 0
            cst = HDLConstant(cpfx + '_' + e.name, word_size,
                              value=HDLBinConst(psm, word_size))
            cst.eol_comment = ' : Value : X"{:0{}X}"'.format(
                psm, word_size / 4)
            decls.append(cst)

    decls.append(HDLComment('CODE FIELDS'))
    cpfx = 'C_Code_{}'.format(root.name)
    word_size = 8 * root.c_word_size
    for e in root.elements:
        if isinstance(e, tree.Reg):
            for f in e.fields:
                if not hasattr(f, 'x_gena'):
                    continue
                codes = f.x_gena.get('code-fields')
                if not codes:
                    continue
                sz = f.c_width
                for cf in codes:
                    cf = cf['code-field']
                    cst = HDLConstant(
                        cpfx + '_' + e.name + '_' + f.name + '_' + cf['name'],
                        sz, lo_idx=f.lo, value=HDLBinConst(cf['code'], sz))
                    decls.append(cst)

    res.decls = decls
    return res
