#! /usr/bin/env python3
import sys
import ast
import re
import os.path
import argparse
from xml.etree import ElementTree as ET
import cheby.tree
import cheby.pprint

# If True, display ignored constructs.
flag_ignore = False


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


NODE_SEPARATOR = '/'

CONST_VAR_PREFIXES = ["CST_", "CFG_"]


class SyntaxValidator(ast.NodeVisitor):

    def __init__(self, convFactorInput):
        self.convFactorInput = convFactorInput

    def visit_Module(self, node):
        self.names = set()
        self.calls = set()
        self.generic_visit(node)

    def visit_Name(self, node):
        self.names.add(node.id)

    def visit_Call(self, node):
        self.calls.add(node.func.id)
        self.generic_visit(node)

    def convertVariablesSyntax(self):
        regexPattern = r"([a-zA-Z0-9]+\_+[a-zA-Z0-9]+\w+)(?<!_)"

        rawVariables = self.names - self.calls
        allVars = re.findall(regexPattern, ",".join(rawVariables))

        # Warnings
        for var in rawVariables:
            if var.find("_") in [0, len(var) - 1]:
                raise Exception("WARNING: variable \"{}\" shoud not contain \"_\" on the begging or end of name!".format(var))

        for var in allVars:
            if var.find("__") != -1:
                raise Exception("ERROR: variable \"{}\" shoud not contain multiple \"_\" in name! - conversion failed.".format(var))

        # removing constans
        allVars = [var for var in allVars if all(prefix not in var for prefix in CONST_VAR_PREFIXES)]
        convertedVars = [(var, var.replace("_", ".")) for var in allVars]

        newConvFactorText = self.convFactorInput
        for var, newVar in convertedVars:
            newConvFactorText = newConvFactorText.replace(var, newVar)

        return newConvFactorText


def convFactorSyntaxModifier(convFactorInput):
    if not isinstance(convFactorInput, str):
        return

    validator = SyntaxValidator(convFactorInput)

    try:
        validator.visit(ast.parse(convFactorInput))
        return validator.convertVariablesSyntax()
    except Exception as errMsg:
        raise UnknownValue("Failed to parse conversion factor: {}: {}".format(convFactorInput, errMsg))


def error(str):
    sys.stderr.write(str + '\n')


def ignore_attr(attr, el):
    if flag_ignore:
        sys.stderr.write("note: ignored attribute '{}' in tag '{}'\n".format(
            attr, el.tag))


def ignore_tag(tag, el):
    if flag_ignore:
        sys.stderr.write("note: ignored child tag '{}' in tag '{}'\n".format(
            tag, el.tag))


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
    if s == 'next' or s == 'virtual':
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
    elif k == 'comment':
        node.comment = conv_string(v)
    elif k == 'comment-encoding':
        if v != 'PlainText':
            raise UnknownValue(k, v)
    elif k == 'note':
        node.note = v
    else:
        return False
    return True


def conv_codefield(parent, el):
    cf = parent.x_gena.get('code-field', [])
    cf.append({f: el.attrib[f] for f in ['name', 'code', 'description', 'comment', 'note'] if f in el.attrib})
    parent.x_gena['code-field'] = cf


def conv_constant(parent, el):
    cv = parent.x_driver_edge.get('constant-value', [])
    cv.append({f: el.attrib[f] for f in ['name', 'value', 'description', 'comment'] if f in el.attrib})
    parent.x_driver_edge['constant-value'] = cv


def conv_configuration_val(parent, el):
    cv = parent.x_fesa.get('configuration-value', [])
    cv.append({f: el.attrib[f] for f in ['name', 'value', 'description', 'comment'] if f in el.attrib})
    parent.x_fesa['configuration-value'] = cv


