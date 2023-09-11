#!/bin/sh

GHDL=${GHDL:-ghdl}
GHDL_FLAGS=--std=08
CHEBY=${CHEBY:-../../proto/cheby.py}

set -e

build_infra()
{
    $GHDL -a $GHDL_FLAGS wishbone_pkg.vhd
    $GHDL -a $GHDL_FLAGS cheby_pkg.vhd
    $GHDL -a $GHDL_FLAGS apb_tb_pkg.vhdl
    $GHDL -a $GHDL_FLAGS axi4_tb_pkg.vhdl
    $GHDL -a $GHDL_FLAGS wb_tb_pkg.vhdl
    $GHDL -a $GHDL_FLAGS cernbe_tb_pkg.vhdl
    $GHDL -a $GHDL_FLAGS avalon_tb_pkg.vhdl
    $GHDL -a $GHDL_FLAGS dpssram.vhdl
    $GHDL -a $GHDL_FLAGS block1_apb.vhdl
    $GHDL -a $GHDL_FLAGS block1_axi4.vhdl
    $GHDL -a $GHDL_FLAGS block1_wb.vhdl
    $GHDL -a $GHDL_FLAGS block1_cernbe.vhdl
    $GHDL -a $GHDL_FLAGS block1_avmm.vhdl
    $GHDL -a $GHDL_FLAGS sram2.vhdl
}

build_interface()
{
    name="$1"
    name_short="$2"

    echo "## Testing interface '${name}'"

    sed -e '/bus:/s/BUS/'"${name}"'/' -e '/name:/s/NAME/'"${name_short}"'/' < all1_BUS.cheby > all1_${name_short}.cheby
    $CHEBY --no-header --gen-hdl=all1_${name_short}.vhdl -i all1_${name_short}.cheby
    $GHDL -a $GHDL_FLAGS all1_${name_short}.vhdl
    $GHDL -a $GHDL_FLAGS all1_${name_short}_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS all1_${name_short}_tb --assert-level=error --wave=all1_${name_short}_tb.ghw
}

build_axi4_addrwidth()
{
    echo "## Testing AXI4 bus width $1 $2"

    sed -e "s/GRANULARITY/$2/" < addrwidth_axi4_sub_xxx.cheby > addrwidth_axi4_sub_${2}.cheby
    $CHEBY --gen-hdl=addrwidth_axi4_sub_${2}.vhdl -i addrwidth_axi4_sub_${2}.cheby

    sed -e "s/GRANULARITY/$1/" -e "s/SLAVE/$2/" < addrwidth_axi4_mst_xxx.cheby > addrwidth_axi4_mst_${1}.cheby
    $CHEBY --gen-hdl=addrwidth_axi4_mst_${1}.vhdl -i addrwidth_axi4_mst_${1}.cheby

    sed -e "s/GRANULARITY/$1/" -e "s/SLAVE/$2/" < addrwidth_axi4_xxx_tb.vhdl > addrwidth_axi4_${1}_tb.vhdl

    $GHDL -a $GHDL_FLAGS addrwidth_axi4_mst_${1}.vhdl
    $GHDL -a $GHDL_FLAGS addrwidth_axi4_sub_${2}.vhdl
    $GHDL -a $GHDL_FLAGS addrwidth_axi4_${1}_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS addrwidth_axi4_${1}_tb --assert-level=error --wave=addrwidth_axi4_${1}_tb.ghw
}

build_avalon_reg2()
{
    echo "## Testing Avalon (reg2)"

    sed -e '/bus:/s/BUS/avalon-lite-32/' -e '/name:/s/NAME/avalon/' \
        -e '/pipeline:/d' -e '/^  x-hdl:$/d' \
        < reg2_xxx.cheby > reg2_avalon.cheby
    $CHEBY --no-header --gen-hdl=reg2_avalon.vhdl -i reg2_avalon.cheby
    $GHDL -a $GHDL_FLAGS reg2_avalon.vhdl
    $GHDL -a $GHDL_FLAGS reg2_avalon_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS reg2_avalon_tb --assert-level=error --wave=reg2_avalon.ghw
}

build_wb_any()
{
    f=$1
    sed -e '/bus:/s/BUS/wb-32-be/' -e '/name:/s/NAME/wb/' < ${f}_xxx.cheby > ${f}_wb.cheby
    $CHEBY --no-header --gen-hdl=${f}_wb.vhdl -i ${f}_wb.cheby
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

build_buserr_any()
{
    name="$1"
    name_short="$2"

    sed -e '/bus:/s/BUS/'"${name}"'/' -e '/name:/s/NAME/'"${name_short}"'/' < buserr.cheby > buserr_${name_short}.cheby

    $CHEBY --no-header --gen-hdl=buserr_${name_short}.vhdl -i buserr_${name_short}.cheby

    $GHDL -a $GHDL_FLAGS buserr_${name_short}.vhdl
    $GHDL -a $GHDL_FLAGS buserr_${name_short}_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS buserr_${name_short}_tb --assert-level=error --wave=buserr_${name_short}_tb.ghw
}

build_buserr()
{
    echo "## Testing bus error"
    build_buserr_any "apb-32" "apb"
    build_buserr_any "axi4-lite-32" "axi4"
    build_buserr_any "wb-32-be" "wb"
}

build_all2()
{
    $CHEBY --no-header --gen-hdl=sub2_axi4.vhdl -i sub2_axi4.cheby
    $CHEBY --no-header --gen-hdl=all2_axi4.vhdl -i all2_axi4.cheby
    $GHDL -a $GHDL_FLAGS sub2_axi4.vhdl
    $GHDL -a $GHDL_FLAGS all2_axi4.vhdl
    $GHDL -a $GHDL_FLAGS all2_axi4_tb.vhdl
    $GHDL --elab-run $GHDL_FLAGS all2_axi4_tb --assert-level=error --wave=all2_axi4_tb.ghw
}


# Build packages
build_infra


# Avalon Reg 2
build_avalon_reg2

# AXI4 byte/word addresses
build_axi4_addrwidth byte byte
build_axi4_addrwidth word byte
build_axi4_addrwidth byte word

# Wishbone registers
build_wb_reg_simple
build_wb_reg
build_wb_reg_ac
build_wb_reg_const
build_wb_reg_orclr

# Test buses with bus error
build_buserr

#
build_all2


# Test buses without pipeline
echo "# Testing without pipeline"
sed -e '/PIPELINE/d' < all1_xxx.cheby > all1_BUS.cheby

build_interface "apb-32" "apb"
build_interface "avalon-lite-32" "avalon"
build_interface "axi4-lite-32" "axi4"
build_interface "cern-be-vme-32" "cernbe"
build_interface "wb-32-be" "wb"

# Test buses with various pipelining
for pl in "none" "rd" "wr" "in" "out" "rd-in" "rd-out" "wr-in" "wr-out" \
          "wr-in,rd-out" "rd-in,wr-out" "in,out" "all"
do
    echo "# Testing pipeline $pl"
    sed -e "s/PIPELINE/$pl/" < all1_xxx.cheby > all1_BUS.cheby

    build_interface "apb-32" "apb"
    build_interface "avalon-lite-32" "avalon"
    build_interface "axi4-lite-32" "axi4"
    build_interface "cern-be-vme-32" "cernbe"
    build_interface "wb-32-be" "wb"
done

echo "SUCCESS"
