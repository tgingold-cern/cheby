from setuptools import setup

setup(
    name="Cheby",
    version="0.1",
    packages=['cheby'],
    package_dir={'': 'proto'},
    entry_points={
        'console_scripts': [
            'cheby = cheby.main:main'
        ]
    },

    author='CERN',
    author_email='cheby-codegen@cern.ch',
    description='Generate HDL/C/Doc from HW/SW interface description',
    license='GPLv2+',
    keywords="VHDL HDL registers driver",
    url='https://gitlab.cern.ch/cohtdrivers/cheby'
)
