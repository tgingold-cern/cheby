from cheby.hdl.wbbus import WBBus
from cheby.hdl.cernbus import CERNBEBus
from cheby.hdl.srambus import SRAMBus
from cheby.hdl.simplebus import SimpleBus
from cheby.hdl.apbbus import APBBus
from cheby.hdl.axi4litebus import AXI4LiteBus
from cheby.hdl.avalonbus import AvalonBus


def name_to_busgen(name, root, module):
    if name.startswith('wb-'):
        return WBBus(name, root, module)
    elif name.startswith('apb-'):
        return APBBus(name, root, module)
    elif name == 'axi4-lite-32':
        return AXI4LiteBus(name, root, module)
    elif name == 'avalon-lite-32':
        return AvalonBus(name, root, module)
    elif name.startswith('cern-be-vme-'):
        return CERNBEBus(name, root, module)
    elif name == 'sram':
        return SRAMBus(name, root, module)
    elif name == 'simple-32':
        return SimpleBus(name, root, module)
    else:
        raise AssertionError("Unhandled bus '{}'".format(name))
