# pyright: reportShadowedImports=false
import sys
import cheby.yamlread as yamlread
import cheby.tree as tree


class ParseException(Exception):
    """Exception raised in case of parse error"""
    def __init__(self, msg):
        super(ParseException, self).__init__()
        self.msg = msg

    def __str__(self):
        return self.msg


def error(msg):
    raise ParseException("parse error: {}".format(msg))

def warning(n, msg):
    sys.stderr.write("{}:warning: {}\n".format(n.get_root().c_filename, msg))

def isstr(s):
    "Test if s is a string (python 2 and 3)"
    try:
        return isinstance(s, basestring)
    except NameError:
        return isinstance(s, str)


def read_text(parent, key, val, allow_empty = False):
    if val is None or val == "":
        if allow_empty:
            return val
        else:
            error("expect a non-empty string for {}:{}".format(parent.get_path(), key))
    if isstr(val):
        return val
    error("expect a string for {}:{}".format(parent.get_path(), key))


def read_size(parent, key, val):
    if isinstance(val, int):
        return str(val), val
    elif isstr(val):
        units = {'k': 1 << 10, 'M': 1 << 20, 'G': 1 << 30}
        if val[-1] in units:
            return val, int(val[:-1]) * units[val[-1]]
        else:
            return val, int(val)
    else:
        error("expect a string for {}:{}".format(parent.get_path(), key))


def read_bool(parent, key, val):
    if isinstance(val, bool):
        return val
    error("expect a boolean for {}:{}".format(parent.get_path(), key))


def read_int(parent, key, val):
    if isinstance(val, int):
        return val
    error("expect an integer for {}:{}".format(parent.get_path(), key))


def read_address(parent, key, val):
    if val == 'next':
        return 'next'
    else:
        return read_int(parent, key, val)


def parse_name(node, els):
    """Do an early decode of the name attribute to improve error messages."""
    name = els.get('name', None)
    if name is not None and isstr(name):
        node.name = name
        if ' ' in name:
            error("found a space in `name` field of {}".format(node.get_path()))

def parse_named(node, key, val):
    if key == 'name':
        node.name = read_text(node, key, val, allow_empty=True)
        if ' ' in node.name:
            error("found a space in `name` field of {}".format(node.get_path()))
    elif key == 'description':
        node.description = read_text(node, key, val)
    elif key == 'comment':
        node.comment = read_text(node, key, val, allow_empty=True)
        if node.comment:
            node.comment = node.comment.rstrip()
    elif key == 'note':
        node.note = read_text(node, key, val)
        warning(node, "'note' attribute is deprecated")
    elif isinstance(val, dict):
        if key == 'x-wbgen':
            node.x_wbgen = val
        elif key == 'x-hdl':
            node.x_hdl = val
        elif key == 'x-conversions':
            node.x_conversions = val
        elif key == 'x_gena' or key == 'x-gena':
            node.x_gena = val
        elif key == 'x-fesa':
            node.x_fesa = val
        elif key == 'x-driver-edge':
            node.x_driver_edge = val
        elif key == 'x-map-info':
            node.x_map_info = val
        elif key == 'x-devicetree':
            node.x_devicetree = val
        elif key == 'x-interrupts':
            node.x_interrupts = val
        elif key == 'x-enums':
            node.x_enums = val
        elif key.startswith("x-"):
            # Unkown extension.  This is a warning to allow users to add extensions.
            # But in order to avoid conflicts, they are kindly requested to register the
            #  extension name.
            warning(node, "unknown extension name '{}'".format(key))
            warning(node, "please register the extension on "
                          "https://gitlab.cern.ch/cohtdrivers/cheby")
            return True
        else:
            return False
    else:
        return False
    return True


def parse_children(node, val):
    if not isinstance(val, list):
        error("'children' for {} must be a list".format(node.get_path()))
    for el in val:
        for k, v in el.items():
            if v is None:
                error("child {} of {} is empty".format(
                    k, node.get_path()))
            if k == 'reg':
                ch = parse_reg(node, v)
            elif k == 'block':
                ch = parse_block(node, v)
            elif k == 'submap':
                ch = parse_submap(node, v)
            elif k == 'array':
                ch = parse_array(node, v)
            elif k == 'memory':
                ch = parse_memory(node, v)
            elif k == 'repeat':
                ch = parse_repeat(node, v)
            elif k == 'address-space':
                ch = parse_address_space(node, v)
            else:
                error("unhandled '{}' in children of {}".format(
                    k, node.get_path()))
            node.children.append(ch)


