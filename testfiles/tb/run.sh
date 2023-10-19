#!/bin/bash

GHDL=${GHDL:-ghdl}
GHDL_FLAGS=--std=08
CHEBY=${CHEBY:-../../proto/cheby.py}
REGEN=${REGEN:false}

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

build_any()
{
    local file_names=();
    local file_names_ext=();
    local tb_file_name="";
    if [ "$#" -eq 1 ]; then
        file_names+=("$1")
        file_names_ext+=("$1")
        tb_file_name="$1_tb"
    elif [ "$#" -eq 2 ]; then
        file_names+=("$1")
        file_names_ext+=("$2")
        tb_file_name="$1_tb"
    elif [ "$#" -ge 3 ]; then
        local args=("$@")
        for ((i = 0; i < ${#args[@]} - 2; i += 2)); do
          file_names+=("${args[i]}")
          file_names_ext+=("${args[i + 1]}")
        done
        tb_file_name="${args[${#args[@]} - 1]}"
    fi

    echo "### Building"
    for (( i = 0; i < ${#file_names[@]}; i++ )); do
        $CHEBY --no-header -i "${file_names[$i]}.cheby" --gen-hdl="${file_names[$i]}.vhdl"
    done

    if [[ "${REGEN}" == "true" || "${REGEN}" == true ]]; then
        echo "### Update output"
        for (( i = 0; i < ${#file_names[@]}; i++ )); do
            cp "${file_names[$i]}.vhdl" "golden_files/${file_names_ext[$i]}.vhdl"
        done

    else
        echo "### Verifying generated output"
        for (( i = 0; i < ${#file_names[@]}; i++ )); do
            cmp "${file_names[$i]}.vhdl" "golden_files/${file_names_ext[$i]}.vhdl"
        done

        echo "### Verify simulation"
        for (( i = 0; i < ${#file_names[@]}; i++ )); do
            $GHDL -a $GHDL_FLAGS "${file_names[$i]}.vhdl"
        done
        $GHDL -a $GHDL_FLAGS "${tb_file_name}.vhdl"
        $GHDL --elab-run $GHDL_FLAGS "${tb_file_name}" --assert-level=error --wave="${tb_file_name}.ghw"
    fi
}

build_avalon_reg2()
{
    echo "## Testing Avalon (reg2)"
    sed -e '/bus:/s/BUS/avalon-lite-32/' -e '/name:/s/NAME/avalon/' \
        -e '/pipeline:/d' -e '/^  x-hdl:$/d' \
        < reg2_xxx.cheby > reg2_avalon.cheby

    build_any "reg2_avalon"
}

build_axi4_addrwidth()
{
    echo "## Testing AXI4 bus width $1 $2"
    sed -e "s/GRANULARITY/$2/" < addrwidth_axi4_sub_xxx.cheby > addrwidth_axi4_sub_${2}.cheby
    sed -e "s/GRANULARITY/$1/" -e "s/SLAVE/$2/" < addrwidth_axi4_mst_xxx.cheby > addrwidth_axi4_mst_${1}.cheby
    sed -e "s/GRANULARITY/$1/" -e "s/SLAVE/$2/" < addrwidth_axi4_xxx_tb.vhdl > addrwidth_axi4_${1}_tb.vhdl

    build_any "addrwidth_axi4_mst_${1}" "addrwidth_axi4_mst_${1}-${2}" "addrwidth_axi4_sub_${2}" "addrwidth_axi4_sub_${2}-${1}" "addrwidth_axi4_${1}_tb"
}

build_wb_any()
{
    f=$1
    sed -e '/bus:/s/BUS/wb-32-be/' -e '/name:/s/NAME/wb/' < ${f}_xxx.cheby > ${f}_wb.cheby

    build_any "${f}_wb"
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

build_all1_any()
{
    name="$1"
    name_short="$2"
    pipeline="$3"

    echo "## Testing interface '${name}' (${pipeline})"
    sed -e '/bus:/s/BUS/'"${name}"'/' \
        -e '/name: all1_/s/NAME/'"${name_short}"'/' \
        -e '/pipeline:/s/PIPELINE/'"${pipeline}"'/' \
        < all1_xxx.cheby > all1_${name_short}.cheby

    build_any "all1_${name_short}" "all1_${name_short}_${pipeline}"
}

build_all2()
{
    echo "## Testing AXI4 bus"

    build_any "sub2_axi4" "sub2_axi4" "all2_axi4" "all2_axi4" "all2_axi4_tb"
}

build_buserr_any()
{
    name="$1"
    name_short="$2"

    echo "## Testing bus error for interface '${name}'"
    sed -e '/bus:/s/BUS/'"${name}"'/' -e '/name:/s/NAME/'"${name_short}"'/' < buserr.cheby > buserr_${name_short}.cheby

    build_any "buserr_${name_short}"
}

build_wmask_any()
{
    name="$1"
    name_short="$2"

    echo "## Testing register write mask for interface '${name}'"
    sed -e '/bus:/s/BUS/'"${name}"'/' -e '/name:/s/NAME/'"${name_short}"'/' < wmask.cheby > wmask_${name_short}.cheby

    build_any "wmask_${name_short}"
}

build_lock_any()
{
    name="$1"
    name_short="$2"

    echo "## Testing locking for interface '${name}'"
    sed -e '/bus:/s/BUS/'"${name}"'/' -e '/name:/s/NAME/'"${name_short}"'/' < lock.cheby > lock_${name_short}.cheby

    build_any "lock_${name_short}"
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

# Test buses with various pipelining
for pl in "none" "rd" "wr" "in" "out" "rd-in" "rd-out" "wr-in" "wr-out" \
          "wr-in,rd-out" "rd-in,wr-out" "in,out" "all"
do
    build_all1_any "apb-32" "apb" "${pl}"
    build_all1_any "avalon-lite-32" "avalon" "${pl}"
    build_all1_any "axi4-lite-32" "axi4" "${pl}"
    build_all1_any "cern-be-vme-32" "cernbe" "${pl}"
    build_all1_any "wb-32-be" "wb" "${pl}"
done

#
build_all2

# Test buses with bus error
build_buserr_any "apb-32" "apb"
build_buserr_any "axi4-lite-32" "axi4"
build_buserr_any "wb-32-be" "wb"

# Test buses with register write mask
build_wmask_any "apb-32" "apb"
build_wmask_any "avalon-lite-32" "avalon"
build_wmask_any "axi4-lite-32" "axi4"
build_wmask_any "wb-32-be" "wb"

# Test locking
build_lock_any "apb-32" "apb"

echo "SUCCESS"
