#!/bin/sh

GHDL=${GHDL:-ghdl}
GHDL_FLAGS=--std=08
CHEBY=${CHEBY:-../../proto/cheby.py}

set -e

build_infra()
{
 $GHDL -a $GHDL_FLAGS wishbone_pkg.vhd
 $GHDL -a $GHDL_FLAGS wbgen2_pkg.vhd
 $GHDL -a $GHDL_FLAGS axi4_tb_pkg.vhdl
 $GHDL -a $GHDL_FLAGS wb_tb_pkg.vhdl
 $GHDL -a $GHDL_FLAGS dpssram.vhdl
 $GHDL -a $GHDL_FLAGS block1_axi4.vhdl
 $GHDL -a $GHDL_FLAGS block1_wb.vhdl
}

build_axi4()
{
 echo "## Testing AXI4"

 sed -e '/bus:/s/xxx/axi4-lite-32/' -e '/name:/s/NAME/axi4/' < array1_xxx.cheby > array1_axi4.cheby
 $CHEBY --gen-hdl=array1_axi4.vhdl -i array1_axi4.cheby
 $GHDL -a $GHDL_FLAGS array1_axi4.vhdl
 $GHDL -a $GHDL_FLAGS array1_axi4_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS array1_axi4_tb --assert-level=error --wave=array1_axi4_tb.ghw
}

build_wb()
{
 echo "## Testing WB"

 # Simple test.
 # TODO: check strobe
 #       check wire + strobe read
  sed -e '/bus:/s/BUS/wb-32-be/' -e '/name:/s/NAME/wb/' < reg2_xxx.cheby > reg2_wb.cheby
 $CHEBY --gen-hdl=reg2_wb.vhdl -i reg2_wb.cheby
 $GHDL -a $GHDL_FLAGS reg2_wb.vhdl
 $GHDL -a $GHDL_FLAGS reg2_wb_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS --std=08 reg2_wb_tb --stop-time=1us

  sed -e '/bus:/s/xxx/wb-32-be/' -e '/name:/s/NAME/wb/' < array1_xxx.cheby > array1_wb.cheby
 $CHEBY --gen-hdl=array1_wb.vhdl -i array1_wb.cheby
 $GHDL -a $GHDL_FLAGS array1_wb.vhdl
 $GHDL -a $GHDL_FLAGS array1_wb_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS array1_wb_tb --assert-level=error --vcd=array1_wb_tb.vcd
}

build_cernbe()
{
 echo "## Testing CERN-BE"

 sed -e '/bus:/s/xxx/cern-be-vme-32/' -e '/name:/s/NAME/cernbe/' < array1_xxx.cheby > array1_cernbe.cheby
 $CHEBY --gen-hdl=array1_cernbe.vhdl -i array1_cernbe.cheby
 $GHDL -a $GHDL_FLAGS array1_cernbe.vhdl
 # No testbench (yet).
}

build_infra
build_wb
build_axi4
build_cernbe

echo "SUCCESS"
