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


class UnknownGenAttribute(Exception):
    def __init__(self, msg, n):
        self.msg = msg
        self.node = n


class UnknownTag(Exception):
    def __init__(self, msg):
        super(UnknownTag, self).__init__()
        self.msg = msg


class UnknownValue(Exception):
    def __init__(self, name, val):
        self.name = name
        self.val = val


def error(str):
    sys.stderr.write(str + '\n')


def conv_access(acc):
    # TODO: incorrect for rmw
    return {'r': 'ro', 'rmw': 'rw', 'rw': 'rw', 'w': 'wo'}[acc]


def conv_string(s):
    # Empty string is the same as no string.
    if s == '':
        return None
    return s


def conv_depth(s):
    units = {'k': 1 << 10, 'M': 1 << 20, 'G': 1 << 30}
    if s[-1] in units:
        return int(s[:-1]) * units[s[-1]]
    else:
        return int(s)


def conv_address(s):
    if s == 'next':
        return s
    else:
        return int(s, 0)


def conv_int(s):
    if s is None:
        return None
    elif s.startswith('0b'):
        return int(s[2:], 2)
    elif s.startswith('0x'):
        return int(s[2:], 16)
    else:
        return int(s)


def conv_bool(k, s):
    if s.lower() in ('true'):
        return True
    elif s.lower() in ('false'):
        return False
    else:
        raise UnknownValue(k, s)


def conv_common(node, k, v):
    if k == 'description':
        node.description = v
        return True
    elif k == 'comment':
        node.comment = conv_string(v)
        return True
    elif k == 'comment-encoding':
        if v == 'PlainText':
            return True
        raise UnknownValue(k, v)
    else:
        return False


def conv_codefield(parent, el):
    cf = parent.x_gena.get('code-field', [])
    cf.append({f: el.attrib[f] for f in ['name', 'code']})
    parent.x_gena['code-field'] = cf


