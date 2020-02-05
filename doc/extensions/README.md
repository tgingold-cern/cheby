#Updates
##core
###1.0.0 -> 2.0.0
* merge 'note' with 'description'
## x-fesa:
###1.0.0 -> 2.0.0
* split persistence=PPM/Fesa/None to persistence=true/false and multiplexed=true/false
# Extensions

In december 2019, we decided to add versioning for the schema of the
core specifications and for the schema of the extensions.

The schema version is defined using semantic versioning.

The current extensions are described in the following sections.
## <a name="x-map-info">x-map-info
This extension is the successor of [x-cern-info](#x-cern-info) and some attributes previously used in x-gena as well.

It contains 2 possible attributes
*  ident
*  memmap-version

### ident
Ident is a unique identifier of a memory map which can be feed back to a ro register to provide information and identification about what type of board/firwmare the memory map belongs to.
The value itself is not standardized among the different CERN groups.

In RF we have a long standing list of idents (formarlly names ident-code in the old cheburashka based memory maps) for VME which are mastered centrally by John Molendijk (`john.molendijk@cern.ch`).
For uTCA based boards we start from scratch with a new list of idents. Currently there is no central person or location to award them and in fact the firmware does not yet provide any meaningful data. But a first [wiki page](https://wikis.cern.ch/pages/viewpage.action?pageId=122066518) has been created

* **Previous used ident-code attribute in x-cern-info/ident-code and x-gena/ident-code are migrated to x-map-info/ident**

### memmamp-version
The memorymap version attribut is now a semantic version only consisting of 3 parts with 8bits each. As an attribute value they have to be specified as a string separated by dots. The different parts are using the standard schema MAJOR.MINOR.PATCH as specified by [Semantic Versioning](https://semver.org)
These values are being exposed by according registers in the firmware/IP cores.

* **Previous x-cern-info/semantic-mem-map-version is migrated to x-map-info/memmap-version**
* **Previous x-gena/semantic-mem-map-version is migrated to x-map-info/memmap-version**
* **Previous x-gena/map-version which was a date-code is debriacted and should not longer be used in new maps**


## x-hdl

## x-gena

## x-fesa

## x-driver-edge

TBD: For now this is just the list of existing attributes, further documentation needs to be added
* name
* equipment-code
* module-type
* vme-base-addr
* endianness
* bus-type
* board-type
* driver-version
* driver-version-suffix
* schema-version
* description
* default-pci-bar-name
* generate-separate-library
* dma-mode
* pci-device-info

### pci-device-info

The PCI device info is mandatory for PCI modules as the kernel idenifies the board with this ID in order to know which driver to load to access the hardware.

TBD: Format

It is possible to not add all of the attributes if you have a driver which fits more than one card.

* vendor-id
* device-id
* subvendor-id
* subdevice-id

## x-conversions

## x-wbgen

## x-devicetree

## x-interrupts

# Deprecated extensions

## <a name="x-cern-info">x-cern-info
This attribute is deprecated! Please use [x-map-info](#x-map-info)
