from cheby.hdltree import (HDLCst, HDLComb,
                           HDLSignal, HDLPort, HDLInterfaceSelect,
                           HDLBinary, HDLUnary,
                           HDLCst, HDLReplicate, HDLSlice, HDLIndex,
                           HDLAssign, HDLSwitch, HDLComment)

def compute_sensitivity(comb):
    res = []
    sres = set()

    def extract_expr(expr, is_target=False):
        if isinstance(expr, (HDLSignal, HDLPort, HDLInterfaceSelect)):
            if is_target:
                return
            if expr not in sres:
                res.append(expr)
                sres.add(expr)
        elif isinstance(expr, HDLCst):
            pass
        elif isinstance(expr, HDLReplicate):
            assert not is_target
            extract_expr(expr.expr)
        elif isinstance(expr, HDLBinary):
            assert not is_target
            extract_expr(expr.left)
            extract_expr(expr.right)
        elif isinstance(expr, HDLUnary):
            assert not is_target
            extract_expr(expr.expr)
        elif isinstance(expr, (HDLSlice, HDLIndex)):
            if not is_target:
                extract_expr(expr.prefix)
        else:
            assert False, "cannot handle expression {}".format(expr)

    def extract_stmt_list(stmts):
        for s in stmts:
            if isinstance(s, HDLAssign):
                extract_expr(s.target, True)
                extract_expr(s.expr)
            elif isinstance(s, HDLSwitch):
                extract_expr(s.expr)
                for ch in s.choices:
                    # Choice is static.
                    extract_stmt_list(ch.stmts)
            elif isinstance(s, HDLComment):
                pass
            else:
                assert False, "cannot handle statement {}".format(s)

    extract_stmt_list(comb.stmts)
    comb.sensitivity = res
