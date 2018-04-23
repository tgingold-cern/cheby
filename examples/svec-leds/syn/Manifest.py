target = "xilinx"
action = "synthesis"

syn_device = "xc6slx150t"
syn_grade = "-3"
syn_package = "fgg900"
syn_top = "svec_leds_top"
syn_project = "svec_leds_top.xise"
syn_tool = "ise"

modules = {
    "local" : [
        "../top",
    ],
}
