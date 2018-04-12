#! /usr/bin/env python3
import sys
import os.path
import argparse
from xml.etree import ElementTree as ET
import cheby.tree
import cheby.pprint

class UnknownAttribute(Exception):
    def __init__(self, msg):
        self.msg = msg

class UnknownTag(Exception):
    def __init__(self, msg):
        self.msg = msg

class UnknownValue(Exception):
    def __init__(self, name, val):
        self.name = name
        self.val = val

def conv_access(acc):
    # TODO: incorrect for rmw
    return {'r': 'ro', 'rmw': 'rw', 'rw': 'rw', 'w': 'wo'}[acc]


def conv_bit_field_data(reg, el):
    res = cheby.tree.Field(reg)
    attrs = el.attrib
    for k, v in attrs.items():
        if k == 'bit-preset':
            if v == 'true':
                res.preset = '1'
        elif k in ['name', 'bit']:
            # Handled
            pass
        elif k in ['autoclear', 'name', 'bit']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    res.lo = int(attrs['bit'])
    for child in el:
        if child.tag == 'code-field':
            pass
        else:
            raise UnknownTag(child.tag)
    reg.fields.append(res)

def conv_sub_reg(reg, el):
    res = cheby.tree.Field(reg)
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ['name', 'range']:
            # Handled
            pass
        elif k in ['auto-clear-mask', 'sub-reg-preset-mask']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    rng = attrs['range'].split('-')
    res.hi = int(rng[0])
    res.lo = int(rng[1])
    for child in el:
        if child.tag == 'code-field':
            pass
        else:
            raise UnknownTag(child.tag)
    reg.fields.append(res)

def conv_register_data(parent, el):
    res = cheby.tree.Reg(parent)
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ['access-mode', 'address', 'name', 'element-width',
                 'bit-encoding']:
            # Handled
            pass
        elif k in ['code-generation-rule', 'auto-clear', 'preset',
                   'persistence', 'max-val', 'min-val']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    res.address = attrs['address']
    res.width = attrs['element-width']
    res.access = conv_access(attrs['access-mode'])
    for child in el:
        if child.tag == 'code-field':
            pass
        elif child.tag == 'bit-field-data':
            conv_bit_field_data(res, child)
        elif child.tag == 'sub-reg':
            conv_sub_reg(res, child)
        else:
            raise UnknownTag(child.tag)
    if not res.fields:
        enc = attrs.get('bit-encoding', None)
        if enc == 'unsigned':
            res.type = enc
        else:
            raise UnknownValue('bit-encoding', enc)
        res.fields.append(cheby.tree.FieldReg(res))
    parent.elements.append(res)

def conv_root(root, filename):
    res = cheby.tree.Root()

    d = {}
    acc_mode = None
    for k, v in root.attrib.items():
        if k in ['map-version', 'ident-code', 'driver-name',
                 'equipment-code', 'note', 'module-type']:
            pass
        elif k in ['name', 'area-depth', 'gen', 'description']:
            d[k] = v
        elif k == 'mem-map-access-mode':
            acc_mode = v
        elif k == '{http://www.w3.org/2001/XMLSchema-instance}schemaLocation':
            pass
        else:
            raise UnknownAttribute(k)
    res.name = d.get('name', os.path.basename(filename))
    res.description = d.get('description', None)
    if acc_mode == 'A24/D16':
        res.bus = 'cern-be-vme-16'
    elif acc_mode == 'A32/D32':
        res.bus = 'cern-be-vme-32'
    else:
        raise UnknownValue('mem-map-access-mode', acc_mode)

    for child in root:
        if child.tag == 'register-data':
            conv_register_data(res, child)
        elif child.tag == 'constant-value':
            raise UnknownTag(child.tag)
        elif child.tag == 'memory-data':
            raise UnknownTag(child.tag)
        elif child.tag == 'area':
            raise UnknownTag(child.tag)
        elif child.tag == 'submap':
            raise UnknownTag(child.tag)
        else:
            raise UnknownTag(child.tag)
    return res


def main():
    aparser = argparse.ArgumentParser(description='Gena to Cheby converter')
    aparser.add_argument('FILE')

    args = aparser.parse_args()
    f = args.FILE
    tree = ET.parse(f)
    root = tree.getroot()

    res = conv_root(root, f)

    cheby.pprint.pprint_cheby(sys.stdout, res)


if __name__ == '__main__':
    main()
