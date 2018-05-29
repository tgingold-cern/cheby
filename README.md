# Cheby

The Cheby project aims at defining a file format to describe the HW/SW
interface (the memory map), and a set of tools to generate HDL,
drivers, documentation... from these files.

The Cheby project is the successor of the Cheburashka and Wbgen tools.

## Version 0.1

The purpose of this version is to handle the Cheburashka files, to
generate HDL, and to understand all the features available.
TCurrently there is no real packaging.

Two tools are available:

* gena2cheby.py

Usage: gena2cheby.py FILE

Convert the Cheburashka/Gena file to the Cheby file format.  The
result is sent to the standard output.  All valid files are supported,
all the tags and attributes for generating HDL are converted.  Some attributes
are currently ignored; the next step is to define how they will be converted.

Note that included submaps are not converted (but the name extension
is changed from .xml to .cheby).

The result follows the Cheby file format but many extensions (under
the 'x_gena' name) are created to support features not defined in the
Cheby core format.

* cheby.py

Usage: cheby.py --gen-gena-memmap FILE

Generate a VHDL memory map file from FILE.  The result is sent to the
standard output.  The generated file is equivalent to the output of gena.py -m.

Usage: cheby.py --gen-gena-regctrl FILE

Generate a VHDL regctrl file from FILE.  The result is sent to the standard
output.  The generated file is equivalent to the output of gena.py

Usage: cheby.py --print-memmap FILE
Usage: cheby.py --print-simple FILE

Display a textual description of the memory map described by FILE.