def parse_composite(node, key, val):
    if parse_named(node, key, val):
        return True
    elif key == 'children':
        parse_children(node, val)
        return True
    else:
        return False


def parse_field(parent, el):
    if not isinstance(el, dict):
        error("'children' of {} must be a dictionnary".format(
            parent.get_path()))
    res = tree.Field(parent)
    for k, v in el.items():
        if parse_named(res, k, v):
            pass
        elif k == 'range':
            if isinstance(v, int):
                res.lo = v
            else:
                pos = v.find('-')
                if pos < 0:
                    res.lo = int(v)
                else:
                    res.lo = int(v[pos + 1:], 0)
                    res.hi = int(v[0:pos], 0)
        elif k == 'preset':
            res.preset = read_int(res, k, v)
        elif k == 'type':
            res.type = read_text(res, k, v)
        else:
            error("unhandled '{}' in field {}".format(k, parent.get_path()))
    return res


def parse_reg(parent, el):
    res = tree.Reg(parent)
    parse_name(res, el)
    for k, v in el.items():
        if parse_named(res, k, v):
            pass
        elif k == 'width':
            res.width = read_int(res, k, v)
        elif k == 'preset':
            res.preset = read_int(res, k, v)
        elif k == 'constant':
            res.constant = read_text(res, k, v)
        elif k == 'type':
            res.type = read_text(res, k, v)
        elif k == 'access':
            res.access = read_text(res, k, v)
        elif k == 'address':
            res.address = read_address(res, k, v)
        elif k == 'children':
            if not isinstance(v, list):
                error("attribute {}/children must be a list".format(
                    res.get_path()))
            for f in v:
                for k1, v1 in f.items():
                    if k1 == 'field':
                        ch = parse_field(res, v1)
                    else:
                        error("unhandled '{}' in {}/children".format(
                            k1, parent.get_path()))
                    res.children.append(ch)
        else:
            error("unhandled '{}' in reg {}".format(k, res.get_path()))
    return res


def parse_complex(node, k, v):
    if parse_composite(node, k, v):
        pass
    elif k == 'address':
        node.address = read_address(node, k, v)
    elif k == 'align':
        node.align = read_bool(node, k, v)
    elif k == 'size':
        node.size_str, node.size_val = read_size(node, k, v)
    else:
        return False
    return True


