"""Generate HDL for block nodes"""

from cheby.hdl.elgen import ElGen
from cheby.hdl.genreg import GenReg
from cheby.hdl.geninterface import GenInterface
from cheby.hdl.genmemory import GenMemory
from cheby.hdl.gensubmap import GenSubmap
from cheby.hdltree import HDLInterface, HDLInterfaceArray, HDLInterfaceIndex, HDLNestedSelect
from cheby.hdl.globals import gconfig
import cheby.tree as tree
from cheby.layout import ilog2

class GenBlock(ElGen):
    def create_generators(self):
        """Add the object to generate hdl"""
        for n in self.n.children:
            if isinstance(n, tree.RepeatBlock):
                n.h_gen = GenRepeatBlock(self.root, self.module, n)
            elif isinstance(n, tree.Block):
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
                    if n.c_elsize <= self.root.c_word_size:
                        n.c_addr_bits = ilog2(n.c_depth_interface)
                        n.c_width = n.c_elsize * tree.BYTE_SIZE
                    else:
                        n.c_addr_bits = ilog2(n.memsize_val) - self.root.c_addr_word_bits
                        n.c_width = self.root.c_word_size * tree.BYTE_SIZE
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
        is_top_iogroup = False

        if self.n.hdl_iogroup is not None:
            if self.root.h_itf:
                flatten = getattr(self.n, 'hdl_iogroup_flatten', True)
                if not flatten and gconfig.hdl_lang == 'vhdl':
                    # Nested iogroup: create a sub-interface within the parent record
                    prev_itf = self.root.h_itf
                    prev_ports = self.root.h_ports

                    nested_itf = HDLInterface('t_' + self.n.hdl_iogroup)
                    parent_idx = self.module.global_decls.index(prev_itf)
                    self.module.global_decls.insert(parent_idx, nested_itf)

                    nested_name = self.n.h_pname or self.n.hdl_iogroup
                    prev_itf.add_modport(nested_name, nested_itf, True)

                    self.root.h_itf = nested_itf
                    self.root.h_ports = HDLNestedSelect(prev_ports, nested_name)

                    for n in self.n.children:
                        n.h_gen.gen_ports()

                    self.root.h_itf = prev_itf
                    self.root.h_ports = prev_ports
                    return
                # else: flatten — children use parent interface as-is
            else:
                is_top_iogroup = True
                self.root.h_itf = HDLInterface('t_' + self.n.hdl_iogroup)
                first_iogroup = not self.root.h_itf_added
                if first_iogroup:
                    self.root.h_itf_added = True
                self.module.global_decls.append(self.root.h_itf)
                self.root.h_ports = self.module.add_modport(
                    self.n.h_pname or self.n.hdl_iogroup, self.root.h_itf, True)
                if first_iogroup:
                    self.root.h_ports.comment = "Wires and registers"

        for n in self.n.children:
            n.h_gen.gen_ports()

        if is_top_iogroup:
            self.root.h_itf = None
            self.root.h_ports = self.module

    def gen_processes(self, ibus):
        for n in self.n.children:
            n.h_gen.gen_processes(ibus)

    def gen_read(self, s, off, ibus, rdproc):
        raise AssertionError

    def gen_write(self, s, off, ibus, wrproc):
        raise AssertionError


class GenRepeatBlock(GenBlock):
    """Generate code for a RepeatBlock which replaces a 'repeat' node.
       It has as many Block children as the repeat count"""
    def gen_ports(self):
        if self.n.hdl_iogroup is not None:
            # Create only one port (the modport array)
            # Save current interface
            prev_itf = self.root.h_itf
            prev_ports = self.root.h_ports

            itf = HDLInterface('t_' + self.n.hdl_iogroup)
            itf_arr = HDLInterfaceArray(itf, self.n.count)

            # Set new interface to build.
            self.root.h_itf = itf_arr
            self.module.global_decls.append(itf_arr)
            ports_arr = self.module.add_modport(self.n.hdl_iogroup, itf_arr, is_master=True)
            c = self.n.origin
            ports_arr.comment = "\n" + (c.comment or "REPEAT {}".format(c.name))

            # Create each port (when first_index is True), and
            # expand all ports.
            for i, n in enumerate(self.n.children):
                itf_arr.first_index = (i == 0)
                self.root.h_ports = HDLInterfaceIndex(ports_arr, i)
                n.h_gen.gen_ports()

            # Retore interface
            self.root.h_itf = prev_itf
            self.root.h_ports = prev_ports
        else:
            for n in self.n.children:
                n.h_gen.gen_ports()
