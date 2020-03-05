import yaml
from yaml.reader import *
from yaml.scanner import *
from yaml.parser import *
from yaml.composer import *
from yaml.resolver import *

from yaml.constructor import SafeConstructor

# Create custom safe constructor class that inherits from SafeConstructor
class MySafeConstructor(SafeConstructor):

    # Only handle true/false as boolean.
    bool_values = {
        'true':     True,
        'false':    False
    }

    # Create new method handle boolean logic
    def add_bool(self, node):
        value = self.construct_scalar(node)
        return self.bool_values.get(value.lower(), value)

# Inject the above boolean logic into the custom constuctor
MySafeConstructor.add_constructor('tag:yaml.org,2002:bool',
                                      MySafeConstructor.add_bool)


class MySafeLoader(Reader, Scanner, Parser, Composer, MySafeConstructor, Resolver):

    def __init__(self, stream):
        Reader.__init__(self, stream)
        Scanner.__init__(self)
        Parser.__init__(self)
        Composer.__init__(self)
        MySafeConstructor.__init__(self)
        Resolver.__init__(self)


def load(raw):
    return yaml.load(raw, Loader=MySafeLoader)