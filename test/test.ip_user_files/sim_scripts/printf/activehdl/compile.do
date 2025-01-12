vlib work
vlib activehdl

vlib activehdl/xil_defaultlib

vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl/verilog" "+incdir+../../../../test.srcs/sources_1/ip/printf/hdl" \
"../../../../test.srcs/sources_1/ip/printf/sim/printf.v" \


vlog -work xil_defaultlib \
"glbl.v"

