#!/bin/sh

GHDL=${GHDL:-ghdl}

set -e

$GHDL -a repro.vhdl sub_repro.vhdl tb_repro.vhdl
$GHDL -e tb_repro
$GHDL -r tb_repro --stop-time=200ns | tee | grep OK