def conv_bit_field_data(reg, el):
    res = cheby.tree.Field(reg)
    res.x_gena = {}
    res.x_fesa = {}
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
                elif e in ('ignore', 'handshake', 'ext-acm'):
                    xg[e] = True
                elif e.startswith('gen='):
                    # gen=ignore
                    kg, vg = e.split('=')
                    if kg == 'ignore':
                        xg[kg] = True
                    else:
                        UnknownGenAttribute(e, res)
                elif e.startswith('ext-codes='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('alarm-level',):
            alarm_mapping = {
                'high': 'CRITICAL',
                'medium': 'ERROR',
                'low': 'WARNING'
            }
            if v != "none":
                res.x_fesa[k] = alarm_mapping[str.lower(v)]
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
    res.x_fesa = {}
    res.x_conversions = {}
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
                elif e in ['write-strobe']:
                    pass
                elif e in ['ext-acm']:
                    xg[e] = True
                elif e.startswith('ext-codes='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                elif e in ('ignore',):
                    xg[e] = True
                elif e.startswith('gen='):
                    # gen=ignore
                    kg, vg = e.split('=')
                    if kg == 'ignore':
                        xg[kg] = True
                    elif kg == 'internal':
                        xg['suppress-port'] = True
                    else:
                        UnknownGenAttribute(e, res)
                elif e.startswith('const='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k == 'read-conversion-factor':
            res.x_conversions['read'] = convFactorSyntaxModifier(v)
        elif k == 'write-conversion-factor':
            res.x_conversions['write'] = convFactorSyntaxModifier(v)
        elif k in ['unit']:
            res.x_fesa[k] = v
        elif k in ['constant-value']:
            res.x_gena[k] = v
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
    res.x_fesa = {}
    res.x_conversions = {}
    res.x_driver_edge = {}
    attrs = el.attrib
    res.name = attrs['name']
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['access-mode', 'address', 'name', 'element-width',
                   'bit-encoding']:
            # Handled
            pass
        elif k in ['auto-clear', 'preset']:
            res.x_gena[k] = v
        elif k == 'gen':
            xg = {}
            v = v.replace(' ', '')
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e in ('write-strobe', 'srff', 'bus-out', 'no-split',
                           'ext-creg', 'ext-acm', 'ignore', 'read-strobe'):
                    xg[e] = True
                elif e == 'internal':
                    xg['suppress-port'] = True
                elif e.startswith('resize='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                elif e.startswith('mux='):
                    kg, vg = e.split('=')
                    xg[kg] = vg.replace('_', '.')
                elif e.startswith('const='):
                    kg, vg = e.split('=')
                    xg[kg] = vg
                elif e.startswith('gen='):
                    kg, vg = e.split('=')
                    if kg == 'ignore':
                        xg[kg] = True
                    else:
                        UnknownGenAttribute(e, res)
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('persistence', ):
            res.x_fesa[k] = v
        elif k == 'code-generation-rule':
            if v not in ('Fesa', 'HW', 'HW,Fesa'):
                raise UnknownValue('code-generation-rule', v)
            # The default is True, and is very common.  So only set when
            # being False.
            if v == 'Fesa':
                res.x_driver_edge['generate'] = False
            if v == 'HW':
                res.x_fesa['generate'] = False
        elif k == 'read-conversion-factor':
            res.x_conversions['read'] = convFactorSyntaxModifier(v)
        elif k == 'write-conversion-factor':
            res.x_conversions['write'] = convFactorSyntaxModifier(v)
        elif k == 'unit':
            res.x_fesa[k] = v
        elif k in ['max-val', 'min-val']:
            res.x_driver_edge[k] = v
        else:
            raise UnknownAttribute(k)
    res.address = conv_address(attrs['address'])
    res.width = int(attrs['element-width'], 0)
    if attrs['access-mode'] == 'rmw':
        res.x_gena['rmw'] = True
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
        preset = res.x_gena.get('preset', None)
        if preset is not None:
            res.preset = conv_int(preset)
            # Remove the x-gena:preset attribute, as it has been moved to preset.
            del res.x_gena['preset']
    else:
        # FIXME: what about bit-encoding ?  For resizing ?
        # Move preset to children
        preset = attrs.get('preset', None)
        if preset is not None:
            preset = conv_int(preset)
            npreset = 0
            for f in res.children:
                if f.preset is None:
                    if f.hi is None:
                        w = 1
                    else:
                        w = f.hi - f.lo + 1
                    f.preset = (preset >> f.lo) & ((1 << w) - 1)
                    npreset |= f.preset << f.lo
            if npreset == preset:
                # Remove the x-gena:preset attribute if useless.  Contrary to the
                # preset attribute, it can also set the value of unused fields.
                del res.x_gena['preset']
    if res.address == 'virtual':
        return
        # if not hasattr(parent, 'x_fesa'):
        #     parent.x_fesa = {}
        # virtuals = parent.x_fesa.get('fesa-field', [])
        # virtuals.append(res)
        # parent.x_fesa['fesa-field'] = virtuals
    else:
        parent.children.append(res)


def conv_memory_bit_field_data(el):
    res = {}
    attrs = el.attrib
    for k, v in attrs.items():
        if k in ('bit', 'name', 'description', 'comment'):
            res[k] = v
        elif k in ('comment-encoding',):
            pass
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
                 'unit', 'bit-encoding', 'note', 'comment'):
            res[k] = v
        elif k in ('read-conversion-factor', 'write-conversion-factor'):
            res[k] = convFactorSyntaxModifier(v)
        elif k in ('comment-encoding', ):
            pass
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
                 'ors-definition', 'note', 'name', 'comment'):
            res[k] = v
        elif k in ['comment-encoding']:
            pass
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
    res.x_fesa = {}
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
                elif e in ['ignore']:
                    xg[e] = True
                elif e in ['no-split']:
                    pass
                elif e.startswith('gen='):
                    # gen=ignore
                    kg, _ = e.split('=')
                    if kg == 'ignore':
                        xg[kg] = True
                    elif kg == 'internal':
                        pass
                    else:
                        UnknownGenAttribute(e, res)
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('persistence', ):
            res.x_fesa[k] = v
        else:
            raise UnknownAttribute(k)
    res.address = conv_address(attrs['address'])
    res.repeat_str = attrs['element-depth']
    res.repeat_val = conv_depth(res.repeat_str)

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
    # Convert repeat from bytes to words.
    ws = reg.width // cheby.tree.BYTE_SIZE
    res.repeat_val //= ws
    repeat_unit = res.repeat_str[-1]
    if repeat_unit in "kMG":
        v = int(res.repeat_str[:-1])
        if v % ws != 0:
            v = v * 1024
            repeat_unit = {'k': '', 'M': 'k', 'G': 'M'}[repeat_unit]
        res.repeat_str = "{}{}".format(v // ws, repeat_unit)
    else:
        res.repeat_str = str(res.repeat_val)

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
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e in ('ext-area',):
                    xg[e] = True
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff'):
                    xg[e] = True
                elif e in ['ext-creg']:
                    # Discard ?
                    pass
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('persistence',):
            ignore_attr(k, el)
        else:
            raise UnknownAttribute(k)
    res.name = attrs['name']
    res.address = conv_address(attrs['address'])
    res.size_str = attrs['element-depth']
    res.size_val = conv_depth(res.size_str)

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
                    res.include = True
                elif e.startswith('include'):
                    raise UnknownGenAttribute(e, res)
                elif e == 'no-hdl':
                    xg['ignore'] = True
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff'):
                    xg[e] = True
                elif e in ('generate',):
                    xg[e] = True
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ['ro2wo', 'access-mode-flip']:
            res.x_gena[k] = v
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
    res.x_fesa = {}
    res.x_driver_edge = {}
    res.x_cern_info = {}
    acc_mode = None
    size_val = None
    size_str = None
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
            size_str = v
            size_val = conv_depth(v)
        elif k in ('map-version', 'ident-code', 'semantic-mem-map-version'):
            res.x_cern_info[k] = v
        elif k == 'gen':
            xg = {}
            for e in [g.strip() for g in v.split(',')]:
                if e == '':
                    pass
                elif e.startswith('library='):
                    _, vg = e.split('=')
                    xg['vhdl-library'] = vg
                elif e.startswith('package='):
                    _, vg = e.split('=')
                    xg['package'] = [n for n in vg.split(';')]
                elif e in ('no-creg-mux-dff', 'no-reg-mux-dff',
                           'no-mem-mux-dff', 'dsp'):
                    xg[e] = True
                elif e == 'split-address':
                    split_suffix = '-split'
                elif e == 'error=on':
                    err_suffix = '-err'
                elif e == 'no-hdl':
                    xg['ignore'] = True
                elif e.startswith('include'):
                    # Bogus use, discard.
                    pass
                elif e == "generate":
                    pass
                else:
                    raise UnknownGenAttribute(e, res)
            res.x_gena['gen'] = xg
        elif k in ('equipment-code', 'module-type',
                   'vme-base-addr'):
            res.x_driver_edge[k] = v
        elif k in ['driver-name']:
            res.x_driver_edge['name'] = v
        elif k in ['vme-base-address']:
            res.x_driver_edge['vme-base-addr'] = v
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

    res.size_val = size_val or bus_size
    res.size_str = size_str or str(res.size_val)

    for child in root:
        if child.tag == 'constant-value':
            conv_constant(res, child)
        elif child.tag == 'configuration-value':
            conv_configuration_val(res, child)
        elif child.tag == 'fesa-class-properties':
            ignore_tag(child.tag, root)
        else:
            conv_element(res, child)
    return res


def convert(filename):
    tree = ET.parse(filename)
    root = tree.getroot()
    return conv_root(root, filename)


def main():
    global flag_ignore
    aparser = argparse.ArgumentParser(description='Gena to Cheby converter',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Convert the XML input file to cheby YAML file\n"
             "The result is printed on the standard output\n"
             "You can then use cheby to generate vhdl:\n"
             " cheby --gen-gena-regctrl=OUTPUT.vhdl -i INPUT.cheby")
    aparser.add_argument('FILE', nargs='+')
    aparser.add_argument('-i', '--ignore', action='store_true',
                         help='display ignored attributes')
    aparser.add_argument('-q', '--quiet', action='store_true',
                         help='do not display the result')
    aparser.add_argument('-f', '--out_file', action='store_true',
                         help="Output to file with changed extension")

    args = aparser.parse_args()
    flag_ignore = args.ignore
    for file in args.FILE:
        try:
            res = convert(file)
        except UnknownGenAttribute as e:
            error("error: unknown 'gen=' attribute '{}' in {}".format(
                e.msg, e.node.get_path()))
            sys.exit(1)
        except UnknownTag as e:
            error("error: unknown tag '{}'".format(
                e.msg))
            sys.exit(1)
        if not args.quiet:
            if args.out_file:
                new_filename = os.path.splitext(file)[0] + '.cheby'
                with open(new_filename, 'w') as f:
                    cheby.pprint.pprint_cheby(f, res)
            else:
                cheby.pprint.pprint_cheby(sys.stdout, res)


if __name__ == '__main__':
    main()
