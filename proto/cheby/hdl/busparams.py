from cheby.hdltree import HDLConcat, HDLBinConst, HDLSlice, HDLAssign
import cheby.parser as parser


class BusOptions:
    """Gather options for a bus"""
    def __init__(self, bus, root):
        self.bus = bus
        self.root = root
        # Extract x-hdl options for :param bus:
        self.busgroup = bus.get_extension('x_hdl', 'busgroup')

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
        self.addr_wd = addr_wd

    def resize_addr_out(self, addr, ibus):
        if self.addr_low == ibus.addr_low:
            return addr
        else:
            assert self.addr_low == 0
            return HDLConcat(addr, HDLBinConst(0, ibus.addr_low))

    def resize_addr_in(self, addr, ibus):
        """Resize extern input address :param addr: to the internal size."""
        if self.addr_low == ibus.addr_low:
            return addr
        delta = ibus.addr_low - self.addr_low
        if delta == 0:
            return addr
        else:
            return HDLSlice(addr, ibus.addr_low, ibus.addr_size)


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


