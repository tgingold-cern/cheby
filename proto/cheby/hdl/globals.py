dirname = {'IN': 'i', 'OUT': 'o'}

class gconfig:
    # HDL language to generate for
    # Used to distinguish between Verilog and SystemVerilog
    hdl_lang = None

    # Used by all HDLSync processes.
    # When true, the flip-flop reset is synchronous.
    rst_sync = True
