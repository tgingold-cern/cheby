# Cheby

The Cheby project aims at defining a file format to describe the HW/SW
interface (the memory map), and a set of tools to generate HDL,
drivers, documentation... from these files.

The Cheby project is the successor of the Cheburashka and Wbgen tools.

Currently the tools are command-line tools.

## How to install cheby

The Cheby tools are written in Python, so you could use the standard
approach:

    $  python setup.py install [--user]

Add `--user` to install in user directory instead of a system wide
installation.

Python version 3 is recommended.

## Documentation

There is a user guide in the [doc/](doc) directory.  It contains a getting started
part with an example.

To build the documentation, simply run `make` from within the [doc/](doc) directory.

Please note that the documentation build process requires
[asciidoc](http://asciidoc.org/) and [asciidoctor](https://asciidoctor.org/).

The documentation for the extensions are in [doc/extensions](doc/extensions) directory.

## Release

To create a new release:

* Run cheby tests (proto/tests.py)

* Run simulation tests (testfiles/tb)

* document changes and issues in this README.md file

* increase the version in cheby/__init__.py and in doc/cheby-ug.txt

* generate the pdf documentation

* tag the git tree (and push)

* Announce on the cheby-codegen mailing list

* Update the wiki at https://gitlab.cern.ch/cohtdrivers/cheby/wikis/home

## Version 1.4 (dev)

Add x-hdl:pipeline to control pipelining of the root.

Add root:version for versionning.

Add attribute 'constant' to registers to get the value of version, map-version
or ident-code.

Fix --gen-gena-regctrl generation for inline multi-word register (issue#32)

gena2cheby: do not generate duplicate x-gena:preset attribute (issue#33)

Improve comments generation on ports (issue#35)

gena2cheby: set 'interface' to 'include' if 'include=int' was set (issue#23)

Add support for memories with ro access (issue#22)

Add attribute `include` for submaps (issue#36)

Add `memory` and `repeat` nodes to replace `array` (issue#39)

Add `interface` attribute to `memory`.

Ignore gena 'resize' attribute for --gen-hdl (issue#40).

Add `autoclear` port type.

Fix duplicate/incorrect assignments for --gen-hdl in case of holes and non
ordered fields (issue#41).

Fix pipeline for null-address buses (issue#41)

Support or-clr (aka 'srff' in Cheburashka) type.

Fix crash while generating hdl for a single register with cernbus (issue#45)

Correctly handle Rst polarity of CERN-BE bus (issue#47).
IMPORTANT: this is incompatible with previous Cheby behaviour.

gena2cheby now put the ident-code, map-version and semantic-mem-map-version
to the x-gena section instead of the x-cern-info section.

A new section x-map-info is now supported at the root with 2 attributes:
ident and memmap-version.  Values are written to the consts file.

Support added for enumerated types.

The tool gena2cheby now discards empty note, description and comment.

Attribute 'x-hdl:port' is now allowed in a register without
fields.  A warning is emitted.  (issue#58)

Attribute 'constant' is not allowed in a register with fields and
properly diagnosticed.  (issue#57)

Attribute 'x-hdl:type' can now be added to 'reg' and inherited by
the fields.  A field can overwrite the attribute.  (issue#59)

Emit warnings when 'x-hdl:busgroup' is ignored.  (issue#60)

For wbgen2cheby, WRITE_READ access is handled like
READ_WRITE (issue #63).

Styles 'vhdl-ohwr' and 'vhdl-orig' have been added for `--consts-style'.

'x-hdl:type: or-clr-out' has been added.  It behaves like 'or-clr' and
also outputs the current value.

'x-hdl:name-suffix' has been added at root.  It adds a suffix to the
name for hdl module name.

## Version 1.3

Add x-hdl:port to specify how ports are generated for registers (issue#11)

Add --c-style=arm to follow the CMSIS style (merge!10)

Support all submap cases, rework generated logic.

Add x-hdl:read-ack and x-hdl:write-ack attributes.

Add option '-i' to gena2cheby (to display ignored constructs).

Add option '-q' to gena2cheby (to not generate output).

Add 'note' as a common attribute.

For '--gen-gena-regctrl', add missing Rd/WrError signals in Area mux
sensitivity lists.

Handle large addresses (up to 32 bits).

'x_gena' has been renamed to 'x-gena' for uniformity.

Full translation of Cheburashka map by gena2cheby.

Add a 'do not edit' header to hdl generated files.

Fix byte and word address in comments for gena memmap file.

Use synchronous reset for expanded RMW and SRFF in generated regctrl code.

Size and repeat attributes are now a string with k/M/G suffixes allowed.

The attribute semantic-mem-map-version now generates a constant in Gena memmap file.

Handle x-gena.packages and gen.const attributes.

Handle x-gena.suppress-port attribute.

A pulse is now generated for strobe-write (it was already the case for
strobe-read).

wbgen2cheby now correctly place the write-strobe attribute (issue #28).

Synchronous reset are now generated by --gen-hdl instead of asynchronous one.
(See http://www.xilinx.com/support/documentation/white_papers/wp231.pdf to
 understand why this improves optimization on FPGAs).

wbgen2cheby now supports the version attribute.

## Version 1.2

Add --gen-custom to support user defined pass (merge!4)

Fix SILECS compatibility bugs (merge!3, merge!5)

Explain workflow for '--gen-c' (issue#3)

Fix padding of structures to their size in --gen-c.

Add '--consts-style' for '--gen-consts', and support VHDL constants generation.

By default, '--gen-gena-regctrl' does not use anymore the CommonVisual
components.  Use '--gena-common-visual' option to use them (issue#2)

Size of blocks, arrays and submap are now generated by '-gen-consts' (issue#4)

Fix address of external submap in '--gen-doc' (issue#5)

Generate per word strobe signals.

Generate constants for preset values (issue#6)

Uniformize markdown and HTML output (merge!9)

Gena memmap generation: use full prefix for code fields (issue#7)

Macros are now generated by --gen-c for fields.

Handle unaligned register in HDL generation (issue#8)

Fix incorrect decoding for some nested register (issue#9)

Fix duplicate prefix in some names (issue#9)

Add word-endian attribute to specify the word endianness (issue#14)

Fix python3 incompatibility in setup.py (issue#16)

## Version 1.1

The argument '--version' has been added to the tool.

Attributes 'write-strobe' and 'read-strobe' of 'x-hdl' applies only to
registers.  Documentation has been clarified.

Fix an incorrect slice bound in HDL generation.

Fix reading of a rw field of type wire.

Set unused bit to 0 while reading a register.

Document root 'x-hdl' extensions.

Add --gen-silecs to generate SILECS files.

Add --gen-consts option to generate a constants file.

## Version 1.0

Syntax of options has changed. Options that generate contents accept
the file as an optional argument.  If there is no filename, the
content is written on the standard output.  The input must be
specified with the -i/--input argument.  So to generate vhdl code for the
file example.cheby:

    $ cheby --gen-hdl example.vhdl -i example.cheby

The cheby tool is now able to generate HTML or Markdown documentation.
It also supports interconnect between AXI4 and WB.

## Version 0.2

This version offers backward compatiblity with wbgen files, and
provides an setup.py installer.

You can use the `wbgen2cheby` tool to convert from wbgen.

    Usage: wbgen2cheby FILE.wb > FILE.cheby

The tool generates on the standard output a cheby file that contains
extensions for wbgen compatibility.  You can then generate a VHDL file
from this cheby file:

    $ cheby --gen-wbgen-vhdl FILE.cheby > FILE.vhdl

## Version 0.1

The purpose of this version is to handle the Cheburashka files, to
generate HDL, and to understand all the features available.
Currently there is no real packaging.

Two tools are available:

* gena2cheby

    Usage: gena2cheby FILE

Convert the Cheburashka/Gena file to the Cheby file format.  The
result is sent to the standard output.  All valid files are supported,
all the tags and attributes for generating HDL are converted.  Some attributes
are currently ignored; the next step is to define how they will be converted.

Note that included submaps are not converted (but the name extension
is changed from .xml to .cheby).

The result follows the Cheby file format but many extensions (under
the 'x_gena' name) are created to support features not defined in the
Cheby core format.

* cheby

    Usage: cheby --gen-gena-memmap FILE

Generate a VHDL memory map file from FILE.  The result is sent to the
standard output.  The generated file is equivalent to the output of gena.py -m.

    Usage: cheby --gen-gena-regctrl FILE

Generate a VHDL regctrl file from FILE.  The result is sent to the standard
output.  The generated file is equivalent to the output of gena.py

    Usage: cheby --print-memmap FILE
    Usage: cheby --print-simple FILE

Display a textual description of the memory map described by FILE.
