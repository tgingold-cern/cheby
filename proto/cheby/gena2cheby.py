#! /usr/bin/env python3
import sys
import ast
import re
import os.path
from pathlib import Path
import argparse
from xml.etree import ElementTree as ET
import cheby.tree
import cheby.pprint
import cheby.layout as layout
from cheby.schemas_version import VERSIONS

# If True, display ignored constructs.
flag_ignore = False

# Whether holes-preset is kept.
# always: keep them
# no-split: kept only if no-split attribute is also present.
# never: discard them
flag_keep_preset = 'no-split'

# parse recursively
flag_recurse = False

# autosave to file with .cheby extension
flag_out_file = False

# do not display the result
flag_quiet = False

# If code-fields are converted to enumerations.
flag_enums = False

class AppException(Exception):
    "Exception defined for the application"
    pass

class UnknownAttribute(AppException):
    def __init__(self, msg):
        self.msg = msg


class UnknownGenAttribute(AppException):
    def __init__(self, msg, n):
        self.msg = msg
        self.node = n

class ErrorGenAttribute(AppException):
    def __init__(self, n, msg):
        self.msg = msg
        self.node = n


class UnknownTag(AppException):
    def __init__(self, msg):
        super(UnknownTag, self).__init__()
        self.msg = msg


class UnknownValue(AppException):
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
        raise UnknownValue("Failed to parse conversion factor: {}: {}".format(convFactorInput, errMsg), None)


def error(str):
    sys.stderr.write(str + '\n')


def warning(s):
    sys.stderr.write('warning: ' + s + '\n')


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
        node.description = conv_string(v)
    elif k == 'comment':
        node.comment = conv_string(v)
    elif k == 'comment-encoding':
        if v != 'PlainText':
            raise UnknownValue(k, v)
    elif k == 'note':
        node.note = conv_string(v)
    else:
        return False
    return True


def adjust_common(n):
    """Merge note to comment/description"""
    if n.note is not None:
        if n.note == n.description:
            pass
        elif n.description is None:
            n.description = n.note
        else:
            n.description += '\n' + n.note
        n.note = None


def adjust_common_dict(n):
    """Merge note to comment/description but for a dict.
       FIXME: this is almost the same as adjust_common, so is there an easy way to factorize the code ?"""
    if 'note' not in n:
        return
    if n['note'] == n.get('description'):
        pass
    elif 'description' not in n:
        n['description'] = n['note']
    else:
        if 'comment' not in n:
            n['comment'] = n['note']
        else:
            n['comment'] += '\n' + n['note']
    del(n['note'])


def conv_codefield(parent, el):
    """Convert code-field as x-gena:code-field"""
    if not flag_enums:
        cf = parent.x_gena.get('code-field', [])
        cf.append({f: el.attrib[f] for f in ['name', 'code', 'description', 'comment', 'note'] if f in el.attrib})
        parent.x_gena['code-field'] = cf


