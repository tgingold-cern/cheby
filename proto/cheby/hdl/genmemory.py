import functools
from cheby.hdl.elgen import ElGen
from cheby.hdltree import (HDLComment, HDLComb, HDLSync,
                           HDLEq, HDLOr, HDLAnd, HDLNot,
                           HDLIfElse,
                           HDLAssign, HDLSlice, HDLReplicate, HDLInstance,
                           HDLNumber, HDLBool, bit_1, bit_0, bit_x)
from cheby.hdl.globals import gconfig
from cheby.layout import ilog2
import cheby.tree as tree


class GenMemory(ElGen):
    def gen_ports(self):
        """Create RAM ports and wires shared by all the registers.
        :attr h_addr: the address port
        """
        mem = self.n
        # Compute width, and create address port.
        mem.h_addr_width = ilog2(mem.c_depth)
        mem.h_addr = self.add_module_port(mem.c_name + '_adr', mem.h_addr_width, 'IN')
        mem.h_addr.comment = '\n' + "RAM port for {}".format(mem.c_name)

        for c in mem.children:
            if isinstance(c, tree.Reg):
                # Ram
                self.gen_ports_reg(c)
            else:
                raise AssertionError(c)

    def gen_ports_reg(self, reg):
        """Create ports and wires for a ram.
        :attr h_we: the write enable
        :attr h_rd: the read enable
        :attr h_dat: the data (either input or output)
        """
        # Create ports for external access to the RAM.
        if reg.access == 'ro':
            reg.h_wr = self.add_module_port(reg.c_name + '_we', None, 'IN')
            reg.h_dat = self.add_module_port(reg.c_name + '_dat', reg.c_rwidth, 'IN')
        else:
            reg.h_rd = self.add_module_port(reg.c_name + '_rd', None, 'IN')
            reg.h_dat = self.add_module_port(reg.c_name + '_dat', reg.c_rwidth, 'OUT')

        if reg.access == 'ro':
            # External port is WO
            reg.h_sig_dati = self.module.new_HDLSignal(reg.c_name + '_int_dati', reg.c_rwidth)
            reg.h_sig_dato = self.module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
            reg.h_dat_ign = self.module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
            reg.h_rreq = self.module.new_HDLSignal(reg.c_name + '_rreq')
            reg.h_rack = self.module.new_HDLSignal(reg.c_name + '_rack')
            reg.h_sig_wr = self.module.new_HDLSignal(reg.c_name + '_int_wr')
            reg.h_ext_rd = self.module.new_HDLSignal(reg.c_name + '_ext_rd')
        else:
            # External port is RO.
            reg.h_sig_dato = self.module.new_HDLSignal(reg.c_name + '_int_dato', reg.c_rwidth)
            reg.h_dat_ign = self.module.new_HDLSignal(reg.c_name + '_ext_dat', reg.c_rwidth)
            reg.h_rreq = self.module.new_HDLSignal(reg.c_name + '_rreq')
            reg.h_rack = self.module.new_HDLSignal(reg.c_name + '_rack')
            reg.h_sig_wr = self.module.new_HDLSignal(reg.c_name + '_int_wr')
            reg.h_ext_wr = self.module.new_HDLSignal(reg.c_name + '_ext_wr')

    def gen_processes(self, ibus):
        mem = self.n
        self.module.stmts.append(HDLComment('Memory {}'.format(mem.c_name)))
        if self.root.h_ram is None:
            self.module.deps.append(('work', 'cheby_pkg'))
            self.root.h_ram = True

        if ibus.wr_adr != ibus.rd_adr and any([r.access in ['wo', 'rw'] for r in mem.children]):
            # Read request and Write request.  Priority for the write.
            mem.h_wr = self.module.new_HDLSignal(mem.c_name + '_wr')
            mem.h_rr = self.module.new_HDLSignal(mem.c_name + '_rr')
            # Any write request
            mem.h_wreq = self.module.new_HDLSignal(mem.c_name + '_wreq')
            mem.h_adr_int = self.module.new_HDLSignal(mem.c_name + '_adr_int',
                                                 mem.h_addr_width)

            # Create a mux for the ram address
            proc = HDLComb()
            proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, mem.h_wr])
            if_stmt = HDLIfElse(HDLEq(mem.h_wr, bit_1))
            if_stmt.then_stmts.append(
                HDLAssign(mem.h_adr_int,
                          HDLSlice(ibus.wr_adr, self.root.c_addr_word_bits, mem.h_addr_width)))
            if_stmt.else_stmts.append(
                HDLAssign(mem.h_adr_int,
                          HDLSlice(ibus.rd_adr, self.root.c_addr_word_bits, mem.h_addr_width)))
            proc.stmts.append(if_stmt)
            self.module.stmts.append(proc)

            # Handle R & W accesses (priority to W)
            self.module.stmts.append(
                HDLAssign(mem.h_wreq,
                          functools.reduce(HDLOr, [r.h_sig_wr for r in mem.children])))
            rreq = functools.reduce(HDLOr, [r.h_rreq for r in mem.children])
            self.module.stmts.append(
                HDLAssign(mem.h_rr, HDLAnd(rreq, HDLNot(mem.h_wreq))))
            self.module.stmts.append(HDLAssign(mem.h_wr, mem.h_wreq))
        else:
            mem.h_adr_int = None

        for c in mem.children:
            if isinstance(c, tree.Reg):
                # Ram
                self.gen_processes_reg(ibus, c)
            else:
                raise AssertionError(c)

    def gen_processes_reg(self, ibus, reg):
        mem = reg._parent
        # Instantiate the ram.
        inst = HDLInstance(reg.c_name + "_raminst", "cheby_dpssram")
        self.module.stmts.append(inst)
        inst.params.append(("g_data_width", HDLNumber(reg.c_rwidth)))
        inst.params.append(("g_size", HDLNumber(1 << mem.h_addr_width)))
        inst.params.append(("g_addr_width", HDLNumber(mem.h_addr_width)))
        inst.params.append(("g_dual_clock", bit_0))
        inst.params.append(("g_use_bwsel", bit_1 if ibus.wr_sel is not None else bit_0))
        inst.conns.append(("clk_a_i", self.root.h_bus['clk']))
        inst.conns.append(("clk_b_i", self.root.h_bus['clk']))
        if mem.h_adr_int is not None:
            adr_int = mem.h_adr_int
        else:
            adr_int = HDLSlice(ibus.rd_adr, self.root.c_addr_word_bits, mem.h_addr_width)
        inst.conns.append(("addr_a_i", adr_int))

        # Use byte select on port A if available.
        bwsel = HDLReplicate(bit_1, reg.c_rwidth // tree.BYTE_SIZE)
        inst.conns.append(("bwsel_a_i", ibus.wr_sel or bwsel))

        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['rst'], rst_sync=gconfig.rst_sync)
        proc.rst_stmts.append(HDLAssign(reg.h_rack, bit_0))
        if self.root.h_bussplit and reg.access in ['rw', 'wo']:
            # Arbiter: the RAM has only one address bus on port A.
            rack = HDLAnd(HDLAnd(reg.h_rreq, HDLNot(mem.h_wreq)),
                          HDLNot(reg.h_rack))
        else:
            rack = reg.h_rreq
        proc.sync_stmts.append(HDLAssign(reg.h_rack, rack))
        self.module.stmts.append(proc)

        if reg.access == 'ro':
            # Internal port (RO)
            inst.conns.append(("data_a_i", reg.h_sig_dati))  # Unused.
            inst.conns.append(("data_a_o", reg.h_sig_dato))
            inst.conns.append(("rd_a_i", reg.h_rreq))
            inst.conns.append(("wr_a_i", reg.h_sig_wr))

            self.module.stmts.append(HDLAssign(reg.h_sig_wr, bit_0))
            self.module.stmts.append(HDLAssign(reg.h_sig_dati, HDLReplicate(bit_x, reg.c_rwidth)))

            # External port (WO)
            self.module.stmts.append(HDLAssign(reg.h_ext_rd, bit_0))

            inst.conns.append(("addr_b_i", mem.h_addr))
            inst.conns.append(("bwsel_b_i", bwsel))
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
            self.module.stmts.append(HDLAssign(reg.h_ext_wr, bit_0))

            inst.conns.append(("addr_b_i", mem.h_addr))
            inst.conns.append(("bwsel_b_i", bwsel))
            inst.conns.append(("data_b_i", reg.h_dat_ign))
            inst.conns.append(("data_b_o", reg.h_dat))
            inst.conns.append(("rd_b_i", reg.h_rd))
            inst.conns.append(("wr_b_i", reg.h_ext_wr))

    def gen_read(self, s, off, ibus, rdproc):
        # TODO: handle list of registers!
        n = self.n
        r = n.children[0]
        # Output ram data
        s.append(HDLAssign(ibus.rd_dat, r.h_sig_dato))
        # Set rd signal to ram: read when there is not WR request,
        # and either a read request or a pending read request.
        if self.root.h_bussplit and r.access in ['wo', 'rw']:
            rd_sig = HDLAnd(ibus.rd_req, HDLNot(n.h_wreq))
        else:
            rd_sig = ibus.rd_req
        s.append(HDLAssign(r.h_rreq, rd_sig))
        # But set it to 0 when the ram is not selected.
        rdproc.stmts.append(HDLAssign(r.h_rreq, bit_0))
        # Use delayed ack as ack.
        s.append(HDLAssign(ibus.rd_ack, r.h_rack))

    def gen_write(self, s, off, ibus, wrproc):
        # TODO: handle list of registers!
        n = self.n
        r = n.children[0]
        if r.access in ['rw', 'wo']:
            wrproc.stmts.append(HDLAssign(r.h_sig_wr, bit_0))
            s.append(HDLAssign(r.h_sig_wr, ibus.wr_req))
            s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))
