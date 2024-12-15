vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib -64 -incr "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl/verilog" "+incdir+../../../../THERMO.srcs/sources_1/ip/temp_vi/hdl" \
"../../../../THERMO.srcs/sources_1/ip/temp_vi/sim/temp_vi.v" \


vlog -work xil_defaultlib \
"glbl.v"