def conv_codefields(parent, el, width):
    """Convert code-field as x-enum"""
    if not flag_enums:
        return
    if not any([child.tag == 'code-field' for child in el]):
        return
    res = cheby.tree.EnumDecl(parent)
    name = parent.name
    root = parent._parent
    while root._parent is not None:
        name = root.name + '_' + name
        root = root._parent
    res.name = name
    res.width = width
    for child in el:
        if child.tag == 'code-field':
            val = cheby.tree.EnumVal(res)
            for k, v in child.attrib.items():
                if k in ('description', 'comment', 'note'):
                    conv_common(val, k, v)
                elif k == 'name':
                    val.name = v
                elif k == 'code':
                    val.value = conv_int(v)
                else:
                    raise UnknownAttribute(k)
            adjust_common(val)
            res.children.append(val)
    root.x_enums.append(res)
    parent.x_enums = {'name': res.name}

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
    adjust_common(res)
    res.lo = int(attrs['bit'])
    conv_codefields(res, el, 1)
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
            if v != '-':
                res.x_fesa[k] = v
        elif k in ['constant-value']:
            res.x_gena[k] = v
        else:
            raise UnknownAttribute(k)
    adjust_common(res)
    rng = attrs['range'].split('-')
    res.hi = int(rng[0])
    res.lo = int(rng[1])
    if res.hi == res.lo:
        res.hi = None
    elif res.lo > res.hi:
        # Swap incorrect order.
        res.lo, res.hi = (res.hi, res.lo)
    conv_codefields(res, el, 1 if res.hi is None else res.hi - res.lo + 1)
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
        elif k == 'persistence':
            if v == "Fesa":
                res.x_fesa['persistence'] = True
                res.x_fesa['multiplexed'] = False
            elif v == "PPM":
                res.x_fesa['persistence'] = True
                res.x_fesa['multiplexed'] = True
            elif v == "None":
                res.x_fesa['persistence'] = False
                res.x_fesa['multiplexed'] = False
            else:
                raise UnknownValue(k, v)
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
            if v != '-':
                res.x_fesa[k] = v
        elif k in ['max-val', 'min-val']:
            res.x_driver_edge[k] = v
        else:
            raise UnknownAttribute(k)
    adjust_common(res)
    res.address = conv_address(attrs['address'])
    res.width = int(attrs['element-width'], 0)
    if attrs['access-mode'] == 'rmw':
        res.x_gena['rmw'] = True
    res.access = conv_access(attrs['access-mode'])
    conv_codefields(res, el, res.width // 2 if attrs['access-mode'] == 'rmw' else res.width)
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
        # Move the preset attribute.
        preset = res.x_gena.get('preset', None)
        if preset is not None:
            res.preset = conv_int(preset)
            # Remove the x-gena:preset attribute, as it has been moved to preset.
            del res.x_gena['preset']
    else:
        # FIXME: what about bit-encoding ?  For resizing ?
        # Move preset to children, keep values for holes in holes-preset.
        preset = attrs.get('preset', None)
        if preset is not None:
            preset = conv_int(preset)
            for f in res.children:
                if f.hi is None:
                    w = 1
                else:
                    w = f.hi - f.lo + 1
                mask = (1 << w) - 1
                if f.preset is None:
                    # Extract the preset value from the register preset.
                    f.preset = (preset >> f.lo) & mask
                preset &= ~(mask << f.lo)
            if preset != 0:
                if flag_keep_preset == 'always' \
                   or (flag_keep_preset == 'no-split'
                       and layout.get_gena_gen(res, 'no-split', False)):
                    res.x_gena['holes-preset'] = "0x{:x}".format(preset)
                else:
                    sys.stderr.write("warning: discard preset for {}\n".format(res.get_path()))
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
        if k in ('name', 'description', 'comment'):
            s = conv_string(v)
            if s is not None:
                res[k] = s
        elif k in ('bit',):
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
        if k in ('note', 'description', 'comment'):
            s = conv_string(v)
            if s is not None:
                res[k] = s
        elif k in ('buffer-type', 'buffer-select-code', 'name', 'bit-encoding'):
            res[k] = v
        elif k == 'unit':
            if v != '-':
                res['unit'] = v
        elif k in ('read-conversion-factor', 'write-conversion-factor'):
            res[k] = convFactorSyntaxModifier(v)
        elif k in ('comment-encoding', ):
            pass
        else:
            raise UnknownAttribute(k)
    adjust_common_dict(res)

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
    res = cheby.tree.Memory(parent)
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
        elif k == 'persistence':
            if v == "Fesa":
                res.x_fesa['persistence'] = True
                res.x_fesa['multiplexed'] = False
            elif v == "PPM":
                res.x_fesa['persistence'] = True
                res.x_fesa['multiplexed'] = True
            elif v == "None":
                res.x_fesa['persistence'] = False
                res.x_fesa['multiplexed'] = False
            else:
                raise UnknownValue(k, v)
        else:
            raise UnknownAttribute(k)
    adjust_common(res)
    res.address = conv_address(attrs['address'])
    res.memsize_str = attrs['element-depth']
    res.memsize_val = conv_depth(res.memsize_str)

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
    adjust_common(res)
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
    xg = {}
    for k, v in attrs.items():
        if conv_common(res, k, v):
            pass
        elif k in ['address', 'name', 'filename']:
            # Handled
            pass
        elif k == 'gen':
            for e in [g.strip() for g in v.split(',')]:
                if e == 'include':
                    xg['include'] = 'include'
                    raise ErrorGenAttribute(res, "no value for 'include'")
                elif e == 'include=ext':
                    xg['include'] = 'external'
                    res.include = False
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
    adjust_common(res)
    if 'include' not in xg:
        warning("'include' is set to 'external' if missing")
        res.include = False
    else:
        # Remove this gen extension, keep the standard 'include' attribute.
        del xg['include']

    # process recursively

    if flag_recurse:
        try:
            base_path = Path(res.get_root().c_filename).parent
            process_file(base_path / attrs["filename"])
        except Exception as e:
            error(f"Failed to parse recursively file: {attrs['filename']} because: {e}")
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
    res.c_filename = filename
    res.x_gena = {}
    res.x_fesa = {}
    res.x_driver_edge = {}
    res.x_enums = []
    res.x_map_info = {}
    res.schema_version = VERSIONS
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
        elif k == 'map-version':
            res.x_gena[k] = v
        elif k == 'ident-code':
            res.x_map_info['ident'] = v
        elif k == 'semantic-mem-map-version':
            res.x_map_info['memmap-version'] = v
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
    adjust_common(res)
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


def process_file(filename):
    try:
        res = convert(filename)
    except UnknownGenAttribute as e:
        error("error: unknown 'gen=' attribute '{}' in {}".format(
            e.msg, e.node.get_path()))
        raise
    except ErrorGenAttribute as e:
        error("error: {}: {}".format(e.node.get_path(), e.msg))
        raise
    except UnknownTag as e:
        error("error: unknown tag '{}'".format(
            e.msg))
        raise
    except UnknownValue as e:
        error("error: unknown value '{}' for tag '{}'".format(
            e.val, e.name))
        raise
    if not flag_quiet:
        if flag_out_file:
            new_filename = os.path.splitext(filename)[0] + '.cheby'
            with open(new_filename, 'w') as f:
                cheby.pprint.pprint_cheby(f, res)
        else:
            cheby.pprint.pprint_cheby(sys.stdout, res)


def main():
    global flag_ignore, flag_keep_preset, flag_recurse, flag_out_file, flag_recurse, flag_quiet
    global flag_enums
    aparser = argparse.ArgumentParser(description='Gena to Cheby converter',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Convert the XML input file to cheby YAML file\n"
             "The result is printed on the standard output\n"
             "You can then use cheby to generate vhdl:\n"
             " cheby --gen-gena-regctrl=OUTPUT.vhdl -i INPUT.cheby")
    aparser.add_argument('--version', action='version',
                         version='%(prog)s ' + cheby.__version__)
    aparser.add_argument('FILE', nargs='+')
    aparser.add_argument('-i', '--ignore', action='store_true',
                         help='display ignored attributes')
    aparser.add_argument('-q', '--quiet', action='store_true',
                         help='do not display the result')
    aparser.add_argument('-f', '--out_file', action='store_true',
                         help="Output to file with changed extension")
    aparser.add_argument('--keep-preset', choices=['no', 'no-split', 'always'], default='no-split',
                         help="keep holes-preset attributes")
    aparser.add_argument('-r', '--recursive', action='store_true',
                         help="Recursively parse submaps, works only with -f (--out_file)")
    aparser.add_argument('--enums', action='store_true', default=False,
                         help='Use enumeration for code-fields')
    aparser.add_argument('--no-enums', action='store_false', dest='enums',
                         help='Do not use enumeration for code-fields but x-gena extensions (default)')

    args = aparser.parse_args()
    flag_ignore = args.ignore
    flag_keep_preset = args.keep_preset
    flag_out_file = args.out_file
    flag_recurse = args.recursive and flag_out_file
    flag_quiet = args.quiet
    flag_enums = args.enums

    succeeded = True

    for file in args.FILE:
        try:
            process_file(file)
        except AppException as e:
            if False:
                print('error: {}'.format(e))
            succeeded = False
        except Exception as e:
            print('error: {}'.format(e))
            succeeded = False
    if not succeeded:
        exit(1)


if __name__ == '__main__':
    main()
