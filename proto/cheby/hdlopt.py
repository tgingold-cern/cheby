"""Optimization pass
   Remove unused signals
"""
import cheby.hdltree as hdltree

# TODO: currently we always keep control statements (ifelse, case, Sync, Comb)
# Remove them if they are empty ?

class Unused:
    def __init__(self):
        # Signals that are known to be used.  The initial set is input ports.
        self.used = set()
        # Signals that have been discovered, but not known if used.
        self.discovered = set()
        # Graph of dependency: if a signal S is used, all signals that are used to
        # to compute S are also used.
        self.graph = {}
        self.unused = set()

    def build_module(self, t):
        """Build graph for a module"""
        self.build_list(t.global_decls)
        self.build_list(t.params)
        self.build_list(t.ports)
        self.build_list(t.decls)
        self.build_list(t.stmts)

    def build_list(self, l):
        """Build graph for a list of nodes"""
        if l is None:
            return
        for e in l:
            self.build(e)

    def build_port(self, t):
        assert t not in self.graph
        self.graph[t] = set()
        if t.dir in ('IN', 'EXT'):
            # All inputs are known to be used
            self.used.add(t)
        else:
            # Dependencies for an output are used
            assert t.dir == 'OUT'
            self.discovered.add(t)

    def build_interfaceinstance(self, t):
        assert t not in self.graph
        # The interface is known to be used (as it is connected to the outside)
        # But we also need to extract dependencies for its outputs.
        self.graph[t] = set()
        self.discovered.add(t)

    def build_signal(self, t):
        assert t not in self.graph
        self.graph[t] = set()

    def extract_target(self, t):
        if isinstance(t, (hdltree.HDLSignal, hdltree.HDLInterfaceInstance, hdltree.HDLPort)):
            return t
        elif isinstance(t, (hdltree.HDLInterfaceSelect, hdltree.HDLInterfaceIndex,
                            hdltree.HDLSlice, hdltree.HDLIndex)):
            # For index: check the index is const.
            return self.extract_target(t.prefix)
        else:
            assert False, "extract target {}".format(t)

    def build_expr(self, s, e):
        if e is None:
            return
        if isinstance(e, (hdltree.HDLSignal, hdltree.HDLPort, hdltree.HDLInterfaceInstance)):
            s.add(e)
        elif isinstance(e, (hdltree.HDLSlice, hdltree.HDLIndex)):
            self.build_expr(s, e.prefix)
            self.build_expr(s, e.index)
        elif isinstance(e, (hdltree.HDLInterfaceSelect, hdltree.HDLInterfaceIndex)):
            self.build_expr(s, e.prefix)
        elif isinstance(e, hdltree.HDLBinary):
            self.build_expr(s, e.left)
            self.build_expr(s, e.right)
        elif isinstance(e, (hdltree.HDLUnary, hdltree.HDLParen, hdltree.HDLReplicate)):
            self.build_expr(s, e.expr)
        elif isinstance(e, (int, hdltree.HDLBit, hdltree.HDLUndef, hdltree.HDLConstBase)):
            pass
        else:
            assert False, "build_expr {}".format(e)

    def build(self, t):
        """Build graph for a node"""
        if t is None:
            return
        #print("build {} {}".format(t.__class__, t.name if hasattr(t, "name") else ""))
        if isinstance(t, hdltree.HDLModule):
            self.build_module(t)
        elif isinstance(t, hdltree.HDLPort):
            self.build_port(t)
        elif isinstance(t, (hdltree.HDLInterface, hdltree.HDLInterfaceArray, hdltree.HDLInterfaceInstance)):
            self.build_interfaceinstance(t)
        elif isinstance(t, hdltree.HDLInterfaceSelect):
            pass
        elif isinstance(t, hdltree.HDLSignal):
            self.build_signal(t)
        elif isinstance(t, hdltree.HDLAssign):
            targ = self.extract_target(t.target)
            self.build_expr(self.graph[targ], t.expr)
        elif isinstance(t, hdltree.HDLSync):
            self.build_expr(self.discovered, t.clk)
            self.build_expr(self.discovered, t.rst)
            self.build_list(t.rst_stmts)
            self.build_list(t.sync_stmts)
        elif isinstance(t, hdltree.HDLComb):
            self.build_list(t.stmts)
        elif isinstance(t, hdltree.HDLIfElse):
            self.build_expr(self.discovered, t.cond)
            self.build_list(t.then_stmts)
            self.build_list(t.else_stmts)
        elif isinstance(t, hdltree.HDLSwitch):
            self.build_expr(self.discovered, t.expr)
            self.build_list(t.choices)
        elif isinstance(t, hdltree.HDLChoice):
            self.build_list(t.stmts)
        elif isinstance(t, hdltree.HDLInstance):
            for _, expr in t.conns:
                self.build_expr(self.discovered, expr)
        elif isinstance(t, (hdltree.HDLComment, )):
            pass
        else:
            assert False, "unhandled type {} {}".format(t.__class__, t.name if hasattr(t, "name") else "")

    def iterate(self):
        while len(self.discovered) > 0:
            # Take an element, but leave it.
            for s in self.discovered:
                break
            if s not in self.used:
                deps = self.graph[s]
                self.discovered |= deps - self.used
                self.used.add(s)
            self.discovered.remove(s)

    def extract_unused(self):
        self.unused = set(self.graph) - self.used

    def is_unused(self, t):
        if isinstance(t, hdltree.HDLSignal):
            return t in self.unused
        elif isinstance(t, hdltree.HDLAssign):
            return self.is_unused(t.target)
        elif isinstance(t, (hdltree.HDLInterfaceSelect,
                            hdltree.HDLInterfaceIndex,
                            hdltree.HDLIndex, hdltree.HDLSlice)):
            return self.is_unused(t.prefix)
        elif isinstance(t, (hdltree.HDLInterfaceInstance, hdltree.HDLPort)):
            assert t not in self.unused
            return False
        elif isinstance(t, hdltree.HDLIfElse):
            return not (t.then_stmts or t.else_stmts)
        elif isinstance(t, hdltree.HDLSync):
            return not (t.rst_stmts or t.sync_stmts)
        elif isinstance(t, (hdltree.HDLComment,
                            hdltree.HDLComb, hdltree.HDLInstance,
                            hdltree.HDLSwitch, hdltree.HDLChoice)):
            return False
        else:
            assert False, "is_unused: unhandled type {} {}".format(t.__class__, t.name)

    def remove_unused_list(self, l):
        if l is None:
            return
        i = 0
        while i < len(l):
            # Recurse first
            self.remove_unused(l[i])
            # Then remove if possible
            if self.is_unused(l[i]):
                del l[i]
            else:
                i += 1

    def remove_unused(self, t):
        if t is None:
            return
        # print("build {} {}".format(t.__class__, t.name))
        if isinstance(t, hdltree.HDLModule):
            self.remove_unused_list(t.decls)
            self.remove_unused_list(t.stmts)
        elif isinstance(t, hdltree.HDLSync):
            self.remove_unused_list(t.rst_stmts)
            self.remove_unused_list(t.sync_stmts)
        elif isinstance(t, hdltree.HDLComb):
            self.remove_unused_list(t.stmts)
        elif isinstance(t, hdltree.HDLIfElse):
            self.remove_unused_list(t.then_stmts)
            self.remove_unused_list(t.else_stmts)
        elif isinstance(t, hdltree.HDLSwitch):
            self.remove_unused_list(t.choices)
        elif isinstance(t, hdltree.HDLChoice):
            self.remove_unused_list(t.stmts)
        elif isinstance(t, (hdltree.HDLSignal, hdltree.HDLComment,
                            hdltree.HDLInstance, hdltree.HDLAssign)):
            # No recursion
            pass
        else:
            assert False, "remove_unused: unhandled type {} {}".format(t.__class__, t.name)


def remove_unused(t):
    u = Unused()
    # Initialize the graph of dependencies
    u.build(t)
    #for k, v in u.graph.items():
    #    print("{}: {}".format(k.name, {s.name for s in v}))
    # Iterate until all the signals in discovered are handled
    u.iterate()
    # Extract list of unused signals
    u.extract_unused()
    #for s in u.used:
    #    print("used: {}".format(s.name))
    #for s in u.unused:
    #    print("unused: {}".format(s.name))
    # Remove unused signals (declaration and use)
    u.remove_unused(t)
