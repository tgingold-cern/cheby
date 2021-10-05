import os
import sys
import glob
import yaml
import jsonschema
from pathlib import Path


schema_base_url = "http://gitlab.cern.ch/cohtdrivers/cheby/"
schema_base_dir = Path(os.path.abspath(__file__)).parents[2] / 'schemas'


def get_schema(sch_id):
    if not os.path.isfile(schema_base_dir / sch_id):
        print(sch_id + ": no match, error opening file", file=sys.stderr)
        sys.exit(-1)

    with open(schema_base_dir / sch_id, 'r') as sch:
        schema = yaml.load(sch.read(), Loader=yaml.SafeLoader)

    return schema


def process_schema(filename):
    try:
        with open(filename, 'r') as sch:
            schema = yaml.load(sch.read(), Loader=yaml.SafeLoader)
    except yaml.YAMLError as e:
        print(filename + ": ignoring, error parsing file", file=sys.stderr)
        return

    try:
        jsonschema.Draft7Validator.check_schema(schema)
    except jsonschema.SchemaError as exc:
        print(filename + ": ignoring, error in schema: " + ': '.join(str(x) for x in exc.path), file=sys.stderr)
        return

    return schema


def http_handler(uri):
    '''Custom handler for YAML references'''
    try:
        if schema_base_url in uri:
            return process_schema(uri.replace(schema_base_url, ''))

        return yaml.load(jsonschema.compat.urlopen(uri).read().decode('utf-8'))
    except FileNotFoundError as e:
        print('Unknown file referenced:', e, file=sys.stderr)
        exit(-1)


handlers = {"http": http_handler}


ChebyVal = jsonschema.validators.extend(jsonschema.Draft7Validator)


class ChebyValidator(ChebyVal):
    resolver = jsonschema.RefResolver('', None, handlers=handlers)
    format_checker = jsonschema.FormatChecker()

    def __init__(self, schema, types=()):
        if isinstance(schema, str):
            schema = get_schema(schema)

        jsonschema.Draft7Validator.__init__(
            self, schema, types, resolver=self.resolver,
            format_checker=self.format_checker,
        )

def validate(infile, sch_id):
    with open(infile, 'r') as f:
        data = yaml.load(f.read(), Loader=yaml.SafeLoader)
    schema = get_schema(sch_id)

    try:
        v = ChebyValidator(schema)
        v.validate(data)
    except jsonschema.exceptions.ValidationError as exc:
        elt = ''.join([f'[\'{e}\']' for e in exc.absolute_path])
        print(f'CRITICAL: {infile}: {elt}: {exc.message}', file=sys.stderr)
        sys.exit(1)
