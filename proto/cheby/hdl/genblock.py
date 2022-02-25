from cheby.hdl.elgen import ElGen
from cheby.hdl.genreg import GenReg
from cheby.hdl.geninterface import GenInterface
from cheby.hdl.genmemory import GenMemory
from cheby.hdl.gensubmap import GenSubmap
from cheby.hdltree import HDLInterface
import cheby.tree as tree
from cheby.layout import ilog2

class GenBlock(ElGen):
    def create_generators(self):
        """Add the object to generate hdl"""
        for n in self.n.children:
            if isinstance(n, tree.Block):
                n.h_gen = GenBlock(self.root, self.module, n)
            elif isinstance(n, tree.Submap):
                if n.include is True:
                    # Inline
                    n.h_gen = GenBlock(self.root, self.module, n.c_submap)
                elif n.filename is None:
                    # A pure interface
                    n.c_bus_access = 'rw'
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    # A submap defined in a file
                    n.h_gen = GenSubmap(self.root, self.module, n)
            elif isinstance(n, tree.Memory):
                if n.interface is not None:
                    n.c_addr_bits = ilog2(n.c_depth)
                    n.c_width = n.c_elsize * tree.BYTE_SIZE
                    n.c_bus_access = n.c_mem_access
                    n.h_gen = GenInterface(self.root, self.module, n)
                else:
                    n.h_gen = GenMemory(self.root, self.module, n)
            elif isinstance(n, tree.Reg):
                n.h_gen = GenReg(self.root, self.module, n)
            else:
                raise AssertionError
            n.h_gen.create_generators()

    def gen_ports(self):
        if self.n.hdl_iogroup is not None:
            if self.root.h_itf:
                print("nested interface is ignored")
                self.root.hdl_iogroup = None
            else:
                self.root.h_itf = HDLInterface('t_' + self.n.hdl_iogroup)
                self.module.global_decls.append(self.root.h_itf)
                self.root.h_ports = self.module.add_modport(self.n.hdl_iogroup, self.root.h_itf, True)
                if isinstance(self.n, tree.Root):
                    self.root.h_ports.comment = "Wires and registers"

        for n in self.n.children:
            n.h_gen.gen_ports()

        if self.n.hdl_iogroup is not None:
            self.root.h_itf = None
            self.root.h_ports = self.module

    def gen_processes(self, ibus):
        for n in self.n.children:
            n.h_gen.gen_processes(ibus)

    def gen_read(self, s, off, ibus, rdproc):
        raise AssertionError

    def gen_write(self, s, off, ibus, wrproc):
        raise AssertionError
