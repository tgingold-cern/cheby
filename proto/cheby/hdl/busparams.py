from cheby.hdltree import HDLConcat, HDLBinConst, HDLSlice, HDLAssign, HDLReplicate, bit_0
from cheby.tree import Root, Submap
import cheby.parser as parser


class BusOptions:
    """Gather options for a bus"""
    def __init__(self, bus, root):
        self.bus = bus
        self.root = root
        # Extract x-hdl options for :param bus:
        self.busgroup = bus.get_extension('x_hdl', 'busgroup')
        self.bus_error = bus.get_extension('x_hdl', 'bus-error')

        # External size.  There might be some extra unused bits for address.
        # The default rule is to restrict the address bus to only the used bits.
        # In particular, sub-word address bits are not used.
        # At worst, there is no address bus (if there is only one addressable word).
        # But for compatibility reasons, a user may prefer to have 0-based address bus.
        # The lowest address bit of the external bus is stored in addr_low.
        gran = bus.get_extension('x_hdl', 'bus-granularity')
        if gran is None or gran == 'word':
            addr_low = root.c_addr_word_bits
            addr_wd = bus.c_addr_bits
        elif gran == 'byte':
            addr_low = 0
            addr_wd = bus.c_addr_bits + root.c_addr_word_bits
        else:
            parser.error("bad value for x-hdl:bus-granularity for {}".format(
                bus.get_path()))
        self.addr_low = addr_low
        supported = ('axi', 'wb')
        if self.busgroup and ((isinstance(bus, Root) and any(x in bus.name for x in supported)) or \
                              (isinstance(bus, Submap) and any(x in bus.interface for x in supported))):
            # only axi & wb (interface) currently support busgroup, with fixed width
            self.addr_wd = 32
        else:
            self.addr_wd = addr_wd

    def resize_addr_out(self, addr, ibus):
        if self.addr_low == ibus.addr_low:
            return addr
        else:
            assert self.addr_low == 0
            return HDLConcat(addr, HDLBinConst(0, ibus.addr_low))

    def resize_addr_out_full(self, addr, ibus):
        """Expand full extern input address :param addr: to the internal size."""
        if self.bus.c_addr_bits > 0:
            res = self.resize_addr_out(
                HDLSlice(addr, ibus.addr_low, self.bus.c_addr_bits), ibus)
        else:
            res = None

        if self.busgroup:
            repl = HDLReplicate(bit_0, self.addr_wd - self.bus.c_addr_bits - self.root.c_addr_word_bits, False)
            res = repl if res is None else HDLConcat(repl, res)
            if ibus.addr_low > 0:
                repl = HDLReplicate(bit_0, ibus.addr_low, False)
                res = repl if res is None else HDLConcat(res, repl)

        if res is None:
            raise AssertionError('Sliced address is empty')
        return res


    def resize_addr_in(self, addr, ibus):
        """Resize extern input address :param addr: to the internal size."""
        if (ibus.addr_low - self.addr_low) != 0 or self.busgroup:
            return HDLSlice(addr, ibus.addr_low, ibus.addr_size)
        else:
            return addr

    def resize_addr_lhs(self, addr, ibus):
        """Resize input address LHS :param addr: to the internal size."""
        if (ibus.addr_low - self.addr_low) != 0 and self.addr_low != 0:
            # slice only when different addr_low AND not byte granularity (see constructor)
            return HDLSlice(addr, ibus.addr_low, ibus.addr_size)
        else:
            return addr

    def new_resizer_addr_in(self, module, addr, ibus, name_rsz):
        """If needed, create an intermediate signal named :param name_rsz: for
           input address signal :param addr:"""
        naddr = self.resize_addr_in(addr, ibus)
        if naddr == addr:
            # Nop.
            return addr
        else:
            res = module.new_HDLSignal(name_rsz, ibus.addr_size, ibus.addr_low)
            module.stmts.append(HDLAssign(res, naddr))
            return res


