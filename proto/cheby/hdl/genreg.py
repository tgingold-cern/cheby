import cheby.tree as tree
import cheby.layout as layout
from cheby.hdl.elgen import ElGen
from cheby.hdl.globals import gconfig
from cheby.hdltree import (
    HDLAssign,
    HDLSync,
    HDLComb,
    HDLComment,
    HDLIfElse,
    bit_1,
    bit_0,
    HDLEq,
    HDLAnd,
    HDLOr,
    HDLNot,
    HDLParen,
    HDLIndex,
    HDLReplicate,
    Slice_or_Index,
    HDLConst,
)


class GenFieldBase(object):
    def __init__(self, root, reg, field):
        self.root = root
        self.reg = reg
        self.field = field

    def extract_reg_bounds(self, off):
        """Return the (LO, W) bounds of the register for index :param off:.
        For single word register, this function returns (0, W) where W is
        the width of the register when :param off: is 0.
        For multi word registers, it returns the bounds of the field that is
        visible at word :param off: (in bits).  The field must be visible at
        that offset.
        Graphically, for words of 32 bits, and a field at range 39-16:
            +--------+--------+--------+--------+
            |63    56|55    48|47    40|39****32|  offset: 32
            +--------+--------+--------+--------+
            |31****24|23****16|15     8|7      0|  offset:  0
            +--------+--------+--------+--------+
         returns: (0, 16) when off = 0
                  (16, 8) when off = 32
        """
        f = self.field
        # Register and value bounds
        d_hi = f.lo + f.c_rwidth - 1
        v_lo = 0
        v_hi = f.c_rwidth - 1
        # Check register is at least partially at OFF.
        assert d_hi >= off
        assert f.lo < off + self.root.c_word_bits
        if f.lo < off:
            # Strip the part below OFF.
            v_lo += off - f.lo
        # Set right boundaries
        d_hi -= off
        if d_hi >= self.root.c_word_bits:
            v_hi -= d_hi + 1 - self.root.c_word_bits
        return (v_lo, v_hi - v_lo + 1)

    def extract_reg2(self, val, lo, w):
        if w == self.field.c_rwidth:
            # The whole field is selected
            return val
        else:
            return Slice_or_Index(val, lo, w)

    def extract_dat2(self, val, lo, w):
        if w == self.root.c_word_bits:
            assert lo == 0
            # The whole field is selected
            return val
        else:
            return Slice_or_Index(val, lo, w)

    def extract_mask2(self, val, lo, w):
        if val is None:
            return None
        else:
            return self.extract_dat2(val, lo, w)

    def extract_reg(self, off, val):
        lo, w = self.extract_reg_bounds(off)
        return self.extract_reg2(val, lo, w)

    def extract_reg_dat(self, off, reg, dat, mask):
        lo, w = self.extract_reg_bounds(off)
        return (
            self.extract_reg2(reg, lo, w),
            self.extract_dat2(dat, self.field.lo + lo - off, w),
            self.extract_mask2(mask, self.field.lo + lo - off, w),
        )

    def get_offset_range(self):
        """Return an iterator on the address offsets for this register."""
        wb = self.root.c_word_bits
        return range(layout.align_floor(self.field.lo, wb),
                     layout.align(self.field.lo + self.field.c_rwidth, wb),
                     wb)

    def need_iport(self):
        """Return true if an input port is needed."""
        return False

    def need_oport(self):
        """Return true if an output port is needed."""
        return False

    def need_reg(self):
        """Return true if the field requires an internal register."""
        return False

    def get_input(self, off):
        """Return the value on a bus read.  Can be larger than a word."""
        raise AssertionError

    def connect_output(self, stmts, ibus): # pylint: disable=unused-argument
        """Called once for wo/rw registers to connect outputs"""
        return

    def assign_reg(self, then_stmts, else_stmts, off, ibus): # pylint: disable=unused-argument
        """Called if need_reg() was true to connect the register."""
        return


