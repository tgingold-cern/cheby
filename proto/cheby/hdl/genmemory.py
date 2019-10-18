import functools
from cheby.hdl.elgen import ElGen, add_module_port
from cheby.hdltree import (HDLComment, HDLComb, HDLSync,
                           HDLEq, HDLOr, HDLAnd, HDLNot,
                           HDLIfElse,
                           HDLAssign, HDLSlice, HDLReplicate, HDLInstance,
                           HDLNumber, HDLBool, bit_1, bit_0, bit_x)
from cheby.hdl.globals import rst_sync
from cheby.layout import ilog2
import cheby.tree as tree


class GenMemory(ElGen):
    def gen_ports(self, root, module, mem):
        """Create RAM ports and wires shared by all the registers.
        :attr h_addr: the address port
        """
        # Compute width, and create address port.
        mem.h_addr_width = ilog2(mem.c_depth)
        mem.h_addr = add_module_port(
            root, module, mem.c_name + '_adr', mem.h_addr_width, 'IN')
        mem.h_addr.comment = '\n' + "RAM port for {}".format(mem.c_name)

        for c in mem.children:
            if isinstance(c, tree.Reg):
                # Ram
                self.gen_ports_reg(root, module, c)
            else:
                raise AssertionError(c)

    def gen_ports_reg(self, root, module, reg):
        """Create ports and wires for a ram.
        :attr h_we: the write enable
        :attr h_rd: the read enable
        :attr h_dat: the data (either input or output)
        """
        # Create ports for external access to the RAM.
        if reg.access == 'ro':
            reg.h_wr = add_module_port(
                root, module, reg.c_name + '_we', None, 'IN')
            reg.h_dat = add_module_port(
                root, module, reg.c_name + '_dat', reg.c_rwidth, 'IN')
        else:
            reg.h_rd = add_module_port(
                root, module, reg.c_name + '_rd', None, 'IN')
            reg.h_dat = add_module_port(
                root, module, reg.c_name + '_dat', reg.c_rwidth, 'OUT')

        nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
        reg.h_sig_bwsel = module.new_HDLSignal(reg.c_name + '_int_bwsel', nbr_bytes)

        if reg.access == 'ro':
            # External port is WO
            reg.h_sig_dati = module.new_HDLSignal(reg.c_name + '_int_dati', reg.c_rwidth)
            reg.h_sig_dato = module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
            reg.h_dat_ign = module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
            reg.h_rreq = module.new_HDLSignal(reg.c_name + '_rreq')
            reg.h_rack = module.new_HDLSignal(reg.c_name + '_rack')
            reg.h_sig_wr = module.new_HDLSignal(reg.c_name + '_int_wr')
            reg.h_ext_rd = module.new_HDLSignal(reg.c_name + '_ext_rd')
        else:
            # External port is RO.
            reg.h_sig_dato = module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
            reg.h_dat_ign = module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
            reg.h_rreq = module.new_HDLSignal(reg.c_name + '_rreq')
            reg.h_rack = module.new_HDLSignal(reg.c_name + '_rack')
            reg.h_sig_wr = module.new_HDLSignal(reg.c_name + '_int_wr')
            reg.h_ext_wr = module.new_HDLSignal(reg.c_name + '_ext_wr')

    def gen_processes(self, root, module, ibus, mem):
        module.stmts.append(HDLComment('Memory {}'.format(mem.c_name)))
        if root.h_ram is None:
            module.deps.append(('work', 'wbgen2_pkg'))
            root.h_ram = True

        if ibus.wr_adr != ibus.rd_adr and any([r.access in ['wo', 'rw'] for r in mem.children]):
            # Read request and Write request.  Priority for the write.
            mem.h_wr = module.new_HDLSignal(mem.c_name + '_wr')
            mem.h_rr = module.new_HDLSignal(mem.c_name + '_rr')
            # Any write request
            mem.h_wreq = module.new_HDLSignal(mem.c_name + '_wreq')
            mem.h_adr_int = module.new_HDLSignal(mem.c_name + '_adr_int',
                                                 mem.h_addr_width)

            # Create a mux for the ram address
            proc = HDLComb()
            proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, mem.h_wr])
            if_stmt = HDLIfElse(HDLEq(mem.h_wr, bit_1))
            if_stmt.then_stmts.append(
                HDLAssign(mem.h_adr_int,
                          HDLSlice(ibus.wr_adr, root.c_addr_word_bits, mem.h_addr_width)))
            if_stmt.else_stmts.append(
                HDLAssign(mem.h_adr_int,
                          HDLSlice(ibus.rd_adr, root.c_addr_word_bits, mem.h_addr_width)))
            proc.stmts.append(if_stmt)
            module.stmts.append(proc)

            # Handle R & W accesses (priority to W)
            module.stmts.append(
                HDLAssign(mem.h_wreq,
                          functools.reduce(HDLOr, [r.h_sig_wr for r in mem.children])))
            rreq = functools.reduce(HDLOr, [r.h_rreq for r in mem.children])
            module.stmts.append(
                HDLAssign(mem.h_rr, HDLAnd(rreq, HDLNot(mem.h_wreq))))
            module.stmts.append(HDLAssign(mem.h_wr, mem.h_wreq))
        else:
            mem.h_adr_int = None

        for c in mem.children:
            if isinstance(c, tree.Reg):
                # Ram
                self.gen_processes_reg(root, module, ibus, c)
            else:
                raise AssertionError(c)

    def gen_processes_reg(self, root, module, ibus, reg):
        mem = reg._parent
        # Instantiate the ram.
        inst = HDLInstance(reg.c_name + "_raminst", "wbgen2_dpssram")
        module.stmts.append(inst)
        inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
        inst.params.append(("g_size", HDLNumber(1 << mem.h_addr_width)))
        inst.params.append(("g_addr_width", HDLNumber(mem.h_addr_width)))
        inst.params.append(("g_dual_clock", HDLBool(False)))
        inst.params.append(("g_use_bwsel", HDLBool(False)))
        inst.conns.append(("clk_a_i", root.h_bus['clk']))
        inst.conns.append(("clk_b_i", root.h_bus['clk']))
        if mem.h_adr_int is not None:
            adr_int = mem.h_adr_int
        else:
            adr_int = HDLSlice(ibus.rd_adr, root.c_addr_word_bits, mem.h_addr_width)
        inst.conns.append(("addr_a_i", adr_int))

        # Always write words to RAM (no byte select)
        inst.conns.append(("bwsel_b_i", reg.h_sig_bwsel))
        inst.conns.append(("bwsel_a_i", reg.h_sig_bwsel))

        proc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
        proc.rst_stmts.append(HDLAssign(reg.h_rack, bit_0))
        if root.h_bussplit and reg.access in ['rw', 'wo']:
            # Arbiter: the RAM has only one address bus on port A.
            rack = HDLAnd(HDLAnd(reg.h_rreq, HDLNot(mem.h_wreq)),
                          HDLNot(reg.h_rack))
        else:
            rack = reg.h_rreq
        proc.sync_stmts.append(HDLAssign(reg.h_rack, rack))
        module.stmts.append(proc)

        if reg.access == 'ro':
            # Internal port (RO)
            inst.conns.append(("data_a_i", reg.h_sig_dati))  # Unused.
            inst.conns.append(("data_a_o", reg.h_sig_dato))
            inst.conns.append(("rd_a_i", reg.h_rreq))
            inst.conns.append(("wr_a_i", reg.h_sig_wr))

            module.stmts.append(HDLAssign(reg.h_sig_wr, bit_0))
            module.stmts.append(HDLAssign(reg.h_sig_dati, HDLReplicate(bit_x, reg.c_rwidth)))

            # External port (WO)
            module.stmts.append(HDLAssign(reg.h_ext_rd, bit_0))

            inst.conns.append(("addr_b_i", mem.h_addr))
            inst.conns.append(("data_b_i", reg.h_dat))
            inst.conns.append(("data_b_o", reg.h_dat_ign))
            inst.conns.append(("rd_b_i", reg.h_ext_rd))
            inst.conns.append(("wr_b_i", reg.h_wr))
        else:
            # Internal port (RW)
            inst.conns.append(("data_a_i", ibus.wr_dat))
            inst.conns.append(("data_a_o", reg.h_sig_dato))
            inst.conns.append(("rd_a_i", reg.h_rreq))
            inst.conns.append(("wr_a_i", reg.h_sig_wr))

            # External port (RO)
            module.stmts.append(HDLAssign(reg.h_ext_wr, bit_0))

            inst.conns.append(("addr_b_i", mem.h_addr))
            inst.conns.append(("data_b_i", reg.h_dat_ign))
            inst.conns.append(("data_b_o", reg.h_dat))
            inst.conns.append(("rd_b_i", reg.h_rd))
            inst.conns.append(("wr_b_i", reg.h_ext_wr))

        nbr_bytes = reg.c_rwidth // tree.BYTE_SIZE
        module.stmts.append(HDLAssign(reg.h_sig_bwsel,
                                      HDLReplicate(bit_1, nbr_bytes)))

    def gen_read(self, root, s, n, off, ibus, rdproc):
        # TODO: handle list of registers!
        r = n.children[0]
        rdproc.sensitivity.append(r.h_sig_dato)
        # Output ram data
        s.append(HDLAssign(ibus.rd_dat, r.h_sig_dato))
        # Set rd signal to ram: read when there is not WR request,
        # and either a read request or a pending read request.
        if root.h_bussplit and r.access in ['wo', 'rw']:
            rd_sig = HDLAnd(ibus.rd_req, HDLNot(n.h_wreq))
            rdproc.sensitivity.extend([n.h_wreq])
        else:
            rd_sig = ibus.rd_req
        s.append(HDLAssign(r.h_rreq, rd_sig))
        # But set it to 0 when the ram is not selected.
        rdproc.stmts.append(HDLAssign(r.h_rreq, bit_0))
        # Use delayed ack as ack.
        s.append(HDLAssign(ibus.rd_ack, r.h_rack))
        rdproc.sensitivity.append(r.h_rack)

    def gen_write(self, root, s, n, off, ibus, wrproc):
        # TODO: handle list of registers!
        r = n.children[0]
        if r.access in ['rw', 'wo']:
            wrproc.stmts.append(HDLAssign(r.h_sig_wr, bit_0))
            s.append(HDLAssign(r.h_sig_wr, ibus.wr_req))
            s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))
