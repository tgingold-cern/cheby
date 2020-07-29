import functools
from cheby.hdl.elgen import ElGen
from cheby.hdltree import (HDLComment, HDLComb, HDLSync,
                           HDLEq, HDLOr, HDLAnd, HDLNot,
                           HDLIfElse,
                           HDLSwitch, HDLChoiceExpr, HDLChoiceDefault,
                           HDLAssign, HDLSlice, HDLReplicate, HDLInstance,
                           HDLNumber, bit_1, bit_0, bit_x, HDLBinConst)
from cheby.hdl.globals import gconfig
from cheby.layout import ilog2
import cheby.tree as tree


class GenMemory(ElGen):
    def gen_ports(self):
        """Create RAM ports and wires shared by all the registers.
        :attr h_ext_addr: the external address port
        """
        mem = self.n
        # Compute width, and create address port.
        mem.h_addr_width = ilog2(mem.c_depth)
        mem.h_addr_off = ilog2(mem.c_elsize)
        mem.h_ext_addr = self.add_module_port(mem.c_name + '_adr_i', mem.h_addr_width, 'IN')
        mem.h_ext_addr.comment = '\n' + "RAM port for {}".format(mem.c_name)

        for c in mem.children:
            assert isinstance(c, tree.Reg)
            self.gen_ports_reg(c)

    def gen_ports_reg(self, reg):
        """Create ports and wires for a ram.
        :attr h_we: the write enable
        :attr h_rd: the read enable
        :attr h_dat: the data (either input or output)
        """
        # Create ports for external access to the RAM.
        if reg.access == 'ro':
            reg.h_wr = self.add_module_port(reg.c_name + '_we_i', None, 'IN')
            reg.h_dat = self.add_module_port(reg.c_name + '_dat_i', reg.c_rwidth, 'IN')
        else:
            reg.h_rd = self.add_module_port(reg.c_name + '_rd_i', None, 'IN')
            reg.h_dat = self.add_module_port(reg.c_name + '_dat_o', reg.c_rwidth, 'OUT')

        def build_sig(name, datsize=False):
            res = []
            if datsize:
                wd = reg.c_rwidth if reg.c_nwords == 1 else self.root.c_word_bits
            else:
                wd = None
            for i in range(reg.c_nwords):
                ext = '' if reg.c_nwords == 1 else str(i)
                res.append(self.module.new_HDLSignal(reg.c_name + name  + ext, wd))
            return res

        if reg.access == 'ro':
            # External port is WO
            reg.h_sig_dato = build_sig('_int_dato', True)
            reg.h_dat_ign = build_sig('_ext_dat', True)
            reg.h_rreq = build_sig('_rreq')
            reg.h_rack = build_sig('_rack')
        else:
            # External port is RO.
            reg.h_sig_dato = build_sig('_int_dato', True)
            reg.h_dat_ign = build_sig('_ext_dat', True)
            reg.h_rreq = build_sig('_rreq')
            reg.h_rack = build_sig('_rack')
            reg.h_sig_wr = build_sig('_int_wr')

    def gen_processes(self, ibus):
        mem = self.n
        self.module.stmts.append(HDLComment('Memory {}'.format(mem.c_name)))
        # Import the cheby_pkg package (only once)
        if self.root.h_ram is None:
            self.module.deps.append(('work', 'cheby_pkg'))
            self.root.h_ram = True

        if ibus.wr_adr != ibus.rd_adr and any([r.access in ['wo', 'rw'] for r in mem.children]):
            # Read request and Write request.  Priority for the write.
            mem.h_wr = self.module.new_HDLSignal(mem.c_name + '_wr')
            mem.h_rr = self.module.new_HDLSignal(mem.c_name + '_rr')
            # Any write request
            mem.h_wreq = self.module.new_HDLSignal(mem.c_name + '_wreq')
            mem.h_adr_int = self.module.new_HDLSignal(mem.c_name + '_adr_int', mem.h_addr_width)

            # Create a mux for the ram address
            proc = HDLComb()
            proc.sensitivity.extend([ibus.rd_adr, ibus.wr_adr, mem.h_wr])
            if_stmt = HDLIfElse(HDLEq(mem.h_wr, bit_1))
            if_stmt.then_stmts.append(
                HDLAssign(mem.h_adr_int, HDLSlice(ibus.wr_adr, mem.h_addr_off, mem.h_addr_width)))
            if_stmt.else_stmts.append(
                HDLAssign(mem.h_adr_int, HDLSlice(ibus.rd_adr, mem.h_addr_off, mem.h_addr_width)))
            proc.stmts.append(if_stmt)
            self.module.stmts.append(proc)

            # Handle R & W accesses (priority to W)
            self.module.stmts.append(
                HDLAssign(mem.h_wreq,
                          functools.reduce(HDLOr, [r.h_sig_wr[i] for r in mem.children for i in range(r.c_nwords)])))
            rreq = functools.reduce(HDLOr, [r.h_rreq[i] for r in mem.children for i in range(r.c_nwords)])
            self.module.stmts.append(
                HDLAssign(mem.h_rr, HDLAnd(rreq, HDLNot(mem.h_wreq))))
            self.module.stmts.append(HDLAssign(mem.h_wr, mem.h_wreq))
        else:
            mem.h_adr_int = None

        for c in mem.children:
            assert(isinstance(c, tree.Reg))
            self.gen_processes_reg(ibus, c)

    def gen_processes_reg(self, ibus, reg):
        mem = reg._parent
        # Instantiate the ram(s).
        multiword = reg.c_nwords > 1
        for i in range(reg.c_nwords):
            inst = HDLInstance("{}_raminst{}".format(reg.c_name, i if multiword else ''),
                               "cheby_dpssram")
            self.module.stmts.append(inst)
            wd = self.root.c_word_bits if multiword else reg.c_rwidth
            inst.params.append(("g_data_width", HDLNumber(wd)))
            inst.params.append(("g_size", HDLNumber(1 << mem.h_addr_width)))
            inst.params.append(("g_addr_width", HDLNumber(mem.h_addr_width)))
            inst.params.append(("g_dual_clock", bit_0))
            inst.params.append(("g_use_bwsel", bit_1 if ibus.wr_sel is not None else bit_0))
            inst.conns.append(("clk_a_i", self.root.h_bus['clk']))
            inst.conns.append(("clk_b_i", self.root.h_bus['clk']))
            if mem.h_adr_int is not None:
                adr_int = mem.h_adr_int
            else:
                adr_int = HDLSlice(ibus.rd_adr, mem.h_addr_off, mem.h_addr_width)
            inst.conns.append(("addr_a_i", adr_int))

            # Use byte select on port A if available.
            bwsel = HDLReplicate(bit_1, wd // tree.BYTE_SIZE)
            inst.conns.append(("bwsel_a_i", ibus.wr_sel or bwsel))

            def gen_slice(sig):
                if not multiword:
                    return sig
                if self.root.c_word_endian == 'big':
                    # Big endian
                    off = reg.c_nwords - 1 - i
                else:
                    # Little endian
                    off = i
                return HDLSlice(sig, off * wd, wd)

            if reg.access == 'ro':
                # Internal port (RO)
                inst.conns.append(("data_a_i", HDLReplicate(bit_x, wd)))
                inst.conns.append(("data_a_o", reg.h_sig_dato[i]))
                inst.conns.append(("rd_a_i", reg.h_rreq[i]))
                inst.conns.append(("wr_a_i", bit_0))

                # External port (WO)
                inst.conns.append(("addr_b_i", mem.h_ext_addr))
                inst.conns.append(("bwsel_b_i", bwsel))
                inst.conns.append(("data_b_i", gen_slice(reg.h_dat)))
                inst.conns.append(("data_b_o", reg.h_dat_ign[i]))
                inst.conns.append(("rd_b_i", bit_0))
                inst.conns.append(("wr_b_i", reg.h_wr))
            else:
                # Internal port (RW)
                inst.conns.append(("data_a_i", ibus.wr_dat))
                inst.conns.append(("data_a_o", reg.h_sig_dato[i]))
                inst.conns.append(("rd_a_i", reg.h_rreq[i]))
                inst.conns.append(("wr_a_i", reg.h_sig_wr[i]))

                # External port (RO)
                inst.conns.append(("addr_b_i", mem.h_ext_addr))
                inst.conns.append(("bwsel_b_i", bwsel))
                inst.conns.append(("data_b_i", reg.h_dat_ign[i]))
                inst.conns.append(("data_b_o", reg.h_dat))
                inst.conns.append(("rd_b_i", reg.h_rd))
                inst.conns.append(("wr_b_i", bit_0))

        proc = HDLSync(self.root.h_bus['clk'], self.root.h_bus['rst'], rst_sync=gconfig.rst_sync)
        for i in range(reg.c_nwords):
            proc.rst_stmts.append(HDLAssign(reg.h_rack[i], bit_0))
            if self.root.h_bussplit and reg.access in ['rw', 'wo']:
                # Arbiter: the RAM has only one address bus on port A.
                rack = HDLAnd(HDLAnd(reg.h_rreq[i], HDLNot(mem.h_wreq)),
                            HDLNot(reg.h_rack[i]))
            else:
                rack = reg.h_rreq[i]
            proc.sync_stmts.append(HDLAssign(reg.h_rack[i], rack))
        self.module.stmts.append(proc)

    def foreach_word(self, s, reg, ibus, func):
        wordaddr = ilog2(reg.c_nwords)
        if wordaddr != 0:
            sw = HDLSwitch(HDLSlice(ibus.rd_adr, self.root.c_addr_word_bits, wordaddr))
            s.append(sw)
        for i in range(reg.c_nwords):
            if wordaddr != 0:
                ch = HDLChoiceExpr(HDLBinConst(i, wordaddr))
                sw.choices.append(ch)
                s = ch.stmts
            func(s, reg, i)
        if wordaddr != 0:
            # The for-loop cover all the values except the meta-values.
            # Add a default choice to make vhdl simulators happy.
            ch = HDLChoiceDefault()
            sw.choices.append(ch)

    def gen_read(self, s, off, ibus, rdproc):
        def gen_read_word(stmt, reg, i):
            # Output ram data
            stmt.append(HDLAssign(ibus.rd_dat, reg.h_sig_dato[i]))
            # Set rd signal to ram: read when there is not WR request,
            # and either a read request or a pending read request.
            if self.root.h_bussplit and reg.access in ['wo', 'rw']:
                rd_sig = HDLAnd(ibus.rd_req, HDLNot(n.h_wreq))
            else:
                rd_sig = ibus.rd_req
            stmt.append(HDLAssign(reg.h_rreq[i], rd_sig))
            # But set it to 0 when the ram is not selected.
            rdproc.stmts.append(HDLAssign(reg.h_rreq[i], bit_0))
            # Use delayed ack as ack.
            stmt.append(HDLAssign(ibus.rd_ack, reg.h_rack[i]))

        # TODO: handle list of registers!
        n = self.n
        reg = n.children[0]
        self.foreach_word(s, reg, ibus, gen_read_word)

    def gen_write(self, s, off, ibus, wrproc):
        def gen_write_word(stmt, reg, i):
            if reg.access in ['rw', 'wo']:
                wrproc.stmts.append(HDLAssign(reg.h_sig_wr[i], bit_0))
                s.append(HDLAssign(reg.h_sig_wr[i], ibus.wr_req))

        # TODO: handle list of registers!
        n = self.n
        reg = n.children[0]
        if reg.access in ['rw', 'wo']:
            self.foreach_word(s, reg, ibus, gen_write_word)
        # Always ack the request, even if ignored.
        s.append(HDLAssign(ibus.wr_ack, ibus.wr_req))