class GenFieldReg(GenFieldBase):
    def need_oport(self):
        return True

    def need_reg(self):
        return True

    def get_input(self, off):
        return self.extract_reg(off, self.field.h_reg)

    def connect_output(self, stmts, ibus):
        f = self.field

        # Overwrite output with lock-value if present
        if f.hdl_lock_value and (
            hasattr(self.root, "h_lock_port") and self.root.h_lock_port
        ):
            proc = HDLComb()
            proc.sensitivity.extend([self.root.h_lock_port, f.h_reg])
            proc.stmts.append(HDLComment("Overwrite output with lock value"))
            proc_if = HDLIfElse(HDLEq(self.root.h_lock_port, bit_1))
            proc_if.then_stmts.append(
                HDLAssign(
                    f.h_oport,
                    HDLConst(f.hdl_lock_value, f.c_rwidth if f.c_rwidth != 1 else None),
                )
            )
            proc_if.else_stmts.append(HDLAssign(f.h_oport, f.h_reg))
            proc.stmts.append(proc_if)
            stmts.append(proc)
        else:
            stmts.append(HDLAssign(f.h_oport, f.h_reg))


    def assign_reg(self, then_stmts, else_stmts, off, ibus):
        reg, dat, mask = self.extract_reg_dat(
            off, self.field.h_reg, ibus.wr_dat, ibus.wr_sel
        )

        # Regular assignment
        field_assign = HDLAssign(reg, dat)

        # Apply mask to assignment
        if hasattr(self.root, "hdl_wmask") and self.root.hdl_wmask and mask is not None:
            field_assign = HDLAssign(
                    reg,
                    HDLOr(
                        HDLParen(HDLAnd(reg, HDLNot(mask))), HDLParen(HDLAnd(dat, mask))
                    ),
                )

        # Apply lock signal
        if self.field.hdl_lock and (
            hasattr(self.root, "h_lock_port") and self.root.h_lock_port
        ):
            lock_if = HDLIfElse(HDLEq(self.root.h_lock_port, bit_0))
            lock_if.then_stmts.append(field_assign)
            lock_if.else_stmts = None
            field_assign = lock_if

        then_stmts.append(field_assign)


class GenFieldNoPort(GenFieldBase):
    """No-port register having no input and output ports"""
    def need_reg(self):
        return True

    def get_input(self, off):
        return self.extract_reg(off, self.field.h_reg)

    def assign_reg(self, then_stmts, else_stmts, off, ibus):
        reg, dat, mask = self.extract_reg_dat(
            off, self.field.h_reg, ibus.wr_dat, ibus.wr_sel
        )
        if hasattr(self.root, "hdl_wmask") and self.root.hdl_wmask and mask is not None:
            then_stmts.append(
                HDLAssign(
                    reg,
                    HDLOr(
                        HDLParen(HDLAnd(reg, HDLNot(mask))), HDLParen(HDLAnd(dat, mask))
                    ),
                )
            )
        else:
            then_stmts.append(HDLAssign(reg, dat))


class GenFieldWire(GenFieldBase):
    def need_iport(self):
        return self.reg.access in ['ro', 'rw']

    def need_oport(self):
        return self.reg.access in ['wo', 'rw']

    def get_input(self, off):
        return self.extract_reg(off, self.field.h_iport)

    def connect_output(self, stmts, ibus):
        # Handle wire fields: create connections between the bus and the outputs.
        for off in self.get_offset_range():
            reg, dat, mask = self.extract_reg_dat(
                off, self.field.h_oport, ibus.wr_dat, ibus.wr_sel
            )

            field_assign = HDLAssign(reg, dat)

            # Apply lock-value signal
            if self.field.hdl_lock_value and (
                hasattr(self.root, "h_lock_port") and self.root.h_lock_port
            ):
                proc = HDLComb()
                proc.sensitivity.extend([self.root.h_lock_port, dat])
                proc.stmts.append(HDLComment("Overwrite output with lock value"))
                proc_if = HDLIfElse(HDLEq(self.root.h_lock_port, bit_1))
                proc_if.then_stmts.append(
                    HDLAssign(
                        reg,
                        HDLConst(
                            self.field.hdl_lock_value,
                            self.field.c_rwidth if self.field.c_rwidth != 1 else None,
                        ),
                    )
                )
                proc_if.else_stmts.append(field_assign)
                proc.stmts.append(proc_if)
                field_assign = proc

            stmts.append(field_assign)

            # Output mask on separate port if available (and wmask active)
            if mask is not None and self.field.h_wmask_port is not None:
                stmts.append(HDLAssign(self.field.h_wmask_port, mask))


