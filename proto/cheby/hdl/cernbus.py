from cheby.hdl.simplebus import SimpleBus


class CERNBEBus(SimpleBus):
    def __init__(self, name):
        super().__init__(name)
        names = name[12:].split('-')
        self.buserr = names[0] == 'err'
        if self.buserr:
            del names[0]
        self.split = names[0] == 'split'
        if self.split:
            del names[0]
        assert len(names) == 1

    names = {
        'clk': 'Clk',
        'rst': 'Rst',
        'adr': 'VMEAddr',
        'adrr': 'VMERdAddr',
        'adrw': 'VMEWrAddr',
        'dato': 'VMERdData',
        'dati': 'VMEWrData',
        'rd': 'VMERdMem',
        'wr': 'VMEWrMem',
        'rack': 'VMERdDone',
        'wack': 'VMEWrDone',
        'rderr': 'VMERdError',
        'wrerr': 'VMEWrError'
    }
