"""AST for the hdl description"""


class HDLNode(object):
    pass


class HDLUnit(HDLNode):
    # Top level unit
    def __init__(self, name=None):
        super(HDLUnit, self).__init__()
        self.name = name
        self.libraries = []
        self.deps = []      # list of (lib, pkg)


class HDLPortsBase(object):
    "Base class for a class that has ports (module, interface, portgroup and component)"
    def __init__(self):
        super(HDLPortsBase, self).__init__()
        self.ports = []

    def add_port(self, *args, **kwargs):
        res = HDLPort(*args, **kwargs)
        res.parent = self
        self.ports.append(res)
        return res

    def add_modport(self, *args, **kwargs):
        res = HDLInterfaceInstance(*args, **kwargs)
        res.parent = self
        self.ports.append(res)
        return res


class HDLModule(HDLUnit, HDLPortsBase):
    def __init__(self, name=None):
        super(HDLModule, self).__init__(name)
        self.global_decls = []
        self.params = []
        self.decls = []
        self.stmts = []

    def new_HDLSignal(self, *args, **kwargs):
        sig = HDLSignal(*args, **kwargs)
        self.decls.append(sig)
        return sig


class HDLPackage(HDLUnit):
    def __init__(self, name=None):
        super(HDLPackage, self).__init__(name)
        self.decls = []


class HDLComponent(HDLNode, HDLPortsBase):
    def __init__(self, name):
        super(HDLComponent, self).__init__()
        self.name = name
        self.params = []


class HDLComponentSpec(HDLNode):
    def __init__(self, comp, bind):
        super(HDLComponentSpec, self).__init__()
        self.comp = comp
        self.bind = bind


class HDLObject(HDLNode):
    def __init__(self, name=None, size=None, lo_idx=0, typ='L'):
        super(HDLObject, self).__init__()
        # Logic, Unsigned, Signed, Integer, Natural, Positive
        assert typ in "LUSINP"
        assert size is None or isinstance(size, (int, HDLExpr))
        assert lo_idx is None or isinstance(lo_idx, int)
        self.name = name
        self.size = size
        self.lo_idx = lo_idx
        self.typ = typ
        self.comment = None
        self.parent = None


class HDLSignal(HDLObject):
    pass


class HDLInterfaceInstance(HDLNode, HDLPortsBase):
    """Declare an interface instance"""
    def __init__(self, name=None, itf=None, is_master=True):
        super(HDLInterfaceInstance, self).__init__()
        self.name = name
        self.comment = None
        self.interface = itf
        self.is_master = is_master
        self.parent = None
        self.attributes = {}


class HDLInterface(HDLNode, HDLPortsBase):
    """Declare an interface (the type, not an instance)"""
    def __init__(self, name=None):
        super(HDLInterface, self).__init__()
        self.name = name
        self.comment = None


class HDLInterfaceArray(HDLNode):
    """Declare an interface array"""
    def __init__(self, prefix, count):
        super(HDLInterfaceArray, self).__init__()
        # TODO: array of array ?
        assert isinstance(prefix, HDLInterface)
        self.prefix = prefix
        self.count = count
        self.name_prefix = ''
        self.name_suffix = ''
        self.first_index = True
        self.names = {'IN': {}, 'OUT': {}}

    def add_port(self, name, *args, **kwargs):
        assert name.startswith(self.name_prefix)
        assert name.endswith(self.name_suffix)
        plen = len(self.name_prefix)
        slen = len(self.name_suffix)
        if plen > 0:
            name = name[plen:]
        if slen > 0:
            name = name[:-slen]
        dirn = kwargs['dir']
        # Ports are created when the first index is used,
        # then for the following indexes, ports are reused.
        if self.first_index:
            res = HDLPort(name, *args, **kwargs)
            res.parent = self.prefix
            self.prefix.ports.append(res)
            self.names[dirn][name] = res
            return res
        else:
            return self.names[dirn][name]
        

class HDLInterfaceSelect(HDLNode):
    """Select port :param subport: in interface :param prefix:"""
    def __init__(self, prefix, subport):
        super(HDLInterfaceSelect, self).__init__()
        self.prefix = prefix
        self.subport = subport


class HDLInterfaceIndex(HDLNode):
    """Select port :param subport: in interface :param prefix:"""
    def __init__(self, prefix, index):
        super(HDLInterfaceIndex, self).__init__()
        self.prefix = prefix
        self.index = index


class HDLPort(HDLObject):
    def __init__(self, name=None, size=None,
                 lo_idx=0, typ='L', dir='IN', default=None):
        super(HDLPort, self).__init__(name, size, lo_idx, typ)
        assert dir in ('IN', 'OUT', 'EXT')
        self.dir = dir
        self.default = default
        self.attributes = {}
        self.parent = None


class HDLConstant(HDLObject):
    def __init__(self, name=None, size=None, lo_idx=0, typ='L', value=None):
        super(HDLConstant, self).__init__(name, size, lo_idx, typ)
        self.value = value


class HDLParam(HDLConstant):
    pass


class HDLStmt(HDLNode):
    pass


class HDLComment(HDLStmt):
    def __init__(self, comment, nl=True):
        super(HDLComment, self).__init__()
        self.comment = comment
        self.nl = nl


class HDLGenIf(HDLStmt):
    def __init__(self, cond):
        super(HDLGenIf, self).__init__()
        self.cond = cond
        self.stmts = []


