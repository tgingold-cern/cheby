vlog -novopt +acc axi4_lite_if.sv axi_gpio.sv axi_gpio_expanded.sv
vcom +acc ../../testfiles/tb/wishbone_pkg.vhd ../../testfiles/tb/wb_tb_pkg.vhdl
vcom +acc gpios.vhdl gpios_tb.vhdl
#vsim -c gpios_tb
