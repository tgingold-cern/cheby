import cheby.wbgen.tree as tree
import cheby.wbgen.ltree as ltree


class ConvertExcept(Exception):
    pass


def is_common(name):
    return name in ['name', 'description', 'prefix', 'c_prefix',
                    'hdl_prefix']


def check_string(e):
    if not isinstance(e._val, ltree.LitString):
        raise ConvertExcept("attribute '{}' must be a string".format(
                            e._name))
    return e._val._val


def check_name(e, vals):
    if not isinstance(e._val, ltree.LitName):
        raise ConvertExcept("attribute '{}' must be a name".format(
                            e._name))
    if vals and e._val._val not in vals:
        raise ConvertExcept(
            "unknown value '{}' for attribute '{}'".format(
                e._val._val, e._name))
    return e._val._val


def check_bool(e):
    v = check_name(e, ['true', 'false'])
    return v == 'true'


def check_identifier(e):
    if not isinstance(e, ltree.LitName):
        raise ConvertExcept(
            "attribute must be an identier")


def conv_number(s):
    if s[:2] == "0x" or s[:2] == '0X':
        return int(s[2:], 16)
    else:
        return int(s)


def check_number(e):
    if not isinstance(e._val, ltree.LitNumeral):
        raise ConvertExcept("attribute '{}' must be a number".format(
                            e._name))
    return conv_number(e._val._val)


def check_litnumber(e):
    if not isinstance(e, ltree.LitNumeral):
        raise ConvertExcept("field must be a number")
    return conv_number(e._val)


def check_list(e):
    if not isinstance(e._val, ltree.LitTable):
        raise ConvertExcept("attribute '{}' must be a list".format(
                            e._name))


def check_table(e):
    if not isinstance(e, ltree.Table):
        raise ConvertExcept("attribute '{}' must be a table".format(
                            e._name))


def convert_common(res, e):
    s = check_string(e)
    if e._name == 'name':
        res.name = s
    elif e._name == 'description':
        res.desc = s
    elif e._name == 'prefix':
        res.prefix = s
    elif e._name == 'c_prefix':
        res.c_prefix = s.upper()
    elif e._name == 'hdl_prefix':
        res.hdl_prefix = s


def convert_field_access(e):
    res = check_name(e, ['READ_ONLY', 'WRITE_ONLY', 'READ_WRITE', 'WRITE_READ'])
    if res == 'WRITE_READ':
        res = 'READ_WRITE'
    return res


def convert_field(t):
    res = tree.Field()
    res.pre_comment = t._comment
    check_table(t)
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'type':
            res.typ = check_name(
                e, ['BIT', 'SLV', 'SIGNED', 'UNSIGNED',
                    'MONOSTABLE', 'PASS_THROUGH', 'CONSTANT'])
        elif e._name == 'size':
            res.size = check_number(e)
        elif e._name == 'access_bus':
            res.access_bus = convert_field_access(e)
        elif e._name == 'access_dev':
            res.access_dev = convert_field_access(e)
        elif e._name == 'align':
            res.align = check_number(e)
        elif e._name == 'load':
            res.load = check_name(e, ['LOAD_EXT'])
        elif e._name == 'clock':
            res.clock = check_string(e)
        elif e._name == 'value':
            res.value = check_number(e)
        elif e._name == 'reset_value':
            try:
                res.reset_value = check_number(e)
            except ConvertExcept:
                res.reset_value = check_string(e)
        elif e._name == 'ack_read':
            res.ack_read = check_string(e)
        elif e._name == 'range':
            check_list(e)
            vals = e._val._val
            if len(vals) != 2:
                raise ConvertExcept(
                    "incorrect number of values for range")
            res.range = [check_litnumber(vals[0]),
                         check_litnumber(vals[1])]
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in field".format(
                    e._name))
    return res


def convert_fifo_reg_flags(e):
    check_list(e)
    res = []
    for e2 in e._val._val:
        check_identifier(e2)
        if e2._val not in ['FIFO_FULL', 'FIFO_EMPTY',
                           'FIFO_COUNT', 'FIFO_CLEAR',
                           'FIFO_RESET']:
            raise ConvertExcept(
                "incorrect flags name '{}'".format(
                    e2._val))
        res.append(e2._val)
    return res


def convert_fifo_reg(t):
    res = tree.Fifo()
    res.pre_comment = t._comment
    check_table(t)
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'direction':
            res.direction = check_name(
                e, ['CORE_TO_BUS', 'BUS_TO_CORE'])
        elif e._name == 'mode':
            res.mode = check_name(e, ['PIPELINE'])
        elif e._name == 'size':
            res.size = check_number(e)
        elif e._name == 'flags_bus':
            res.flags_bus = convert_fifo_reg_flags(e)
        elif e._name == 'flags_dev':
            res.flags_dev = convert_fifo_reg_flags(e)
        elif e._name == 'clock':
            res.clock = check_string(e)
        elif e._name == 'optional':
            res.optional = check_string(e)
        elif e._name == 'field':
            res.fields.append(convert_field(e))
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in fifo_reg".format(
                    e._name))
    return res


def convert_reg(t):
    res = tree.Reg()
    res.pre_comment = t._comment
    check_table(t)
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'clock':
            res.clock = check_string(e)
        elif e._name == 'align':
            res.align = check_number(e)
        elif e._name == 'field':
            res.fields.append(convert_field(e))
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in reg".format(
                    e._name))
    return res


def convert_ram(t):
    res = tree.Ram()
    check_table(t)
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'width':
            res.width = check_number(e)
        elif e._name == 'size':
            res.size = check_number(e)
        elif e._name == 'byte_select':
            res.byte_select = check_bool(e)
        elif e._name == 'wrap_bits':
            res.wrap_bits = check_number(e)
        elif e._name == 'access_bus':
            res.access_bus = convert_field_access(e)
        elif e._name == 'access_dev':
            res.access_dev = convert_field_access(e)
        elif e._name == 'clock':
            res.clock = check_string(e)
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in ram".format(
                    e._name))
    return res


def convert_irq(t):
    res = tree.Irq()
    check_table(t)
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'trigger':
            res.trigger = check_name(
                e, ['LEVEL_0', 'LEVEL_1',
                    'EDGE_RISING', 'EDGE_FALLING'])
        elif e._name == 'ack_line':
            res.ack_line = check_bool(e)
        elif e._name == 'mask_line':
            res.mask_line = check_bool(e)
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in irq".format(
                    e._name))
    return res


def convert_peripheral(t):
    res = tree.Peripheral()
    check_table(t)
    res.pre_comment = t._comment
    for e in t._val:
        if is_common(e._name):
            convert_common(res, e)
        elif e._name == 'hdl_entity':
            res.hdl_entity = check_string(e)
        elif e._name == 'version':
            res.version = check_number(e)
        elif e._name == 'mode':
            res.mode = check_name(e, ['PIPELINED'])
        elif e._name == 'fifo_reg':
            res.regs.append(convert_fifo_reg(e))
        elif e._name == 'reg':
            res.regs.append(convert_reg(e))
        elif e._name == 'ram':
            res.regs.append(convert_ram(e))
        elif e._name == 'irq':
            res.regs.append(convert_irq(e))
        else:
            raise ConvertExcept(
                "unhandled attribute '{}' in peripheral".format(
                    e._name))
    return res


def convert(t):
    if not isinstance(t, ltree.Table):
        raise ConvertExcept("input file must be a table")
    if t._name != "peripheral":
        raise ConvertExcept("input file must be a peripheral")
    return convert_peripheral(t)
