import os


def generate_custom(fd, root):
    """Opens the gen_custom.py file from the invoking directory and
    runs generate_custom(fd, root)
    """
    fn = os.getcwd() + "/gen_custom.py"
    if os.path.isfile(fn):
        exec(open(fn).read(), globals())
        generate_custom(fd, root)
    else:
        print("Error: file %s not found" % fn)
