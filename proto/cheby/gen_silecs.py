import cheby.tree as tree
from datetime import datetime

def gen_header(fd, name, owner, editor):
    fd.write(('<?xml version="1.0" encoding="UTF-8"?><SILECS-Design silecs-version="SILECS-1.m.p" created="{date}" updated="{date}"\n'
    '\txmlns:xsi="http://www.w3.org/2001/XMLSchema-instance\n'
    '\txsi:noNamespaceSchemaLocation="../../../.schemas/DesignSchema.xsd">\n'
    '\t<Information>\n'
    '\t\t<Owner user-login="{owner}"/>\n'
    '\t\t<Editor user-login="{editor}"/>\n'
    '\t</Information>\n'
    '\t<SILECS-Class name="{name}" version="1.0.0" domain="OPERATIONAL">\n'
    ).format(name=name, owner=owner, editor=editor, date=datetime.now().strftime('%d/%m/%y')))


def gen_block(fd, root, acc, synchro):
    for r in root.children:
        if isinstance(r, tree.Reg):
            if r.access == acc:
                fd.write (
                    '\t\t\t<Register name="{}" format="uint{}" synchro="{}">'
                    '</Register>\n'.format(r.name, r.width, synchro))


def gen_trailer(fd):
    fd.write("\t</SILECS-Class>\n")
    fd.write("</SILECS-Design>\n")


def generate_silecs(fd, root):
    gen_header(fd, root.name, "owner", "editor")
    block_name = root.name[:7]
    fd.write('\t\t<Block name="{}_ro" area="MEMORY" mode="READ-ONLY">\n'.format(
        block_name))
    gen_block(fd, root, 'ro', 'MASTER')
    fd.write('\t\t</Block>\n')
    fd.write('\t\t<Block name="{}_rw" mode="READ-WRITE">\n'.format(
        block_name))
    gen_block(fd, root, 'rw', 'SLAVE')
    fd.write('\t\t</Block>\n')
    gen_trailer(fd)
