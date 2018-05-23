import cheby.parser
import cheby.layout
import cheby.tree as tree

class UALValue(object):
    def __init__(self, ual, root, node, offset):
        self._ual = ual
        self._root = root
        self._node = node
        self._offset = offset

    def _get_child(self, name, children):
        els = [el for el in children if el.name == name]
        if len(els) != 1:
            raise AttributeError("no {} in {}".format(name, self._node.name))
        return els[0]

    def _read_val(self):
        res = 0
        word_size = self._root.c_word_size * tree.BYTE_SIZE
        # FIXME: assume LE
        for i in range(self._node.width // word_size):
            addr = self._offset + i * word_size
            if word_size == 16:
                v = self._ual.readw(addr)
            elif word_size == 32:
                v = self._ual.readl(addr)
            else:
                raise AssertionError
            res |= v << (i * word_size)
        return res

    def _write_val(self, val):
        word_size = self._root.c_word_size * tree.BYTE_SIZE
        # FIXME: assume LE
        for i in range(self._node.width // word_size):
            addr = self._offset + i * word_size
            v = (val >> (i * word_size)) & ((1 << word_size) - 1)
            if word_size == 16:
                self._ual.writew(addr, v)
            elif word_size == 32:
                self._ual.writel(addr, v)
            else:
                raise AssertionError

    def __getattr__(self, name):
        if isinstance(self._node, (tree.Root, tree.Block, tree.Array)):
            el = self._get_child(name, self._node.children)
            return UALValue(self._ual, self._root, el,
                            self._offset + el.c_address)
        elif isinstance(self._node, tree.Reg) and self._node.type is None:
            raise AttributeError
#            el = self._get_child(name)
#            val = self.read_reg()
        else:
            raise AttributeError

    def __setattr__(self, name, value):
        if name[0] == '_':
            object.__setattr__(self, name, value)
        elif isinstance(self._node, tree.Reg) and self._node.type is None:
            el = self._get_child(name, self._node.children)
            val = self._read_val()
            mask = ((1 << el.c_width) - 1) << el.lo
            val &= ~mask
            val |= (value << el.lo) & mask
            self._write_val(val)
        else:
            print(self._node)
            raise AttributeError("no '{}' in {}".format(name, self._node.name))

    def __getitem__(self, key):
        if not isinstance(key, int):
            raise KeyError
        if isinstance(self._node, tree.Array):
            if key >= self._node.repeat:
                raise IndexError
            return UALValue(self._ual, self._root, self._node,
                            self._offset + key * self._node.c_elsize)
        else:
            raise TypeError

def create_ual_access(ual, filename):
    root = cheby.parser.parse_yaml(filename)
    cheby.layout.layout_cheby(root)

    return UALValue(ual, root, root, 0)
