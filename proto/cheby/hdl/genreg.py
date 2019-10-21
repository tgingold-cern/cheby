import cheby.tree as tree
from cheby.hdl.elgen import ElGen, add_module_port, field_decode, strobe_init, strobe_index
from cheby.hdl.globals import rst_sync
from cheby.hdltree import (HDLAssign, HDLSync, HDLComment,
                           HDLIfElse,
                           bit_1, bit_0,
                           HDLEq,
                           HDLSlice, HDLReplicate, Slice_or_Index,
                           HDLConst)


class GenReg(ElGen):
    def gen_ack_strobe_ports(self, root, module, n):
        # Strobe size.  There is one strobe signal per word, so create a vector if
        # the register is longer than a word.
        sz = None if n.c_size <= root.c_word_size else n.c_nwords

        # Write strobe
        if n.hdl_write_strobe:
            n.h_wreq_port = add_module_port(
                root, module, n.c_name + '_wr', size=sz, dir='OUT')
        else:
            n.h_wreq_port = None

        # Read strobe
        if n.hdl_read_strobe:
            n.h_rreq_port = add_module_port(
                root, module, n.c_name + '_rd', size=sz, dir='OUT')
        else:
            n.h_rreq_port = None

        # Write ack
        if n.hdl_write_ack:
            n.h_wack_port = add_module_port(
                root, module, n.c_name + '_wack', size=sz, dir='IN')
        else:
            n.h_wack_port = None

        # Read ack
        if n.hdl_read_ack:
            n.h_rack_port = add_module_port(
                root, module, n.c_name + '_rack', size=sz, dir='IN')
        else:
            n.h_rack_port = None

    def gen_regs(self, root, module, n):
        """Add internal registers (to memorize the value)."""

        n.h_has_regs = False

        for f in n.children:
            w = None if f.c_rwidth == 1 else f.c_rwidth

            # Create the register (only for registers)
            if f.hdl_type == 'reg':
                f.h_reg = module.new_HDLSignal(f.c_name + '_reg', w)
                n.h_has_regs = True
            else:
                f.h_reg = None

    def gen_ports(self, root, module, n):
        """Add ports and wires for register or fields of :param n:
           :field h_reg: the register.
           :field h_rint: word(s) that are read from the register.
           :field h_wreq: the internal write request signal.
           :field h_iport: the input port.
           :field h_oport: the output port.
           :field h_wreq_port: the write strobe port.
           :field h_rreq_port: the read strobe port.
           :field h_rack_port: the read ack port.
           :field h_wack_port: the write ack port.
        """
        # Single port when 'port: reg' is set.
        iport = None
        oport = None

        # Register comment.  Always add a separation between registers ports.
        comment = '\n' + (n.comment or n.description or "REG {}".format(n.name))

        for f in n.children:
            w = None if f.c_rwidth == 1 else f.c_rwidth

            if n.hdl_port != 'reg' and not isinstance(f, tree.FieldReg):
                # Append field comment to the register comment (if present)
                pcomment = f.comment or f.description
                if pcomment is not None:
                    comment = pcomment if comment is None else comment + '\n' + pcomment

            # Input
            if f.hdl_type == 'wire' and n.access in ['ro', 'rw']:
                if n.hdl_port == 'reg':
                    # One port used for all fields.
                    if iport is None:
                        iport = add_module_port(root, module, n.c_name, n.width, dir='IN')
                        iport.comment = comment
                        comment = None
                    f.h_iport = Slice_or_Index(iport, f.lo, w)
                else:
                    # One port per field.
                    f.h_iport = add_module_port(root, module, f.c_name, w, dir='IN')
                    f.h_iport.comment = comment
                    comment = None
            else:
                f.h_iport = None

            # Output
            if n.access in ['wo', 'rw']:
                if n.hdl_port == 'reg':
                    # One port used for all fields.
                    if oport is None:
                        oport = add_module_port(root, module, n.c_name, n.width, dir='OUT')
                        oport.comment = comment
                        comment = None
                    f.h_oport = Slice_or_Index(oport, f.lo, w)
                else:
                    # One port per field.
                    f.h_oport = add_module_port(root, module, f.c_name, w, dir='OUT')
                    f.h_oport.comment = comment
                    comment = None
            else:
                f.h_oport = None

        comment = None

        self.gen_regs(root, module, n)
        self.gen_ack_strobe_ports(root, module, n)

        # Internal write request signal.
        n.h_wack = None
        if n.access in ['wo', 'rw']:
            # Strobe size.
            sz = None if n.c_size <= root.c_word_size else n.c_nwords
            n.h_wreq = module.new_HDLSignal(n.c_name + '_wreq', sz)
            if n.h_has_regs:
                # Need an intermediate wire for delayed ack
                n.h_wack = module.new_HDLSignal(n.c_name + '_wack', sz)
        else:
            n.h_wreq = None

        # Internal read port.
        if n.access in ['ro', 'rw'] and (n.has_fields() or n.children[0].hdl_type == 'const'):
            n.h_rint = module.new_HDLSignal(n.c_name + '_rint', n.c_rwidth)
        else:
            n.h_rint = None

    def gen_processes(self, root, module, ibus, n):
        module.stmts.append(HDLComment('Register {}'.format(n.c_name)))

        # Assign ports from the register.
        for f in n.children:
            if f.h_reg is not None and f.h_oport is not None:
                module.stmts.append(HDLAssign(f.h_oport, f.h_reg))

        if n.access in ['rw', 'wo']:
            # Handle wire fields: create connections between the bus and the outputs.
            for off in range(0, n.c_size, root.c_word_size):
                off *= tree.BYTE_SIZE
                for f in n.children:
                    if f.hdl_type != 'wire':
                        continue
                    reg, dat = field_decode(root, n, f, off, f.h_oport, ibus.wr_dat)
                    if reg is not None:
                        module.stmts.append(HDLAssign(reg, dat))

            if n.h_has_regs:
                wrproc = HDLSync(root.h_bus['clk'], root.h_bus['rst'], rst_sync=rst_sync)
                module.stmts.append(wrproc)
                for off in range(0, n.c_size, root.c_word_size):
                    off *= tree.BYTE_SIZE
                    wr_if = HDLIfElse(HDLEq(strobe_index(root, n, off, n.h_wreq), bit_1))
                    wr_if.else_stmts = None
                    for f in n.children:
                        if f.hdl_type != 'reg':
                            continue
                        # Reset code
                        if f.h_reg is not None and off == 0:
                            v = f.c_preset or 0
                            cst = HDLConst(v, f.c_rwidth if f.c_rwidth != 1 else None)
                            wrproc.rst_stmts.append(HDLAssign(f.h_reg, cst))
                        # Assign code
                        reg, dat = field_decode(root, n, f, off, f.h_reg, ibus.wr_dat)
                        if reg is not None:
                            wr_if.then_stmts.append(HDLAssign(reg, dat))
                    wrproc.sync_stmts.append(wr_if)

                # In case of regs, the strobe is delayed so that it appears at the same time as
                # the value.
                wrproc.sync_stmts.append(HDLAssign(n.h_wack, n.h_wreq))
                wrproc.rst_stmts.append(HDLAssign(n.h_wack, strobe_init(root, n)))

            if n.h_wreq_port is not None:
                module.stmts.append(HDLAssign(n.h_wreq_port, n.h_wack or n.h_wreq))

        if n.access in ['ro', 'rw'] and n.h_rint is not None:
            nxt = 0

            def pad(first):
                """Set the value of unused bits."""
                width = first - nxt
                if width <= 0:
                    return
                if width == 1:
                    val = bit_0
                else:
                    val = HDLReplicate(bit_0, first - nxt)
                module.stmts.append(HDLAssign(Slice_or_Index(n.h_rint, nxt, width), val))

            for f in n.children:
                if f.h_reg is not None:
                    src = f.h_reg
                elif f.h_iport is not None:
                    src = f.h_iport
                elif f.hdl_type == 'const':
                    src = HDLConst(f.c_preset, f.c_rwidth)
                else:
                    raise AssertionError
                pad(f.lo)
                module.stmts.append(HDLAssign(Slice_or_Index(n.h_rint, f.lo, f.c_rwidth), src))
                nxt = f.lo + f.c_rwidth
            pad(n.c_rwidth)

    def gen_read(self, root, s, n, off, ibus, rdproc):
        # Strobe
        if n.h_rreq_port is not None:
            s.append(HDLAssign(strobe_index(root, n, off, n.h_rreq_port), ibus.rd_req))
            if off == 0:
                # Default values for the strobe
                v = strobe_init(root, n)
                rdproc.stmts.append(HDLAssign(n.h_rreq_port, v))
        # Ack
        if n.h_rack_port is not None:
            rack = n.h_rack_port
            if off == 0:
                rdproc.sensitivity.append(rack)
            rack = strobe_index(root, n, off, rack)
        else:
            rack = ibus.rd_req
        s.append(HDLAssign(ibus.rd_ack, rack))
        if n.access == 'wo':
            return
        # Data
        if n.h_rint is not None:
            src = n.h_rint
        else:
            src = n.children[0].h_iport or n.children[0].h_reg
        if off == 0:
            rdproc.sensitivity.append(src)
        if n.c_nwords != 1:
            src = HDLSlice(src, off, root.c_word_bits)
        s.append(HDLAssign(ibus.rd_dat, src))

    def gen_write(self, root, s, n, off, ibus, wrproc):
        # Strobe
        if n.h_wreq is not None:
            s.append(HDLAssign(strobe_index(root, n, off, n.h_wreq), ibus.wr_req))
            if off == 0:
                # Default values for the strobe
                v = strobe_init(root, n)
                wrproc.stmts.append(HDLAssign(n.h_wreq, v))
        # Ack
        wack = n.h_wack_port or n.h_wack
        if wack is not None:
            if off == 0:
                wrproc.sensitivity.append(wack)
            wack = strobe_index(root, n, off, wack)
        else:
            wack = ibus.wr_req
        s.append(HDLAssign(ibus.wr_ack, wack))
