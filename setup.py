from setuptools import setup

setup(
    name="cheby",
    version="0.2",
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