class GenFieldConst(GenFieldBase):
    def get_input(self, off):
        lo, w = self.extract_reg_bounds(off)
        return HDLConst(self.field.c_preset >> lo, w if w != 1 else None)


class GenFieldAutoclear(GenFieldBase):
    def need_oport(self):
        return True

    def need_reg(self):
        return True

    def get_input(self, off):
        # In case the field appear within an rw register, always read 0.
        _, w = self.extract_reg_bounds(off)
        return HDLConst(0, w if w != 1 else None)

    def assign_reg(self, then_stmts, else_stmts, off, ibus):
        _, w = self.extract_reg_bounds(off)
        reg, dat, mask = self.extract_reg_dat(
            off, self.field.h_reg, ibus.wr_dat, ibus.wr_sel
        )
        if hasattr(self.root, "hdl_wmask") and self.root.hdl_wmask and mask is not None:
            # Do not OR with previous value as its an autoclear field
            then_stmts.append(HDLAssign(reg, HDLAnd(dat, mask)))
        else:
            then_stmts.append(HDLAssign(reg, dat))
        else_stmts.append(HDLAssign(reg, HDLConst(0, w if w != 1 else None)))

    def connect_output(self, stmts, ibus):
        stmts.append(HDLAssign(self.field.h_oport, self.field.h_reg))


class GenFieldOrClr(GenFieldBase):
    def need_iport(self):
        return True

    def need_reg(self):
        return True

    def get_input(self, off):
        return self.extract_reg(off, self.field.h_reg)

    def assign_reg(self, then_stmts, else_stmts, off, ibus):
        lo, w = self.extract_reg_bounds(off)
        inp = self.extract_reg2(self.field.h_iport, lo, w)
        reg = self.extract_reg2(self.field.h_reg, lo, w)
        dat = self.extract_dat2(ibus.wr_dat, self.field.lo + lo - off, w)
        # Since a write request to the register is used to clear individual bits (and
        # not to store a new value), the mask is not applied
        then_stmts.append(HDLAssign(reg, HDLOr(inp, HDLParen(HDLAnd(reg, HDLNot(dat))))))
        else_stmts.append(HDLAssign(reg, HDLOr(inp, reg)))


class GenFieldOrClrOut(GenFieldOrClr):
    def need_oport(self):
        return True

    def connect_output(self, stmts, ibus):
        stmts.append(HDLAssign(self.field.h_oport, self.field.h_reg))


