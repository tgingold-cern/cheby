#!/bin/sh

GHDL=${GHDL:-ghdl}
GHDL_FLAGS=--std=08
CHEBY=${CHEBY:-../../proto/cheby.py}

set -e

build_infra()
{
 $GHDL -a $GHDL_FLAGS wishbone_pkg.vhd
 $GHDL -a $GHDL_FLAGS cheby_pkg.vhd
 $GHDL -a $GHDL_FLAGS axi4_tb_pkg.vhdl
 $GHDL -a $GHDL_FLAGS wb_tb_pkg.vhdl
 $GHDL -a $GHDL_FLAGS cernbe_tb_pkg.vhdl
 $GHDL -a $GHDL_FLAGS dpssram.vhdl
 $GHDL -a $GHDL_FLAGS block1_axi4.vhdl
 $GHDL -a $GHDL_FLAGS block1_wb.vhdl
 $GHDL -a $GHDL_FLAGS block1_cernbe.vhdl
 $GHDL -a $GHDL_FLAGS sram2.vhdl
}

build_axi4()
{
 echo "## Testing AXI4"

 sed -e '/bus:/s/BUS/axi4-lite-32/' -e '/name:/s/NAME/axi4/' < all1_BUS.cheby > all1_axi4.cheby
 $CHEBY --gen-hdl=all1_axi4.vhdl -i all1_axi4.cheby
 $GHDL -a $GHDL_FLAGS all1_axi4.vhdl
 $GHDL -a $GHDL_FLAGS all1_axi4_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS all1_axi4_tb --assert-level=error --wave=all1_axi4_tb.ghw
}

build_wb()
{
 echo "## Testing WB"

  sed -e '/bus:/s/BUS/wb-32-be/' -e '/name:/s/NAME/wb/' < all1_BUS.cheby > all1_wb.cheby
 $CHEBY --gen-hdl=all1_wb.vhdl -i all1_wb.cheby
 $GHDL -a $GHDL_FLAGS all1_wb.vhdl
 $GHDL -a $GHDL_FLAGS all1_wb_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS all1_wb_tb --assert-level=error --wave=all1_wb_tb.ghw
}

build_cernbe()
{
 echo "## Testing CERN-BE"

 sed -e '/bus:/s/BUS/cern-be-vme-32/' -e '/name:/s/NAME/cernbe/' < all1_BUS.cheby > all1_cernbe.cheby
 $CHEBY --gen-hdl=all1_cernbe.vhdl -i all1_cernbe.cheby
 $GHDL -a $GHDL_FLAGS all1_cernbe.vhdl
 $GHDL -a $GHDL_FLAGS all1_cernbe_tb.vhdl
 $GHDL --elab-run $GHDL_FLAGS all1_cernbe_tb --assert-level=error --wave=all1_cernbe_tb.ghw
}

build_wb_any()
{
    f=$1
    sed -e '/bus:/s/BUS/wb-32-be/' -e '/name:/s/NAME/wb/' < ${f}_xxx.cheby > ${f}_wb.cheby
    $CHEBY --gen-hdl=${f}_wb.vhdl -i ${f}_wb.cheby
    $GHDL -a $GHDL_FLAGS ${f}_wb.vhdl
    $GHDL -a $GHDL_FLAGS ${f}_wb_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS ${f}_wb_tb --assert-level=error --wave=${f}_wb.ghw
}

build_wb_reg_simple()
{
    echo "## Testing regs simple (WB)"

    # Simple test.
    # TODO: check strobe
    #       check wire + strobe read
    build_wb_any reg2
}

build_wb_reg()
{
    echo "## Testing regs (WB)"
    for f in reg2pip reg2wo reg2ro reg2rw reg3rw reg3wrw reg4wrw reg5rwbe reg5rwle; do
        build_wb_any $f
    done
}

build_wb_reg_ac()
{
    echo "## Testing autoclear (WB)"
    build_wb_any reg6ac
}

build_wb_reg_const()
{
    echo "## Testing const (WB)"
    build_wb_any reg7const
}

build_wb_reg_orclr()
{
    echo "## Testing or-clr (WB)"
    build_wb_any reg8orclr
}

build_infra
build_wb_reg_simple
build_wb_reg
build_wb_reg_ac
build_wb_reg_const
build_wb_reg_orclr

# Test buses without pipeline.
sed -e '/PIPELINE/d' < all1_xxx.cheby > all1_BUS.cheby
build_wb
build_axi4
build_cernbe

# Test buses with various pipelining.
for pl in "none" "rd" "wr" "in" "out" "rd-in" "rd-out" "wr-in" "wr-out" \
          "wr-in,rd-out" "rd-in,wr-out" "in,out"
do
    echo "### Testing pipeline $pl"
    sed -e "s/PIPELINE/$pl/" < all1_xxx.cheby > all1_BUS.cheby
    build_wb
    build_axi4
    build_cernbe
done

echo "SUCCESS"