def parse_block(parent, el):
    res = tree.Block(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        else:
            error("unhandled '{}' in block {}".format(k, parent.get_path()))
    return res


def parse_submap(parent, el):
    res = tree.Submap(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'filename':
            res.filename = read_text(res, k, v)
        elif k == 'interface':
            res.interface = read_text(res, k, v)
        elif k == 'include':
            res.include = read_bool(res, k, v)
        elif k == 'address-space':
            res.address_space = read_text(res, k, v)
        else:
            error("unhandled '{}' in submap {}".format(k, parent.get_path()))
    return res


def parse_array(parent, el):
    if not isinstance(el, dict):
        error("array {} must be a dictionnary".format(parent.get_path()))
    if el.get('align', True):
        res = tree.Memory(parent)
    else:
        res = tree.Repeat(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'repeat':
            if isinstance(res, tree.Memory):
                # Number of elements, so the depth of the memory.
                _, res.c_depth = read_size(res, k, v)
            else:
                res.count = read_int(res, k, v)
        else:
            error("unhandled '{}' in array {}".format(k, parent.get_path()))
    if isinstance(res, tree.Memory):
        warning(res, "'array' is deprecated, use 'memory' for {}".format(res.get_path()))
    else:
        warning(res, "'array' is deprecated, use 'repeat' for {}".format(res.get_path()))
    return res


def parse_repeat(parent, el):
    if not isinstance(el, dict):
        error("repeat {} must be a dictionnary".format(parent.get_path()))
    res = tree.Repeat(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'count':
            res.count = read_int(res, k, v)
        else:
            error("unhandled '{}' in repeat {}".format(k, parent.get_path()))
    return res


def parse_memory(parent, el):
    if not isinstance(el, dict):
        error("memory {} must be a dictionnary".format(parent.get_path()))
    res = tree.Memory(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'memsize':
            res.memsize_str, res.memsize_val = read_size(res, k, v)
        elif k == 'interface':
            res.interface = read_text(res, k, v)
        else:
            error("unhandled '{}' in memory {}".format(k, parent.get_path()))
    return res


def parse_address_space(parent, el):
    if not isinstance(el, dict):
        error("address-space {} must be a dictionnary".format(parent.get_path()))
    res = tree.AddressSpace(parent)
    parse_name(res, el)
    for k, v in el.items():
        if parse_composite(res, k, v):
            pass
        elif k == 'size':
            res.size_str, res.size_val = read_size(res, k, v)
        else:
            error("unhandled '{}' in address-spaces:address-space".format(k))
    if not isinstance(parent, tree.Root):
        error("address-space {} can only appear in a root".format(res.get_path()))
    return res


def parse_map_info(root, el):
    if not isinstance(el, dict):
        error("x-map-info {} must be a dictionnary".format(root.get_path()))
    for k, v in el.items():
        if k == 'ident':
            root.ident = read_int(root, k, v)
        elif k == 'memmap-version':
            root.memmap_version = read_text(root, k, v)
        else:
            error("unhandled '{}' in x-map-info".format(k))


def parse_enums_values(decl, el):
    if not isinstance(el, list):
        error("x-enums:enum {} 'children' must be a list".format(decl.name))
    for val in el:
        if not isinstance(val, dict) \
           or len(val) != 1 \
           or 'item' not in val:
            error("x-enums:enum {} 'children' must be a list of 'item'")
        val = val['item']
        res = tree.EnumVal(decl)
        parse_name(res, val)
        for k, v in val.items():
            if parse_named(res, k, v):
                pass
            elif k == 'value':
                res.value = read_int(res, k, v)
            else:
                error("unhandled '{}' in x-enums:enum {} item {}".format(decl.name, val.name, k))
        decl.children.append(res)


def parse_enums(root, enums):
    if not isinstance(enums, list):
        error("x-enums must be a list (of enum)")
    for en in enums:
        if not isinstance(en, dict) \
           or len(en) != 1 \
           or 'enum' not in en:
            error("x-enums list element must be 'enum'")
        en = en['enum']
        res = tree.EnumDecl(root)
        parse_name(res, en)
        for k, v in en.items():
            if parse_named(res, k, v):
                pass
            elif k == 'width':
                res.width = read_int(res, k, v)
            elif k == 'children':
                parse_enums_values(res, v)
            else:
                error("unhandled '{}' in x-enums:enum".format(k))
        root.x_enums.append(res)


def parse_c_header(root, el):
    if not isinstance(el, dict):
        error("'children' of {} must be a dictionnary".format(
            root.get_path()))
    for k, v in el.items():
        if k == 'prefix-struct':
            root.c_prefix_c_struct = read_bool(root, k, v)
        else:
            error("unhandled '{}' in x-c-header {}".format(k, root.get_path()))


def parse_yaml(filename):
    try:
        el = yamlread.load(open(filename))
    except IOError as e:
        raise ParseException(str(e))
    except yamlread.ScanException as e:
        raise ParseException(str(e))

    if not isinstance(el, dict):
        error("open error: {}: bad format (not yaml)".format(filename))
    if 'memory-map' not in el:
        error("open error: {}: missing 'memory-map' root node".format(
            filename))
    el = el['memory-map']

    res = tree.Root()
    parse_name(res, el)
    res.c_filename = filename
    for k, v in el.items():
        if k == 'x-map-info':
            parse_map_info(res, v)
        elif k == 'x-enums':
            parse_enums(res, v)
        elif k == 'x-c-header':
            parse_c_header(res, v)
        elif parse_composite(res, k, v):
            # The bulk of the work!
            pass
        elif k == 'bus':
            res.bus = read_text(res, k, v)
        elif k == 'size':
            res.size_str, res.size_val = read_size(res, k, v)
        elif k == 'word-endian':
            res.word_endian = read_text(res, k, v)
        elif k == 'version':
            warning(res, 'memory-map:version is deprecated')
            res.version = read_text(res, k, v)
        elif k == 'schema-version':
            res.schema_version = v
        elif k == 'address-spaces':
            error("'address-spaces' feature has been removed")
        else:
            error("unhandled '{}' in root".format(k))
    return res
