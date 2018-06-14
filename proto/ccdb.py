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
   print('desc: {}'.format(cursor.description))
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
   print("{:4} {:20} {:10} {}".format('nid', 'name', 'creator', 'description'))
   print('------------------------------------------------------------------')
   for nid, name, desc, creator in cursor:
      print("{:4} {:20} {:10} {}".format(nid, name, creator, desc))


def list_filenames(cmd_name):
   cursor = connection.cursor()
   cursor.execute(
      """SELECT
        cheby_files.file_id,
        cheby_files.file_name,
        cheby_namespaces.namespace_name,
        cheby_files.created_on
      FROM cheby_files
      INNER JOIN cheby_namespaces
        ON cheby_files.namespace_id = cheby_namespaces.namespace_id""")
   print("{:4} {:20} {:16} {}".format('fid', 'filename', 'namespace', 'date'))
   print('------------------------------------------------------------------')
   for fid, filename, namespace, date in cursor.fetchall():
      print("{:4} {:20} {:16} {}".format(fid, filename, namespace, date))


def list_includes(cmd_name):
   cursor = connection.cursor()
   cursor.execute(
      """SELECT source_file_id, included_file_id
      FROM cheby_file_inclusions""")
   print("{:4} {:4}".format('fid', 'iid'))
   print('------------')
   for fid, iid in cursor.fetchall():
      print("{:4} {:4}".format(fid, iid))


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


def get_namespace_id(name):
   cursor = connection.cursor()
   cursor.execute(
      """SELECT namespace_id
         FROM cheby_namespaces
         WHERE namespace_name = :name""", name=name)
   rows = cursor.fetchall()
   if len(rows) == 0:
      return None
   return rows[0][0]
   

def cmd_get_namespace_id(cmd_name, *args):
   if len(args) != 1:
      sys.stderr.write(
         'usage: {} namespace\n'.format(cmd_name))
      return
   name = args[0]
   nid = get_namespace_id(name)
   print(nid)


def add_file(cmd_name, *args):
   if len(args) != 2:
      sys.stderr.write("usage: {} filename namespace\n".format(cmd_name))
      return
   filename = args[0]
   namespace = args[1]
   nid = get_namespace_id(namespace)
   if nid is None:
      sys.stderr.write("error: namespace '{}' not found\n".format(namespace))
      return
   content = open(filename).read()
   cursor = connection.cursor()
   cursor.execute(
      """INSERT INTO cheby_files
          (file_name, namespace_id, file_content)
         VALUES(:name, :nid, :content)""",
      name=filename,
      nid=nid,
      content=content)
   connection.commit()


def cat_file(cmd_name, *args):
   if len(args) != 1:
      sys.stderr.write("usage: {} filename\n".format(cmd_name))
      return
   filename = args[0]
   cursor = connection.cursor()
   cursor.execute(
      """SELECT file_content FROM cheby_files
         WHERE file_name = :name""", name=filename)
   for content, in cursor.fetchall():
      sys.stdout.write(content.read())

def add_include_by_id(cmd_name, *args):
   if len(args) != 2:
      sys.stderr.write("usage: {} file-id include-id\n".format(cmd_name))
      return
   fid = int(args[0])
   iid = int(args[1])
   cursor = connection.cursor()
   cursor.execute(
      """INSERT INTO cheby_file_inclusions
          (source_file_id, included_file_id)
         VALUES(:fid, :iid)""",
      fid=fid, iid=iid)
   connection.commit()
   
commands = {
   'show': show,
   'list-namespaces': list_namespaces,
   'remove-namespace': remove_namespace,
   'add-namespace': add_namespace,
   'get-namespace-id': cmd_get_namespace_id,
   'list-filenames': list_filenames,
   'add-file': add_file,
   'cat-file': cat_file,
   'list-includes': list_includes,
   'add-include-by-id': add_include_by_id
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
