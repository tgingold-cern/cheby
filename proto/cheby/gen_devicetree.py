import cheby.tree as tree


class DTException(Exception):
    """Exception raised in case of device tree error"""
    pass


def error(msg):
    raise DTException(msg)


def get_devicetree(n):
    "Get the value from a devicetree extension"
    return n.get_ext_node('x_devicetree')


def get_interrupts(n):
    "Get the value from interrupts extension"
    return n.get_ext_node('x_interrupts')


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
        l = e.get('label', None)
        if l is not None:
            return l
    return None

unique_id = 0

def create_label(n):
    """Create a label for the devicetree of :name n:"""
    global unique_id

    label = format('{}_{}'.format(n.name, unique_id))
    unique_id += 1
    n.x_devicetree.append({'label': label})
    return label
    
def get_int_ctrl_label(n):
    """Return the label of the interrupt controller for interrupt input n"""
    res = find_label(get_devicetree(n.parent))
    if res is None:
        res = create_label(n.parent)
    return res


def gen_children(f, t, indent):
    """Generate device tree for children of :name t:"""
    global unique_id
    for c in t.children:
        if isinstance(c, tree.Submap):
            if c.filename is None:
                dt = get_devicetree(c)
                if dt is not None:
                    interr = getattr(c, 'c_interrupts', None)
                    label = find_label(dt)
                    is_interr_ctrl = interr is not None and interr.inputs
                    if is_interr_ctrl:
                        # Interrupt controller.
                        # Need a label, so create a unique name (too rough?)
                        if label is None:
                            label = create_label(c)
                    # Disp name with label if present
                    f.write(indent * ' ')
                    if label is not None:
                        f.write('{}: '.format(label))
                    f.write('{}@{:x} {{\n'.format(c.name, c.c_address))

                    nindent = indent + 1
                    gen_common(f, dt, nindent)
                    f.write('{}reg = <0x{:x} 0x{:x}>;\n'.format(
                        nindent * ' ', c.c_address, c.c_size - 1))

                    if is_interr_ctrl:
                        f.write('{}interrupt_controller;\n'.format(
                            nindent * ' '))

                    if interr is not None:
                        l = [n for n in interr.outputs if n.dest is not None]
                        if l:
                            f.write('{}interrupts-extended ={};\n'.format(
                                nindent * ' ',
                                ','.join((' <&{} {}>'.format(get_int_ctrl_label(n.dest), n.dest.index) for n in l))))
                        
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


class interrupt_out(object):
    """Describe an output interrupt pin"""
    def __init__(self):
        self.name = None
        self.path_name = None   # Full path name (built from path and name)
        self.dest = None        # None or destination (interrupt_in object)


class interrupt_in(object):
    """Describe an input interrupt pin"""
    def __init__(self):
        self.name = None        # Name of the interrupt
        self.src_path = None    # Path of the source (as it appear in the file)
        self.src = None         # Source (interrupt_out object)
        self.parent = None      # tree node
        self.index = None       # Interrupt index


class interrupts(object):
    """Describe the interrupt features of a block"""
    def __init__(self):
        self.outputs = []
        self.inputs = []


def build_interrupts_base(base):
    """Create c_interrupts objects for the hierarchy of :name base:"""
    all_interr = []
    build_interrupts(base, base, [], all_interr)
    # Resolve interrupts
    interr_map = {o.path_name: o for interr in all_interr for o in interr.outputs}
    for interr in all_interr:
        for inp in interr.inputs:
            res = interr_map.get(inp.src_path, None)
            if res is None:
                error('cannot find interrupt {}'.format(inp.src_path))
            inp.src = res
            if res.dest is not None:
                error('interrupt output {} assigned to both {} and {}'.format
                    (res.path_name, res.dest.name, inp.name))
            else:
                res.dest = inp
    # List of exported interrupts
    exported_interr = [o for interr in all_interr for o in interr.outputs if o.dest is None]
    return exported_interr

def build_interrupts(n, base, path, all_interr):
    """For :name n: and its children, build the interrupt objects"""
    # Handle N
    # At some point, we need a scheme: check for ill-formed YAML, check for type, check for
    # missing nodes...
    interr_list = get_interrupts(n)
    if interr_list is not None:
        interr_obj = interrupts()
        all_interr.append(interr_obj)
        n.c_interrupts = interr_obj
        for e in interr_list:
            for k, v in e.items():
                if k == 'in':
                    obj = interrupt_in()
                    obj.parent = n
                    # Default index ?
                    # obj.index = len(interr_obj.inputs)
                    interr_obj.inputs.append(obj)
                    for k1, v1 in v.items():
                        if k1 == 'index':
                            obj.index = v1
                        elif k1 == 'name':
                            obj.name = v1
                        elif k1 == 'source':
                            obj.src_path = v1
                        else:
                            error('unknown attribute {} in {}/x-interrupts/in'.format(
                                k1, n.get_path()))
                elif k == 'out':
                    obj = interrupt_out()
                    interr_obj.outputs.append(obj)
                    for k1, v1 in v.items():
                        if k1 == 'name':
                            obj.name = v1
                        else:
                            error('unknown attribute {} in {}/x-interrupts/out'.format(
                                k1, n.get_path()))
                    obj.path_name = '/'.join(path + [obj.name])
                else:
                    error('unknown x-interrupts item "{}" in {}'.format
                        (k, n.get_path()))
    # Handle children
    if isinstance(n, tree.Submap) and n.filename is not None:
        exported_interr = build_interrupts_base(n.c_submap)
        exported_obj = interrupts()
        exported_obj.outputs = exported_interr
        for eint in exported_interr:
            eint.path_name = n.name + '/' + eint.name
        all_interr.append(exported_obj)
    elif isinstance(n, tree.CompositeNode):
        for c in n.children:
            build_interrupts(c, base, path + [c.name], all_interr)


def generate_devicetree(f, t):
    dt = get_devicetree(t)
    if dt is None:
        error("no x-devicetree for {}".format(t.get_path()))
    build_interrupts_base(t)
    f.write("{} {{\n".format(t.name))
    gen_common(f, dt, 1)
    f.write(" #address-cells = <1>;\n")
    f.write(" #size-cells = <1>;\n")
    f.write("\n")

    gen_children(f, t, 1)

    f.write("};\n")
    pass