class GenReg(ElGen):
    FIELD_GEN = {
        "reg": GenFieldReg,
        "no-port": GenFieldNoPort,
        "wire": GenFieldWire,
        "const": GenFieldConst,
        "autoclear": GenFieldAutoclear,
        "or-clr": GenFieldOrClr,
        "or-clr-out": GenFieldOrClrOut,
    }

    def field_decode(self, f, off, dat):
        """Handle multi-word accesses.  Slice (if needed) VAL and DAT for offset
           OFF and field F."""
        # Register and value bounds
        d_lo = f.lo
        d_hi = f.lo + f.c_rwidth - 1
        # Next field if not affected by this read.
        if d_hi < off:
            return None
        if d_lo >= off + self.root.c_word_bits:
            return None
        if d_lo < off:
            # Strip the part below OFF.
            d_lo = off
        # Set right boundaries
        d_lo -= off
        d_hi -= off
        if d_hi >= self.root.c_word_bits:
            d_hi = self.root.c_word_bits - 1

        if d_hi == self.root.c_word_bits - 1 and d_lo == 0:
            return dat
        else:
            return Slice_or_Index(dat, d_lo, d_hi - d_lo + 1)


    def strobe_init(self):
        sz = self.n.c_size // self.root.c_word_size
        if sz <= 1:
            return bit_0
        else:
            return HDLReplicate(bit_0, sz)


    def strobe_index(self, off, lhs):
        if self.n.c_size <= self.root.c_word_size:
            return lhs
        else:
            return HDLIndex(lhs, off // self.root.c_word_bits)

    def get_port_name(self, n, name_sfx, dir_sfx, both):
        """Return the name of the port for node :param n: (a reg or a field)
        :param suffix: is append if the name is not specified with x-hdl:port_name
        attribute or if :param both: is True"""
        if isinstance(n, tree.FieldReg):
            n = n._parent
        name = n.hdl_port_name or n.h_pname
        name += name_sfx
        if (n.hdl_port_name is None or both) and self.root.h_itf is None:
            name += '_' + dir_sfx
        return name

    def gen_ack_strobe_ports(self):
        n = self.n
        # Strobe size.  There is one strobe signal per word, so create a vector if
        # the register is longer than a word.
        sz = None if n.c_size <= self.root.c_word_size else n.c_nwords

        # Write strobe
        if n.hdl_write_strobe:
            n.h_wreq_port = self.add_module_port(
                self.get_port_name(n, "_wr", "o", True), size=sz, dir="OUT"
            )

            if "wire" in n.hdl_field_types and len(n.hdl_field_types) > 1:
                n.h_wreq_wire_port = self.add_module_port(
                    self.get_port_name(n, "_wire_wr", "o", True), size=sz, dir="OUT"
                )
            else:
                n.h_wreq_wire_port = None
        else:
            n.h_wreq_port = None
            n.h_wreq_wire_port = None

        # Read strobe
        if n.hdl_read_strobe:
            n.h_rreq_port = self.add_module_port(
                self.get_port_name(n, '_rd', 'o', True), size=sz, dir='OUT')
        else:
            n.h_rreq_port = None

        # Write ack
        if n.hdl_write_ack:
            n.h_wack_port = self.add_module_port(
                self.get_port_name(n, '_wack', 'i', True), size=sz, dir='IN')
        else:
            n.h_wack_port = None

        # Read ack
        if n.hdl_read_ack:
            n.h_rack_port = self.add_module_port(
                self.get_port_name(n, '_rack', 'i', True), size=sz, dir='IN')
        else:
            n.h_rack_port = None

    def gen_regs(self):
        """Add internal registers (to memorize the value)."""
        n = self.n
        n.h_has_regs = False

        for f in n.children:
            # Create the register (only for registers)
            if f.h_gen.need_reg():
                w = None if f.c_rwidth == 1 else f.c_rwidth
                f.h_reg = self.module.new_HDLSignal(f.h_fname + '_reg', w, preset=f.c_preset)
                n.h_has_regs = True
            else:
                f.h_reg = None

    def gen_internal_wires(self):
        n = self.n

        # Internal write acknowledge
        n.h_wack = None

        # Internal write request
        n.h_wreq = None
        # Internal (delayed) write acknowledge used to generate a write strobe signal
        # after (!) the register was updated
        n.h_wstrb = None
        n.h_wstrb_wire = None

        if n.access in ["wo", "rw"]:
            # Signal width
            sz = None if n.c_size <= self.root.c_word_size else n.c_nwords

            n.h_wreq = self.module.new_HDLSignal(n.c_name + "_wreq", sz)
            if n.h_has_regs:
                n.h_wack = self.module.new_HDLSignal(n.c_name + "_wack", sz)
                n.h_wstrb = self.module.new_HDLSignal(n.c_name + "_wstrb", sz)
                n.h_wstrb_wire = self.module.new_HDLSignal(n.c_name + "_wstrb_wire", sz)

    def gen_ports(self):
        """Add ports and wires for register or fields of :param n:
        :field h_reg: the register.
        :field h_wreq: the internal write request signal.
        :field h_iport: the input port.
        :field h_oport: the output port.
        :field h_wreq_port: the write strobe port.
        :field h_wreq_wire_port: the write strobe port for fields of type "wire".
        :field h_rreq_port: the read strobe port.
        :field h_rack_port: the read ack port.
        :field h_wack_port: the write ack port.
        :field h_wmask_port: the write mask output port.
        """
        n = self.n
        # Single port when 'port: reg' is set.
        iport = None
        oport = None

        # Register comment.  Always add a separation between registers ports.
        comment = "\n" + (n.comment or "REG {}".format(n.name))

        for f in n.children:
            # Set hdl generator for the field.
            f.h_gen = self.FIELD_GEN[f.hdl_type](self.root, n, f)

            w = None if f.c_rwidth == 1 else f.c_rwidth

            if n.hdl_port != 'reg' and not isinstance(f, tree.FieldReg):
                # Append field comment to the register comment (if present)
                if f.comment is not None:
                    comment = (
                        f.comment if comment is None else comment + "\n" + f.comment
                    )

            need_iport = f.h_gen.need_iport()
            need_oport = f.h_gen.need_oport()

            # Input
            if need_iport:
                if n.hdl_port == 'reg':
                    # One port used for all fields.
                    if iport is None:
                        name = self.get_port_name(n, '', 'i', need_oport)
                        iport = self.add_module_port(name, n.width, dir='IN')
                        iport.comment = comment
                        comment = None
                    f.h_iport = Slice_or_Index(iport, f.lo, w)
                else:
                    # One port per field.
                    name = self.get_port_name(f, '', 'i', need_oport)
                    f.h_iport = self.add_module_port(name, w, dir='IN')
                    f.h_iport.comment = comment
                    comment = None
            else:
                f.h_iport = None

            # Output
            f.h_wmask_port = None

            if need_oport:
                if n.hdl_port == "reg":
                    # One port used for all fields.
                    if oport is None:
                        oport_name = self.get_port_name(n, "", "o", need_iport)
                        oport = self.add_module_port(oport_name, n.width, dir="OUT")
                        oport.comment = comment
                        comment = None

                        # Write mask port
                        # (only used by wo/rw wire fields with active wmask)
                        if (
                            f.hdl_type == "wire"
                            and hasattr(self.root, "hdl_wmask")
                            and self.root.hdl_wmask
                        ):
                            wmask_port_name = self.get_port_name(
                                n, "_wmask", "o", need_iport
                            )
                            wmask_port = self.add_module_port(
                                wmask_port_name, n.width, dir="OUT"
                            )

                    f.h_oport = Slice_or_Index(oport, f.lo, w)

                    if (
                        f.hdl_type == "wire"
                        and hasattr(self.root, "hdl_wmask")
                        and self.root.hdl_wmask
                    ):
                        f.h_wmask_port = Slice_or_Index(wmask_port, f.lo, w)

                else:
                    # One port per field.
                    oport_name = self.get_port_name(f, "", "o", need_iport)
                    f.h_oport = self.add_module_port(oport_name, w, dir="OUT")
                    f.h_oport.comment = comment
                    comment = None

                    # Write mask port (only used by wo/rw wire fields with active wmask)
                    if (
                        f.hdl_type == "wire"
                        and hasattr(self.root, "hdl_wmask")
                        and self.root.hdl_wmask
                    ):
                        wmask_port_name = self.get_port_name(
                            f, "_wmask", "o", need_iport
                        )
                        f.h_wmask_port = self.add_module_port(
                            wmask_port_name, w, dir="OUT"
                        )
            else:
                f.h_oport = None

        comment = None

        self.gen_regs()
        self.gen_ack_strobe_ports()
        self.gen_internal_wires()

    def gen_processes(self, ibus):
        n = self.n
        self.module.stmts.append(HDLComment("Register {}".format(n.c_name)))

        if n.access in ["rw", "wo"]:
            for f in n.children:
                f.h_gen.connect_output(self.module.stmts, ibus)

            if n.h_has_regs:
                # Write acknowledge
                self.module.stmts.append(HDLAssign(n.h_wack, n.h_wreq))

                # Register process
                ffproc = HDLSync(
                    self.root.h_bus["clk"],
                    self.root.h_bus["vrst"],
                    rst_sync=gconfig.rst_sync,
                )

                # Reset statements: Add each field with its preset
                for f in n.children:
                    if f.h_reg is not None:
                        cst = HDLConst(
                            f.c_preset or 0, f.c_rwidth if f.c_rwidth != 1 else None
                        )
                        ffproc.rst_stmts.append(HDLAssign(f.h_reg, cst))

                # Synchronous statements: Update each field only with write request
                for off in range(0, n.c_size, self.root.c_word_size):
                    off *= tree.BYTE_SIZE
                    wr_if = HDLIfElse(HDLEq(self.strobe_index(off, n.h_wreq), bit_1))

                    for f in n.children:
                        if f.h_reg is not None and off in f.h_gen.get_offset_range():
                            f.h_gen.assign_reg(
                                wr_if.then_stmts, wr_if.else_stmts, off, ibus
                            )

                    if not wr_if.else_stmts:
                        wr_if.else_stmts = None

                    ffproc.sync_stmts.append(wr_if)

                # Write strobe
                if "wire" in n.hdl_field_types and len(n.hdl_field_types) > 1:
                    # Register contains fields of type "wire" that require a write
                    # strobe without delaying (n.h_wstrb_wire) and other fields whose
                    # data has to be sampled first and hence, require a write strobe
                    # with a delay (n.h_wstrb)
                    ffproc.rst_stmts.append(HDLAssign(n.h_wstrb, self.strobe_init()))
                    ffproc.sync_stmts.append(HDLAssign(n.h_wstrb, n.h_wreq))

                    self.module.stmts.append(HDLAssign(n.h_wstrb_wire, n.h_wreq))

                elif n.hdl_type == "wire" or "wire" in n.hdl_field_types:
                    # Register is of type wire or contains only fields of type "wire".
                    # Requires a write strobe that is not delayed.
                    self.module.stmts.append(HDLAssign(n.h_wstrb, n.h_wreq))

                else:
                    # Register and its fields are not of type "wire". Delay the write
                    # strobe to be aligned with the update of the register/field data.
                    ffproc.rst_stmts.append(HDLAssign(n.h_wstrb, self.strobe_init()))
                    ffproc.sync_stmts.append(HDLAssign(n.h_wstrb, n.h_wreq))

                self.module.stmts.append(ffproc)

            # Connect write strobe to port
            if n.h_wreq_port is not None:
                self.module.stmts.append(
                    HDLAssign(n.h_wreq_port, n.h_wstrb or n.h_wreq)
                )
            if n.h_wreq_wire_port is not None:
                self.module.stmts.append(
                    HDLAssign(n.h_wreq_wire_port, n.h_wstrb_wire or n.h_wreq)
                )

    def gen_read(self, s, off, ibus, rdproc):
        n = self.n

        # Strobe
        if n.h_rreq_port is not None:
            s.append(HDLAssign(self.strobe_index(off, n.h_rreq_port), ibus.rd_req))
            if off == 0:
                # Default values for the strobe
                v = self.strobe_init()
                rdproc.stmts.append(HDLAssign(n.h_rreq_port, v))

        # Acknowledge
        if n.h_rack_port is not None:
            rack = n.h_rack_port
            rack = self.strobe_index(off, rack)
        elif ibus.rd_req_del:
            rack = ibus.rd_req_del
        else:
            rack = ibus.rd_req
        s.append(HDLAssign(ibus.rd_ack, rack))

        # Error
        if n.access == 'wo':
            # Return error if read request to write-only register is made
            s.append(HDLAssign(ibus.rd_err, rack))
        else:
            # Return no error
            s.append(HDLAssign(ibus.rd_err, bit_0))

        # Data
        if n.access == 'wo':
            # No data are returned for wo.
            return

        nxt = off

        def pad(first):
            """Set the value of unused bits."""
            width = first - nxt
            if width <= 0:
                return
            if width == 1:
                val = bit_0
            else:
                val = HDLReplicate(bit_0, first - nxt)
            s.append(HDLAssign(Slice_or_Index(ibus.rd_dat, nxt - off, width), val))

        for f in n.c_sorted_fields:
            if f.lo >= off + self.root.c_word_bits:
                break
            if f.lo + f.c_rwidth <= off:
                continue
            pad(f.lo)
            src = f.h_gen.get_input(off)
            dst = self.field_decode(f, off, ibus.rd_dat)
            s.append(HDLAssign(dst, src))
            nxt = f.lo + f.c_rwidth
        pad(off + self.root.c_word_bits)

    def gen_write(self, s, off, ibus, wrproc):
        n = self.n

        # Strobe
        if n.h_wreq is not None:
            s.append(HDLAssign(self.strobe_index(off, n.h_wreq), ibus.wr_req))
            if off == 0:
                # Default values for the strobe
                v = self.strobe_init()
                wrproc.stmts.append(HDLAssign(n.h_wreq, v))

        # Acknowledge
        wack = n.h_wack_port or n.h_wack
        if wack is not None:
            wack = self.strobe_index(off, wack)
        elif ibus.wr_req_del:
            wack = ibus.wr_req_del
        else:
            wack = ibus.wr_req
        s.append(HDLAssign(ibus.wr_ack, wack))

        # Error
        if n.access == 'ro':
            # Return error if write request to read-only register is made
            s.append(HDLAssign(ibus.wr_err, wack))
        else:
            # Return no error
            s.append(HDLAssign(ibus.wr_err, bit_0))
