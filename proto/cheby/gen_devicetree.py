import cheby.tree as tree


class DTException(Exception):
    """Exception raised in case of device tree error"""
    pass


def error(msg):
    raise DTException(msg)


def get_devicetree(n):
    "Get the value from a devicetree extension"
    return n.get_ext_node('x_devicetree')

def gen_common(f, dt, indent):
    for e in dt:
        for typ, v in e.items():
            if typ == 'label':
                continue
            name = v['name']
            value = v.get('value', None)
            if typ == 'string':
                f.write('{}{} = "{}";\n'.format(indent * ' ', name, value))
            elif typ == 'phandle':
                f.write('{}{} = <&{}>;\n'.format(indent * ' ', name, value))
            elif typ == 'u32':
                f.write('{}{} = {};\n'.format(indent * ' ', name, value))
            elif typ == 'boolean':
                f.write('{}{};\n'.format(indent * ' ', name))
            else:
                error('unhandled type {}'.format(typ))

def find_label(dt):
    for e in dt:
        for typ, v in e.items():
            if typ == 'label':
                return v
    return None

def gen_children(f, t, indent):
    for c in t.children:
        if isinstance(c, tree.Submap):
            if c.filename is None:
                dt = get_devicetree(c)
                if dt is not None:
                    f.write(indent * ' ')
                    # Disp label if present
                    label = find_label(dt)
                    if label is not None:
                        f.write('{}: '.format(label))
                    f.write('{}@{:x} {{\n'.format(c.name, c.c_address))
                    nindent = indent + 1
                    gen_common(f, dt, nindent)
                    f.write('{}reg = <0x{:x} 0x{:x}>;\n'.format(
                        nindent * ' ', c.c_address, c.c_size - 1))
                    f.write('{}}};\n'.format(indent * ' '))
                    f.write("\n")
                else:
                    f.write('{}/* {}@{:x} is not described. */\n'.format(
                        indent * ' ', c.name, c.c_address))
                    f.write("\n")
            else:
                # Has a filename.
                gen_children(f, c.c_submap, indent)
        else:
            error('devicetree: unhandled child type {}'.format(c))

def generate_devicetree(f, t):
    dt = get_devicetree(t)
    if dt is None:
        error("no x-devicetree for {}".format(t.get_path()))
    f.write("{} {{\n".format(t.name))
    gen_common(f, dt, 1)
    f.write(" #address-cells = <1>;\n")
    f.write(" #size-cells = <1>;\n")
    f.write("\n")

    gen_children(f, t, 1)

    f.write("};\n")
    pass
