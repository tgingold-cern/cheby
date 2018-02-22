import yaml
import tree


class ParseException(Exception):
    """Exception raised in case of parse error"""
    def __init__(self, msg):
        self.msg = msg


def error(msg):
    raise ParseException(msg)


def read_text(el):
    return el


def parse_named(node, key, val):
    if key == 'name':
        node.name = val
    elif key == 'description':
        node.description = val
    elif key == 'comment':
        node.comment = read_text(val).rstrip()
    elif key == 'x-wbgen':
        node.x_wbgen = val
    else:
        return False
    return True


def parse_elements(node, val):
    if not isinstance(val, list):
        error("'elements' of {} must be a list".format(node.get_path()))
    for el in val:
        for k, v in el.items():
            if k == 'reg':
                ch = parse_reg(node, v)
            elif k == 'block':
                ch = parse_block(node, v)
            elif k == 'array':
                ch = parse_array(node, v)
            else:
                error("unhandled '{}' in elements of {}".format(
                      k, node.get_path()))
            node.children.append(ch)


def parse_composite(node, key, val):
    if parse_named(node, key, val):
        return True
    elif key == 'elements':
        parse_elements(node, val)
        return True
    else:
        return False


def parse_field(parent, el):
    if not isinstance(el, dict):
        error("'fields' of {} must be a dictionnary".format(parent.get_path()))
    res = tree.Field(parent)
    for k, v in el.items():
        if parse_named(res, k, v):
            pass
        elif k == 'range':
            if isinstance(v, int):
                res.lo = v
            else:
                pos = v.find('-')
                assert pos > 0
                res.lo = int(v[pos + 1:], 0)
                res.hi = int(v[0:pos], 0)
        elif k == 'preset':
            res.preset = v
        else:
            error("unhandled '{}' in field {}".format(k, parent.get_path()))
    return res


def parse_reg(parent, el):
    res = tree.Reg(parent)
    for k, v in el.items():
        if parse_named(res, k, v):
            pass
        elif k == 'width':
            res.width = v
        elif k == 'type':
            res.type = v
        elif k == 'access':
            res.access = v
        elif k == 'address':
            res.address = v
        elif k == 'fields':
            for f in v:
                for k1, v1 in f.items():
                    if k1 == 'field':
                        ch = parse_field(res, v1)
                    else:
                        error("unhandled '{}' in {}/fields".format(
                              k1, parent.get_path()))
                    res.fields.append(ch)
        else:
            error("unhandled '{}' in reg {}".format(k, parent.get_path()))
    return res


def parse_complex(node, key, val):
    if parse_composite(node, key, val):
        pass
    elif key == 'address':
        node.address = val
    elif key == 'align':
        node.align = val
    elif key == 'size':
        node.size = val
    else:
        return False
    return True


def parse_block(parent, el):
    res = tree.Block(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'submap_file':
            res.submap_file = v
        elif k == 'interface':
            res.interface = v
        else:
            error("unhandled '{}' in block {}".format(k, parent.get_path()))
    return res


def parse_array(parent, el):
    if not isinstance(el, dict):
        error("array {} must be a dictionnary".format(parent.get_path()))
    res = tree.Array(parent)
    for k, v in el.items():
        if parse_complex(res, k, v):
            pass
        elif k == 'repeat':
            res.repeat = v
        else:
            error("unhandled '{}' in array {}".format(k, parent.get_path()))
    return res


def parse_yaml(filename):
    try:
        el = yaml.load(open(filename))
    except IOError as e:
        error("open error: {}".format(e))

    res = tree.Root()
    for k, v in el.items():
        if parse_composite(res, k, v):
            pass
        elif k == 'bus':
            res.bus = v
        else:
            error("unhandled '{}' in root".format(k))
    return res
