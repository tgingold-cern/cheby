from cheby.layout import ilog2
import cheby.tree as tree
from cheby.hdltree import (HDLPackage,
                           HDLComment,
                           HDLConstant,
                           HDLHexConst, HDLBinConst)

def get_note(n):
    if hasattr(n, 'x_gena'):
        return n.x_gena.get('note', '')
    else:
        return ''

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

def gen_reg_addr(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Addresses : {}'.format(name)))
    word_width = ilog2(root.c_word_size)
    addr_width = ilog2(n.c_size) - word_width
    for e in n.elements:
        if isinstance(e, tree.Reg):
            addr = e.c_address >> word_width
            val = HDLBinConst(addr, addr_width)
            cst = HDLConstant('C_Reg_{}_{}'.format(pfx, e.name), addr_width,
                              lo_idx=word_width, value=val)
            cst.eol_comment = \
                '{} : Word address : 0x{:0{}x}; Byte Address : 0x{:x}'.format(
                    get_note(e), addr, (addr_width + 3) // 4, e.c_address)
            decls.append(cst)

def gen_reg_acm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Auto Clear Masks : {}'.format(name)))
    word_size = 8 * root.c_word_size
    for e in n.elements:
        if isinstance(e, tree.Reg):
            acm = 0
            cst = HDLConstant('C_ACM_{}_{}'.format(pfx, e.name), word_size,
                              value=HDLBinConst(acm, word_size))
            cst.eol_comment = '{} : Value : X"{:0{}X}"'.format(
                get_note(e), acm, word_size / 4)
            decls.append(cst)

def gen_reg_psm(n, root, decls, name, pfx):
    decls.append(HDLComment('Register Preset Masks : {}'.format(name)))
    word_size = 8 * root.c_word_size
    for e in n.elements:
        if isinstance(e, tree.Reg):
            psm = 0
            cst = HDLConstant('C_PSM_{}_{}'.format(pfx, e.name), word_size,
                              value=HDLBinConst(psm, word_size))
            cst.eol_comment = '{} : Value : X"{:0{}X}"'.format(
                get_note(e), psm, word_size / 4)
            decls.append(cst)

def gen_code_fields(n, root, decls):
    decls.append(HDLComment('CODE FIELDS'))
    cpfx = 'C_Code_{}'.format(root.name)
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

def gen_block(n, root, decls, name, pfx):
    gen_reg_addr(n, root, decls, name, pfx)
    gen_reg_acm(n, root, decls, name, pfx)
    gen_reg_psm(n, root, decls, name, pfx)

def gen_areas_address(areas, root, decls):
    decls.append(HDLComment('Memory Areas.'))
    cpfx = 'C_Area_{}'.format(root.name)
    addr_width = ilog2(root.c_size)
    for e in areas:
        if hasattr(e, 'c_submap'):
            continue
        area_width = ilog2(e.c_size)
        sz = addr_width - area_width
        cst = HDLConstant(cpfx + '_' + e.name, sz, lo_idx=area_width,
                          value=HDLBinConst(e.c_address >> area_width, sz))
        cst.eol_comment = '{} : Word Address : X"{:X}"; Byte Address : 0x{:x}'.format(
            get_note(e), e.c_address // root.c_word_size, e.c_address)
        decls.append(cst)

def gen_gena_memmap(root):
    res = HDLPackage()
    res.name = 'MemMap_{}'.format(root.name)
    decls = []
    gen_header(root, decls)

    areas = [e for e in root.elements
             if isinstance(e, tree.Block)] # or isinstance(e, tree.Array))]
    if areas:
        gen_areas_address(areas, root, decls)
        for e in areas:
            name = 'Area {}'.format(e.name)
            pfx = '{}_{}'.format(root.name, e.name)
            if hasattr(e, 'c_submap'):
                gen_block(e.c_submap, root, decls, name, pfx)
            else:
                gen_block(e, root, decls, name, pfx)

    gen_block(root, root, decls, 'Memory Map', root.name)

    gen_code_fields(root, root, decls)

    decls.append(HDLComment('Memory Data : Memory Map'))
    decls.append(HDLComment('Submap Address : Memory Map'))

    res.decls = decls
    return res
