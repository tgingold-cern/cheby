#! /usr/bin/env python

import argparse
import sys
import os
import cx_Oracle

connection = None

def show(cmd_name):
   cursor = connection.cursor()

   print('files:')
   cursor.execute("""
   SELECT * from cheby_files""")
   for l in cursor:
        print(l)

   print('namespace:')
   cursor.execute("""
   SELECT * from cheby_namespaces""")
   for l in cursor:
        print(l)


def list_namespaces(cmd_name):
   cursor = connection.cursor()
   cursor.execute("SELECT * FROM cheby_namespaces")
   print("{:4} {:20} {:10} {}".format('id', 'name', 'creator', 'description'))
   print('------------------------------------------------------------------')
   for nid, name, desc, creator in cursor:
      print("{:4} {:20} {:10} {}".format(nid, name, creator, desc))


def remove_namespace(cmd_name, *args):
   if len(args) != 1:
      sys.stderr.write('usage: {} namespace\n'.format(cmd_name))
      return
   name = args[0]
   cursor = connection.cursor()
   cursor.execute(
      "DELETE FROM cheby_namespaces WHERE namespace_name = '{}'".format(name))
   connection.commit()


def add_namespace(cmd_name, *args):
   if len(args) == 0 or len(args) > 3 :
      sys.stderr.write(
         'usage: {} namespace [DESCRIPTION] [CREATOR]\n'.format(cmd_name))
      return
   name = args[0]
   desc = args[1] if len(args) > 1 else ''
   user = args[2] if len(args) > 2 else os.environ.get('USER', 'unknown')
   cursor = connection.cursor()
   cursor.execute(
      """INSERT INTO cheby_namespaces
          (namespace_name, namespace_description, creator)
         VALUES('{}', '{}', '{}')""".format(name, desc, user))
   connection.commit()


commands = {
   'show': show,
   'list-namespaces': list_namespaces,
   'remove-namespace': remove_namespace,
   'add-namespace': add_namespace
}

def bad_cmd(cmd_name):
   sys.stderr.write("Unknown command '{}', try --help\n".format(cmd_name))
   sys.exit(1)


def main():
   global connection

   parser = argparse.ArgumentParser(description='CCDB/Cheby bridge')
   parser.add_argument("-c", dest='config', required=True,
                       help='DB connection (usr/passwd@dsn)')
   parser.add_argument("args", nargs='+')
   args = parser.parse_args()

   connection = cx_Oracle.connect(args.config)

   cmd_name = args.args[0]
   cmd_args = args.args[1:]                       
   proc = commands.get(cmd_name, bad_cmd)
   proc(cmd_name, *cmd_args)


if __name__ == '__main__':
   main()
