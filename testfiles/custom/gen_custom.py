import cheby.tree as tree

def gen_header(fd, root):
    tag = root.name.upper()+'_FUNCTIONS_H_'
    fd.write('#ifndef {}\n'.format(tag))
    fd.write('#define {}\n\n'.format(tag))

def gen_footer(fd, root):
    fd.write('\n#endif\n')

def gen_macro(fd, root, acc, prefix, middle, suffix):
    for r in root.children:
        if isinstance(r, tree.Reg):
            if r.access == acc:
                if 'set' in prefix:
                    fd.write('{}{}{}{}{}'.format(
                        prefix, r.name, middle, r.c_address, suffix))
                else:
                    fd.write('{}{}{}{}{}'.format(
                        prefix, r.c_address, middle, r.name, suffix))

def generate_custom(fd, root):
    setpref="block->set"
    setmid="(fasec->read_reg("
    setsuff="));\\\n"
    getpref="fasec->write_reg("
    getmid=",block->get"
    getsuff="());\\\n"

    gen_header(fd, root)
    fd.write('//read functions ro data\n')
    fd.write('#define {}_read_ro \\\n'.format(root.name))
    gen_macro(fd, root, 'ro', setpref, setmid, setsuff)
    fd.write('\n//read functions rw data\n')
    fd.write('#define {}_read_rw \\\n'.format(root.name))
    gen_macro(fd, root, 'rw', setpref, setmid, setsuff)
    fd.write('\n//write functions rw data\n')
    fd.write('#define {}_write_rw \\\n'.format(root.name))
    gen_macro(fd, root, 'rw', getpref, getmid, getsuff)
    gen_footer(fd, root)
