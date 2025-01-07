from copy import deepcopy
from contextlib import contextmanager

dirname = {'IN': 'i', 'OUT': 'o'}

class GlobalConfig:
    def __init__(self):
        # HDL language to generate for
        # Used to distinguish between Verilog and SystemVerilog
        self.hdl_lang = None

        # Used by all HDLSync processes.
        # When true, the flip-flop reset is synchronous.
        self.rst_sync = True

        # Used by all HDLSignal signals.
        # When true, registers are initialized with their preset if it is supplied
        self.initialize_reg_preset = False

    def restore_defaults(self):
        default = GlobalConfig()
        # Remove any added attribute
        for k in vars(self).keys() - vars(default).keys():
            del vars(self)[k]
        # Restore original attributes
        vars(gconfig).update(vars(default))

# The global configuration object
gconfig = GlobalConfig()

@contextmanager
def gconfig_scope():
    """
    A context manager that saves the entire state of the global `gconfig` variable at the beginning,
    allows the caller to modify `gconfig` inside the context, and then restores
    it exactly to its previous state on exit (removing attributes that
    didn't exist before and reverting those that did to their original values).
    """
    old_state = deepcopy(vars(gconfig))
    try:
        # Let the caller make changes
        yield
    finally:
        # Restore state

        # Remove any added attribute
        for k in vars(gconfig).keys() - old_state.keys():
            del vars(gconfig)[k]
        # Restore original attributes
        vars(gconfig).update(old_state)
