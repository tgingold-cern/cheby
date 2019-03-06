import cheby.tree as tree


class DTException(Exception):
    """Exception raised in case of device tree error"""
    pass


def error(msg):
    raise DTException(msg)


def get_devicetree(n):
    "Get the value from a devicetree extension"
    return n.get_ext_node('x_devicetree')

def gen_children(f, t, pfx):
    for c in t.children:
        if isinstance(c, tree.Submap):
            name = pfx + c.name + '_'
            if c.filename is None:
                dt = get_devicetree(c)
                if dt is not None:
                    f.write('{}START=0x{:x}\n'.format(name, c.c_address))
                    f.write('{}END=0x{:x}\n'.format(name, c.c_address + c.c_size - 1))
                else:
                    f.write('# {}@{:x} is not described\n'.format(c.name, c.c_address))
            else:
                # Has a filename.
                gen_children(f, c.c_submap, name)
        else:
            error('devicetree: unhandled child type {}'.format(c))

def generate_device_script(f, t):
    dt = get_devicetree(t)
    if dt is None:
        error("no x-devicetree for {}".format(t.get_path()))

    gen_children(f, t, '')
