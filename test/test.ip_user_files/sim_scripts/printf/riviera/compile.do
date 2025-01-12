vlib work
vlib riviera

vlib riviera/xil_defaultlib

vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl/verilog" "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl" \
"../../../../test.srcs/sources_1/ip/printf/sim/printf.v" \


vlog -work xil_defaultlib \
"glbl.v"

