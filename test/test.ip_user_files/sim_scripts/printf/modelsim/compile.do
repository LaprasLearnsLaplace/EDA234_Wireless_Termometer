vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl/verilog" "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl" \
"../../../../test.srcs/sources_1/ip/printf/sim/printf.v" \


vlog -work xil_defaultlib \
"glbl.v"

