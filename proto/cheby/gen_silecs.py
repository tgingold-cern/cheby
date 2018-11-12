import cheby.tree as tree


def gen_header(fd, name, owner, editor):
    fd.write("""<?xml version="1.0" encoding="UTF-8"?>
<SILECS-Design silecs-version="SILECS-1.m.p" created="08/01/18" updated="08/01/18"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="../../../.schemas/DesignSchema.xsd">
    <Information>
        <Owner user-login="{owner}"/>
        <Editor user-login="{editor}"/>
    </Information>
    <SILECS-Class name="{name}" version="1.0.0" domain="OPERATIONAL">
    """.format(name=name, owner=owner, editor=editor))


def gen_block(fd, root, acc, synchro):
    for r in root.children:
        if isinstance(r, tree.Reg):
            if r.access == acc:
                fd.write (
                    '         '
                    '<Register name="{}" format="uint{}" synchro="{}">'
                    '</Register>\n'.format(r.name, r.width, synchro))


def gen_trailer(fd):
    fd.write("    </SILECS-Class>\n")
    fd.write("</SILECS-Design>\n")


def generate_silecs(fd, root):
    gen_header(fd, root.name, "owner", "editor")
    block_name = root.name[:7]
    fd.write('   <Block name="{}_ro" area="MEMORY" mode="READ-ONLY">\n'.format(
        block_name))
    gen_block(fd, root, 'ro', 'MASTER')
    fd.write('   </Block>\n')
    fd.write('   <Block name="{}_rw" mode="READ-WRITE">\n'.format(
        block_name))
    gen_block(fd, root, 'rw', 'SLAVE')
    fd.write('   </Block>\n')
    gen_trailer(fd)