def conv_bit_field_data(reg, el):
    res = cheby.tree.Field(reg)
    res.x_gena = {}
    attrs = el.attrib
    res.name = attrs['name']
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k == 'bit-preset':
            res.preset = 1 if conv_bool(k, v) else 0
        elif k in ['name', 'bit']:
            # Handled
            pass
        elif k == 'autoclear':
            res.x_gena['auto-clear'] = '1' if conv_bool(k, v) else '0'
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e.startswith('ext-codes='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['alarm-level']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.lo = int(attrs['bit'])
    for child in el:
        if child.tag == 'code-field':
            conv_codefield(res, child)
        else:
            raise UnknownTag(child.tag)
    reg.children.append(res)


def conv_sub_reg(reg, el):
    res = cheby.tree.Field(reg)
    res.x_gena = {}
    attrs = el.attrib
    res.name = attrs['name']
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['name', 'range']:
            # Handled
            pass
        elif k == 'sub-reg-preset-mask':
            res.preset = conv_int(v)
        elif k == 'auto-clear-mask':
            res.x_gena['auto-clear'] = v
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e.startswith('ext-codes='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                elif e in ('ignore', ):
                    xg[e] = True
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['unit', 'read-conversion-factor', 'write-conversion-factor',
                   'constant-value']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    rng = attrs['range'].split('-')
    res.hi = int(rng[0])
    res.lo = int(rng[1])
    if res.hi == res.lo:
        res.hi = None
    elif res.lo > res.hi:
        # Swap incorrect order.
        res.lo, res.hi = (res.hi, res.lo)
    for child in el:
        if child.tag == 'code-field':
            conv_codefield(res, child)
        else:
            raise UnknownTag(child.tag)
    reg.children.append(res)


def conv_register_data(parent, el):
    res = cheby.tree.Reg(parent)
    res.x_gena = {}
    attrs = el.attrib
    res.name = attrs['name']
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['access-mode', 'address', 'name', 'element-width',
                   'bit-encoding']:
            # Handled
            pass
        elif k in ['note', 'auto-clear', 'preset']:
            res.x_gena[k] = v
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e in ('write-strobe', 'srff', 'bus-out', 'no-split',
                           'ext-creg', 'ext-acm', 'ignore', 'read-strobe'):
                    xg[e] = True
                elif e.startswith('resize='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                elif e.startswith('mux='):
                    kg, vg = e.split('=')
                    xg[kg] = vg.replace('_', '.')
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['code-generation-rule',
                   'persistence', 'max-val', 'min-val', 'unit',
                   'read-conversion-factor', 'write-conversion-factor']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.address = conv_address(attrs['address'])
    res.width = int(attrs['element-width'], 0)
    if attrs['access-mode'] == 'rmw':
        res.x_gena['type'] = 'rmw'
    res.access = conv_access(attrs['access-mode'])
    for child in el:
        if child.tag == 'code-field':
            conv_codefield(res, child)
        elif child.tag == 'bit-field-data':
            conv_bit_field_data(res, child)
        elif child.tag == 'sub-reg':
            conv_sub_reg(res, child)
        else:
            raise UnknownTag(child.tag)
    if not res.children:
        # No children, scalar register
        enc = attrs.get('bit-encoding', None)
        if enc in [None, 'unsigned', 'signed', 'float']:
            res.type = enc
        else:
            raise UnknownValue('bit-encoding', enc)
        res.children.append(cheby.tree.FieldReg(res))
        res.preset = conv_int(attrs.get('preset', None))
    else:
        # FIXME: what about bit-encoding ?  For resizing ?
        # Move preset to children
        preset = attrs.get('preset', None)
        if preset is not None:
            preset = conv_int(preset)
            for f in res.children:
                if f.preset is None:
                    if f.hi is None:
                        w = 1
                    else:
                        w = f.hi - f.lo + 1
                    f.preset = (preset >> f.lo) & ((1 << w) - 1)
    parent.children.append(res)


def conv_memory_bit_field_data(el):
    res = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ('bit', 'name', 'description', 'comment', 'comment-encoding'):
            res[k] = v
        else:
            raise UnknownAttribute(k)

    for child in el:
        raise UnknownTag(child.tag)
    return res


def conv_memory_buffer(el):
    res = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ('description', 'buffer-type', 'buffer-select-code', 'name',
                 'read-conversion-factor', 'write-conversion-factor', 'unit',
                 'bit-encoding', 'note', 'comment', 'comment-encoding'):
            res[k] = v
        else:
            raise UnknownAttribute(k)

    bit_fields = []
    for child in el:
        if child.tag == 'bit-field-data':
            bit_fields.append(conv_memory_bit_field_data(child))
        else:
            raise UnknownTag(child.tag)
    if bit_fields:
        res['bit-field-data'] = bit_fields
    return res


def conv_memory_channel(el):
    res = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ('description', 'acq-base-freq', 'acq-width',
                 'buffer-alignment', 'channel-select-code',
                 'ors-definition',
                 'note', 'name', 'comment', 'comment-encoding'):
            res[k] = v
        else:
            raise UnknownAttribute(k)

    memory_buffers = []
    for child in el:
        if child.tag == 'memory-buffer':
            memory_buffers.append(conv_memory_buffer(child))
        else:
            raise UnknownTag(child.tag)
    if memory_buffers:
        res['memory-buffer'] = memory_buffers
    return res


def conv_memory_data(parent, el):
    res = cheby.tree.Array(parent)
    res.x_gena = {}
    attrs = el.attrib
    res.name = attrs['name']
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['access-mode', 'address', 'name', 'element-width',
                   'element-depth']:
            # Handled
            pass
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['persistence', 'note']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.address = conv_address(attrs['address'])
    res.repeat = conv_depth(attrs['element-depth'])

    reg = cheby.tree.Reg(res)
    res.children.append(reg)
    reg.name = res.name
    reg.width = int(attrs['element-width'], 0)
    reg.access = conv_access(attrs['access-mode'])

    bus_width = parent.get_root().c_word_size * cheby.tree.BYTE_SIZE
    if reg.width < bus_width:
        error('memory data of {} is widened from {} to {}.'.format(
                res.name, reg.width, bus_width))
        reg.width = bus_width
    res.repeat //= reg.width // cheby.tree.BYTE_SIZE

    memory_channel = []
    for child in el:
        if child.tag == 'memory-channel':
            memory_channel.append(conv_memory_channel(child))
        else:
            raise UnknownTag(child.tag)
    if memory_channel:
        res.x_gena['memory-channel'] = memory_channel
    parent.children.append(res)


def conv_area(parent, el):
    res = cheby.tree.Block(parent)
    res.x_gena = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['address', 'name', 'element-depth']:
            # Handled and required
            pass
        elif k == 'is-reserved':
            res.x_gena['reserved'] = conv_bool(k, v)
        elif k in ('note',):
            res.x_gena[k] = v
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e in ('ext-area',):
                    xg[e] = True
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff', 'ext-creg'):
                    # Discard ?
                    pass
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('persistence',):
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    res.address = conv_address(attrs['address'])
    res.size = conv_depth(attrs['element-depth'])

    for child in el:
        conv_element(res, child)
    parent.children.append(res)


def conv_submap(parent, el):
    res = cheby.tree.Submap(parent)
    res.x_gena = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['address', 'name', 'filename']:
            # Handled
            pass
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == 'include':
                    xg['include'] = 'include'
                elif e == 'include=ext':
                    xg['include'] = 'external'
                elif e == 'include=int' or e == 'include=generate':
                    xg['include'] = 'internal'
                elif e.startswith('include'):
                    raise UnknownGenAttribute(e, res)
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff'):
                    # Discard ?
                    pass
                elif e in ('generate',):
                    xg[e] = True
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['ro2wo', 'access-mode-flip']:
            # Ignored
            pass
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    res.filename = os.path.splitext(attrs['filename'])[0] + '.cheby'
    res.address = conv_address(attrs['address'])

    for child in el:
        raise UnknownTag(child.tag)
    parent.children.append(res)


def conv_element(parent, child):
    if child.tag == 'register-data':
        conv_register_data(parent, child)
    elif child.tag == 'memory-data':
        conv_memory_data(parent, child)
    elif child.tag == 'area':
        conv_area(parent, child)
    elif child.tag == 'submap':
        conv_submap(parent, child)
    else:
        raise UnknownTag(child.tag)


def conv_root(root, filename):
    res = cheby.tree.Root()

    res.x_gena = {}
    acc_mode = None
    size = None
    split_suffix = ''
    err_suffix = ''
    attrs = root.attrib
    res.name = attrs.get('name', os.path.basename(filename))
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['name']:
            pass
        elif k == 'mem-map-access-mode':
            acc_mode = v
        elif k == 'area-depth':
            size = conv_depth(v)
        elif k in ['map-version', 'ident-code']:
            # x-gena extension
            res.x_gena[k] = v
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e.startswith('library='):
                    _, vg = e.split('=')
                    xg['vhdl-library'] = vg
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff', 'dsp'):
                    xg[e] = True
                elif e == 'split-address':
                    split_suffix = '-split'
                elif e == 'error=on':
                    err_suffix = '-err'
                elif e.startswith('include'):
                    # Bogus use, discard.
                    pass
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['driver-name',
                   'equipment-code', 'note', 'module-type',
                   'semantic-mem-map-version',
                   'vme-base-addr', 'vme-base-address']:
            # Ignored
            pass
        elif k == '{http://www.w3.org/2001/XMLSchema-instance}schemaLocation':
            pass
        else:
            raise UnknownAttribute(k)
    if acc_mode == 'A24/D8':
        res.bus = 'cern-be-vme' + err_suffix + split_suffix + '-8'
        res.c_word_size = 1
        bus_size = 24
    elif acc_mode == 'A24/D16':
        res.bus = 'cern-be-vme' + err_suffix + split_suffix + '-16'
        res.c_word_size = 2
        bus_size = 24
    elif acc_mode == 'A32/D32':
        res.bus = 'cern-be-vme-err' + err_suffix + split_suffix + '-32'
        res.c_word_size = 4
        bus_size = 32
    else:
        raise UnknownValue('mem-map-access-mode', acc_mode)

    res.size = size or bus_size

    for child in root:
        if child.tag == 'constant-value':
            pass
        elif child.tag == 'configuration-value':
            pass
        elif child.tag == 'fesa-class-properties':
            pass
        else:
            conv_element(res, child)
    return res


def convert(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    return conv_root(root, filename)


def main():
    aparser = argparse.ArgumentParser(description='Gena to Cheby converter')
    aparser.add_argument('FILE')

    args = aparser.parse_args()
    try:
        res = convert(args.FILE)
    except UnknownGenAttribute as e:
        error("error: unknown 'gen=' attribute '{}' in {}".format(
            e.msg, e.node.get_path()))
        sys.exit(1)
    except UnknownTag as e:
        error("error: unknown tag '{}'".format(
            e.msg))
        sys.exit(1)
    cheby.pprint.pprint_cheby(sys.stdout, res)


if __name__ == '__main__':
    main()
