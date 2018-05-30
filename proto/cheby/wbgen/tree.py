class Node(object):
    """Base class for the nodes.  Contains common attributes."""
    def __init__(self):
        self.name = None
        self.desc = None
        self.prefix = None
        self.hdl_prefix = None
        self.c_prefix = None

    def visit(self, name, *args, **kwargs):
        return self.dispatcher[name](*args, **kwargs)

    def get_c_prefix(self):
        if self.c_prefix is None:
            return self.prefix.upper() if self.prefix else None
        else:
            return self.c_prefix

    def get_hdl_prefix(self):
        if self.hdl_prefix is None:
            return self.prefix.lower() if self.prefix else None
        else:
            return self.hdl_prefix


class Peripheral(Node):
    dispatcher = {}

    def __init__(self):
        super(Peripheral, self).__init__()
        self.hdl_entity = None
        self.version = None
        self.mode = None
        self.regs = []
        # Computed
        self.addr_len = None
        self.sel_bits = None  # Number of address bits to select a block
        self.blk_bits = None  # Number of address bits per block
        self.reg_bits = None  # Number of address bits for regs (<= blk_bits)
        self.bus_ports = []

    def get_hdl_entity(self):
        if self.hdl_entity:
            return self.hdl_entity
        else:
            return self.get_hdl_prefix()


class AnyReg(Node):
    def __init__(self):
        super(AnyReg, self).__init__()
        self.addr_base = None
        self.addr_len = None
        self.fields = []


class AnyHWReg(AnyReg):
    """HW element implemented as a register"""
    dispatcher = {}

    def __init__(self):
        super(AnyHWReg, self).__init__()
        self.align = None


class Reg(AnyHWReg):
    dispatcher = {}


class IrqReg(AnyHWReg):
    dispatcher = {}


class AnyFifoReg(AnyHWReg):
    dispatcher = {}


class FifoReg(AnyFifoReg):
    dispatcher = {}

    def __init__(self):
        super(FifoReg, self).__init__()
        self.parent = None
        self.bit_offset = None      # Offset in fifo data
        self.num = None             # Register number


class FifoCSReg(AnyFifoReg):
    dispatcher = {}

    def __init__(self):
        super(FifoCSReg, self).__init__()
        self.parent = None


class Fifo(AnyReg):
    dispatcher = {}

    def __init__(self):
        super(Fifo, self).__init__()
        # From the user
        self.size = None        # Depth
        self.optional = None    # Add a generic to make the fifo optional
        self.direction = None   # CORE_TO_BUS or BUS_TO_CORE
        self.flags_bus = None   # Set of FIFO_FULL, FIFO_CLEAR, FIFO_COUNT
        self.flags_dev = None   # Set of FIFO_FULL, FIFO_COUNT
        self.mode = None
        self.clock = None
        # Computed:
        self.log2_size = None
        self.width = None       # Width of the FIFO data
        self.regs = None        # List of regs created by expand_reg


class Field(Node):
    dispatcher = {}

    def __init__(self):
        super(Field, self).__init__()
        # From the input tree:
        self.typ = None
        self.size = None
        self.range = None
        self.access_bus = None
        self.access_dev = None
        self.align = None
        self.clock = None
        self.load = None
        self.value = None
        self.ack_read = None
        self.reset_value = None
        self.range = None
        # Computed:
        self.bit_offset = None
        self.bit_len = None
        self.hdl_port = None
        self.hdl_sig = None
        self.access = None  # bus_dev: RO_WO, WO_RO, RW_RW or RW_RO.
        self.kind = None    # for fifo: clear_bus, full, empty, reset, count
        self.fifo_offset = None # For fifo field: offset in the fifo data port


class Ram(AnyReg):
    dispatcher = {}

    def __init__(self):
        super(Ram, self).__init__()
        self.size = None            # Number of elements
        self.width = None           # Element size (usually 32)
        self.byte_select = None
        self.clock = None
        self.wrap_bits = None
        self.access_bus = None
        self.access_dev = None
        # Computed
        self.ram_wrap_size = None  # Size (in words) with wrap
        self.addr_bits = None      # Nbr of bits in address (without wrap)


class Irq(Node):
    dispatcher = {}

    def __init__(self):
        super(Irq, self).__init__()
        self.trigger = None
        self.ack_line = None
        self.mask_line = None
        # Computed
        self.regs = None        # List of regs for this irq controller


class Visitor(object):
    def visit(self, n, *args, **kwargs):
        return n.visit(self.__class__, self, n, *args, **kwargs)

    @classmethod
    def register(cls, typ):
        def fun(f):
            typ.dispatcher[cls] = f
            return f
        return fun
