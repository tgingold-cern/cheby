from cheby.hdl.elgen import ElGen
from cheby.hdltree import (HDLComment)
from cheby.hdl.buses import name_to_busgen
from cheby.hdl.genreg import GenReg
from cheby.hdl.geninterface import GenInterface
from cheby.hdl.genmemory import GenMemory
from cheby.hdl.gensubmap import GenSubmap
import cheby.tree as tree
from cheby.layout import ilog2

class GenBlock(ElGen):
    def create_generators(self):
        """Add the object to generate hdl"""
        for n in self.n.children:
            if isinstance(n, tree.Block):
                n.h_gen = GenBlock(self.root, self.module, n)
                n.h_gen.create_generators()
            elif isinstance(n, tree.Submap):
                if n.include is True:
                    # Inline
                    n.h_gen = GenBlock(self.root, self.module, n.c_submap)
                    n.h_gen.create_generators()
                elif n.filename is None:
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    n.h_gen = GenSubmap(self.root, self.module, n)
            elif isinstance(n, tree.Memory):
                if n.interface is not None:
                    n.c_addr_bits = ilog2(n.c_depth)
                    n.c_width = n.c_elsize * tree.BYTE_SIZE
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    n.h_gen = GenMemory(self.root, self.module, n)
            elif isinstance(n, tree.Reg):
                n.h_gen = GenReg(self.root, self.module, n)
            else:
                raise AssertionError

    def gen_ports(self):
        pass

    def gen_processes(self, ibus):
        pass

    def gen_read(self, s, off, ibus, rdproc):
        pass

    def gen_write(self, s, off, ibus, wrproc):
        pass
