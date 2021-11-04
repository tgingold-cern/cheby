#include "include\MemMapDSP_const.h"

unsigned int get_firmwareVersion() {
	unsigned int* preg = (unsigned int*)firmwareVersion;
	return (unsigned int) *preg;
}
// read-only: firmwareVersion

unsigned int get_memMapVersion() {
	unsigned int* preg = (unsigned int*)memMapVersion;
	return (unsigned int) *preg;
}
// read-only: memMapVersion

unsigned int get_designerID() {
	unsigned int* preg = (unsigned int*)designerID;
	return (unsigned int) *preg;
}
// read-only: designerID

unsigned int get_designerID_fwDesigner() {
	unsigned int* preg = (unsigned int*)designerID;
	unsigned int b_lsb = 0;
	unsigned int bval = ( (*preg & designerID_fwDesigner) >> b_lsb );
	return bval;
}
// read-only: designerID_fwDesigner

unsigned int get_designerID_hwDesigner() {
	unsigned int* preg = (unsigned int*)designerID;
	unsigned int b_lsb = 16;
	unsigned int bval = ( (*preg & designerID_hwDesigner) >> b_lsb );
	return bval;
}
// read-only: designerID_hwDesigner

