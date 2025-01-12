vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib

vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl/verilog" "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl" \
"../../../../test.srcs/sources_1/ip/printf/sim/printf.v" \


vlog -work xil_defaultlib \
"glbl.v"

