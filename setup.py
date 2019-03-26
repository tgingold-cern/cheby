from setuptools import setup

# Import version
exec(open('proto/cheby/__init__.py').read())

setup(
    name="cheby",
    version=__version__,
    packages=['cheby', 'cheby.wbgen'],
    package_dir={'': 'proto'},
    entry_points={
        'console_scripts': [
            'cheby = cheby.main:main',
            'gena2cheby = cheby.gena2cheby:main',
            'wbgen2cheby = cheby.wbgen2cheby:main'
        ]
    },

    author='CERN',
    author_email='cheby-codegen@cern.ch',
    description='Generate HDL/C/Doc from HW/SW interface description',
    license='GPLv2+',
    keywords="VHDL HDL registers driver",
    url='https://gitlab.cern.ch/cohtdrivers/cheby',

    install_requires=[
        'pyyaml',
    ],
)
