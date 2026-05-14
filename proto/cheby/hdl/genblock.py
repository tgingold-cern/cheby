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
                    if getattr(n, 'hdl_reuse_submap_types', False) \
                            and n.c_submap is not None:
                        if gconfig.hdl_lang != 'vhdl':
                            import sys
                            sys.stderr.write(
                                "warning: reuse-submap-types on '{}' is only "
                                "supported for VHDL, ignored for {}\n".format(
                                    n.get_path(), gconfig.hdl_lang))
                        else:
                            n.c_submap.h_reuse_pkg = (
                                n.c_submap.hdl_module_name + '_pkg')
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
            external_pkg = getattr(self.n, 'h_reuse_pkg', None)
            if self.root.h_itf:
                flatten = getattr(self.n, 'hdl_iogroup_flatten', True)
                if not flatten:
                    if gconfig.hdl_lang == 'vhdl':
                        # Nested iogroup: create a sub-interface within the parent record
                        prev_itf = self.root.h_itf
                        prev_ports = self.root.h_ports

                        nested_itf = HDLInterface(
                            't_' + self.n.hdl_iogroup,
                            external_pkg=external_pkg)
                        parent_idx = self.module.global_decls.index(prev_itf)
                        if external_pkg is None:
                            self.module.global_decls.insert(parent_idx, nested_itf)
                        else:
                            self._add_reuse_dep(external_pkg)

                        nested_name = self.n.h_pname or self.n.hdl_iogroup
                        prev_itf.add_modport(nested_name, nested_itf, True)

                        self.root.h_itf = nested_itf
                        self.root.h_ports = HDLNestedSelect(prev_ports, nested_name)

                        for n in self.n.children:
                            n.h_gen.gen_ports()

                        self.root.h_itf = prev_itf
                        self.root.h_ports = prev_ports
                        return
                    else:
                        import sys
                        sys.stderr.write(
                            "warning: iogroup-flatten: false on '{}' is only "
                            "supported for VHDL, flattening for {}\n".format(
                                self.n.get_path(), gconfig.hdl_lang))
                # flatten — children use parent interface as-is
            else:
                is_top_iogroup = True
                self.root.h_itf = HDLInterface(
                    't_' + self.n.hdl_iogroup, external_pkg=external_pkg)
                first_iogroup = not self.root.h_itf_added
                if first_iogroup:
                    self.root.h_itf_added = True
                    if external_pkg is None:
                        self.module.global_decls.append(self.root.h_itf)
                    else:
                        self._add_reuse_dep(external_pkg)
                self.root.h_ports = self.module.add_modport(
                    self.n.h_pname or self.n.hdl_iogroup, self.root.h_itf, True)
                if first_iogroup and self.n is self.root:
                    self.root.h_ports.comment = "Wires and registers"

        for n in self.n.children:
            n.h_gen.gen_ports()

        if is_top_iogroup:
            self.root.h_itf = None
            self.root.h_ports = self.module

    def _add_reuse_dep(self, pkg_name):
        """Register a 'use work.<pkg_name>.all' dependency on the parent module."""
        dep = ('work', pkg_name)
        if dep not in self.module.deps:
            self.module.deps.append(dep)

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
    def _repeat_port_name(self):
        return self.n.hdl_iogroup or self.n.h_pname or self.n.name

    def _repeat_type_name(self):
        return 't_' + self._repeat_port_name()

    def _get_reused_submap(self):
        """If the repeat body is a single included submap with
        ``reuse-submap-types: true``, return that submap; otherwise None.

        When the repeat has its own ``iogroup`` set, reuse is incompatible:
        a warning is emitted and reuse falls back to standard behavior."""
        if gconfig.hdl_lang != 'vhdl':
            return None
        if not self.n.children:
            return None
        first = self.n.children[0]
        if not isinstance(first, tree.Block) or len(first.children) != 1:
            return None
        sub = first.children[0]
        if not isinstance(sub, tree.Submap):
            return None
        if not getattr(sub, 'hdl_reuse_submap_types', False):
            return None
        if not sub.include or sub.c_submap is None:
            return None
        if not getattr(sub.c_submap, 'hdl_iogroup', None):
            return None
        if self.n.hdl_iogroup is not None:
            import sys
            sys.stderr.write(
                "warning: reuse-submap-types on '{}' ignored because the "
                "parent repeat '{}' has its own iogroup '{}'\n".format(
                    sub.get_path(), self.n.get_path(), self.n.hdl_iogroup))
            return None
        return sub

    def _repeat_element_type_info(self):
        """Return (type_name, external_pkg) for the repeat element interface.

        If the repeat body is an included submap with ``reuse-submap-types``,
        the type name comes from the submap's iogroup and is marked external
        (referencing the submap's standalone package).  Otherwise, falls back
        to the auto-generated ``t_<repeat_name>``."""
        reused = self._get_reused_submap()
        if reused is not None:
            return ('t_' + reused.c_submap.hdl_iogroup,
                    reused.c_submap.hdl_module_name + '_pkg')
        return (self._repeat_type_name(), None)

    def gen_ports(self):
        flatten = getattr(self.n, 'hdl_iogroup_flatten', True)
        indexing = getattr(self.n, 'hdl_repeat_indexing', False)
        has_iogroup = self.n.hdl_iogroup is not None

        if indexing:
            if self.root.h_itf:
                self._gen_ports_nested_array()
            else:
                self._gen_ports_flat()
            return

        if has_iogroup:
            if not flatten and self.root.h_itf and gconfig.hdl_lang != 'vhdl':
                import sys
                sys.stderr.write(
                    "warning: iogroup-flatten: false on '{}' is only "
                    "supported for VHDL, flattening for {}\n".format(
                        self.n.get_path(), gconfig.hdl_lang))
            self._gen_ports_flat()
        else:
            for n in self.n.children:
                n.h_gen.gen_ports()

    def _gen_ports_nested_array(self):
        """Nested array iogroup: add array-of-records as a sub-field
        of the parent interface (e.g. top_regmap_o.dac_regmap(0).field)."""
        prev_itf = self.root.h_itf
        prev_ports = self.root.h_ports

        type_name, ext_pkg = self._repeat_element_type_info()
        itf = HDLInterface(type_name, external_pkg=ext_pkg)
        itf_arr = HDLInterfaceArray(itf, self.n.count)

        parent_idx = self.module.global_decls.index(prev_itf)
        self.module.global_decls.insert(parent_idx, itf_arr)
        if ext_pkg is not None:
            self._add_reuse_dep(ext_pkg)

        nested_name = self._repeat_port_name()
        prev_itf.add_modport(nested_name, itf_arr, True)

        self.root.h_itf = itf_arr
        for i, n in enumerate(self.n.children):
            itf_arr.first_index = (i == 0)
            self.root.h_ports = HDLInterfaceIndex(
                HDLNestedSelect(prev_ports, nested_name), i)
            n.h_gen.gen_ports()

        self.root.h_itf = prev_itf
        self.root.h_ports = prev_ports

    def _gen_ports_flat(self):
        """Default: create a separate module-level array port."""
        prev_itf = self.root.h_itf
        prev_ports = self.root.h_ports

        type_name, ext_pkg = self._repeat_element_type_info()
        itf = HDLInterface(type_name, external_pkg=ext_pkg)
        itf_arr = HDLInterfaceArray(itf, self.n.count)

        self.root.h_itf = itf_arr
        self.module.global_decls.append(itf_arr)
        if ext_pkg is not None:
            self._add_reuse_dep(ext_pkg)
        ports_arr = self.module.add_modport(self._repeat_port_name(), itf_arr, is_master=True)
        c = self.n.origin
        ports_arr.comment = "\n" + (c.comment or "REPEAT {}".format(c.name))

        for i, n in enumerate(self.n.children):
            itf_arr.first_index = (i == 0)
            self.root.h_ports = HDLInterfaceIndex(ports_arr, i)
            n.h_gen.gen_ports()

        self.root.h_itf = prev_itf
        self.root.h_ports = prev_ports