class HDLAssign(HDLStmt):
    def __init__(self, target, expr):
        super(HDLAssign, self).__init__()
        assert target is not None
        assert isinstance(target, (HDLExpr, HDLObject, HDLInterfaceSelect))
        assert isinstance(expr, (HDLExpr, HDLObject, HDLInterfaceSelect))
        self.target = target
        self.expr = expr


class HDLInstance(HDLStmt):
    def __init__(self, name, module_name):
        super(HDLInstance, self).__init__()
        self.name = name
        self.module_name = module_name
        self.params = []  # List of (name, expr).
        self.conns = []   # Ditto.


class HDLComb(HDLStmt):
    def __init__(self):
        super(HDLComb, self).__init__()
        self.name = None
        self.stmts = []
        self.sensitivity = []


class HDLSync(HDLStmt):
    def __init__(self, clk, rst, rst_val=0, rst_sync=False):
        super(HDLSync, self).__init__()
        self.name = None
        self.clk = clk
        self.rst = rst
        self.rst_val = rst_val
        self.rst_sync = rst_sync
        self.rst_stmts = []
        self.sync_stmts = []


class HDLIfElse(HDLStmt):
    def __init__(self, cond):
        super(HDLIfElse, self).__init__()
        assert cond is not None
        self.cond = cond
        self.then_stmts = []
        self.else_stmts = []


class HDLSwitch(HDLStmt):
    def __init__(self, expr):
        super(HDLSwitch, self).__init__()
        assert expr is not None
        self.expr = expr
        self.choices = []


class HDLChoice(HDLNode):
    def __init__(self):
        super(HDLChoice, self).__init__()
        self.stmts = []


class HDLChoiceExpr(HDLChoice):
    def __init__(self, expr):
        super(HDLChoiceExpr, self).__init__()
        assert expr is not None
        self.expr = expr


class HDLChoiceDefault(HDLChoice):
    pass


class HDLExpr(HDLNode):
    pass


class HDLCst(HDLExpr):
    pass


class HDLCstValue(HDLCst):
    def __init__(self, val):
        super(HDLCstValue, self).__init__()
        self.val = val


class HDLBit(HDLCstValue):
    pass


class HDLUndef(HDLCst):
    pass


bit_0 = HDLBit(0)
bit_1 = HDLBit(1)
bit_x = HDLUndef()


class HDLConstBase(HDLCst):
    def __init__(self, val, size):
        super(HDLConstBase, self).__init__()
        self.val = val
        self.size = size


class HDLConst(HDLConstBase):
    "Deprecated - binary constant"


class HDLHexConst(HDLConstBase):
    "Hexadecimal constant.  In VHDL, size must be a multiple of 4."


class HDLBinConst(HDLConstBase):
    "Binary constant."


class HDLNumber(HDLCstValue):
    pass


class HDLBool(HDLCstValue):
    pass


class HDLExternalName(HDLExpr):
    """A reference to an external name.  Used only for gena"""
    def __init__(self, name):
        super(HDLExternalName, self).__init__()
        assert name is not None
        self.name = name


class HDLIndex(HDLExpr):
    def __init__(self, prefix, index):
        super(HDLIndex, self).__init__()
        assert prefix is not None
        assert index is not None
        self.prefix = prefix
        self.index = index


class HDLSlice(HDLExpr):
    def __init__(self, prefix, index, size=1):
        super(HDLSlice, self).__init__()
        assert prefix is not None
        assert index is not None
        self.prefix = prefix
        self.index = index
        self.size = size


def Slice_or_Index(prefix, index, size):
    if size == 1:
        return HDLIndex(prefix, index)
    else:
        return HDLSlice(prefix, index, size)


class HDLReplicate(HDLExpr):
    def __init__(self, expr, num, with_others=True):
        super(HDLReplicate, self).__init__()
        self.expr = expr
        assert num is None or isinstance(num, int)
        self.num = num
        self.with_others = num is None or with_others


class HDLExtBase(HDLExpr):
    "Size conversion (base type)"
    def __init__(self, expr, sz):
        super(HDLExtBase, self).__init__()
        assert expr is not None
        assert isinstance(sz, int)
        self.expr = expr
        self.size = sz


class HDLZext(HDLExtBase):
    pass


class HDLSext(HDLExtBase):
    pass


class HDLUnary(HDLExpr):
    def __init__(self, expr):
        super(HDLUnary, self).__init__()
        assert expr is not None
        self.expr = expr


class HDLNot(HDLUnary):
    pass


class HDLParen(HDLExpr):
    def __init__(self, expr):
        super(HDLParen, self).__init__()
        assert expr is not None
        self.expr = expr


class HDLBinary(HDLExpr):
    def __init__(self, left, right):
        super(HDLBinary, self).__init__()
        assert left is not None
        assert right is not None
        assert isinstance(left, (HDLExpr, HDLObject, HDLInterfaceSelect)), left
        assert isinstance(right, (HDLExpr, HDLObject, HDLInterfaceSelect)), right
        self.left = left
        self.right = right


class HDLAnd(HDLBinary):
    pass


class HDLOr(HDLBinary):
    pass


class HDLEq(HDLBinary):
    pass


class HDLGe(HDLBinary):
    pass


class HDLLe(HDLBinary):
    pass


class HDLConcat(HDLBinary):
    pass


class HDLMul(HDLBinary):
    pass


class HDLSub(HDLBinary):
    pass
