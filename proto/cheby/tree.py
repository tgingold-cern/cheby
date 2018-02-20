"""Classes to represent a Cheby tree.
   This is mostly data oriented:
   - the variables represent user data.  The name of the attribute has
     no prefix.  These variables shouldn't be modified by the program,
     so that the original file can be rewritten (without the comments).
   - Computed values have the 'c_' prefix."""


class Node(object):
    """Base class for any Cheby node.
       :var parent: the parent of that node, None for the root.
       """
    _dispatcher = {}    # Class variable for visitor.

    def __init__(self, parent):
        self._parent = parent

    def visit(self, name, *args, **kwargs):
        return self._dispatcher[name](*args, **kwargs)


class NamedNode(Node):
    """Many Cheby nodes have a name/description/comment.  Create a
       common class for them."""
    _dispatcher = {}

    def __init__(self, parent):
        super(NamedNode, self).__init__(parent)
        self.name = None
        self.description = None
        self.comment = None
        # Computed values
        self.c_address = None
        self.c_size = None
        self.c_align = None

    def get_path(self):
        """Return the full path (from the root) of this node."""
        if self.name is None:
            p = '/??'
        else:
            p = '/' + self.name
        if self._parent is None:
            return p
        else:
            return self._parent.get_path() + p


class CompositeNode(NamedNode):
    """Base class for Cheby nodes with children; they are also named.
       :var children: is the list of children."""
    _dispatcher = {}

    def __init__(self, parent):
        super(CompositeNode, self).__init__(parent)
        self.children = []


class Root(CompositeNode):
    _dispatcher = {}

    def __init__(self):
        super(Root, self).__init__(None)
        self.bus = None
        # Computed variables
        self.c_word_size = None


class Reg(NamedNode):
    _dispatcher = {}

    def __init__(self, parent):
        super(Reg, self).__init__(parent)
        self.width = None
        self.type = None
        self.access = None
        self.address = None
        self.fields = []


class Field(NamedNode):
    _dispatcher = {}

    def __init__(self, parent):
        super(Field, self).__init__(parent)
        self.hi = None
        self.lo = None
        self.preset = None


class ComplexNode(CompositeNode):
    _dispatcher = {}

    def __init__(self, parent):
        super(ComplexNode, self).__init__(parent)
        self.address = None
        self.align = None
        self.size = None


class Block(ComplexNode):
    _dispatcher = {}

    def __init__(self, parent):
        super(Block, self).__init__(parent)
        self.submap_file = None
        self.interface = None


class Array(ComplexNode):
    _dispatcher = {}

    def __init__(self, parent):
        super(Array, self).__init__(parent)
        self.repeat = None


class Visitor(object):
    def visit(self, n, *args, **kwargs):
        return n.visit(self.__class__, self, n, *args, **kwargs)

    @classmethod
    def register(cls, typ):
        def fun(f):
            typ._dispatcher[cls] = f
            return f
        return fun
